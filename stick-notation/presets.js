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

.pragma library

var PRESETS = {
    kodaly: {
        id: "kodaly",
        label: "Englisch / Kodály (movable do)",
        base:  ["do", "re", "mi", "fa", "so", "la", "ti"],
        short: ["d",  "r",  "m",  "f",  "s",  "l",  "t"],
        sharp: ["di", "ri", null, "fi", "si", "li", null],
        flat:  [null, "ra", "me", null, "se", "le", "te"]
    },
    tonikaDo: {
        id: "tonikaDo",
        label: "Deutsches Tonika-Do",
        base:  ["do", "re", "mi", "fa", "so", "la", "ti"],
        short: ["d",  "r",  "m",  "f",  "s",  "l",  "t"],
        sharp: ["di", "ri", null, "fi", "si", "li", null],
        flat:  [null, "ru", "mu", null, "su", "lu", "tu"]
    },
    curwen: {
        id: "curwen",
        label: "Curwen Tonic Sol-fa (britisch)",
        base:  ["doh", "ray", "me",  "fah", "soh", "lah", "te"],
        short: ["d",   "r",   "m",   "f",   "s",   "l",   "t"],
        sharp: ["de",  "re",  null,  "fe",  "se",  "le",  null],
        flat:  [null,  "ra",  "ma",  null,  "sa",  "la",  "ta"]
    }
};

var PRESET_ORDER = ["kodaly", "tonikaDo", "curwen"];
