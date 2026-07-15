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
- [ ] **#36 Gadgets-lite mergen?** `feat/36-gadgets-lite` (dieser Worktree) ist fertig + user-verified, aber ungemerged — main ist inzwischen auf `83e213a` weitergewandert und feat/53 läuft parallel; Merge-Zeitpunkt abstimmen
- [ ] **`.adobeTemp` löschen (4,2 GB, braucht sudo):** `sudo rm -rf /System/Volumes/Data/.adobeTemp` — root-owned, AI kommt nicht ran (Platten-Aufräumen 2026-07-15; npm-Cache bereits geleert)

## Offen — bei AI
Nächstes: **#52 batch-rename quality** (`ready-for-agent`, eigener Worktree). Neu gefiled: **#61 UI-Test `testToggleRightPanel` not hittable** (`needs-triage`, Vorbestand auf main). Volle Queue + Labels: `.scratch/diptychon-mvp/issues/`

## Aktiver Task
<!-- AI-Arbeitsstand; bei Done leeren + Issue schließen -->

*(leer — #36 Gadgets-lite abgeschlossen 2026-07-15, siehe Issue-File + `d1e0047`)*
