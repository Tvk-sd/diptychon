# Demo-Videos + Aufnahme-Harness (#62)

## Finale Assets (2026-07-22, von Till abgenommen)

| Datei | Inhalt |
|---|---|
| `diptychon-hero-final.mp4` | **Hero-Cut, 23s, 1080p** — Navigation → ⌘A → ⌘⌥→ (10 Bilder) → zurück → ⌘K-Palette → ⏎ Run Undo → Toast. Keystroke-Badges zentriert. |
| `diptychon-demo-keys.mp4` | 38s Basis-Cut (Dual-Pane, Suche+Path-Jump, History), kleine Badges unten links |
| `diptychon-demo-sidebar-keys.mp4` | 38s Sidebar-Cut (Copy/Paste + Undo/Redo-Toast), kleine Badges |

## Substack-Assets (2026-08-03) — Post „Legibility beats speed"

| Datei | Inhalt |
|---|---|
| `jump-final.mp4` / `.gif` | **8,0s Path-Jump-Cut** — ⌘F, ⌘V eines *absoluten Dateipfads*, Sprung in `Selects` (80 Dateien), schwacher grauer Landemarker auf `portrait-session-58.jpg`. Badges für ⌘F/⌘V. |
| `gulfs.mp4` / `.gif` | 12,8s Motion-Graphic — Normans zwei Gulfs als Fortschrittsbalken. Bewusst **ohne** Schlusskarte: der Zweizeiler ist die Pointe des Posts und gehört in die Prosa, nicht ins Embed darüber. Nichts fadet am Ende aus, der Clip steht auf seiner Schlusskomposition — als GIF-Loop wäre ein Fade ins Leere ein toter Beat pro Runde. |

**Balkensemantik (Tills Korrektur, v1 war invertiert):** ein Balken misst, wie weit ein
Gulf **geschlossen** ist. 100 % = geschlossen = diese Hälfte der Handlung ist fertig.
Ablauf: beide bei 50 % vorstellen → auf 0 zurück → Execution schnappt sofort auf 100 % →
Evaluation kriecht auf 22 % und bleibt hängen → Cue landet → Evaluation auf 100 %.
v1 liess die Balken wachsen, *wenn* der Gulf sich öffnete; dadurch stimmte die Erzählung
nicht und alle Captions klumpten am Ende. Stil ebenfalls korrigiert: rechteckig, in einer
Box mit Haarlinien, links am Raster ausgerichtet, rechtsbündige Wertspalte — wie die
Dateiliste der App, statt zentrierter Pillen.

**Kein Produkt-Cue in der Graphic.** Eine frühere Fassung zeigte unten das Diptychon-
Dateizeilen-Mock mit dem grauen Marker. Raus auf Tills Ansage: die Graphic erklärt das
Prinzip, den konkreten Cue zeigt der Mitschnitt. Doppelt gezeigt mischt die Register.

Kopien liegen in `~/Projects/till-writing/substack/drafts/assets/`.

**Warum ein neuer Take statt `diptychon-demo-keys.mp4`:** der alte Cut pastet einen
*Ordner*pfad. `PanelModel.swift:272` setzt `highlightedTargetURL = isDir ? nil : url` —
auf einem Ordner gibt es nichts zu markieren, der Marker ist in dem Material also nie
zu sehen. Für den Post ist genau er der Punkt.

**Zielordner muss voll sein.** Erster Take zielte auf `Dev/portfolio-site/src` — 3 Dateien,
Marker auf Zeile 1. Da ist er Dekoration, nicht Wiederfinden. `Selects` wird deshalb per
`harness/fill_selects.py` auf 80 fast gleichnamige JPEGs mit gestreuten mtimes aufgefüllt
(**nach** `make_demo_data.py`, das nur 4 anlegt); das Ziel liegt unter der Kante,
`scrollRowToVisible` (NSTableViewFileList.swift:248) scrollt sichtbar hin. Kontrast
Markerzeile/Nachbarzeile stieg dadurch von 68/48 auf **74,5/37,2**.

Reproduzieren: `harness/record_jump.sh <out.mov>` (staged Instanz, Clipboard wird
gesichert/zurückgesetzt, `STAGED_PID`-Assert verhindert, dass Tastendrücke in eine
parallel laufende echte Instanz gehen). Danach schneiden + Badges wie unten.

**LAG immer am Rohmaterial messen, nie am Schnitt.** `makeschedule`-LAG = Trim-Offset +
`screencapture`-Startverzögerung (hier 0,14s, im Take davor 0,84s — schwankt pro Lauf).
Den Sprungzeitpunkt per Luminanzsprung in der Listenfläche des **Rohfiles** bestimmen
(`crop=1000:1200:0:200,scale=1:1,fps=20`); aus einem bereits geschnittenen File
zurückgerechnete Zeiten waren um 0,7s falsch. Gegenprobe: Badge-Zeit == gemessener
Navigationszeitpunkt.

**Badges nie über die Markerzeile legen.** Erster Versuch lag bei `H*0.72` — exakt auf
dem Marker. Jetzt in der leeren rechten Pane (`overlay=1132-w/2:486`).

`screencapture` überschreibt keine existierende Datei und meldet das nur auf stderr —
`record_jump.sh` löscht `$OUT` daher vorher.

**Badges NICHT mehr über `overlay`:** `AVVideoCompositionCoreAnimationTool` schwärzt
einen unterschiedlich langen Kopf des Exports (gemessen 0,76s bei 8,3s Input, 1,56s bei
9,9s) — dagegen lässt sich nicht stabil schneiden. Stattdessen `harness/badgepng`
(rendert dieselben Pills als PNG) + ffmpeg `overlay`+`fade`. `-loop 1`-Eingänge immer
mit `-t` begrenzen, sonst läuft ffmpeg endlos.

**GIF-Treue geprüft:** der Marker ist `secondaryLabelColor` bei 16 % Alpha — schwach
genug, dass Quantisierung ihn fressen könnte. Gemessen (Luminanz Markerzeile vs.
Nachbarzeile): MP4 67,6/49,2 · GIF `dither=none` 67,9/48,2. Überlebt. `dither=none`
ist zugleich die kleinste Variante (360K vs. 488K bayer).

## Harness (`harness/`) — Videos reproduzieren

1. **Demo-Daten:** `python3 make_demo_data.py ~/Studio` (Creative-Studio-Baum; Selects danach auf 10 Bilder erweitern, siehe #62-Verlauf)
2. **App staged starten:** Build aus main, dann
   `HOME=~/Studio DIPTYCHON_DIR=~/Studio <app> -sidebarVisible YES -rightPanelVisible YES -previewVisible NO -AppleLocale en-US -pinnedFolders "(…)"`
   Fenster via `poke frame <pid> 60 60 1380 776` (stabile Breite! Preview an = Fenster-Resize-Falle)
3. **Aufnahme:** `screencapture -V 24 -R60,60,1380,776 take.mov &` + `KEYLOG=keys.log zsh take3.sh`
4. **Badges:** `python3 makeschedule.py keys.log sched.tsv 0.0` → `./overlay take.mov sched.tsv out.mov` → `avconvert --preset Preset1920x1080 …`

Gotchas (Details in `.scratch/diptychon-mvp/issues/62-*.md`): cfprefsd ignoriert $HOME
(echte Prefs gelten — Tills goBack/goForward = ⌥←/→!); Fokus-Bootstrap via ⌘K+⎋;
synthetische Klicks unzuverlässig → 100 % Tastatur; Overlay-Export IMMER auf Dauer
prüfen (korrupter Export → stale-File-Falle); offene QuickTime-Fenster zeigen alte
Dateiversionen.
