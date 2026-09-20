# PLAN

## Roadmap-lite
**Entschieden 2026-08-04 (ADR 0008): die Website verteilt und lernt, sie validiert nicht mehr.** Membership ist gekauft, damit wird der Download echt; Signups als Validierungs-Proxy sind hinfällig, ein Download ist das stärkere Signal.

Readiness-Gate (#68) → Notarisierung + echter Download (#69) → Startseite auf „free while in beta" umbauen (#71) → Downloads + Freitext lesen (#70/#72/#73) → Preismodell (#66)

## Offen — bei Till
<!-- persistent; Zeile löschen, sobald entschieden/erledigt -->
- [ ] **Doppelklick-Gegenprobe (#69, 2 Minuten):** der notarisierte Download ist live und per `spctl` abgenommen, aber vom selben Mac aus. Einmal `/Applications/Diptychon.app` von Hand starten und bestätigen, dass kein Gatekeeper-Dialog kam — oder idealerweise auf einem fremden Mac laden
- [ ] **API-Key aus `~/Downloads` räumen (2 Minuten):** `AuthKey_8274WG2YD4.p8` liegt dort weltlesbar. In den Passwort-Manager, dann aus Downloads löschen — er erlaubt, in deinem Namen zu notarisieren. Nicht im Repo, dort ist nichts zu tun (Details in `context/notarization-runbook.md`)
- [ ] **#66-Widerspruch auflösen (sofort machbar):** PRD nennt „MIT license", ADR 0007 nennt Einmalkauf — bevor das Zahlungssignal da ist, muss wenigstens die Dokumentenlage stimmen. Website nennt bis dahin keinen Preis. Zed-Recherche (2026-08-19) liegt im Issue: Zed monetarisiert Dienste, nicht Features, und ist VC-finanziert — als Vorbild strukturell nicht übertragbar; falls doch OSS, wäre Copyleft statt MIT die Lehre (`.scratch/diptychon-mvp/issues/66-open-core-vs-einmalkauf.md`)
- [ ] **A2-Fakten vendor-direkt gegenprüfen (#67):** vor dem #71-Deploy die Preise einmal direkt checken (Remote kommt an binarynights/cocoatech/macupdate nicht ran, 403); Verdachtsfälle im Issue: ForkLifts Update-Fenster-Lizenz, Path Finders Staffel. Daran hängt auch der Wedge-Begriff („Update-Fenster" / „Buy once, updates included. No expiry date.")
- [ ] **Fast-Channel wählen (#84):** Vorarbeit liegt seit 2026-08-19 im Issue — Shortlist mit 5 vorrecherchierten Kandidaten (MacSparky, 512 Pixels, Six Colors ~$750, Dense Discovery, Sweet Setup), Copy-Entwurf, Slug-Schema und eine Empfehlung (Sponsorship vor Track B, mit Fallback-Regel). Dein Teil: Archive/Preise vom eigenen Rechner verifizieren, Empfehlung abnehmen oder kippen, buchen. Außerdem den Substack-Artikel einmal im Original lesen (remote blockt substack.com)
- [ ] **#58 triagieren:** Rename des aktuellen Ordners/Devices via Breadcrumb — 4 offene Fragen im Issue beantworten (Interaktion, Scope, Devices, Watcher-Folgen) oder Grill-Session starten (`.scratch/diptychon-mvp/issues/58-rename-in-place-via-breadcrumb.md`)

## Offen — bei AI
**Die Folge #68→#69→#71 ist komplett** (2026-08-11): Gate leer, Download notarisiert, Startseite + A2-Seiten + `/docs` live auf „free while in beta". **Nächstes: lesen statt bauen** — Downloads pro Kanal (#70/#73) und Freitext (#72) auswerten, sobald etwas hereinkommt; die ersten Zähler sind live seit dem Flip. Danach entscheidet sich #66 (Preis) und die Auftau-Bedingung für #39/#40. DMG-Umstellung: #79.

Eingefroren bis echter Nutzer-Input da ist: **#39** (Recent Locations) und **#40** (Ladepfad). Beide sind Vermutungen aus der Netnographie, und ADR 0008 stellt die Reihenfolge künftig auf das um, was Nutzer schreiben. Auftau-Bedingung ist deshalb nicht „nach #71", sondern: die ersten Freitextantworten aus **#72** liegen vor. Nennt sie niemand, sind sie nicht dran.
