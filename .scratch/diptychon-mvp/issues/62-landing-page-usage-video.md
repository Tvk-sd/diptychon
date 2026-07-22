# #62 — Usage-Video für die Landing Page (Showcase-Daten)

**Status:** Video ABGENOMMEN (Till, 2026-07-22: „looks great" zum Hero-Cut). Offen: Einbindung Landing Page.
**Stand 2026-07-21 (abends):** ZWEI Videos fertig, warten auf Tills Abnahme.
mp4 (40s, 1,9 MB, 1080p): Scratchpad `diptychon-demo.mp4`, Roh-Take `take6.mov`.
Flows wie beschlossen; ⌘K-Palette als Cameo in Beat 2. Loop schließt sauber
(Start- = Endzustand, beide Panes auf Studio-Root).

**Nebenfunde (Produkt, uncommitted im Working Tree, Review nötig):**
1. `NSTableViewFileList.swift` — Fokus-Bug-Fix: Tastatur-Selektion (↑/↓) starb
   nach jeder ⏎-Navigation (PanelView-Branch-Wechsel baut die Table neu auf;
   Fokus-Claim lief vor Window-Attach ins Leere). Fix: Claim in
   `viewDidMoveToWindow`. Echter Keyboard-UX-Bug, nicht nur Demo-Problem.
2. `PanelModel.swift` — Such-Root respektiert jetzt `DIPTYCHON_DIR`
   (vorher: Suche lief immer über das ECHTE Home, auch im geseedeten Modus —
   betrifft auch UI-Test-Determinismus).

**Learnings (Harness):** cfprefsd löst Defaults über die UID auf — $HOME-Override
isoliert Prefs NICHT (Tills echte hotkeyOverrides galten: goBack/goForward sind
auf ⌥←/⌥→ gebunden, nicht ⌘←/→). `expandingTildeInPath` ignoriert $HOME ebenso.
Synthetische Klicks landen ~falsch (ungeklärt) — Choreo ist 100 % Tastatur.

**Cleanup nach Abnahme:** `/Users/Till/Studio` löschen (300 MB Demo-Daten,
enthält auch verirrte Prefs-Schreibzugriffe unter Studio/Library).
**Erstellt:** 2026-07-21
**Kontext:** GTM Reach-Test (`context/channel-plan.md`), Landing-Page-Assets in `.scratch/landing-page/`

## Ziel

Ein 20–40s Loop-Video (mp4, ohne Ton, fenster-crop) für diptychon.com, das die
Kern-Flows mit glaubwürdigen Showcase-Daten zeigt. Loop muss sauber schließen
(Endzustand ≈ Anfangszustand).

## Entscheidungen (Till, 2026-07-21)

- **Format:** Landing-Page-Loop, 20–40s, kein Audio
- **Flow-Reihenfolge:** 1) Dual-Pane-Navigation → 2) Fuzzy-Search + Path-Jump → 3) History ⌘←/→
- **Showcase-Daten:** Creative-Studio-Mix — Bilder/Assets + Dev-Projektdateien
  (Zielgruppen-Signal: Fotograf:innen UND Entwickler:innen haben Interesse gezeigt)

## Technischer Ansatz

Wiederverwendung Screenshot-Harness (Memory: seeded prefs + `DIPTYCHON_DIR`
+ CGEvent-Key-Driver; synthetische Key-Events erreichen den NSEvent-Monitor):

1. Showcase-Baum im Scratchpad bauen (Studio-Struktur, echte Bild-Thumbnails
   wo Preview sichtbar)
2. Frischer Build von main; Prefs seeden (workspaceState, pinnedFolders,
   Panels, `-AppleLocale en-US`); Fenster auf {60,60}, feste Größe
3. Demo-Driver: getimte Key-Sequenz (swift poke tool)
4. Dry-Run-Screenshot zur Staging-Verifikation
5. Aufnahme `screencapture -V <s> -R <fensterrect>` , mehrere Takes
6. `avconvert` → web-taugliches mp4; Loop-Schnitt prüfen
7. Ergebnis via `open` zeigen (kein Artifact-Umweg, lokale Session)

## Constraints

- Aufnahme übernimmt Bildschirm + Tastatur → Till muss Hände weglassen
  (Takes ~1 min, mehrere)
- Synthetische CGEvents treiben keine NSTrackingArea → keine Hover-Effekte
  zeigen, rein tastaturgetriebener Flow (on-brand)
