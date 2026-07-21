# #64 — Globale Suche ignoriert DIPTYCHON_DIR (läuft immer übers echte Home)

**Status:** closed (2026-07-21)
**Erstellt:** 2026-07-21 (posthum, gefunden bei #62 Demo-Video-Harness)

## Symptom

Mit gesetztem `DIPTYCHON_DIR` (UI-Tests, Demos, deterministische Läufe) öffnen
beide Panes im Seed-Root — aber die globale Suche (`PanelModel.homeDirectory`)
walkt weiterhin `FileManager.homeDirectoryForCurrentUser`, also das ECHTE Home.
Folgen: nicht-deterministische/riesige Such-Walks in Tests, und im Demo-Fall
tauchen echte private Dateien in den Ergebnissen auf.

## Ursache

`homeDirectory` war fix auf das User-Home berechnet; der `DIPTYCHON_DIR`-
Kontrakt („open here, deterministically", WorkspaceModel) galt nur für die
Pane-Roots, nicht für den Such-Root.

## Fix

`PanelModel.homeDirectory` bevorzugt `DIPTYCHON_DIR`, sonst wie bisher das
User-Home. Reale Nutzer: unverändert. Datei:
`Sources/Diptychon/Panel/PanelModel.swift`.

## Verifikation

- Demo-Harness (#62): Suche „harbor" liefert mit Fix sofort Ergebnisse aus dem
  Seed-Tree statt eines minutenlangen Walks über das echte Home.
- Volle Suite: siehe Outcome.

## Outcome

Committed auf main: `378cfae` — Suite grün vor Commit (220 Unit + 13 UI).
