# PLAN

## Roadmap-lite
**Entschieden 2026-08-04 (ADR 0008): die Website verteilt und lernt, sie validiert nicht mehr.** Membership ist gekauft, damit wird der Download echt; Signups als Validierungs-Proxy sind hinfällig, ein Download ist das stärkere Signal.

Readiness-Gate (#68) → Notarisierung + echter Download (#69) → Startseite auf „free while in beta" umbauen (#71) → Downloads + Freitext lesen (#70/#72/#73) → Preismodell (#66)

## Offen — bei Till
<!-- persistent; Zeile löschen, sobald entschieden/erledigt -->
- [ ] **Signier-Schlüssel zurück in den Schlüsselbund (Release 0.2.0 blockiert):** am 2026-09-21 fehlten beide — kein „Developer ID Application"-Zertifikat, kein Notary-Profil `diptychon-notary` (Schlüsselbund-Ordner ist vom 2026-09-03/04, sieht nach Neuaufsetzen aus). Zertifikat: Xcode ▸ Settings ▸ Accounts ▸ Manage Certificates ▸ `+` ▸ Developer ID Application. Notary: `.p8` aus dem Passwort-Manager, dann `xcrun notarytool store-credentials diptychon-notary --key <pfad.p8> --key-id <KEY_ID> --issuer <ISSUER_UUID>` (eine Zeile). Danach `RELEASE_BRANCH=… ./scripts/release.sh` — Version 0.2.0 (Build 2) ist schon committet (`772cbaa`), Unit-Tests grün
- [ ] **Doppelklick-Gegenprobe (#69, 2 Minuten):** der notarisierte Download ist live und per `spctl` abgenommen, aber vom selben Mac aus. Einmal `/Applications/Diptychon.app` von Hand starten und bestätigen, dass kein Gatekeeper-Dialog kam — oder idealerweise auf einem fremden Mac laden
- [ ] **API-Key aus `~/Downloads` räumen (2 Minuten):** `AuthKey_8274WG2YD4.p8` liegt dort weltlesbar. In den Passwort-Manager, dann aus Downloads löschen — er erlaubt, in deinem Namen zu notarisieren. Nicht im Repo, dort ist nichts zu tun (Details in `context/notarization-runbook.md`)
- [ ] **#66-Widerspruch auflösen (sofort machbar):** PRD nennt „MIT license", ADR 0007 nennt Einmalkauf — bevor das Zahlungssignal da ist, muss wenigstens die Dokumentenlage stimmen. Website nennt bis dahin keinen Preis. Zed-Recherche (2026-08-19) liegt im Issue: Zed monetarisiert Dienste, nicht Features, und ist VC-finanziert — als Vorbild strukturell nicht übertragbar; falls doch OSS, wäre Copyleft statt MIT die Lehre (`.scratch/diptychon-mvp/issues/66-open-core-vs-einmalkauf.md`)
- [ ] **A2-Fakten vendor-direkt gegenprüfen (#67):** vor dem #71-Deploy die Preise einmal direkt checken (Remote kommt an binarynights/cocoatech/macupdate nicht ran, 403); Verdachtsfälle im Issue: ForkLifts Update-Fenster-Lizenz, Path Finders Staffel. Daran hängt auch der Wedge-Begriff („Update-Fenster" / „Buy once, updates included. No expiry date.")
- [ ] **Fast-Channel wählen (#84):** Vorarbeit liegt seit 2026-08-19 im Issue — Shortlist mit 5 vorrecherchierten Kandidaten (MacSparky, 512 Pixels, Six Colors ~$750, Dense Discovery, Sweet Setup), Copy-Entwurf, Slug-Schema und eine Empfehlung (Sponsorship vor Track B, mit Fallback-Regel). Dein Teil: Archive/Preise vom eigenen Rechner verifizieren, Empfehlung abnehmen oder kippen, buchen. Außerdem den Substack-Artikel einmal im Original lesen (remote blockt substack.com)
- [ ] **`DIPTYCHON_NO_DEVICES` abnehmen oder kippen (2 Minuten):** drei Zeilen in `WorkspaceModel.swift` leeren die Devices-Sektion, wenn die Variable gesetzt ist — gleiche Bauart wie `DIPTYCHON_DIR`, eingeführt für die Landingpage-Screenshots (sonst stehen deine echten Volumes im Bild). Produktcode mit Marketing-Haken: behalten oder rausnehmen und stattdessen vor jedem Shooting auswerfen (Commit `512ae55`)
- [ ] **#58 triagieren:** Rename des aktuellen Ordners/Devices via Breadcrumb — 4 offene Fragen im Issue beantworten (Interaktion, Scope, Devices, Watcher-Folgen) oder Grill-Session starten (`.scratch/diptychon-mvp/issues/58-rename-in-place-via-breadcrumb.md`)
- [ ] **Homepage, mittlere „Why“-Kachel („Small, native, private“):** hat kein Screenshot, nur die Textliste. Bild gewünscht, und wenn ja welches? (Tags-Light-Shot bleibt wie er ist, Tills Entscheidung 2026-09-21: das ist macOS-Standard-Icon in Light, Reshoot ändert nichts)

## Offen — bei AI

