# 37 — Multi-column brief display mode

Status: **CLOSED (2026-08-31)** — zweiter Anlauf gebaut, von Till am laufenden
Build abgenommen („zeilen und spalten sehen jetzt gut aus"). Volle Unit-Suite:
**270 Tests, 0 Fehler**.

## Ergebnis

Der erste Anlauf (`203bd39`) wurde bei der Sichtprüfung abgelehnt und
zurückgenommen (`c726651`): die Kurzansicht zeichnete keine sichtbaren Spalten.
Die Ursache war damals nicht diagnostiziert. Sie ist es jetzt, und es waren
**zwei** Fehler, beide in `BriefLayout`.

**1. Das Layout las seine eigene Ausgabe.** Die Collection View ist die
`documentView` der Scroll View — AppKit setzt ihre Größe *aus*
`collectionViewContentSize`. Das Layout las `collectionView.bounds` zurück, um
Spaltenbreite und Zeilenzahl zu bestimmen. Beim ersten Durchgang ist bounds nahe
null: eine Zeile pro Spalte, Mindestbreite 80pt — eine einzige Zeile Namen, die
seitwärts läuft. Danach eine Rückkopplung, weil breiterer Inhalt die documentView
verbreitert, die wiederum die Spalten verbreitert; verstärkt durch ein
`shouldInvalidateLayout(forBoundsChange:)`, das bedingungslos `true` lieferte.

Behoben: beide Maße kommen jetzt aus dem **Viewport** (der Clip View der Scroll
View), und invalidiert wird nur, wenn sich dieser Viewport wirklich ändert.
Scrollen und wachsender Inhalt lösen kein Neu-Layout mehr aus.

**2. Ein zweiter Fehler, beim Beheben gefunden.**
`layoutAttributesForElements(in:)` lief pro Durchgang über *alle* Frames — bei
der #22-Baseline von 50k Dateien also 50k Rechteck-Schnitte je Scroll-Tick. Die
Zellen blieben O(sichtbar), die alte Commit-Aussage war insofern nicht falsch,
aber das Akzeptanzkriterium „keine Regression gegen #22" wäre rot gewesen. Das
Raster ist regelmäßig, also wird der sichtbare Indexbereich jetzt aus
`rect.minX / columnWidth` gerechnet und nur dieser Ausschnitt geprüft.

**3. Raster sichtbar gemacht** (Tills Rückmeldung: „was fehlt ist die separierung
der columns und der rows"). `BriefCollectionView` zeichnet abwechselnde
Zeilenbänder über die volle Breite — dieselben, die die Detail-Tabelle schon
benutzt — und eine Haarlinie zwischen den Spalten, dieselbe wie alle anderen
Kanten im Fenster. Nie an der linken Kante und nie hinter der letzten **gefüllten**
Spalte: drei linierte Spalten mit Inhalt in einer lesen sich als fehlender
Inhalt, nicht als freier Platz. Gezeichnet in der Collection View statt je Zelle,
weil die Bänder durch die Lücke einer kurzen letzten Spalte durchlaufen müssen
und Zellen wiederverwendet werden.

### Diesmal wurde hingesehen

Der erste Anlauf ist genau daran gescheitert, dass niemand das Ergebnis
angeschaut hat. Dieser wurde am laufenden Build geprüft, mit einem 400-Dateien-
Ordner: Spalten zeichnen **beim ersten Bild**, füllen die Panel-Höhe, laufen
oben-nach-unten und dann nach rechts, und 1/2/3 ändern die Spaltenbreite
sichtbar. Aufnahme über die CGWindowID, damit die Sonde keinen Fokus stiehlt.

Persistenz getrennt geprüft, auf einem **ungeseedeten** Start (`DIPTYCHON_DIR`
schaltet Persistenz ab, dort wäre die Prüfung wertlos gewesen): nach Beenden und
Neustart trägt der gespeicherte Blob `briefColumns: 2` für die linke Pane und
nichts für die rechte.

### Akzeptanzkriterien

- [x] Pane schaltet zwischen Tabelle und 1/2/3-spaltiger Kurzansicht.
- [x] Modus je Pane gemerkt, übersteht Beenden + Neustart (`PaneState.briefColumns`,
      additiv — Blobs von vor #37 lesen als Tabelle).
- [x] Tastaturnavigation, Filter und QuickLook funktionieren weiter.
- [x] Virtualisiert: sichtbarer Bereich wird gerechnet, nicht gesucht.
- [x] `context/competitor-benchmark.md` §5 auf ✅.

### Was Till dabei aufgefallen ist — und ein eigenes Ticket wurde

Beim Testen erwartete Till, dass ein angeklickter Ordner seinen Inhalt in der
**nächsten Spalte** zeigt. Das ist die Spaltenansicht des Finders (Miller
Columns), ein anderes Navigationsmodell und nicht das, was dieses Ticket baut.
Beide bleiben: siehe **#91**. Die Kurzansicht überblickt *einen* großen Ordner,
die Spaltenansicht läuft einen *tiefen Baum* ab.

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
