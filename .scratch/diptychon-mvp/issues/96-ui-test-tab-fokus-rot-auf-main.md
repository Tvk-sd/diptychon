# 96 — UI-Test `testTabMovesArrowKeyFocusToOtherPanel` ist rot auf main

Status: **OPEN** — `needs-triage`. Gefunden am 2026-09-20 beim vollen Suitenlauf
für #95; reproduziert auf main `e9caa9b` ohne die #95-Änderungen (Einzellauf,
zweimal).

## Problem Statement

`Tests/DiptychonUITests/DiptychonUITests.swift:165`:

```
XCTAssertTrue failed - ↓ after Tab should select in the right panel, not keep driving the left
```

Tab wechselt das Panel, ↓ wählt danach aber weiter links. Verdacht: die heute
gemergte Fokus-Runde aus #94 (`e9caa9b`, Spaltenansicht-Fokusmodell, Focus-Claim-
Guards in Table und Brief) hat das Tab-Verhalten der Tabellenansicht verschoben.
Nicht verifiziert — nur der Zeitpunkt passt.

## Nächster Schritt

Am laufenden Build prüfen, ob Tab + ↓ wirklich falsch ist oder nur der Test
(Fokus-Claim greift zu spät). Dann entweder #94 nachziehen oder den Test.
