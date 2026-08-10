# 79 — DMG mit „Drag to Applications" statt Zip

Status: **needs-triage** (bewusst hinter #71 eingereiht)
Category: release / onboarding

## Parent

Tills Frage nach der #69-Abnahme (2026-08-10): „wenn die App notarisiert ist,
warum ist es überhaupt noch ne Zip?" `docs/distribution.md` nennt das DMG
bereits als Zielpfad. Baut auf **#69** (Pipeline in `scripts/release.sh`,
Runbook `context/notarization-runbook.md`) auf; Auslieferung berührt **#78**
(Größenangaben ändern sich erneut).

## Warum Zip — und warum das Argument weg ist

Zip war die richtige Wahl **vor** der Developer-Lizenz: ein unsigniertes DMG
addierte eine zweite Quarantäne-Ebene, die jedem Tester erklärt werden musste.
Mit Developer ID ist das hinfällig — Notarisierung ist format-neutral.

## Was das Zip heute kostet

- Safari entpackt automatisch: nacktes `.app` liegt in Downloads, nichts sagt
  „nach Programme ziehen"
- Start direkt aus Downloads triggert **App Translocation** (randomisierter
  Read-only-Pfad) — läuft, aber wackelig für Pfad-Persistenz und Updates
- kein geführter Installationsmoment; die Landing-Copy muss erklären, was das
  DMG-Fenster selbst zeigen würde

Das Drag-Fenster ist reine Konvention, kein Feature: Hintergrundbild plus
Symlink auf `/Applications` im DMG-Root.

## Was zu bauen ist

1. `scripts/release.sh` erweitern: nach dem Stapeln des `.app` ein DMG bauen
   (`hdiutil create`, Layout mit Symlink `/Applications`, optional
   Hintergrundbild in Diptychon-Formsprache — rechteckig, box-aligned)
2. **Das DMG selbst signieren, notarisieren und stapeln** — das gestapelte
   `.app` darin reicht nicht für den quellenlosen Erstkontakt
3. Worker anpassen (`src/worker.js`): `/download` liefert `.dmg`,
   `content-disposition` auf `Diptychon.dmg`
4. Landing-Copy: Downloadgröße neu messen (#78-Regel: messen, nicht schätzen),
   Installationszeile anpassen
5. Abnahme wie in #69: echter Browser-Download, `spctl` auf der Kopie,
   Doppelklick-Start; zusätzlich prüfen, dass das DMG-Fenster mit Drag-Ziel
   aufgeht

## Nicht in diesem Ticket

GitHub Releases + Homebrew Cask (in `docs/distribution.md` als Ausbaustufe
skizziert) — eigener Kanal, eigenes Ticket, wenn der Bedarf da ist.

## Warum hinter #71

Der Flip schafft überhaupt erst Nutzer, die den Installationsmoment erleben.
Das notarisierte Zip startet per Doppelklick ohne Warnung (Abnahme #69) —
das DMG verbessert den Erstkontakt, es repariert nichts Kaputtes.

## Done heißt

`diptychon.com/download` liefert ein notarisiertes, gestapeltes DMG; Öffnen
zeigt das Drag-Fenster; die App startet nach dem Ziehen aus `/Applications`
ohne Dialog; Größenangaben auf der Seite stimmen mit dem DMG überein.

## Outcome

_(offen)_
