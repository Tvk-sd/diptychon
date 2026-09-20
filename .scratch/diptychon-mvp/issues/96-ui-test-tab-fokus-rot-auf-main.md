# 96 — UI-Test `testTabMovesArrowKeyFocusToOtherPanel` ist rot auf main

Status: **CLOSED (2026-09-20)** — gemerged auf main als `b7132a5` (Commit `9893000`). Test war veraltet, Verhalten in Ordnung. Gefunden am 2026-09-20 beim vollen Suitenlauf
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

## Outcome (2026-09-20, main `b7132a5`)

Der Verdacht auf #94 war falsch. Der Test ist seit **#86** (`775188a`) rot: dort
bekam Tab die Regel „Ziel-Panel erhält eine Heimatzeile (Zeile 0)", der Test aus
#53 erwartete aber noch, dass ↓ nach Tab Zeile 0 wählt. Seit #86 wählt ↓ Zeile 1.
Nachgewiesen durch Lauf des Originaltests am Commit `775188a` (rot).

Das Verhalten ist das gewollte: Tab wechselt das Panel, gibt ihm Zeile 0, ↓ geht
dort auf Zeile 1 (gamma), nicht im linken Panel. Der Test erwartet jetzt das
Rename-Feld `gamma.txt` im rechten Panel. Nur der Test geändert.

UI-Suite: 17/17 grün. Die Lehre steht in
`~/.claude/…/memory/run-full-suite-before-merge.md`: #86 ist ohne UI-Lauf gemergt
worden, und drei Merges lang hat es niemand gemerkt.
