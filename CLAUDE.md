# CLAUDE.md

## Agent skills

### Issue tracker

Issues and PRDs live as local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

**End of task (mandatory):** before ending any task, close the loop in the originating issue file — set the triage label and append a short outcome note (what shipped, commit hash). Decisions without an issue → `docs/adr/`. Anything now waiting on Till → add a line to `PLAN.md` › "Offen — bei Till". Git history is the changelog; there is no PROJECT-TRACKER to update (archived).

### Triage labels

Five canonical triage roles using default label strings (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
