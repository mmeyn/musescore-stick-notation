// Solmization logic: maps a note's pitch (relative to a movable "do") to a
// solfège syllable, independent of the MuseScore plugin API so it stays
// easy to reason about and (in principle) unit-test outside MuseScore.
//
// All MuseScore-specific inputs are plain numbers:
//   - tpc:   MuseScore "tonal pitch class" of the note (note.tpc1, concert pitch)
//   - pitch: absolute MIDI pitch of the note (note.pitch, concert pitch)
//   - keySig: number of sharps (positive) / flats (negative) at that point,
//             as returned by Cursor.keySignature

.pragma library

// MuseScore's TPC space: tpc 13..19 are the natural letters F C G D A E B
// (circle-of-fifths order). Each +/-7 shifts the accidental by one semitone.
var FIFTHS_LETTERS = ["F", "C", "G", "D", "A", "E", "B"];

// Natural semitone offset from C for each letter, and its index in the
// *diatonic* (alphabetical) letter order C D E F G A B used for scale-degree
// counting.
var LETTER_INFO = {
    "C": { natural: 0, diatonicIndex: 0 },
    "D": { natural: 2, diatonicIndex: 1 },
    "E": { natural: 4, diatonicIndex: 2 },
    "F": { natural: 5, diatonicIndex: 3 },
    "G": { natural: 7, diatonicIndex: 4 },
    "A": { natural: 9, diatonicIndex: 5 },
    "B": { natural: 11, diatonicIndex: 6 }
};

var MAJOR_SCALE_SEMITONES = [0, 2, 4, 5, 7, 9, 11]; // do re mi fa so la ti

// Key signature (-7..7, negative = flats) -> major tonic {letter, acc}
var MAJOR_TONIC_BY_KEYSIG = {
    "-7": { letter: "C", acc: -1 }, "-6": { letter: "G", acc: -1 },
    "-5": { letter: "D", acc: -1 }, "-4": { letter: "A", acc: -1 },
    "-3": { letter: "E", acc: -1 }, "-2": { letter: "B", acc: -1 },
    "-1": { letter: "F", acc: 0 },  "0": { letter: "C", acc: 0 },
    "1": { letter: "G", acc: 0 },   "2": { letter: "D", acc: 0 },
    "3": { letter: "A", acc: 0 },   "4": { letter: "E", acc: 0 },
    "5": { letter: "B", acc: 0 },   "6": { letter: "F", acc: 1 },
    "7": { letter: "C", acc: 1 }
};

// Key signature (-7..7) -> relative natural-minor tonic {letter, acc}
var MINOR_TONIC_BY_KEYSIG = {
    "-7": { letter: "A", acc: -1 }, "-6": { letter: "E", acc: -1 },
    "-5": { letter: "B", acc: -1 }, "-4": { letter: "F", acc: 0 },
    "-3": { letter: "C", acc: 0 },  "-2": { letter: "G", acc: 0 },
    "-1": { letter: "D", acc: 0 },  "0": { letter: "A", acc: 0 },
    "1": { letter: "E", acc: 0 },   "2": { letter: "B", acc: 0 },
    "3": { letter: "F", acc: 1 },   "4": { letter: "C", acc: 1 },
    "5": { letter: "G", acc: 1 },   "6": { letter: "D", acc: 1 },
    "7": { letter: "A", acc: 1 }
};

function mod(n, m) {
    return ((n % m) + m) % m;
}

// tpc (MuseScore tonal pitch class) -> { letter, acc }
function tpcToLetterAcc(tpc) {
    var idx = tpc - 13; // 13 == F natural, start of the natural-letter block
    var level = Math.floor(idx / 7);
    var letterIdx = mod(idx, 7);
    return { letter: FIFTHS_LETTERS[letterIdx], acc: level };
}

function letterAccPitchClass(letterAcc) {
    return mod(LETTER_INFO[letterAcc.letter].natural + letterAcc.acc, 12);
}

// doMode: "major" | "minor" | "fixed"
// fixedLetterAcc: { letter: "C".."B", acc: -1|0|1 }, only used when
// doMode === "fixed" (this also covers the "do = c" case)
function getDoReference(doMode, fixedLetterAcc, keySig) {
    if (doMode === "major") {
        return MAJOR_TONIC_BY_KEYSIG[String(keySig)] || { letter: "C", acc: 0 };
    }
    if (doMode === "minor") {
        return MINOR_TONIC_BY_KEYSIG[String(keySig)] || { letter: "A", acc: 0 };
    }
    return fixedLetterAcc;
}

// Returns { degreeIndex: 0..6, deviation: integer semitones (0 = diatonic,
// +1 raised, -1 lowered, other = double alteration / unusual spelling) }
function analyzeNote(tpc, pitch, doRef) {
    var noteLetterAcc = tpcToLetterAcc(tpc);
    var degreeIndex = mod(
        LETTER_INFO[noteLetterAcc.letter].diatonicIndex - LETTER_INFO[doRef.letter].diatonicIndex,
        7
    );
    var degreeNaturalSemitone = MAJOR_SCALE_SEMITONES[degreeIndex];

    var doPitchClass = letterAccPitchClass(doRef);
    var notePitchClass = mod(pitch, 12);
    var offsetFromDo = mod(notePitchClass - doPitchClass, 12);

    var deviation = offsetFromDo - degreeNaturalSemitone;
    if (deviation > 6) deviation -= 12;
    if (deviation < -6) deviation += 12;

    return { degreeIndex: degreeIndex, deviation: deviation };
}

function accidentalSuffix(deviation) {
    var symbol = deviation > 0 ? "♯" : "♭"; // sharp / flat
    var count = Math.abs(deviation);
    var s = "";
    for (var i = 0; i < count; i++) s += symbol;
    return s;
}

// preset: { base:[7], short:[7], sharp:[7 or null], flat:[7 or null] }
function syllableFor(tpc, pitch, doRef, preset, useShortForm) {
    var a = analyzeNote(tpc, pitch, doRef);
    var degreeIndex = a.degreeIndex;
    var deviation = a.deviation;

    if (deviation === 0) {
        return useShortForm ? preset.short[degreeIndex] : preset.base[degreeIndex];
    }
    if (deviation === 1 && preset.sharp[degreeIndex]) {
        return preset.sharp[degreeIndex];
    }
    if (deviation === -1 && preset.flat[degreeIndex]) {
        return preset.flat[degreeIndex];
    }
    // Unusual spelling (double alteration, or a raised/lowered degree that
    // has no dedicated syllable in this preset): fall back to the plain
    // degree syllable plus an explicit accidental marker.
    return preset.base[degreeIndex] + accidentalSuffix(deviation);
}
