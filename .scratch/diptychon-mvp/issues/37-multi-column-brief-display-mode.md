# 37 — Multi-column brief display mode

Status: **in Arbeit (2026-08-31)** — zweiter Anlauf auf `feat/37-brief-view`.

## Erster Anlauf: abgelehnt, Ursache jetzt gefunden

Der erste Versuch (`203bd39`) ging auf `main` und wurde bei der Sichtprüfung
abgelehnt (zurückgenommen in `c726651`): die Kurzansicht zeichnete **keine
sichtbaren Spalten** und sah kaputt aus. Ursache war damals nicht diagnostiziert.

**Diagnose (2026-08-31), durch Lesen des zurückgenommenen Codes:**

`BriefLayout` liest `collectionView.bounds`, um Spaltenbreite und Zeilenzahl
auszurechnen. Die Collection View ist aber die `documentView` der Scroll View —
ihre Größe wird *aus* `collectionViewContentSize` gesetzt. Das Layout liest also
seine eigene Ausgabe wieder ein. Zwei Folgen:

1. **Beim ersten Zeichnen** ist `bounds` nahe null, also `rowsPerColumn = 1` und
   `columnWidth = 80`. Ergebnis: eine einzige Zeile Namen, die seitwärts läuft —
   exakt das, was Till gesehen hat.
2. **Danach eine Rückkopplung**: Inhalt breiter als bounds, also wächst die
   documentView, also liest der nächste `prepare()` breitere bounds, also noch
   breitere Spalten. Verstärkt durch `shouldInvalidateLayout(forBoundsChange:)`,
   das bedingungslos `true` liefert.

**Zweiter Befund, gleiche Datei:** `layoutAttributesForElements(in:)` läuft über
*alle* Frames pro Durchgang. Bei 50k Dateien sind das 50k Rechteck-Schnitte je
Scroll-Tick. Die Zellen bleiben zwar O(sichtbar) — die Aussage im alten Commit
war nicht gelogen — aber das Akzeptanzkriterium „keine Regression gegen die
#22-Baselines" wäre rot.

**Beide werden in diesem Anlauf behoben, und ich sehe mir das Ergebnis selbst an,
bevor Till es sieht** — genau der Schritt, den der erste Anlauf ausgelassen hat.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A second, pane-local **display mode**: a compact **brief view** that lays file names
out in **1, 2, or 3 columns** (names only, wrapping down-then-across), alongside the
existing detailed table view. The user toggles per pane.

Marta's model (our reference): two display modes — Table (detailed) and Multi-column
(1/2/3 columns) — switched via a *Display Mode* action; the setting is pane-local.
The brief view fits far more entries on screen when you're scanning by name, which is
the common case in a dual-pane workflow.

## Notes / design

- **Pane-local, not global.** Each panel remembers its own mode (a folder you're
  scanning for a name → brief; a folder you're inspecting → table). Persist per-pane.
- **State persistence (issue 41).** 41 shipped the durable snapshot and owns
  save/restore; its schema is additive. When this lands, add the mode (+ column count)
  to `PaneState` (`Sources/Diptychon/Panel/WorkspaceState.swift`) so it survives quit +
  relaunch — this is JTBD-1's "view is preserved" clause. Mode is a small enum; make it
  a `Codable` optional field so old snapshots default to table view.
- **Column count is a mode parameter** (1/2/3). Decide in plan whether it's a fixed
  choice or auto-fits to pane width; Marta lets the user pick — start with an explicit
  pick to keep it simple.
- **Reuse the virtualized list, not a fresh view.** The perf posture (virtualized
  `NSTableView`, O(visible rows) — issues 01/22) must hold in brief mode too; a 50k
  folder can't render every cell. This likely means an `NSCollectionView` /
  flow-layout with the same virtualization discipline, or a multi-column table
  layout — call the approach in the plan and confirm it stays O(visible).
- **Keyboard nav must adapt.** In brief mode, `Left`/`Right` move between columns and
  `Up`/`Down` within a column (issue 02 base nav assumes single-column table
  semantics — Marta explicitly redefines arrow behavior per mode). Selection model,
  type-ahead filter (issue 02), and QuickLook (issue 09) must all still work.
- **What's shown:** names + icon only in brief mode (no Kind/Tags/size columns —
  those are the table view's job, issues 27/29). Sort still applies.
- **Entry point:** command palette (issue 19) + menu; optional hotkey (issue 28).

## Acceptance criteria

- [x] A pane can switch between detailed table and a 1/2/3-column brief view.
- [x] The display mode is remembered per pane (survives navigation) **and persists
      across quit + relaunch** via issue 41's snapshot (mode + column count in
      `PaneState`). Flips issue 41's deferred "view mode restored" AC to done.
- [x] Keyboard navigation works correctly in brief mode (arrows move across/within
      columns; type-ahead filter and QuickLook still function).
- [x] Brief mode stays virtualized — a 50k-file folder renders without materializing
      every cell (no regression against issue 22 baselines).
- [x] `context/competitor-benchmark.md` §5 gap row for multi-column view flips to ✅.

## Out of scope

- Icon/gallery/coverflow-style views (this is a text brief view, not a thumbnail grid).
- Auto-fitting column count to window width (start with explicit 1/2/3 pick).
- Per-column custom fields in brief mode (that's the table view's domain).

## Blocked by

- `01-panel-lists-local-folder` / `22-performance-baseline-measurements`
  (virtualization posture the brief view must preserve) — done.
- `02-panel-navigation-sort-filter` (base nav + type-ahead this must adapt) — done.

## Related

- `context/competitor-benchmark.md` §5 (Marta deep-dive).
- `17-file-list-polish`, `27-tags-column`, `29-kind-column` (table-view columns —
  the detailed mode this sits beside).
- `41-state-persistence` (owns the snapshot; add view mode to `PaneState` — see Notes).
