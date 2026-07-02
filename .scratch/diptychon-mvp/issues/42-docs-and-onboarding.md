# 42 — Text-first docs & first-run onboarding

Status: needs-triage (2026-07-02) — drafted from netnography finding N3
(`context/netnography/04-diptychon-mapping.md` §3) / theme T4
(`context/netnography/02-analyse-und-befunde.md`). Not a code feature — an
**adoption** feature. Cheapest real moat against Marta / Path Finder.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Make Diptychon **learnable in the first five minutes** via **readable, text-based**
documentation and a lightweight first-run orientation — so a power-user evaluating it
sees the payoff before they give up.

**Netnography backing** (`context/netnography/`, theme T4): two rival tools were
abandoned *specifically because of documentation*, despite genuine interest:
- Marta: *"Their documentation is severely broken … such pathetic docs binned it"* (S3/S5).
- Path Finder: *"the docs are almost entirely YouTube videos, which I despise. I read
  faster than you talk; give me text."* (S5).

This segment (Persona B/C) reads fast, distrusts video-only docs, and tolerates a
learning curve **only if the payoff is visible**. Good text docs are a low-cost,
high-leverage differentiator — code rivals under-invest here.

## Notes / design

- **Text-first, not video.** A concise, skimmable, searchable text reference (README /
  docs site / in-app help). Video optional, never the *only* source. Respect "give me
  text."
- **Keyboard cheat-sheet.** Diptychon is keyboard-first (issues 15/19/28) — a single
  discoverable list of chords/gestures is the highest-value page. Consider an in-app
  overlay (e.g. `?`), not just external docs.
- **First-run orientation (light).** A minimal, dismissible first-launch hint at the
  core model: two panes, active/inactive (Tab), copy-to-other-panel, Go to Folder,
  staging. **Not** a multi-step wizard — restraint per positioning. Must be skippable
  and never reappear (respect issue 41 persistence: "onboarding seen" is persisted).
- **Coverage priorities:** the dual-pane mental model, the Commander gestures, tags,
  staging, undo/queue. Mirror the structure of `context/competitor-benchmark.md` §5 so
  docs and positioning stay aligned.
- **Honesty in docs.** Where a limit exists (local-only, 50k not "instant" — see
  memory / issue 22), document it plainly. This audience rewards candor and punishes
  overclaiming ("proof culture", netnography §4).
- **Scope decision (plan):** how much lives *in-app* (cheat sheet, first-run) vs. on a
  docs site/README. Lean in-app for the cheat sheet, external for the reference.

## Acceptance criteria

- [ ] A text-based reference exists covering the core model + Commander gestures +
      tags + staging + undo/queue (skimmable, searchable; not video-only).
- [ ] A discoverable in-app keyboard cheat-sheet lists the current chords/gestures.
- [ ] A minimal, skippable first-run orientation introduces the dual-pane model; once
      dismissed it does not reappear (persisted).
- [ ] Docs state known limits honestly (local-only; large-folder load behavior).

## Out of scope

- A full video course / marketing site (text reference first).
- Localization of docs (English v1; revisit).
- Interactive in-app tutorial / multi-step wizard (a single light hint, not a tour).

## Related

- `context/netnography/04-diptychon-mapping.md` §3 N3, §6 step 3.
- `context/netnography/02-analyse-und-befunde.md` T4; `03` JTBD-8.
- `19-command-palette`, `28-keyboard-command-expansion`, `15-path-bar-go-to-folder`
  (the gestures to document).
- `41-state-persistence` (persist "onboarding seen").
- `context/competitor-benchmark.md` §5 (structure to mirror).
