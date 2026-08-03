# PLAN

## Roadmap-lite
**Entschieden 2026-08-04 (ADR 0008): die Website verteilt und lernt, sie validiert nicht mehr.** Membership ist gekauft, damit wird der Download echt; Signups als Validierungs-Proxy sind hinfällig, ein Download ist das stärkere Signal.

Readiness-Gate (#68) → Notarisierung + echter Download (#69) → Startseite auf „free while in beta" umbauen (#71) → Downloads + Freitext lesen (#70/#72/#73) → Preismodell (#66)

## Offen — bei Till
<!-- persistent; Zeile löschen, sobald entschieden/erledigt -->
- [ ] **Notarisierung abschließen (#69):** Enrollment-Status prüfen (kann 48 h „pending" stehen), Developer-ID-Application-Zertifikat in Xcode erzeugen, Notary-API-Key in App Store Connect holen (die `.p8` lädt genau einmal), `xcrun notarytool store-credentials`. Danach die Ausgabe von `security find-identity -v -p codesigning` durchgeben — daraus kommt die Team-ID. Blockiert #71
- [ ] **Doku regenerieren und platzieren (#42):** die Referenz ist nicht ungeprüft, sondern falsch — sie nennt `⌘[`/`⌘]`, seit #60 gilt ⌘←/⌘→; Terminal, Gadgets, Suche und Queue kommen null Mal vor. Generator neu laufen lassen, dann Platzierung entscheiden (Empfehlung: `diptychon.com/docs`)
- [ ] **Menüeintrag gegentesten (#74):** Hilfe ▸ Keyboard Shortcuts… ist gebaut und per UI-Test belegt, aber noch nie von Hand gesehen — beim Bauen lief deine eigene Instanz
- [ ] **#58 triagieren:** Rename des aktuellen Ordners/Devices via Breadcrumb — 4 offene Fragen im Issue beantworten (Interaktion, Scope, Devices, Watcher-Folgen) oder Grill-Session starten (`.scratch/diptychon-mvp/issues/58-rename-in-place-via-breadcrumb.md`)

## Offen — bei AI
Nächstes: **#68 Teil 2** — der empirische Erstlauf (Start ohne `workspaceState`, Timing der macOS-Zugriffsdialoge, Lesbarkeit der Zwei-Panel-Anordnung ohne Vorwissen, Rest der Standardmenüs). Braucht Tills Bildschirm, deshalb terminiert. Danach **#71** (Startseite umbauen), sobald #69 durch ist.

Eingefroren bis echter Nutzer-Input da ist: **#39** (Recent Locations) und **#40** (Ladepfad). Beide sind Vermutungen aus der Netnographie, und ADR 0008 stellt die Reihenfolge künftig auf das um, was Nutzer schreiben. Auftau-Bedingung ist deshalb nicht „nach #71", sondern: die ersten Freitextantworten aus **#72** liegen vor. Nennt sie niemand, sind sie nicht dran.
