# 35 — Analyze Disk Usage

Status: needs-triage (2026-07-02) — drafted from Marta gap analysis
(`context/competitor-benchmark.md` §5). Self-contained, high-utility, low-weight.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

An **Analyze Disk Usage** action: recursively scan the current folder, compute the
true (recursive) size of each immediate child, and show the folder's contents sorted
**descending by size** so the user can see what's eating space.

Marta's model (our reference): the action scans the hierarchy under the current
folder, computes exact per-subfolder sizes, then opens a **new virtual view** with a
"descending by size" order. It's the fast answer to "what's filling this disk?"

## Notes / design

- **Recursive size, not shallow.** The value is that each folder row shows the sum of
  everything beneath it — that's what the plain size column can't do. Files show
  their own size.
- **Off-main, non-blocking — reuse the perf posture.** A deep tree can be large; the
  scan must run off the main thread (like `LocalDirectorySource` loads, issue 01)
  and the UI must stay responsive with a progress/loading state. Tie cancellation to
  issue 34's queue if landed, or at minimum make the scan abortable.
- **Presentation — decide in plan.** Two options:
  1. A **virtual/ephemeral view** of the *current* folder re-sorted by recursive
     size (closest to Marta; no new navigation model, reuses the panel + a sort key).
  2. A dedicated results surface. Prefer (1) unless the panel can't express a
     "recursive size" sort key cleanly.
- **Sort key:** introduce a recursive-size sort option; default this action to sort
  desc by it. Reuse the existing sort infrastructure (issue 02) rather than a bespoke
  list.
- **Entry point:** command palette (issue 19) + a menu item; optional hotkey.
- **Symlinks / hard links:** don't follow symlinks out of the tree; note the
  chosen policy in the plan (double-counting hard links is acceptable for v1 — flag
  it, don't solve it).

## Acceptance criteria

- [ ] An "Analyze Disk Usage" action exists (command palette + menu) that runs on the
      active pane's current folder.
- [ ] After scanning, the view shows each immediate child with its **recursive**
      size, sorted descending by size.
- [ ] The scan runs off-main and does not freeze the UI on a large tree; the user
      sees a loading/progress state and can leave/abort.
- [ ] Symlink-follow policy is defined and implemented (no infinite loops).
- [ ] `context/competitor-benchmark.md` §5 gap row for Analyze Disk Usage flips to ✅.

## Out of scope

- Graphical treemap / sunburst visualization (list + size is enough for v1).
- Deleting or acting on results beyond normal selection ops.
- Caching scan results across navigations (recompute on demand for v1).
- Running inside archives (no archive source in MVP — see §3).

## Blocked by

- `01-panel-lists-local-folder` (off-main load infrastructure) — done.
- `02-panel-navigation-sort-filter` (sort infrastructure to hang the size sort on) — done.

## Related

- `context/competitor-benchmark.md` §5 (Marta deep-dive).
- `context/performance.md` (off-main scan posture; note the per-file cost caveat).
