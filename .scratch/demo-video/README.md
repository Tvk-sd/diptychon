# Demo-Videos + Aufnahme-Harness (#62)

## Finale Assets (2026-07-22, von Till abgenommen)

| Datei | Inhalt |
|---|---|
| `diptychon-hero-final.mp4` | **Hero-Cut, 23s, 1080p** — Navigation → ⌘A → ⌘⌥→ (10 Bilder) → zurück → ⌘K-Palette → ⏎ Run Undo → Toast. Keystroke-Badges zentriert. |
| `diptychon-demo-keys.mp4` | 38s Basis-Cut (Dual-Pane, Suche+Path-Jump, History), kleine Badges unten links |
| `diptychon-demo-sidebar-keys.mp4` | 38s Sidebar-Cut (Copy/Paste + Undo/Redo-Toast), kleine Badges |

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
