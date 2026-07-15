# PLAN

## Roadmap-lite
Reach-Test (Ads/Outreach → signups) → Demand-Test (5 Sessions → Day-10-Retention) → GO? → Notarisierung ($99) → Launch (Access-Wall weg)

## Offen — bei Till
<!-- persistent; Zeile löschen, sobald entschieden/erledigt -->
- [ ] **Finder-Ersatz: main pushen?** Merge `24f9396` ist nur lokal (Worktree + Branch bereits entfernt 2026-07-12; Runbook: `context/finder-replacement-runbook.md`)
- [ ] **Cloudflare Zero Trust Access-Wall:** durchklicken (Schritte im Chat 2026-07-07) ODER bestätigen, dass der Reach-Test-Pivot sie überflüssig gemacht hat
- [ ] **Impressum-Daten liefern** → `datenschutz.html`/`impressum.html` füllen + deployen (aktuell Platzhalter, uncommitted in `.scratch/landing-page/`)
- [ ] **Reach-Test starten:** Google Ads + Roundup-Outreach live → `signups:src:*` lesen → GO/ITERATE/STOP (`context/reach-test.md`, `google-ads-setup.md`, `roundup-outreach.md`)
- [ ] **Demand-Test starten:** Screener finalisieren, 5 rekrutieren (2 Netzwerk + 3 cold) → Sessions Woche 1, Retention-Check ~Tag 10 (`context/demand-test.md`; Preis-Frage: €9.99 one-time)
- [ ] **Setup-Skills nachziehen** (Backlog, nicht dringend): `~/.claude/skills/user/project-setup` auf das neue Ruleset umstellen — PLAN-Struktur (Roadmap-lite / Offen-Till / Offen-AI / Aktiver Task), End-of-task-Issue-Close statt PROJECT-TRACKER-Scaffold; dabei alle Skills nach `PROJECT-TRACKER` greppen (auch `conductor`, `project-handoff`) — sonst regeneriert das nächste Projekt die alte Konvention (transferable-learnings §26)

## Offen — bei AI
Nächstes: **#52 batch-rename quality** (`ready-for-agent`, eigener Worktree). Volle Queue + Labels: `.scratch/diptychon-mvp/issues/`

## Aktiver Task
<!-- AI-Arbeitsstand; bei Done leeren + Issue schließen -->

### #36 Gadgets-lite — Plan (freigegeben 2026-07-15)

**Issue:** `.scratch/diptychon-mvp/issues/36-gadgets-lite-external-tool-actions.md` (ready-for-agent)
**Branch:** `feat/36-gadgets-lite` ab `e4091fc` (dieser Worktree, steady-fig — Achtung: springt vor #52 in der Queue)

**Verstanden:** User definiert deklarative "Gadgets" (Application = gespeichertes "Open With"; Executable = Binary + Argument-Template). Ausführung gegen die aktuelle Selektion, 6 Substitutionsvariablen, multi-value → separate argv-Einträge. Kein Scripting, kein Output-Capture, keine GUI.

**Recon-Fakten (2026-07-13):**
- Palette-Commands sind closure-fähig (`PaletteCommand`, `CommandPalette.swift:6`) → Gadgets werden dort zur Laufzeit eingemischt. `AppAction`-Enum ist statisch → **Hotkey-Binding für Gadgets = v1 out of scope** (Issue sagt "optional").
- App ist **nicht sandboxed** (`Diptychon.entitlements`, ADR 0001) → `Process` spawnen ist ohne Entitlement-Änderung möglich. Akzeptanzkriterium "Sandbox verifizieren" = dokumentieren, erledigt.
- Open-With-Plumbing (`OpenWithController.swift:100`, `NSWorkspace.open(_:withApplicationAt:)`) ist direkt wiederverwendbar für Application-Gadgets.
- Persistenz-Konvention der App = UserDefaults-Blobs; es gibt noch KEINE Datei in Application Support.

**Schritte:**
1. [x] `Gadget` + `GadgetConfig` (toleranter Decode) + `GadgetStore` (`gadgets.json` in App Support) — `Sources/Diptychon/Gadgets/`
2. [x] Substitutions-Engine pure (`GadgetSubstitution`), unit-getestet inkl. Spaces/Multi-Select/Fehlerfälle
3. [x] Ausführung `GadgetRunner`: NSWorkspace / Process (argv-Array), off-main, First-Run-Confirm (B), Fehler → Alert
4. [x] Palette-Integration: Gadgets + „Gadgets: Edit Config…"/„Gadgets: Reload" zur Laufzeit gemerged (`filter(_:in:)`-Overload)
5. [x] Tests: 3 neue Suiten (Substitution/Config/Store), Unit-Suite 192/192 grün; UI-Suite: `testToggleRightPanel` schlägt fehl, aber **identisch auf main 83e213a** → Vorbestand/Umgebung, nicht #36
6. [x] Doku: `docs/gadgets.md` neu; Benchmark §5 Gadgets-Zeile → ✅, Extensibility-Note angepasst

**Status 2026-07-15:** Implementiert + getestet, UNCOMMITTED — wartet auf Tills Hands-on-Test (show-before-commit). Danach: commit, Issue #36 schließen, PLAN leeren. Offen zu klären: UI-Test-Vorbestand ggf. als eigenes Issue filen.

**Entscheidungen (Till, 2026-07-15):**
- **A — Config:** JSON-Datei in `~/Library/Application Support/Diptychon/gadgets.json` (handeditierbar)
- **B — Confirm-Dialog:** JA — beim ersten Lauf jedes Executable-Gadgets (zeigt, was ausgeführt wird)
- **C — Hotkey-Binding:** bestätigt out of scope v1 (Palette-only; Folge-Issue statt Keymap-Umbau)
