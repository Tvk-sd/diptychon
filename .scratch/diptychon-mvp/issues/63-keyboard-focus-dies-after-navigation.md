# #63 — Tastatur-Selektion stirbt nach jeder ⏎-Navigation (bis zum Klick)

**Status:** closed (2026-07-21)
**Erstellt:** 2026-07-21 (posthum, gefunden bei #62 Demo-Video-Harness)

## Symptom

Nach jeder Ordner-Navigation per ⏎ reagieren ↑/↓ nicht mehr — Selektion tot,
bis man einmal in die Liste klickt. Keymap-Chords (⌘↑, Tab, ⌥←/→) funktionieren
weiter (laufen über den NSEvent-Monitor, brauchen keinen Table-Fokus).
Trifft den Kern der Keyboard-first-Story.

## Ursache

`PanelView` schaltet beim Navigieren durch den Load-State-`switch` (loading ↔
loaded) — SwiftUI reißt das `NSTableViewFileList`-Representable ab und baut es
neu. Der Fokus-Claim in `updateNSView` läuft im ersten Update-Pass, wenn
`scroll.window == nil` (View noch nicht attached) → no-op, kein Retry. Erst-
responder bleibt beim Window; native Pfeiltasten erreichen die Table nie.

## Fix

`FileTableView.viewDidMoveToWindow` claimt den Fokus selbst, sobald die Table
im Window landet (`claimsKeyFocusOnAttach`-Closure, vom Representable gesetzt).
Guard unverändert: nie einem Textfeld (NSText/Field-Editor) den Fokus stehlen.
Datei: `Sources/Diptychon/Panel/NSTableViewFileList.swift`.

## Verifikation

- Reproduziert + Fix bestätigt über CGEvent-Harness (#62): ⏎-Navigation zwei
  Ebenen tief, danach ↓ selektiert sofort (Screenshot-verifiziert).
- Volle Suite: siehe Outcome.

## Outcome

Committed auf main: `fe2f3d1` — Suite grün vor Commit (220 Unit + 13 UI; 3 initiale UI-Failures waren testmanagerd-Wedge, nach pkill reproduzierbar grün).
