# 34 — Operation Queue UI (progress · pause · cancel)

Status: needs-triage (2026-07-02) — drafted from Marta gap analysis
(`context/competitor-benchmark.md` §5). Highest-ROI competitive gap: it extends
our existing reversible-Operation lead rather than bolting on a new domain.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A **visible queue for in-flight file operations** — the copy/move/trash/delete work
that today runs off-main but has no surface. Give the user a progress indicator, the
ability to **pause and cancel** a running or queued operation, and a **merge / smart
conflict resolution** choice when a copy/move hits an existing folder or file.

**Netnography backing** (`context/netnography/`): confirms both halves. Users criticise
Nimble Commander for having *"no file transfer pane showing number of files or time
remaining"* and for offering *"no merge"* (S3); ForkLift is praised precisely for the
opposite — it *"organizes [transfers] in the sidebar and keeps a log"*. Merge is
wish **W9** (*"smart conflict resolution"*, S7). See `04-diptychon-mapping.md` §2–3.

Marta's model (our reference): all continuous ops are queued and run one after
another; a progress bar sits in a window corner; clicking it opens a popup listing
each op with per-op progress, pause, and cancel; the popup is fully keyboard-driven
(`=` opens it, arrows navigate, `Space`/`P` pause, `A`/`D` abort).

This is the one Marta feature that directly builds on a Diptychon strength: we
already model file work as reversible `Operation`s (issues 04/18). Surfacing them
as a live queue is the natural extension.

## Notes / design

- **Reuse the Operation spine.** Don't invent a parallel job type — the queue should
  visualize the same `Operation` objects that feed undo/redo. An op is created →
  enqueued → runs → completes (and remains undoable). Confirm the current spine can
  report progress incrementally (bytes or item count); if it's currently
  fire-and-run-to-completion, exposing a progress callback is part of this issue.
- **Scope of "op" for v1:** copy and move are the ones with meaningful duration —
  prioritize those. Trash/delete/rename are near-instant; they can flash through the
  queue without a progress bar but should still be cancellable if queued behind a
  slow copy.
- **Serialized vs concurrent:** match Marta — **one at a time**, queued. Simpler,
  avoids disk contention, and makes cancel semantics obvious. (Revisit concurrency
  later if measured as a bottleneck.)
- **Cancel semantics:** cancelling a *queued* op just removes it; cancelling a
  *running* op stops after the current file and must leave a **consistent,
  undoable** state (no half-copied file left behind — clean up the partial). This is
  the subtle part; define the guarantee explicitly in the plan.
- **Merge / conflict resolution (W9):** when a copy/move lands on an existing
  folder, offer **Merge** (recurse and only resolve per-file conflicts) alongside the
  existing pre-write collision choices (overwrite / keep-both / skip — issues 04/05).
  Per-file, a merge should still let the user resolve collisions (overwrite/keep-both/
  skip, ideally "apply to all"). This extends the existing collision dialog rather
  than replacing it; the queue is where a long merge's progress is shown.
- **Surface — a toggleable bottom-left panel, like Staging.** Per the product idea:
  the queue lives as a **dockable panel toggled from the bottom-left**, mirroring the
  Staging panel's toggle affordance (issue 31), so "operations" and "staging" feel
  like sibling drawers rather than two unrelated UIs. Proposed toggle **icon: a
  list/stack glyph** (the attached SF-Symbol-style list icon, e.g. `list.bullet` /
  `list.triangle`) — deliberately distinct from issue 18's clock/history glyph so the
  two are not confused (see boundary below). A compact progress indicator can also sit
  in the top bar (issue 21) as a secondary entry point. Keyboard entry + in-panel
  pause/cancel keys, per Marta.
- **Boundary vs issue 18 (operation *history*).** These are siblings, not the same
  panel: **34 = present/in-flight** (what's copying *now* — progress, pause, cancel,
  merge), **18 = past/completed** (the undo timeline — "jump back to a known-good
  point"). Different data (a pending/running queue vs a completed-undo stack),
  different verbs (cancel vs undo), different icons (list vs clock). They may *visually*
  cohabit the bottom drawer area later, but keep them as **separate surfaces/toggles**;
  do not merge the queue into the undo history. If both dock bottom-left, they are two
  tabs/toggles, not one list.
- **Interaction with undo:** a completed op stays in the undo stack as today (that's
  issue 18's domain). An in-flight op is not yet undoable; a cancelled op should behave
  as if it never committed (nothing to undo). State this so the two systems don't fight.

## Acceptance criteria

- [ ] A running copy/move shows live progress (per-op) somewhere always-visible.
- [ ] The user can open a queue view listing pending + running ops.
- [ ] A queued op can be cancelled (removed before it starts).
- [ ] A running op can be cancelled and leaves a consistent filesystem state (no
      orphaned partial file); the result is not left in a broken half-state.
- [ ] Ops run serialized (one at a time); a second op queued behind a slow one waits.
- [ ] Queue view is operable by keyboard (open + pause/cancel), matching the app's
      keyboard-first posture.
- [ ] The queue is a **toggleable bottom-left panel** (sibling to Staging, issue 31),
      with a list-glyph toggle icon distinct from issue 18's history glyph.
- [ ] Copying/moving onto an existing folder offers a **Merge** option alongside
      overwrite/keep-both/skip; a merge resolves per-file conflicts (with apply-to-all)
      and its progress is shown in the queue.
- [ ] `context/competitor-benchmark.md` §5 gap row for Operation Queue flips to ✅.

## Out of scope

- Concurrent/parallel op execution (serialize for v1).
- Pause/resume of an op *mid-file* (pause = "don't start the next unit"; a single
  large file copy either completes its current unit or is cancelled).
- Bandwidth/throttling controls, per-op priority reordering.
- Remote-source transfers (no remote sources in MVP — see §3).
- The operation **history/undo timeline** — that's issue 18 (past ops), a separate
  surface (see boundary note above).
- Three-way / content-level merge of *file contents* (this is folder-level merge with
  per-file conflict resolution, not a diff/merge tool).

## Blocked by

- `04-command-undo-spine-copy-to-inactive` (the Operation spine) — done.
- Coordinates with `31-staging-add-surface-and-toggle-button` (the bottom-left panel
  toggle pattern to mirror) and `21-unified-top-bar` (secondary progress affordance).
- Builds on the collision dialog in `05-remaining-file-operations` (merge extends it).

## Related

- `context/competitor-benchmark.md` §5 (Marta deep-dive — top gap).
- `context/netnography/04-diptychon-mapping.md` §2–3 (queue + merge/W9 evidence).
- `18-operation-history-time-travel-undo` (sibling surface — *past* ops; keep separate).
- ADR 0004 (reversible operation model).
