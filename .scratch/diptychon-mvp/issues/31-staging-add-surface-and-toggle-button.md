# 31 — Staging: full add surface + header toggle button

Status: done — merged (staging stack, PR #33; commit `857f70e`, supersedes Option A), user-verified

## Parent

`.scratch/diptychon-mvp/issues/20-virtual-staging-panel.md`

## What to build

Complete the ways a user puts files into staging and surfaces the staging view, beyond
the keyboard chords delivered in issue 30.

End-to-end behavior (revised 2026-06-30 for the auxiliary-pane surfacing — see issue 20):

- A **bottom-bar toggle** (tray icon, beside the Preview toggle, set apart by a
  full-height divider) reveals/hides the Staging pane in the right auxiliary region,
  mutually exclusive with the file Preview. Discoverable without the chord.
- A **context-menu item "Add to Staging"** on a file row adds the row (or the whole
  selection if the clicked row is part of it) to the staging set.
- **Dragging files onto the Staging pane** (including its empty placeholder) adds them.

All three paths add to the same staging collection (issue 30), regardless of which
folder the files came from; the Staging pane reflects additions live and auto-reveals
when the user stages from a panel.

## Acceptance criteria

- [x] A bottom-bar toggle reveals/hides the Staging pane (mutually exclusive with
      Preview); a highlighted icon shows when it's active.
- [x] A context-menu "Add to Staging" action adds the clicked row or current selection.
- [x] Dropping files onto the Staging pane (incl. its empty placeholder) adds them.
- [x] All add paths target the one shared staging collection and update the view live.

## Blocked by

- `30-stage-and-view-files`

## Related

- ADR 0003 (`PanelSource`).
