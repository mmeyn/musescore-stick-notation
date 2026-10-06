// Solmization syllable presets.
//
// Each preset gives, for scale degrees 1-7 (do re mi fa so la ti):
//   base:  the plain diatonic syllable
//   short: the single-consonant shorthand (used when "unaltered tones get
//          the short form" is enabled, to visually set alterations apart)
//   sharp: syllable for a degree raised by one semitone (null where the
//          tradition has no such syllable, e.g. raised mi/ti)
//   flat:  syllable for a degree lowered by one semitone (null where the
//          tradition has no such syllable, e.g. lowered do/fa)
//
// Raised syllables ("Hochalterationen") are always the "i"-vowel set
// (di ri fi si li), which is consistent across sources. The lowered
// syllables ("Tiefalterationen") differ by vowel/author tradition:
//   - dunkler: mixed a/o/u darkening (ra ma su lo ta) - the "ma/lo/ta"
//     core is attested as the most common Tiefalterationen in German
//     relative-solmization teaching, with "su" for lowered so.
//   - A: same core, but "sa" instead of "su" for lowered so (the other
//     commonly seen variant for that one syllable).
//   - E: single "e"-vowel darkening (ra me se le te), as in the
//     English/Kodály movable-do tradition - re stays "ra" to avoid
//     colliding with the unaltered "re".
//   - U: single "u"-vowel darkening (ru mu su lu tu), per Hundoegger's
//     Tonika-Do method.

.pragma library

var PRESETS = {
    dunkler: {
        id: "dunkler",
        label: "ra ma su lo ta",
        base:  ["do", "re", "mi", "fa", "so", "la", "ti"],
        short: ["d",  "r",  "m",  "f",  "s",  "l",  "t"],
        sharp: ["di", "ri", null, "fi", "si", "li", null],
        flat:  [null, "ra", "ma", null, "su", "lo", "ta"]
    },
    A: {
        id: "A",
        label: "ra ma sa lo ta",
        base:  ["do", "re", "mi", "fa", "so", "la", "ti"],
        short: ["d",  "r",  "m",  "f",  "s",  "l",  "t"],
        sharp: ["di", "ri", null, "fi", "si", "li", null],
        flat:  [null, "ra", "ma", null, "sa", "lo", "ta"]
    },
    E: {
        id: "E",
        label: "ra me se le te",
        base:  ["do", "re", "mi", "fa", "so", "la", "ti"],
        short: ["d",  "r",  "m",  "f",  "s",  "l",  "t"],
        sharp: ["di", "ri", null, "fi", "si", "li", null],
        flat:  [null, "ra", "me", null, "se", "le", "te"]
    },
    U: {
        id: "U",
        label: "ru mu su lu tu",
        base:  ["do", "re", "mi", "fa", "so", "la", "ti"],
        short: ["d",  "r",  "m",  "f",  "s",  "l",  "t"],
        sharp: ["di", "ri", null, "fi", "si", "li", null],
        flat:  [null, "ru", "mu", null, "su", "lu", "tu"]
    },
    jale: {
        id: "jale",
        label: "ja le mi ni ro su wa",
        base:  ["ja", "le", "mi", "ni", "ro", "su", "wa"],
        short: ["j",  "l",  "m",  "n",  "r",  "s",  "w"],
        sharp: ["je", "li", null, "no", "ru", "sa", null],
        flat:  [null, "la", "me", null, "ri", "so", "wu"]
    }
};

var PRESET_ORDER = ["dunkler", "A", "E", "U", "jale"];
