# 18 — Operation history / time-travel undo

Status: Tier 1 (undo toast) ✅ done + user-verified 2026-06-30; Tier 2 (scrubbable
timeline) deferred — build only if the toast shows appetite for seeing further back.

## Decision (2026-06-30): test appetite with a lightweight tier first

PM challenged the feature ("is this git with extra steps, just for files? who's the
user?"). Conclusion: the **reversible spine already shipped** (multi-level ⌘Z); this
issue only adds *legibility* + *jump-to-a-point*. The job it serves is narrow but real:

> **The bulk reorganiser, in the "wait — did I just break my folder structure?" moment.**
> JTBD: when I've done a burst of file changes and doubt one, let me see what I did and
> get back to a known-good point without guessing how many times to hit ⌘Z.

That moment is occasional, so we right-sized it into tiers and shipped the cheap one:

- **Tier 1 — undo/redo toast (DONE):** a transient HUD on every ⌘Z/⇧⌘Z — "Undone —
  Moved 12 items". Closes the one real gap in blind ⌘Z (*what did I just undo?*) for
  ~15% of the build. Overwrites toast "Can't undo … — files were overwritten" (honest,
  per ADR 0004). Forward ops don't toast (the user did them on purpose).
- **Tier 2 — scrubbable timeline + "undo to here" (DEFERRED):** see below. Build only
  if users start wishing they could see further back and jump. **Not a git graph** — our
  undo is strictly linear (LIFO), so a branch/merge diagram is both heavy and wrong; the
  right shape is a flat, newest-first list.

---

## Original scope notes (Tier 2)

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Surface the reversible `Operation` spine (ADR 0004) as a **persistent, scrubbable
activity log**. Today every `Operation` records its inverse and powers ⌘Z/⇧⌘Z, but
that history is invisible and LIFO-only. This issue makes it a visible timeline:
"you moved 12 files to /Archive 8 minutes ago → Undo back to here."

The differentiation: Finder and most managers treat file ops as fire-and-forget.
We already record inverses — this makes that capability *legible*. Positioning
line: **"the file manager you can't mess up."** See
`context/competitor-benchmark.md` §3 (reversibility as a place we win).

## Notes / design

- **Source of truth:** `OperationCoordinator` already holds undo/redo stacks. This
  issue adds a UI over that history + the ability to undo *back to* a chosen point,
  not just the top.
- **Scope decision (resolve in plan):**
  - **v1 — timeline + "undo to here" (recommended):** show the undo stack as a
    list; choosing an entry undoes everything *above* it (still LIFO under the
    hood, just visible and one-click to a point). Safe, no new conflict model.
  - **Stretch — true selective undo:** undo a single non-top operation. Risky —
    a past op may conflict with later ones (e.g. undo a move whose destination was
    since renamed). Needs a conflict model; defer unless v1 proves demand.
- **Each entry shows:** timestamp (relative), operation kind, human description,
  affected count (e.g. "Moved 12 items → Archive"). Reuse the description each
  `Operation` already implies; add a `summary` if missing.
- **Surface:** a togglable popover/panel (e.g. a toolbar `clock.arrow.circlepath`
  button); not permanent chrome. Follows the progressive-disclosure principle
  (`context/dashboard-research.md`).
- **Session scope:** history is in-memory for the session (matches current undo).
  Persisting across launches is **out of scope** — reverting after relaunch is a
  much harder guarantee (files may have moved).
- **Redo:** keep ⇧⌘Z working; the timeline shows the redo branch too, or greys it.

## Acceptance criteria

**Tier 1 — undo toast (done):**
- [x] Every ⌘Z/⇧⌘Z flashes a transient toast naming what was reversed (description +
      affected count, reusing `Operation.title`), then auto-dismisses.
- [x] Forward operations do not toast.
- [x] Overwrites toast that they *can't* be undone (per ADR 0004) — never a false "Undone".

**Tier 2 — scrubbable timeline (deferred, build on demand signal):**
- [ ] A visible history lists completed operations this session (kind, time,
      description, affected count), newest first — a **flat list, not a git graph**.
- [ ] Choosing an entry undoes back to that point (everything above it; chosen entry
      stays applied), leaving state consistent; ⌘Z/⇧⌘Z still work alongside it.
- [ ] The history surface is toggleable (toolbar + optional chord), not permanent.
- [ ] Overwrites shown as non-undoable in the list, never offering a misleading undo.

## Out of scope

- Cross-launch persistence of history / undo.
- True selective (non-LIFO) undo — tracked as the stretch above.

## Blocked by

- `04-command-undo-spine-copy-to-inactive` (the Operation/undo spine) — done.

## Related

- `19-command-palette` (could expose "Undo to…" as a palette action).
- ADR 0004 (reversible Operations).
