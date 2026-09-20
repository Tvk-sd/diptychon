# 95 — ⌘V (und ⌘C/⌘X) in Textfeldern tot: Pfad in die Suche einfügen geht nicht

Status: **CLOSED (2026-09-20)** — gemerged auf main als `9dc1061` (Fix-Commit `51e47c6`), Release-Build nach `/Applications` installiert. Gemeldet von Till am 2026-09-20: „path search
does not work it seems" — ein voller Pfad, in allen drei Ansichten.

## Parent

`.scratch/diptychon-mvp/issues/76-*.md` (Menüleiste sagt die Wahrheit über das
Produkt, `f880391`). Der Pfad-Sprung selbst ist aus der Fuzzy-Search-Runde
(`PanelModel.navigateIfPath`, gemerged `74a5070`) und funktioniert unverändert.

## Problem Statement

Ein Pfad, der in das Suchfeld **eingefügt** wird, kommt dort nie an. ⌘V tut in
jedem Textfeld der App nichts — Suche, Filter, Umbenennen, Gehe-zu-Ordner.

Ursache: AppKit beantwortet ⌘V/⌘C/⌘X in einem Textfeld nicht selbst. Das tut das
**Bearbeiten-Menü**, über die Tastenkürzel seiner Standard-Einträge Ausschneiden /
Kopieren / Einfügen (Aktion `paste:` an den First Responder). #76 hat die
`.pasteboard`-Gruppe durch `ActionMenuItem`-Zeilen ersetzt, die absichtlich kein
Tastenkürzel tragen (der NSEvent-Monitor ist die Tastatur-Autorität). Damit ist
der einzige Weg, auf dem ⌘V ein Textfeld erreicht hat, weggefallen. Der Monitor
selbst reicht das Event zwar durch (`firstResponder is NSText`), aber dahinter
wartet niemand mehr.

Genau diese Regression hat #76 für ⌘A schon einmal gebaut und nur für ⌘A repariert
(siehe Kommentar an der „Select All"-Zeile in `DiptychonApp.swift`).

Nachgewiesen am laufenden Debug-Build (2026-09-20): Tippen von `abc` in die Suche
funktioniert, ⌘A markiert, ⌘V mit einem Pfad in der Zwischenablage ändert nichts.

## Plan

1. `Keymap.textEditingSelector(for:)`: feste Tabelle ⌘X/⌘C/⌘V → `cut:`/`copy:`/
   `paste:`. Systemkonvention, nicht rebindbar, kein `AppAction`.
2. Key-Monitor in `WorkspaceView`: im `NSText`-Zweig den Selector per
   `NSApp.sendAction` in die Responder-Kette schicken und das Event verbrauchen.
   Der Monitor bleibt der eine Weg, auf dem ein Tastendruck etwas auslöst.
3. Unit-Test für die Tabelle; Nachweis am laufenden Build wie oben (Pfad einfügen
   → Sprung in den Ordner, Datei markiert).

## Out of Scope

- ⌘Z/⇧⌘Z im Textfeld (`.undoRedo` ebenfalls ersetzt) — gleiche Klasse, eigener
  Mechanismus (Undo-Manager des Field Editors). Wird hier mitgeprüft, aber nur
  übernommen, wenn es am laufenden Build nachweisbar geht.
- Spaltenansicht zeigt Suchergebnisse nur in der letzten, 240 pt schmalen Spalte
  (`PanelView.swift:99` rendert den Column-Browser vor dem Such-Zweig). Echt, aber
  nicht dieser Bug — eigenes Ticket, falls gewünscht.

## Outcome (2026-09-20, main `9dc1061`)

Zwei Fehler, beide behoben:

1. **⌘V/⌘C/⌘X tot in Textfeldern** — `Keymap.textEditing` (feste Tabelle Chord →
   `cut:`/`copy:`/`paste:`) plus Zustellung im Key-Monitor (`WorkspaceView`),
   solange ein `NSText` First Responder ist. `Keymap.action(for:)` teilt sich
   jetzt den Lookup (`lookup(_:in:)`), Verhalten unverändert. Unit-Test
   `TextEditingChordTests` (3 Fälle).
2. **Feld zeigte nach dem Sprung weiter den Pfad** — das Modell leert
   `searchQuery` im selben Turn (`afterNavigation`), SwiftUI sah „" → Pfad → „"
   als „keine Änderung" und schob nichts ins `NSTextField`; der nächste Tastendruck
   hängte sich an den alten Pfad. `SearchFieldView` hält den Text jetzt als
   eigenen `@State`, spiegelt ihn ins Modell und liest die Leerung direkt nach der
   Übergabe zurück. Ein `onChange` auf dem Modell wäre für denselben Rundlauf
   ebenso blind gewesen — deshalb das Zurücklesen in `onChange(of: text)`.

Nachweis am laufenden Debug-Build (Seed-Ordner, `osascript`-Tastendrücke,
Screenshots): Pfad einfügen → Pane springt in `seed/alpha/beta`, `target.txt` grau
markiert, Suchfeld leer; danach `hello` tippen, ⌘A, ⌘C → Zwischenablage `hello`
(vorher: Pfad + `hello`). ⌘X-Rundlauf ebenfalls geprüft.

Tests: 310 Unit-Tests grün. UI-Suite 15/16 — `testTabMovesArrowKeyFocusToOtherPanel`
fällt **auch auf main** (`e9caa9b`) ohne diese Änderung, siehe #96.

⌘Z/⇧⌘Z im Textfeld: nicht angefasst (siehe Out of Scope).
