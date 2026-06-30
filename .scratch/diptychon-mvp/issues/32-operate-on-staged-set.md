# 32 — Operate on the staged set

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/issues/20-virtual-staging-panel.md`

## What to build

Make the staged set a usable **source** for the existing file operations, with the
other (real-directory) panel as the **destination**. This is the payoff of the feature.

End-to-end behavior:

- With the Staging pane open (right auxiliary pane — see issue 20/A′), the existing
  operations — copy/move into a file panel (Commander gesture ⌥⌘→/←), ⌘C/⌘V, trash, and
  tag — act on the **Staging pane's selection as source**, writing into the active (or
  designated) file panel's directory where a destination is needed.
- Every such operation is **undoable through the existing reversible spine** (ADR 0004);
  no new operation type should be required — the operations already accept an arbitrary
  set of source URLs.
- Note: the auxiliary-pane surfacing (A′) means **both file panels are always real
  directories**, so the "exclusive single-panel staging" constraint from the original
  plan is no longer needed — there is always a directory destination. The open question
  is instead *which* file panel is the destination when operating from Staging (the
  active one is the natural default).

The reversible-spine integration means a move/copy/trash/tag from a staging set is undone
exactly like the same operation from a directory.

## Acceptance criteria

- [ ] Move/copy into a file panel, trash, and tag all work with the Staging pane's
      selection as the operation source and a file panel's directory as destination.
- [ ] Each operation is undoable/redoable via the existing spine, with no new operation
      type added.
- [ ] The destination file panel is unambiguous (active panel by default).

## Blocked by

- `30-stage-and-view-files`

## Related

- ADR 0004 (reversible Operations).
