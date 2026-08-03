# 69 — Frischen Build notarisieren und den Download echt machen

Status: **ready-for-human** (hängt an Tills Apple-Developer-Lizenz)
Category: release

## Parent

Strategiewechsel 2026-08-03 (#66). Blockiert von **#68** (Readiness-Gate).

## Warum

Der Download auf `diptychon.com/download` ist heute ein gebrochenes Versprechen:
das Zip ist nicht notarisiert, macOS Gatekeeper lehnt es ab und legt es in den
Papierkorb. Solange das so ist, darf auf der Seite nichts von „free download"
stehen — der Besucher merkt es in 30 Sekunden und ist weg.

Till hat entschieden, die Developer-Lizenz (~$99/Jahr) ohnehin zu kaufen,
unabhängig von jedem Reichweitensignal. Damit ist sie **Voraussetzung, kein
Gate** — die alte Roadmap-Reihenfolge („erst Reichweite messen, dann $99") ist
hinfällig.

## Wichtig: frisch bauen, nicht das vorhandene Zip notarisieren

`.scratch/landing-page/dist/Diptychon.zip` ist vom **2026-07-17** (1.560.529 B).
Seitdem sind unter anderem das eingebettete Terminal (#65, `4043372`) und
weitere Arbeit auf main gelandet. Das Zip ist veraltet.

## Schritte

1. Apple-Developer-Lizenz kaufen (Till)
2. Developer-ID-Zertifikat einrichten, Signing in den Build hängen
3. **Frisch von main bauen** — nicht das vorhandene Zip anfassen
4. `codesign` mit Hardened Runtime, dann `notarytool submit --wait`, dann
   `stapler staple`
5. Neu zippen, in `dist/` legen, Größe in der Copy nachziehen (die Seiten nennen
   1,5 MB — die Zahl stimmt nach einem neuen Build vermutlich nicht mehr)
6. **Verifizieren wie ein Fremder:** Zip über `https://diptychon.com/download`
   herunterladen (nicht lokal kopieren — Quarantäne-Flag entsteht nur beim
   echten Download), dann `spctl -a -vv /Applications/Diptychon.app` und einmal
   per Doppelklick starten. Erst wenn das ohne Warndialog durchläuft, ist das
   Ticket fertig

## Done heißt

Ein von diptychon.com heruntergeladenes Zip startet auf einem Mac ohne
Entwicklerwerkzeuge per Doppelklick, ohne Gatekeeper-Dialog. Mit Ausgabe von
`spctl -a -vv` in diesem Issue dokumentiert.

## Outcome

_(offen)_
