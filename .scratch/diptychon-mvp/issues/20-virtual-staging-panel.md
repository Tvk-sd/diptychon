# 20 — Virtual staging panel

Status: done — merged (PR #33) — 4 slices #30–#33, user-verified; Option A→A′ auxiliary-pane pivot

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A panel whose source is **an explicit set of files the user collected across many
folders**, rather than a single directory. The user "stages" files from anywhere
into this virtual list, then operates on the whole set at once (copy/move to the
other panel, tag, trash). A power-user superpower — Total Commander's "branch
view" / feed-to-listbox, which almost nothing on macOS offers.

The differentiation: this is the payoff of the `PanelSource` abstraction (ADR
0003) we've carried since issue 01 — "what a panel lists" was never required to be
a directory. See `context/competitor-benchmark.md` §3.

## Notes / design

- **Model:** a new `PanelSource` (ADR 0003), e.g. `StagingSource`, backed by an
  ordered set of `URL`s. It is *not* a directory — no FSEvents watch on a parent;
  instead validate each URL on read (skip / grey items that moved or were deleted).
- **Adding to staging (decide in plan):** a selection action "Add to Staging"
  (context menu + a chord), and/or drag onto the staging panel. Adds the Active
  selection regardless of which folder they came from.
- **Surfacing the staging panel — RESOLVED 2026-06-30 → option A′ (auxiliary pane).**
  Built option A first (temporary source swap) and tested it live: swapping a file
  panel to Staging sacrifices a whole directory view, but the staging workflow needs
  source panel + destination panel + the set visible at once. So staging now renders in
  the **right auxiliary pane** (where the file Preview sits), mutually exclusive with
  Preview, toggled from the bottom bar. Both file panels stay directories — preserves
  the diptych (it's the aux pane, not a third *file* panel), so it does not trip the B
  concern. The "exclusive single-panel staging" constraint is no longer needed.
  Original options, for the record:
  - ~~A — temporary source swap: a panel toggles to show Staging instead of its
    directory~~ (built, then superseded — felt wrong: lost a panel).
  - ~~B — a third file pane~~ (would break the diptych; A′ avoids this by living in the
    auxiliary/preview region rather than adding a third file panel).
- **Operating on the set:** existing Operations must accept a staging selection as
  *source* into a real directory *destination* (Commander gesture ⌥⌘→/←, ⌘C/⌘V,
  drag). The reversible spine (ADR 0004) applies unchanged — moves/copies from a
  staging set are still undoable.
- **Remove / clear:** remove individual items from the set (hover/context menu) and
  a clear-all. Removing from staging never touches the file on disk.
- **Persistence:** session-only for v1; persisting the staged set across launches
  is out of scope (paths go stale).
- **Empty/edge states:** empty staging shows a clear "drag or Add to Staging"
  placeholder; a staged file that's since been deleted is greyed and excluded from
  operations.

## Acceptance criteria

- [ ] The user can add the Active selection (from any folder) to a staging set, and
      see all staged items in one panel even though they live in different folders.
- [ ] File operations (move/copy to the other panel, tag, trash) work on the staged
      set as the source and are undoable via the existing spine.
- [ ] Items can be removed from staging (and a clear-all) without touching the files
      on disk; staged items that no longer exist degrade gracefully.
- [ ] The staging view is reachable/dismissable without permanently adding a third
      pane (unless option B is explicitly chosen in plan).

## Out of scope

- Cross-launch persistence of the staged set.
- Saved/named collections (a staging set is ephemeral, not a smart folder).

## Blocked by

- `03-dual-panels-focus`
- Relies on the `PanelSource` seam from `01-panel-lists-local-folder` (ADR 0003).

## Related

- ADR 0003 (`PanelSource`), ADR 0004 (reversible Operations).
- `competitor-benchmark.md` §3 (validates the abstraction).
