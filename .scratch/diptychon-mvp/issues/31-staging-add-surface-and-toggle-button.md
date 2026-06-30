# 31 — Staging: full add surface + header toggle button

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/issues/20-virtual-staging-panel.md`

## What to build

Complete the ways a user puts files into staging and surfaces the staging view, beyond
the keyboard chords delivered in issue 30.

End-to-end behavior:

- A **panel-header toggle** (button/affordance) switches that panel into/out of the
  staging view, so the feature is discoverable without knowing the chord, and it is
  visually obvious which panel is currently showing Staging.
- A **context-menu item "Add to Staging"** on a file row adds the row (or the whole
  selection if the clicked row is part of it) to the staging set.
- **Dragging files onto the staging panel** adds them to the set.

All three paths add to the same staging collection introduced in issue 30, regardless
of which folder the files came from. The staging panel reflects additions live.

## Acceptance criteria

- [ ] A header toggle switches a panel into/out of the staging view and indicates which
      panel is staging.
- [ ] A context-menu "Add to Staging" action adds the clicked row or current selection.
- [ ] Dropping files onto the staging panel adds them to the set.
- [ ] All add paths target the one shared staging collection and update the view live.

## Blocked by

- `30-stage-and-view-files`

## Related

- ADR 0003 (`PanelSource`).
