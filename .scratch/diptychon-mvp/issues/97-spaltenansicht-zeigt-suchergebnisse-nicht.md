# 97 — Spaltenansicht zeigt Suchergebnisse nicht

Status: **CLOSED (2026-09-20)** — gemerged auf main als `73df9bc` (Commit `89c956b`), Release-Build nach `/Applications` installiert. Gefunden am 2026-09-20 bei der Analyse von
#95; Till hat das Ticket angefordert („open an issue for the column view search").

## Parent

`.scratch/diptychon-mvp/issues/91-spaltenansicht-miller-columns.md` — die
Spaltenansicht kennt die Suche nicht. Die Suche selbst (Fuzzy-Match, Pfad-Suche,
Pfad-Sprung) ist in Ordnung und in #95 zuletzt geprüft.

## Problem Statement

Steht eine Pane in der Spaltenansicht, rendert `PanelView` den `ColumnBrowserView`
**vor** dem Such-Zweig (`Sources/Diptychon/Panel/PanelView.swift`, Abfrage
`displayMode == .columns` vor `isSearching`). Folgen, alle nur in dieser Ansicht:

- Die Suche läuft, die Kopfzeile meldet „N results", aber der Körper zeigt weiter
  die Spaltenkette.
- Die Treffer erscheinen nur in der **letzten** Spalte — 240 pt breit, ohne den
  Ordner-Untertitel, den die Tabellen- und Kurzansicht zeigen. Die letzte Spalte ist
  das Pane-Modell selbst (`columnModel(for:)` gibt `self` zurück), und dessen
  `visibleItems` sind während der Suche die Treffer.
- „Searching…" und „No Results" erscheinen nie; beide Zustände liegen im
  Nicht-Spalten-Zweig. Während der Walk läuft, ist die letzte Spalte einfach leer.

Das liest sich als „Suche geht nicht", wenn man in der Spaltenansicht sucht.

## Entscheidung (Till, 2026-09-20: „yes a")

**Option A:** Solange eine Suche aktiv ist (`isSearching`), zeigt die Pane die normale
Trefferliste — Tabellen- oder Kurzansicht, mit Untertitel, „Searching…" und
„No Results" — und fällt nach dem Leeren der Suche in die Spaltenkette zurück.
Kein Umbau des Column-Browsers. Verworfen wurde B (Treffer in der letzten Spalte
lassen): schmal, ohne Ort, und die beiden Leerzustände fehlen weiter.

## Plan

1. `PanelView`: den `displayMode == .columns`-Zweig um `&& !model.isSearching`
   ergänzen, damit der bestehende Such-/Tabellen-Pfad greift. Prüfen, welche
   Listenvariante während der Suche gilt (Tabelle, wie vor #91).
2. Sicherstellen, dass `columnRootStorage`/die Kette beim Zurückfallen intakt ist
   (Suche leeren → wieder Spalten, gleiche Verankerung wie vorher).
3. Ein Test auf Modellebene, falls die Anzeige-Entscheidung als reine Funktion
   herausgelöst wird; sonst Nachweis am laufenden Build mit Screenshot.

## Out of Scope

- Eine Suche, die innerhalb der Spalten lebt (Treffer als Spalteninhalt mit
  Pfadbrücke). Erst, wenn der Gebrauch danach ruft.

## Outcome (2026-09-20, main `73df9bc`)

Option A umgesetzt: `PanelModel.renderedMode` liefert, was der Inhaltsbereich
zeichnet — `displayMode`, außer Spalten während einer Suche, dann die Tabelle.
`PanelView` fragt an allen drei Stellen (28-pt-Abstandsstreifen, Column-Browser,
Kurzansicht) `renderedMode` statt `displayMode`. Der gewählte Modus bleibt, der
Umschalter zeigt weiter „Spalten", die Kette kommt beim Leeren der Suche zurück.

Tests: `RenderedModeTests` (2 Fälle, Modellebene) und XCUITest
`testSearchInColumnViewShowsResultListThenColumnsReturn` (Spalten → Ordner wählen
→ suchen → Treffer mit Ort in der Tabelle, keine Spalten → leeren → Spalten zurück).
Der UI-Test ist ohne die Änderung rot (geprüft gegen main). Suite: 312 Unit-Tests
grün, UI 17/18 — die eine rote ist weiter #96.

Nebenbefund beim Probieren von Hand: `osascript`-Mausklicks landeten hier nicht im
Fenster, ⌘2 stirbt, solange das Suchfeld First Responder ist. Der XCUITest war
der verlässliche Weg.