- Test-Instanz aus /Applications-Kopie (TCC-frei), Tills laufende App vorher
  beenden (macOS-Relaunch-Falle)

## Done heißt

- [ ] mp4 20–40s, loopt sauber, Flows in beschlossener Reihenfolge sichtbar
- [ ] Showcase-Daten lesbar & glaubwürdig (keine Platzhalter-Namen im Bild)
- [ ] Till hat das Video gesehen und abgenommen
- [ ] Einbindung auf der Landing Page = separater Schritt (nicht Teil von #62)

## Nachtrag 2026-07-21 (abends)

- **Video v2** auf Tills Wunsch: Sidebar sichtbar + Copy/Paste mit Undo/Redo-
  Toast („Undone — Copy 4 items" / „Redone — Copy 4 items" beide im Bild).
  38s, 1080p aus 1440×810: Scratchpad `diptychon-demo-sidebar.mp4`.
  Sidebar-Staging: pinnedFolders via Argument-Domain überschrieben (Tills echte
  Pins nie im Bild); Devices-Sektion zeigt reale Mounts (tldraw offline,
  Seagate) — bewusst belassen, Retake möglich.
- Nebenfunde #63/#64: gefixt + committed (`fe2f3d1`, `378cfae`), Issues posthum
  angelegt und geschlossen (`d757ce2`). Suite grün (220 Unit + 13 UI).

## Nachtrag 2 — Keystroke-Badges (2026-07-21, spät)

Auf Tills Wunsch: beide Videos neu aufgenommen mit **Tasten-Einblendungen**
(Pill-Badges unten links: ↓, ⏎ Open, ⇥ Switch panel, ⌘F Search, ⌘V Paste,
⌘Z Undo, ⌥← Back …; schnelle Wiederholungen gebündelt als „↓ ×3").
Harness: Driver loggt Epochen-Timestamps pro Event → makeschedule.py →
overlay (AVFoundation, gerasterte Badges + Opacity-Animationen). Kalibrierung:
screencapture startet latenzfrei (LAG 0).
Finale Dateien (Scratchpad): `diptychon-demo-keys.mp4` (Basis) und
`diptychon-demo-sidebar-keys.mp4` (Sidebar + Copy/Paste + Toast).
Die Varianten ohne Badges bleiben daneben liegen.

## Nachtrag 3 — 25s-Hero-Cut (2026-07-21, nachts)

Tills Feedback umgesetzt: **`diptychon-hero-25s.mp4`** (26s, 1080p) —
Badges groß + zentriert (über der Toast-Zone), nur Signatur-Keystrokes:
Navigation → ⌘A → **⌘⌥→ Copy to other panel** (10 Bilder, statt ⌘C/⌘V) →
zurück mit ⌘⇧S-Staging (Pane erscheint automatisch) → ⌘K-Palette →
⏎ „Run Undo" → Toast-Finale „Undone — Copy 10 items".
Selects auf 10 Bilder erweitert. Anmerkung: Staging-Spalte schließt sich
vor dem Finale wieder (App-Verhalten, Ursache nicht final geklärt — bei
Bedarf nachbohren). Ältere Schnitte bleiben im Scratchpad liegen.

## Nachtrag 4 — Hero-Cut final (2026-07-22, 00:00)

Staging-Beat raus (Till: Dead-Space). Diagnose der schwarzen Bänder: NICHT
das Staging allein — (a) Fenster snappt beim Layoutwechsel (Preview-Spalte)
auf Content-Breite; Fix: previewVisible NO + Aufnahme exakt auf stabiler
Fenstergröße 1380×776 (≈16:9); (b) der zuletzt gezeigte Band-Fall war ein
STALE FILE (Overlay-Export korrupt → avconvert scheiterte still → altes mp4
geprüft). Pipeline jetzt schrittweise verifiziert.
**Final (ersetzt): `diptychon-hero-final.mp4` — Badges 60px, höher positioniert; Band-Report vom Morgen war ein stales QuickTime-Fenster (Datei auf Disk war sauber)** (24s, 1080p): Navigation → ⌘A →
⌘⌥→ (10 Bilder) → ⎋/⌘↑×2 zurück → ⌘K-Palette → ⏎ Run Undo →
Toast „Undone — Copy 10 items". Fenster hält Breite durchgängig (live
vermessen, randlos verifiziert).
