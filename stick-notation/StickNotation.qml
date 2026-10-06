import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import MuseScore 3.0

import "solmization.js" as Solmization
import "presets.js" as Presets

MuseScore {
    id: root
    title: "Stick-Notation"
    description: "Vereinfacht die Notenschrift (Notenlinien, Hilfslinien, Schlüssel, Vorzeichen, Versetzungszeichen ausblenden) und/oder ergänzt Solmisationssilben als Liedtext. Das Playback bleibt unverändert."
    version: "1.0.0"
    pluginType: "dialog"
    requiresScore: true

    width: 480
    height: 680

    // Official MuseScore 4.4 porting notes (musescore.org/en/node/337468):
    // "In MU4.4, Qt.labs.settings has been integrated in the Musescore
    // module. The explicit import Qt.labs.settings 1.0 must be removed
    // [...] and is not required for the Settings module to work." So the
    // native Settings element still works exactly as in MuseScore 3 - no
    // FileIO/manual JSON needed, and no plugin-file-sandbox concerns since
    // it goes through Qt's own settings backend (e.g. ~/.config on Linux),
    // not a sandboxed file write.
    Settings {
        id: settings
        category: "StickNotation"
        property bool simplifyNotation: true
        property bool addSyllables: true
        property string doMode: "major"       // "major" | "minor" | "fixed"
        property string doFixedLetter: "C"    // used when doMode === "fixed"
        property int doFixedAcc: 0            // -1 | 0 | 1, used when doMode === "fixed"
        property string presetId: "besAbdunkeln"
        property bool useShortForm: false
        property bool skipTiedNotes: true
    }

    // German pitch names for the "feste Tonhöhe" picker: naturals, both the
    // sharp and flat spelling of every black key, and the four enharmonic
    // "natural note altered to land on a neighboring natural" names (Ces,
    // Eis, Fes, His) at the two half-step pairs E-F and H-C, in chromatic
    // order with enharmonic equivalents grouped together.
    readonly property var doPitchChoices: [
        { letter: "C", acc: -1, label: "Ces" },
        { letter: "C", acc: 0, label: "C" },
        { letter: "C", acc: 1, label: "Cis" },
        { letter: "D", acc: -1, label: "Des" },
        { letter: "D", acc: 0, label: "D" },
        { letter: "D", acc: 1, label: "Dis" },
        { letter: "E", acc: -1, label: "Es" },
        { letter: "E", acc: 0, label: "E" },
        { letter: "E", acc: 1, label: "Eis" },
        { letter: "F", acc: -1, label: "Fes" },
        { letter: "F", acc: 0, label: "F" },
        { letter: "F", acc: 1, label: "Fis" },
        { letter: "G", acc: -1, label: "Ges" },
        { letter: "G", acc: 0, label: "G" },
        { letter: "G", acc: 1, label: "Gis" },
        { letter: "A", acc: -1, label: "As" },
        { letter: "A", acc: 0, label: "A" },
        { letter: "A", acc: 1, label: "Ais" },
        { letter: "B", acc: -1, label: "B" },
        { letter: "B", acc: 0, label: "H" },
        { letter: "B", acc: 1, label: "His" }
    ]

    function pitchChoiceLabels() {
        var items = [];
        for (var i = 0; i < doPitchChoices.length; i++) items.push(doPitchChoices[i].label);
        return items;
    }

    function pitchChoiceIndex(letter, acc) {
        for (var i = 0; i < doPitchChoices.length; i++) {
            if (doPitchChoices[i].letter === letter && doPitchChoices[i].acc === acc) return i;
        }
        return 0;
    }

    function presetLabels() {
        var items = [];
        for (var i = 0; i < Presets.PRESET_ORDER.length; i++) {
            items.push(Presets.PRESETS[Presets.PRESET_ORDER[i]].label);
        }
        return items;
    }

    function presetIndexForId(id) {
        var idx = Presets.PRESET_ORDER.indexOf(id);
        return idx < 0 ? 0 : idx;
    }

    // Qt.quit() terminates the whole MuseScore application, not just this
    // plugin - the correct way to close a dialog-type plugin's window is to
    // close its own Window instance.
    function closeDialog() {
        root.parent.Window.window.close();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // The dialog's fixed height can't guarantee enough room for every
        // combination of visible options (and font/DPI settings vary by
        // system), so the variable-height part scrolls instead of pushing
        // the Abbrechen/Anwenden buttons below the window's bottom edge.
        ScrollView {
            id: scrollArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                // Bind to availableWidth (the actual viewport), not
                // parent.width - the latter resolves to the ScrollView's
                // internal content item, which grows to fit this column's
                // own implicit width instead of constraining it, letting
                // the dialog balloon sideways.
                width: scrollArea.availableWidth
                spacing: 12

        Label {
            text: "Stick-Notation"
            font.pixelSize: 20
            font.bold: true
        }
        Label {
            text: "Wandelt normale Notation in eine vereinfachte Darstellung mit Solmisationssilben um."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Label {
            id: selectionInfoLabel
            font.pixelSize: 11
            font.italic: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            opacity: 0.8
        }

        GroupBox {
            title: "Aktionen"
            Layout.fillWidth: true
            ColumnLayout {
                anchors.fill: parent
                spacing: 4
                CheckBox {
                    id: simplifyCheck
                    text: "Notation vereinfachen"
                    checked: settings.simplifyNotation
                    onToggled: settings.simplifyNotation = checked
                }
                Label {
                    text: "Blendet Notenlinien, Hilfslinien, Schlüssel, Vorzeichen und Versetzungszeichen aus."
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    opacity: 0.7
                }
                CheckBox {
                    id: syllablesCheck
                    text: "Solmisationssilben hinzufügen"
                    checked: settings.addSyllables
                    onToggled: settings.addSyllables = checked
                }
                Label {
                    text: "Schreibt die Tonhöhe jeder Note als Solmisationssilbe in den Liedtext (neue Strophe)."
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    opacity: 0.7
                }
            }
        }

        GroupBox {
            title: "Solmisation"
            Layout.fillWidth: true
            visible: syllablesCheck.checked
            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Label { text: "Wo liegt „do“?" }
                ComboBox {
                    id: doModeCombo
                    Layout.fillWidth: true
                    model: ["Dur-Grundton der Tonart", "Moll-Grundton der Tonart", "Feste Tonhöhe"]
                    currentIndex: settings.doMode === "major" ? 0 : (settings.doMode === "minor" ? 1 : 2)
                    onActivated: function(index) { settings.doMode = (index === 0 ? "major" : (index === 1 ? "minor" : "fixed")); }
                }

                RowLayout {
                    visible: doModeCombo.currentIndex === 2
                    spacing: 8
                    Label { text: "Tonhöhe für „do“:" }
                    ComboBox {
                        id: pitchCombo
                        model: root.pitchChoiceLabels()
                        currentIndex: root.pitchChoiceIndex(settings.doFixedLetter, settings.doFixedAcc)
                        onActivated: function(index) {
                            settings.doFixedLetter = root.doPitchChoices[index].letter;
                            settings.doFixedAcc = root.doPitchChoices[index].acc;
                        }
                    }
                }

                Label { text: "Silben-System" }
                ComboBox {
                    id: presetCombo
                    Layout.fillWidth: true
                    model: root.presetLabels()
                    currentIndex: root.presetIndexForId(settings.presetId)
                    onActivated: function(index) { settings.presetId = Presets.PRESET_ORDER[index]; }
                }

                CheckBox {
                    id: shortFormCheck
                    text: "Unalterierte Töne als Kurzform (d r m f s l t)"
                    checked: settings.useShortForm
                    onToggled: settings.useShortForm = checked
                }
                Label {
                    text: "Alterierte Töne werden immer als volle Silbe geschrieben (z. B. „ri“), damit sie auffallen."
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    opacity: 0.7
                }

                CheckBox {
                    id: skipTiedCheck
                    text: "Silben bei gebundenen Noten weglassen"
                    checked: settings.skipTiedNotes
                    onToggled: settings.skipTiedNotes = checked
                }
            }
        }

            } // end inner ColumnLayout
        } // end ScrollView

        Label {
            id: statusLabel
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: "#1a7a1a"
        }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Button {
                text: "Abbrechen"
                onClicked: root.closeDialog()
            }
            Button {
                text: "Anwenden"
                highlighted: true
                enabled: simplifyCheck.checked || syllablesCheck.checked
                onClicked: root.applyAndClose()
            }
        }
    }

    function currentPreset() {
        // Falls back to the first preset if settings.presetId refers to one
        // that no longer exists (e.g. saved by an older plugin version).
        return Presets.PRESETS[settings.presetId] || Presets.PRESETS[Presets.PRESET_ORDER[0]];
    }

    function applyAndClose() {
        if (!curScore) {
            closeDialog();
            return;
        }
        // No explicit save step needed: each control's onToggled/onActivated
        // handler already writes straight into the Settings element above,
        // which persists it immediately.
        curScore.startCmd();
        try {
            // Each step runs independently: an error in one (as happened
            // during the leger-line rest experiment, which silently aborted
            // lyric creation too) must not prevent the other from running.
            if (settings.simplifyNotation) {
                try {
                    simplifyNotation();
                } catch (e) {
                    console.log("Stick-Notation: Fehler beim Vereinfachen der Notation: " + e);
                }
            }
            if (settings.addSyllables) {
                try {
                    addSyllableLyrics();
                } catch (e) {
                    console.log("Stick-Notation: Fehler beim Hinzufügen der Silben: " + e);
                }
            }
        } finally {
            curScore.endCmd();
        }
        closeDialog();
    }

    // If the user has a range selection, only that range (staves + ticks)
    // is processed; otherwise the whole score is. endTick === -1 means
    // "no upper bound" (selection reaches the end of the score).
    function getProcessingRange() {
        var range = {
            fullScore: !curScore.selection.isRange,
            startStaff: 0,
            endStaff: curScore.nstaves,
            startTick: 0,
            endTick: -1
        };
        if (!range.fullScore) {
            range.startStaff = curScore.selection.startStaff;
            range.endStaff = curScore.selection.endStaff;
            var c = curScore.newCursor();
            c.rewind(1); // 1 = selection start
            range.startTick = c.tick;
            c.rewind(2); // 2 = selection end
            range.endTick = c.tick > range.startTick ? c.tick : -1;
        }
        return range;
    }

    // Hides clefs, key signatures and staff/ledger lines score-wide via
    // style settings (this does not touch pitch/tpc, so playback is
    // unaffected), and hides the accidental glyph on every altered note.
    function simplifyNotation() {
        var range = getProcessingRange();

        // staffLineWidth/ledgerLineWidth/genClef/genKeysig are score-wide
        // style settings - the plugin API has no per-staff equivalent, so
        // applying them would hide staff lines/clefs on every instrument
        // even when only a range on one staff is selected. Only apply them
        // when processing the whole score; with a range selection, rely
        // solely on the per-element hiding below, which is scoped.
        if (range.fullScore) {
            var style = curScore.style;
            style.setValue("genClef", false);
            style.setValue("genCourtesyClef", false);
            style.setValue("genKeysig", false);
            style.setValue("genCourtesyKeysig", false);
            // A width of exactly 0 falls back to Qt's 1px "cosmetic pen", so
            // use a hair's-width line instead for a visually invisible result.
            style.setValue("staffLineWidth", 0.001);
            style.setValue("ledgerLineWidth", 0.001);
        }
        // With a range selection, staff lines are left alone entirely.
        // Both plugin-API paths to hiding them per staff/range are broken
        // in MuseScore itself (confirmed via source, see project memory):
        // StaffTypeChange crashes on creation (null StaffType pointer), and
        // Staff.staffInvisible is silently a no-op when written - Staff::
        // setProperty() has no case for Pid::STAFF_INVISIBLE at all, even
        // though Staff::getProperty() reads it.

        // The style flags above are not reliable for clefs/key signatures
        // that are already laid out on the page, so hide every Clef and
        // KeySig element directly as well. Start from curScore.firstSegment()
        // rather than a cursor: Cursor.rewind(0) jumps straight to the first
        // ChordRest segment, skipping the header Clef/KeySig segments that
        // precede it, so the very first (most visible) clef never got hidden.
        var segment = curScore.firstSegment();
        while (segment) {
            if (segment.tick >= range.startTick && (range.endTick === -1 || segment.tick < range.endTick)) {
                for (var s = range.startStaff; s < range.endStaff; s++) {
                    for (var v = 0; v < 4; v++) {
                        var segEl = segment.elementAt(s * 4 + v);
                        if (segEl && (segEl.type === Element.CLEF || segEl.type === Element.KEYSIG)) {
                            segEl.visible = false;
                        }
                    }
                }
            }
            segment = segment.next;
        }

        var cursor = curScore.newCursor();
        for (var staffIdx = range.startStaff; staffIdx < range.endStaff; staffIdx++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.staffIdx = staffIdx;
                cursor.voice = voice;
                cursor.rewind(range.fullScore ? 0 : 1); // 0 = score start, 1 = selection start
                while (cursor.segment && (range.endTick === -1 || cursor.tick < range.endTick)) {
                    var el = cursor.element;
                    if (el && el.type === Element.CHORD) {
                        var notes = el.notes;
                        for (var n = 0; n < notes.length; n++) {
                            if (notes[n].accidental) {
                                notes[n].accidental.visible = false;
                            }
                        }
                    }
                    cursor.next();
                }
            }
        }
    }

    // Adds the solmization syllable of each chord's highest note as a new
    // lyrics verse. Only voice 0 is used, matching the usual convention of
    // writing lyrics under the main melodic line.
    function addSyllableLyrics() {
        var preset = currentPreset();
        var range = getProcessingRange();
        var cursor = curScore.newCursor();
        for (var staffIdx = range.startStaff; staffIdx < range.endStaff; staffIdx++) {
            cursor.staffIdx = staffIdx;
            cursor.voice = 0;
            cursor.rewind(range.fullScore ? 0 : 1); // 0 = score start, 1 = selection start
            while (cursor.segment && (range.endTick === -1 || cursor.tick < range.endTick)) {
                var el = cursor.element;
                if (el && el.type === Element.CHORD) {
                    var notes = el.notes;
                    var topNote = notes[0];
                    for (var n = 1; n < notes.length; n++) {
                        if (notes[n].pitch > topNote.pitch) topNote = notes[n];
                    }

                    // A note tied over from the previous one is still the
                    // same pitch being held, not a new one to sing - skip it
                    // by default (tieBack is set on the continuation note).
                    if (settings.skipTiedNotes && topNote.tieBack) {
                        cursor.next();
                        continue;
                    }

                    // cursor.keySignature follows whatever is currently
                    // displayed on this staff: the WRITTEN key signature
                    // when "Concert Pitch" is off, the concert one when it's
                    // on. Since the note itself is always read in concert
                    // pitch (tpc1), the "do" reference must be converted to
                    // concert too, but only when the display is written -
                    // detected per note via tpc === tpc1 (true iff Concert
                    // Pitch is on). tpc2 - tpc1 is the transposition amount
                    // in the same circle-of-fifths unit as the key signature.
                    var concertPitchOn = topNote.tpc === topNote.tpc1;
                    var keySig = concertPitchOn ? cursor.keySignature : cursor.keySignature - (topNote.tpc2 - topNote.tpc1);
                    var fixedRef = { letter: settings.doFixedLetter, acc: settings.doFixedAcc };
                    var doRef = Solmization.getDoReference(settings.doMode, fixedRef, keySig);
                    var syllable = Solmization.syllableFor(topNote.tpc1, topNote.pitch, doRef, preset, settings.useShortForm);

                    var lyrics = newElement(Element.LYRICS);
                    lyrics.text = syllable;
                    el.add(lyrics);
                }
                cursor.next();
            }
        }
    }

    onRun: {
        // Settings{} loads itself automatically; controls bind to it
        // declaratively (e.g. "checked: settings.simplifyNotation"), so no
        // manual load/sync step is needed here.
        if (!curScore) {
            statusLabel.text = "Keine Partitur geöffnet.";
            statusLabel.color = "#a71a1a";
        } else {
            selectionInfoLabel.text = curScore.selection.isRange
                ? "Es ist nur ein Bereich markiert – nur dieser wird bearbeitet."
                : "Keine Auswahl markiert – die gesamte Partitur wird bearbeitet.";
        }
    }
}
