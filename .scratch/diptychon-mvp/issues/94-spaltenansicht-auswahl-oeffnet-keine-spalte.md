# 94 — Spaltenansicht: Ordner auswählen öffnet keine nächste Spalte

Status: **CLOSED (2026-09-20)** — abgenommen von Till („good, looks good"), gemerged auf main als `e606996`. Gemeldet von Till am
2026-09-20 beim Gebrauch der Spaltenansicht aus #91: „selecting a folder (arrow
keys or click) does not fill the next column. It stayed empty in every attempt."

## Parent

`.scratch/diptychon-mvp/issues/91-spaltenansicht-miller-columns.md` — User Story 1
dort („Ordner auswählen und seinen Inhalt sofort rechts daneben sehen") ist für
die letzte Spalte nie gebaut worden. Dieses Ticket holt sie nach.

## Problem Statement

Die Spaltenansicht kennt eine Regel: Ordner in Spalte *i* gewählt → `directory`
zeigt auf ihn → die Kette wächst um eine Spalte. Diese Regel steckt in
`ColumnBrowserView.apply` und gilt nur für die **linken** Spalten. Die **letzte**
Spalte ist direkt an die Auswahl der Pane gebunden (`$bindable.selection`); Klick
und ↑/↓ markieren dort nur die Zeile und rufen `openColumn` nie auf.

Beim Einschalten besteht die Ansicht aus genau einer Spalte, und die ist die
letzte. Also kann keine Auswahl je eine zweite Spalte öffnen. Nur Doppelklick,
Return (`onActivate`) und → kommen an `openColumn` vorbei. Das ist der Grund,
warum jeder Versuch scheiterte.

## Warum kein Einzeiler

Ließe man die letzte Spalte bei Auswahl einfach `openColumn` rufen, würde der
neue Ordner zur letzten Spalte und bekäme mit `claimingKeyFocus(isLast)` sofort
den Tastaturfokus. Jedes ↓ liefe dann in den Kindordner hinein statt zum nächsten
Geschwister. Der Finder hält den Fokus in der Spalte, in der man steht, und zeigt
rechts nur eine Vorschau. Die Ansicht braucht also eine Vorstellung davon,
**welche Spalte den Fokus hat**, getrennt davon, welche die letzte ist.

## Plan

**Annahmen:**
- „Auswählen" heißt Einzelauswahl eines Ordners. Mehrfachauswahl öffnet nichts
  (wie im Finder), sie schneidet die Kette auf die eigene Spalte zurück.
- `directory` bleibt die letzte Spalte; die Herleitung aus #91 bleibt stehen. Neu
  ist nur ein Fokus-Zeiger auf eine Spalten-URL. Zeigt er auf keine Spalte der
  Kette (nach Sidebar-Klick, Breadcrumb, ⌘←), fällt der Fokus auf die letzte.
- Nach Ordnerwahl ist die Pane-Auswahl leer (die letzte Spalte ist der Ordner,
  in dem noch nichts gewählt ist). Das ist bereits heute so, wenn man in einer
  mittleren Spalte klickt; Kopieren wirkt dann auf nichts. Bleibt so.

**Schritte:** (1–4 und 6 erledigt am 2026-09-20, Unit-Suite 300/300 grün; 5 liegt bei Till)
1. `PanelModel`: Fokus-Zeiger `columnFocus` + Auflösung auf die Kette; die
   Auswahlregel wandert als `pickInColumn(ids, at: folder)` ins Modell, damit sie
   testbar ist. ← / → als `stepColumnFocus(right:)`: → rückt den Fokus eine
   Spalte nach rechts und wählt dort die erste Zeile (Story 4 aus #91), ← rückt
   ihn nach links, ohne die Kette zu kürzen (Story 5).
2. `openColumn`: die verlassene Spalte bekommt ihr Spalten-Modell **mit der
   Liste, die die Pane schon hat** (`adoptListing`), sonst zeigt die Spalte, in
   der man gerade tippt, für einen Moment den Spinner, das `NSCollectionView`
   fliegt aus der Hierarchie und der Fokus geht verloren. Umgekehrt übernimmt
   die Pane beim Zurückschneiden die Liste der gecachten Spalte.
3. `ColumnBrowserView`: alle Spalten laufen über dieselbe Bindung (Getter:
   eigene Auswahl in der letzten, hergeleitete in den übrigen; Setter:
   `pickInColumn`). Fokus-Anspruch nach `columnFocus`, nicht nach `isLast`.
4. Unit-Tests am Modell mit injizierter Quelle: Ordner wählen → Kette wächst,
   Fokus bleibt; Datei wählen → Kette schneidet; → / ← bewegen nur den Fokus;
   Sidebar-Navigation setzt den Fokus zurück.
5. Am laufenden Build mit dem Auge prüfen: Klick, ↑/↓ über Ordner und Dateien
   gemischt, →/←, dann Breadcrumb-Klick.
6. Volle Suite, dann Merge.

## Out of Scope

- Vorschau in der letzten Spalte (steht schon in #91 außen vor).
- Spaltenbreiten.
- Das Verhalten von ← in der ersten Spalte (heute: Elternordner öffnen, Anker
  bleibt stehen) — unverändert gelassen, nicht Teil des Fehlers.

## Outcome (2026-09-20, ungemergt, im Worktree `debug/91-column-view`)

- `PanelModel`: `focusedColumn` (Zeiger + Auflösung auf die Kette), `pickInColumn`,
  `stepColumnFocus`, `adoptListing`; `openColumn` setzt den Anker nach, wenn noch
  keiner da ist. `ColumnBrowserView`: eine Bindung für alle Spalten, Fokus-Anspruch
  nach `focusedColumn`; `step`/`apply` aus der View ins Modell gezogen.
- Neue Tests: `Tests/DiptychonTests/ColumnFocusTests.swift` (10 Fälle).
- **Zwei Nebenfunde, beide mitbehoben:**
  1. Eine Pane, die seit dem Start nie navigiert hat (Restore-Pfad), hatte keinen
     Spalten-Anker. Der erste `openColumn` ließ die Kette auf den neuen Ordner
     allein zusammenfallen — die linke Spalte verschwand.
  2. Derselbe Ordner kommt als `…/A/` (aus `contentsOfDirectory`) und als `…/A`
     (aus dem Ketten-Walker). `URL`-Gleichheit hält das für zwei Ordner; Cache,
     Fokus und der Nichts-tun-Guard in `openColumn` vergleichen jetzt über
     `columnKey` (Pfad, normalisiert).
- Abnahme Runde 1 durch Till (2026-09-20): **durchgefallen** — „navigation is broken
  right now, it is not clear to me when the arrows work in what direction and tab
  switches weirdly". Siehe Runde 2.

## Runde 2 (2026-09-20): Tastatur-Modell nachgezogen

Befund am laufenden Build (Sonde mit CGEvents, Screenshots je Taste, Seed-Baum
unter `~/.cache/diptychon-probe/seed`), fünf Ursachen, alle behoben:

1. **Fokus war unsichtbar.** Die Kurzansicht malte jede Auswahl blau, egal welche
   Liste die Tastatur hatte. Mit zwei Spalten hieß das: zwei blaue Zeilen, und ← sah
   aus, als täte es nichts. Jetzt: blau nur in der Liste mit Tastatur, sonst das
   System-Grau der Tabelle (`BriefItem.updateSelectionAppearance`, neu gezeichnet bei
   `becomeFirstResponder`/`resignFirstResponder`).
2. **Tab erreichte die Tabelle nicht.** Die Tabelle übernahm die Tastatur nur von
   einer anderen *Tabelle* oder vom Fenster, nie von einer `BriefCollectionView`. Aus
   einer Spalten- oder Kurzansichts-Pane heraus wurde die andere Pane per Tab zwar
   „aktiv" (fetter Kopf, Home-Zeile), tippte aber weiter in der alten Spalte.
   Altlast aus #37, nicht aus #91. Ein Wort in einem Guard
   (`NSTableViewFileList`).
3. **Abwählen schnitt die Kette.** `NSCollectionView` meldet einen Zeilenwechsel als
   „deselect, dann select". Das leere Zwischenergebnis kürzte die Kette auf die
   eigene Spalte und öffnete sie gleich wieder — zwei Navigationen pro Tastendruck,
   flackernde rechte Spalte. Jetzt ist eine leere Auswahl kein Pick; nur in der
   letzten Spalte ist sie ein echtes Abwählen.
4. **Neue Spalte zeigte alte Zeilen.** `openColumn` lud ohne Ladezustand, also stand
   unter dem neuen Kopf kurz die Liste des vorigen Ordners; → (und Tasten-Repeat)
   pickte daraus. Jetzt: Spinner bis die Zeilen da sind, → wartet solange.
5. **Tab-Home landete in der falschen Spalte.** `selectFirstRowIfEmpty` gab der
   letzten Spalte eine Zeile, auch wenn die Tastatur in einer linken Spalte saß.
   In der Spaltenansicht bekommt nur die fokussierte letzte Spalte ein Home, und
   zwar per `pickInColumn`, damit ein Ordner dort auch aufgeht.

Dazu drei Ecken geglättet: ⌘2 mit markiertem Ordner öffnet dessen Spalte sofort;
← in der ersten Spalte tut nichts mehr (statt Elternordner bei stehendem Anker);
die hergeleitete Markierung vergleicht Pfade statt `URL ==` (unter `/private`
lässt `standardizedFileURL` das Präfix fallen).

**Die Regeln, wie sie jetzt gelten** (auch in `docs/user-guide.md` §8 und
`docs/keyboard-reference.md`):

| Taste | Wirkung |
|---|---|
| Klick / ↑ / ↓ auf Ordner | öffnet ihn rechts; Tastatur bleibt |
| Klick / ↑ / ↓ auf Datei, Mehrfachauswahl | schließt Spalten rechts davon |
| → | Tastatur eine Spalte nach rechts, erste Zeile gepickt |
| ← | Tastatur eine Spalte zurück, Kette bleibt |
| ⇥ | Pane wechseln; zurück in derselben Spalte |
| Blau | die Spalte mit Tastatur; Grau = der Weg |

Sonde (8 Tasten, je Screenshot) am 2026-09-20 nach den Fixes: alle acht wie oben.
Unit-Suite 307/307 grün. Neue Tests: 17 in `ColumnFocusTests`.

- Abnahme Runde 2 durch Till (2026-09-20): **bestanden** („good, looks good").
  Fix-Commit `e606996` (rebased auf main, ohne den Icon-Commit `5ce6013` des
  Ausgangs-Worktrees). Web-Docs unter `.scratch/landing-page/docs` neu generiert
  (Hilfe → User Guide zeigt auf diptychon.com/docs). **Deploy steht aus** — der
  Agent darf nicht deployen; Till führt `npx wrangler deploy` aus
  `.scratch/landing-page` selbst aus (live ist noch der Stand vom 2026-08-10).
