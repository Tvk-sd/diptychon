# PLAN

## Roadmap-lite
**Entschieden 2026-08-04 (ADR 0008): die Website verteilt und lernt, sie validiert nicht mehr.** Membership ist gekauft, damit wird der Download echt; Signups als Validierungs-Proxy sind hinfällig, ein Download ist das stärkere Signal.

Readiness-Gate (#68) → Notarisierung + echter Download (#69) → Startseite auf „free while in beta" umbauen (#71) → Downloads + Freitext lesen (#70/#72/#73) → Preismodell (#66)

## Offen — bei Till
<!-- persistent; Zeile löschen, sobald entschieden/erledigt -->
- [ ] **Doppelklick-Gegenprobe (#69, 2 Minuten):** der notarisierte Download ist live und per `spctl` abgenommen, aber vom selben Mac aus. Einmal `/Applications/Diptychon.app` von Hand starten und bestätigen, dass kein Gatekeeper-Dialog kam — oder idealerweise auf einem fremden Mac laden
- [ ] **Menüeintrag gegentesten (#74):** Hilfe ▸ Keyboard Shortcuts… ist gebaut und per UI-Test belegt, aber noch nie von Hand gesehen — beim Bauen lief deine eigene Instanz
- [ ] **#66-Widerspruch auflösen (sofort machbar):** PRD nennt „MIT license", ADR 0007 nennt Einmalkauf — bevor das Zahlungssignal da ist, muss wenigstens die Dokumentenlage stimmen. Website nennt bis dahin keinen Preis (`.scratch/diptychon-mvp/issues/66-open-core-vs-einmalkauf.md`)
- [ ] **A2-Fakten vendor-direkt gegenprüfen (#67):** vor dem #71-Deploy die Preise einmal direkt checken (Remote kommt an binarynights/cocoatech/macupdate nicht ran, 403); Verdachtsfälle im Issue: ForkLifts Update-Fenster-Lizenz, Path Finders Staffel. Daran hängt auch der Wedge-Begriff („Update-Fenster" / „Buy once, updates included. No expiry date.")
- [ ] **#58 triagieren:** Rename des aktuellen Ordners/Devices via Breadcrumb — 4 offene Fragen im Issue beantworten (Interaktion, Scope, Devices, Watcher-Folgen) oder Grill-Session starten (`.scratch/diptychon-mvp/issues/58-rename-in-place-via-breadcrumb.md`)

## Offen — bei AI
**#68 und #69 sind zu** — Gate leer (letzter Blocker #77 am 2026-08-10 behoben und empirisch bestätigt), Download notarisiert und live (`1a67c05`, promptet beim Start nicht mehr). **Aktiv: #71** (Flip auf „free while in beta") — a2-Branch ist gemerged, Umbau läuft. DMG danach: #79.

Eingefroren bis echter Nutzer-Input da ist: **#39** (Recent Locations) und **#40** (Ladepfad). Beide sind Vermutungen aus der Netnographie, und ADR 0008 stellt die Reihenfolge künftig auf das um, was Nutzer schreiben. Auftau-Bedingung ist deshalb nicht „nach #71", sondern: die ersten Freitextantworten aus **#72** liegen vor. Nennt sie niemand, sind sie nicht dran.
