# 42 — Docs & onboarding (tiered)

Status: **Tier 2 draft delivered 2026-07-03 — awaiting human review.** Files:
`README.md`, `docs/user-guide.md`, `docs/keyboard-reference.md` (keyboard table
generated from `Keymap.default`; deliberately documents shipped behavior only — e.g.
undo/redo, **not** the not-yet-shipped operation queue #34). Tier 1 blocked-by #41;
Tier 3 needs an infra decision. From netnography finding N3
(`context/netnography/04-diptychon-mapping.md` §3) / theme T4 (`02-analyse-und-befunde.md`).
Tier-split precedent: #18.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Make Diptychon **learnable fast** via **readable, text-based** docs — so a power-user
evaluating it sees the payoff before giving up.

**Netnography backing** (theme T4): two rivals were abandoned *specifically because of
docs*, despite genuine interest:
- Marta: *"Their documentation is severely broken … such pathetic docs binned it"* (S3/S5).
- Path Finder: *"the docs are almost entirely YouTube videos, which I despise. I read
  faster than you talk; give me text."* (S5).

This segment reads fast, distrusts video-only docs, tolerates a learning curve *only if
the payoff is visible*. Good text docs are a low-cost, high-leverage moat — rivals
under-invest here. Sliced into three tiers below; **build order = T2 → T1 → T3.**

---

### Tier 2 — README + GitHub docs · `ready-for-agent` (AFK) ✅ · **DO FIRST**

The cleanest AFK slice: **pure text, no code, no dependencies**, derivable from the
existing corpus (`context/competitor-benchmark.md`, `CONTEXT.md`, the issue files,
`context/netnography/`).

- A **dedicated README** + a text reference covering: the **dual-pane mental model**,
  the **Commander gestures** (Tab, copy-to-other, Go to Folder), **tags**, **staging**,
  **undo/queue**.
- **Text-first, searchable, skimmable** — never video-only ("give me text", S5).
- **Honest about limits:** document local-only scope and large-folder behavior (50k is
  not "instant" — issue 22). This audience rewards candor, punishes overclaiming
  (netnography §4 "proof culture").
- **Definition of done = a complete draft for human review.** Docs quality is
  subjective, so the agent produces the full draft; a human approves/polishes. That's
  what makes it safely AFK.

**Tier 2 acceptance criteria:** *(draft complete — verify in review)*
- [x] A dedicated README exists (what Diptychon is, install/run, the core model). → `README.md`
- [x] A text reference covers core model + Commander gestures + tags + staging + undo;
      skimmable + searchable; **no content is video-only**. → `docs/user-guide.md` +
      `docs/keyboard-reference.md`. *(Note: documents shipped **undo**, not the
      unshipped operation **queue** #34 — honest-scope over the original "undo/queue" AC.)*
- [x] Known limits are stated honestly (local-only; large-folder load behavior). → README
      "Honest performance notes" + "What it deliberately does not do".
- [x] Structure/terminology aligns with `CONTEXT.md` + positioning
      (`context/competitor-benchmark.md` §3–5).

---

### Tier 1 — In-app first-run orientation + keyboard cheat-sheet · after #41 🟡

Higher adoption value, but **not AFK** — it touches UI surface, needs copy decisions,
and depends on persistence.

- A minimal, **skippable** first-launch hint at the core model (two panes, active/
  inactive via Tab, copy-to-other-panel, Go to Folder, staging). **Not** a multi-step
  wizard — restraint per positioning.
- A discoverable **in-app keyboard cheat-sheet** (e.g. a `?` overlay) — highest-value
  page for a keyboard-first app (issues 15/19/28).
- **Blocked by #41:** "onboarding seen" must persist so it never re-shows.

**Tier 1 acceptance criteria:**
- [ ] Skippable first-run orientation introduces the dual-pane model; once dismissed it
      never reappears (persisted via #41).
- [ ] A discoverable in-app cheat-sheet lists the current chords/gestures.

---

### Tier 3 — Web documentation · later, needs decision ❌

A hosted docs site. **Not AFK** — an infra/maintenance decision, largest scope.
- Deferred. Decide first: static-site generator? where hosted? kept in-repo vs separate?
- Only scope this once T1/T2 content exists to publish.

---

## Out of scope (all tiers)

- Full video course / marketing site (text reference first).
- Localization of docs (English v1; revisit).
- Interactive multi-step in-app tutorial / tour (Tier 1 is a single light hint).

## Related

- `context/netnography/04-diptychon-mapping.md` §3 N3, §6 step 3; `02` T4; `03` JTBD-8.
- `19-command-palette`, `28-keyboard-command-expansion`, `15-path-bar-go-to-folder`
  (the gestures Tier 1/2 document).
- `41-state-persistence` (Tier 1 depends on it — persist "onboarding seen").
- `18-operation-history-time-travel-undo` (tier-split precedent).
- `context/competitor-benchmark.md` §5 (structure to mirror).
