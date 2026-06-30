# 32 — Operate on the staged set

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/issues/20-virtual-staging-panel.md`

## What to build

Make the staged set a usable **source** for the existing file operations, with the
other (real-directory) panel as the **destination**. This is the payoff of the feature.

End-to-end behavior:

- With a panel showing Staging, the existing operations — copy/move to the other panel
  (Commander gesture ⌥⌘→/←), ⌘C/⌘V, trash, and tag — act on the **staged selection as
  source**, writing into the inactive panel's directory where a destination is needed.
- Every such operation is **undoable through the existing reversible spine** (ADR 0004);
  no new operation type should be required — the operations already accept an arbitrary
  set of source URLs.
- **Exclusive single-panel staging is enforced here:** at most one panel may be in
  staging mode at a time, guaranteeing the other panel is always a real-directory
  destination. Toggling staging on for one side returns the other side to its directory.

The reversible-spine integration means a move/copy/trash/tag from a staging set is undone
exactly like the same operation from a directory.

## Acceptance criteria

- [ ] Move/copy to the other panel, trash, and tag all work with the staged set as the
      operation source and the inactive panel's directory as destination.
- [ ] Each operation is undoable/redoable via the existing spine, with no new operation
      type added.
- [ ] Only one panel can be in staging mode at a time; the other is always a real folder.

## Blocked by

- `30-stage-and-view-files`

## Related

- ADR 0004 (reversible Operations).
