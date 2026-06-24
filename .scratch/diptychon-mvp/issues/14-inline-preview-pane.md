# 14 — Inline preview / inspector pane

Status: done — merged (PR #15)

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A collapsible **preview / inspector pane** that shows a live preview of the Active
Panel's current selection *inline* in the window — distinct from the spacebar
QuickLook **floating** panel (issue 09). As the selection changes, the pane
updates to show the file's preview plus basic metadata (name, kind, size, dates).

This is **not** in the MVP PRD (which only specifies spacebar QuickLook); it's an
enhancement requested after issue 09. Captured here so it isn't lost.

## Notes / design

- Render with AppKit's `QLPreviewView` (live, embeddable) bound to the Active
  Panel's selection; fall back to an icon + metadata when no preview is available
  or nothing is selected.
- **Layout interplay with issue 13** (panel resize + collapse the right panel):
  the two panels already use the window's width. The cleanest home for a preview
  pane is the space freed when the right *file* panel is collapsed — so build this
  on top of, or alongside, issue 13 rather than cramming a third pane in at full
  dual-panel width. Decide: dedicated third pane vs. "right slot shows preview when
  the right panel is collapsed."
- Toggle via a toolbar button + keyboard shortcut (extend `Keymap`/`AppAction`);
  persist visibility at least per session (ideally across launches).
- Reuse the Active-Panel selection plumbing; preview follows `model.active`.

## Acceptance criteria

- [ ] A toggleable inline pane previews the Active Panel's current selection.
- [ ] The preview updates live as the selection changes.
- [ ] Basic metadata (name, kind, size, created/modified) shows with the preview.
- [ ] The pane can be shown/hidden (button + shortcut); state persists per session.
- [ ] Layout stays coherent with the dual panels (and issue 13's collapse).

## Blocked by

- `03-dual-panels-focus`

## Related

- `09-quicklook-openwith-fsevents` (the floating QuickLook this complements)
- `13-panel-resize-and-toggle` (frees the space this pane can use)
