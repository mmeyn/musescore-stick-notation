# Stick-Notation

Ein Plugin für [MuseScore Studio](https://musescore.org) 4.4+, das normale Notation in eine vereinfachte „Stick-Notation“ umwandelt: Notenlinien, Hilfslinien, Schlüssel, Vorzeichen und Versetzungszeichen werden ausgeblendet, und die Tonhöhen werden als Solmisationssilben (do re mi fa so la ti, inkl. Alterationen) unter die Noten geschrieben. Das Playback ändert sich dabei nicht – es werden nur Anzeige-Eigenschaften verändert, keine Tonhöhen.

## Funktionen

- **Notation vereinfachen** (unabhängig zuschaltbar): blendet Notenlinien, Hilfslinien, Schlüssel, Vorzeichen (Tonart) und Versetzungszeichen (einzelne Akzidenzien) aus.
- **Solmisationssilben hinzufügen** (unabhängig zuschaltbar): schreibt für jede Note die passende Silbe als neue Liedtext-Strophe.
- **„Wo liegt do?“** frei einstellbar:
  - Dur-Grundton der aktuellen Tonart
  - Moll-Grundton der aktuellen Tonart (relative Molltonart)
  - feste Tonhöhe (beliebig wählbar, z. B. „C“)
- **Silben-System** wählbar:
  - Englisch / Kodály (`di ri · fi si li` / `ra me · se le te`)
  - Deutsches Tonika-Do (`di ri · fi si li` / `ru mu · su lu tu`)
  - Curwen Tonic Sol-fa (britisch, `de re · fe se le` / `ra ma · sa la ta`)
- **Kurzform für unalterierte Töne** (`d r m f s l t`), damit Alterationen visuell auffallen.
- Die zuletzt verwendeten Einstellungen werden automatisch für den nächsten Durchlauf vorausgewählt.

## Installation

1. Diesen Ordner `stick-notation/` in das MuseScore-Plugins-Verzeichnis kopieren:
   - Windows: `%HOMEPATH%\Documents\MuseScore4\Plugins\`
   - macOS: `~/Documents/MuseScore4/Plugins/`
   - Linux: `~/Documents/MuseScore4/Plugins/`
2. MuseScore Studio starten, unter **Pläne → Plugins** (bzw. **Plugins → Plugins verwalten**) „Stick-Notation“ aktivieren.
3. Partitur öffnen, Plugin über das Plugins-Menü starten.

## Bedienung

Im Dialog lassen sich beide Aktionen unabhängig an- und abschalten:

- Nur **Notation vereinfachen**, wenn die Silben nicht gebraucht werden.
- Nur **Silben hinzufügen**, wenn die normale Notation erhalten bleiben soll.
- Beides zusammen für die vollständige „Stick-Notation“.

Nach „Anwenden“ lässt sich der gesamte Vorgang mit **Strg+Z** als ein Schritt rückgängig machen.

## Bekannte Einschränkungen

- Doppelte Alterationen (Doppelkreuz/Doppel-b) haben in keinem der drei Silben-Systeme eine eigene Silbe; sie werden als Grundsilbe mit angehängtem ♯/♭-Symbol dargestellt (z. B. „fa♯♯“).
- Mehrfaches Ausführen des Plugins auf derselben Partitur fügt jedes Mal eine weitere Liedtext-Strophe hinzu. Vor einem erneuten Durchlauf mit anderen Einstellungen ggf. erst mit Strg+Z rückgängig machen.
- Die Silbe wird pro Akkord an die höchste Stimme vergeben; bei mehrstimmigen Akkorden wird aktuell keine Silbe pro Einzelton vergeben.
- Getestet wurde die Logik bisher nur isoliert (Solmisations-Mapping); ein Testlauf in einer echten MuseScore-4-Installation steht noch aus, da in dieser Entwicklungsumgebung keine MuseScore-GUI zur Verfügung steht. Rückmeldungen zu Problemen gerne als Issue melden.

## Lizenz

Noch nicht festgelegt (Repository ist aktuell privat).
