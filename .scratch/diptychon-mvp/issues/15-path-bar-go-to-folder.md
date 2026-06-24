# 15 — Path bar / Go to Folder

Status: in-review (feat/15-path-bar)

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A way to **navigate the Active Panel to an arbitrary path** directly, instead of
only double-click-into-folder + go-up. Two complementary pieces (either or both):

1. **Editable path bar / breadcrumb** in the panel header showing the current
   directory, where the user can click a segment to jump, or edit the path text
   and press Return to go there.
2. **"Go to Folder…"** command (Finder's ⇧⌘G) — a small sheet/field to type or
   paste an absolute path (with `~` expansion) and jump the Active Panel to it.

Surfaced during issue 10: there was no way to reach folders like `~/Library`
(hidden) to test the Full Disk Access flow — you can only walk the visible tree.

## Notes / hints

- The panel header already shows `model.title` (the path) as static text
  (`PanelView`); this is the natural home for an editable path / breadcrumb.
- Add an `AppAction` + `Keymap` entry for Go to Folder (⇧⌘G), routed through
  `WorkspaceModel` to set the Active Panel's `directory` and reload.
- Validate the entered path (exists + is a directory) before navigating; show a
  gentle error otherwise. Expand `~` and resolve symlinks.
- Pairs well with revealing hidden system folders (the `Hidden` toggle already
  exists) and with issue 10 (reaching protected folders).

## Acceptance criteria

- [x] The user can jump the Active Panel to an arbitrary directory by typing /
      pasting a path (with `~` expansion). _(Go to Folder sheet → `PathInput.resolve`.)_
- [x] Invalid or non-directory paths are rejected with clear feedback (no crash,
      no broken state). _(Inline "No folder at that path."; panel unchanged.)_
- [x] A breadcrumb or editable path control reflects the current directory and
      supports clicking/editing to navigate. _(Header path = a menu of ancestor
      folders + "Go to Folder…".)_
- [x] A keyboard shortcut (⇧⌘G) opens the Go to Folder entry. _(Via Keymap; note:
      like other ⌘-shortcuts it's inactive while the Filter field is focused.)_

## Blocked by

- `02-panel-navigation-sort-filter`
