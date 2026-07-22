# PLAN

## Roadmap-lite
Reach-Test (Ads/Outreach → signups) → Demand-Test (5 Sessions → Day-10-Retention) → GO? → Notarisierung ($99) → Launch (Access-Wall weg)

## Offen — bei Till
- [ ] **#62 Embed beauftragen:** Hero-Cut abgenommen — GO für Einbindung auf diptychon.com geben (+ optional: 38s-Sidebar-Cut als Zweitvideo?); Assets liegen in `.scratch/demo-video/`
<!-- persistent; Zeile löschen, sobald entschieden/erledigt -->
- [ ] **Reach-Test starten:** Google Ads + Roundup-Outreach live → `signups:src:*` lesen → GO/ITERATE/STOP (`context/reach-test.md`, `google-ads-setup.md`, `roundup-outreach.md`)
- [ ] **Demand-Test starten:** Screener finalisieren, 5 rekrutieren (2 Netzwerk + 3 cold) → Sessions Woche 1, Retention-Check ~Tag 10 (`context/demand-test.md`; Preis-Frage: €9.99 one-time)
- [ ] **#58 triagieren:** Rename des aktuellen Ordners/Devices via Breadcrumb — 4 offene Fragen im Issue beantworten (Interaktion, Scope, Devices, Watcher-Folgen) oder Grill-Session starten (`.scratch/diptychon-mvp/issues/58-rename-in-place-via-breadcrumb.md`)
- [ ] **pm-skills-Repo committen:** Deprecation (conductor + project-handoff → `_deprecated/`, entschieden statt Migration 2026-07-12) + project-setup v3.0.0 / project-resume v2.0.0 liegen uncommitted in `~/.claude/skills/user/` — dort warten auch ältere Änderungen (README, brainstorming-ideation, design-analysis); reviewen + committen
- [ ] **Setup-Skills nachziehen** (Backlog, nicht dringend): `~/.claude/skills/user/project-setup` auf das neue Ruleset umstellen — PLAN-Struktur (Roadmap-lite / Offen-Till / Offen-AI / Aktiver Task), End-of-task-Issue-Close statt PROJECT-TRACKER-Scaffold; dabei alle Skills nach `PROJECT-TRACKER` greppen (auch `conductor`, `project-handoff`) — sonst regeneriert das nächste Projekt die alte Konvention (transferable-learnings §26)
- [ ] **macOS-Update abschließen** (Softwareupdate → Neustart): gestagte Update-Snapshots (`MSUPrepareUpdate` + 2) pinnen weiter Plattenplatz — letzter offener Punkt vom Platten-Aufräumen (adobeTemp + npm-Cache erledigt, 26 GB frei Stand 2026-07-16)

## Offen — bei AI
Nächstes: Queue in `.scratch/diptychon-mvp/issues/` (ready-for-agent: #39, #40, #52 batch-rename [eigener Worktree], #57). #36 Gadgets-lite + #53 abgeschlossen + gemerged 2026-07-15; volle Suite grün auf main `2b8bf08` (210 Unit + 13 UI); #61 als Wedge-Artefakt geschlossen (`pkill testmanagerd` = Recovery).

## Aktiver Task
<!-- AI-Arbeitsstand; bei Done leeren + Issue schließen -->
**#62 Usage-Video für Landing Page** (2026-07-21) — Video FERTIG (Take 6, 40s mp4), wartet auf Abnahme; Details im Issue.

**Reach-Test starten** (2026-07-12, Woche-1-Schritte aus `context/channel-plan.md`)

Infrastruktur end-to-end verifiziert (2026-07-12): Seite öffentlich, Capture-Form
+ `?src`-Attribution + `/vs` live, Signup→KV smoke-getestet und wieder auf
**null** zurückgesetzt. Zählerstand = sauber.

- [x] Cloudflare-Web-Analytics-Beacon entdeckt (lief seit ~07.07., injiziert
      nur bei Browser-UA — deshalb zuerst übersehen) → Till hat RUM
      deaktiviert (2026-07-13), Beacon-Entfernung auf /, /vs, /impressum
      live verifiziert. NIE reaktivieren (Datenschutz § 4).
      Mess-Runbook: `context/reach-test-messung.md`.

- [x] Impressum + Datenschutz LIVE (2026-07-12): Till entschied nach
      Abwägung doch eigene Wohnadresse (Service-Adresse verworfen);
      Seiten gefüllt, Footer auf / und /vs verlinkt, deployed + live
      verifiziert (beide 200, Adresse drin, keine Platzhalter).
      Cloudflare „Web Analytics" NIE aktivieren — sonst wird
      Datenschutz §4 falsch. Dateien uncommitted in `.scratch/landing-page/`.
- [ ] **Till (JETZT entblockt):** Google-Ads-Kampagne durchklicken
      (`context/google-ads-setup.md` ist paste-ready, €10/Tag)
- [x] AI: Roundup-Outreach-Pitches personalisiert (2026-07-12) → 6 Drafts +
      Re-Priorisierung in `context/outreach-drafts-2026-07-12.md` (Recherche:
      nur XDA + TheSweetBits sind echte Redaktionen; 3 Ziele sind Vendor-/
      Konkurrenz-Blogs, SimplyMac gestrichen — kein Kontaktweg)
- [ ] Till: Welle-1-Drafts reviewen (XDA, TheSweetBits, FileMinutes) +
      entscheiden ob Welle 2 (Konkurrenten) mitgeht → versenden
- [x] GO-Bar entschieden (Till, 2026-07-12): Competitor-Intent Capture-Rate
      ≥8 %, Cost-per-Signup ≤ €5, Lesefenster 2 Wochen → festgehalten in
      Issue #55 (`.scratch/diptychon-mvp/issues/55-reach-test-execution.md`)
- [ ] Wöchentlich: `signups:src:*` ÷ Klicks pro Kanal → GO/ITERATE/STOP
      (Outcome landet in #55)
