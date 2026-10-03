import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings 1.0
import MuseScore 3.0

import "solmization.js" as Solmization
import "presets.js" as Presets

MuseScore {
    id: root
    title: "Stick-Notation"
    description: "Vereinfacht die Notenschrift (Notenlinien, Hilfslinien, Schlüssel, Vorzeichen, Versetzungszeichen ausblenden) und/oder ergänzt Solmisationssilben als Liedtext. Das Playback bleibt unverändert."
    categoryCode: "composing-arranging-tools"
    version: "1.0.0"
    pluginType: "dialog"
    requiresScore: true

    width: 480
    height: 640

    // Persisted between runs, per Qt.labs.settings ini file.
    Settings {
        id: settings
        category: "StickNotation"
        property bool simplifyNotation: true
        property bool addSyllables: true
        property string doMode: "major"       // "major" | "minor" | "fixed"
        property int doFixedPitchClass: 0      // 0..11, used when doMode === "fixed"
        property string presetId: "kodaly"
        property bool useShortForm: false
    }

    readonly property var pitchClassNames: ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
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
                    onActivated: settings.doMode = (index === 0 ? "major" : (index === 1 ? "minor" : "fixed"))
                }

                RowLayout {
                    visible: doModeCombo.currentIndex === 2
                    spacing: 8
                    Label { text: "Tonhöhe für „do“:" }
                    ComboBox {
                        id: pitchCombo
                        model: root.pitchClassNames
                        currentIndex: settings.doFixedPitchClass
                        onActivated: settings.doFixedPitchClass = index
                    }
                }

                Label { text: "Silben-System" }
                ComboBox {
                    id: presetCombo
                    Layout.fillWidth: true
                    model: root.presetLabels()
                    currentIndex: root.presetIndexForId(settings.presetId)
                    onActivated: settings.presetId = Presets.PRESET_ORDER[index]
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
            }
        }

        Item { Layout.fillHeight: true }

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
                onClicked: Qt.quit()
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
        return Presets.PRESETS[settings.presetId];
    }

    function applyAndClose() {
        if (!curScore) {
            Qt.quit();
            return;
        }
        curScore.startCmd();
        try {
            if (settings.simplifyNotation) simplifyNotation();
            if (settings.addSyllables) addSyllableLyrics();
        } finally {
            curScore.endCmd();
        }
        Qt.quit();
    }

    // Hides clefs, key signatures and staff/ledger lines score-wide via
    // style settings (this does not touch pitch/tpc, so playback is
    // unaffected), and hides the accidental glyph on every altered note.
    function simplifyNotation() {
        var style = curScore.style;
        style.setValue("genClef", false);
        style.setValue("genCourtesyClef", false);
        style.setValue("genKeysig", false);
        style.setValue("genCourtesyKeysig", false);
        // A width of exactly 0 falls back to Qt's 1px "cosmetic pen", so we
        // use a hair's-width line instead to get a visually invisible result.
        style.setValue("staffLineWidth", 0.001);
        style.setValue("ledgerLineWidth", 0.001);

        var cursor = curScore.newCursor();
        for (var staffIdx = 0; staffIdx < curScore.nstaves; staffIdx++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.staffIdx = staffIdx;
                cursor.voice = voice;
                cursor.rewind(0); // 0 = start of score
                while (cursor.segment) {
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
        var cursor = curScore.newCursor();
        for (var staffIdx = 0; staffIdx < curScore.nstaves; staffIdx++) {
            cursor.staffIdx = staffIdx;
            cursor.voice = 0;
            cursor.rewind(0); // 0 = start of score
            while (cursor.segment) {
                var el = cursor.element;
                if (el && el.type === Element.CHORD) {
                    var notes = el.notes;
                    var topNote = notes[0];
                    for (var n = 1; n < notes.length; n++) {
                        if (notes[n].pitch > topNote.pitch) topNote = notes[n];
                    }

                    var keySig = cursor.keySignature;
                    var doRef = Solmization.getDoReference(settings.doMode, settings.doFixedPitchClass, keySig);
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
        if (!curScore) {
            statusLabel.text = "Keine Partitur geöffnet.";
            statusLabel.color = "#a71a1a";
        }
    }
}
