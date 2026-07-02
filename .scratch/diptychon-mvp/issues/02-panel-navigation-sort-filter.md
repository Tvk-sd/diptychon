# 02 — Panel navigation, sorting, hidden files, type-ahead filter

Status: done — merged (PR #2)

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Make a single Panel navigable and usable. Enter and leave directories from the
keyboard, show the current path, sort by column, toggle hidden files, and filter
the listing as the user types (type-ahead). Still one Panel.

## Acceptance criteria

- [x] Keyboard: enter a directory and go back up; current path is visible.
      (Return / double-click to enter; ⌘↑ or Up button to leave; path in header.)
- [x] Clicking a column header sorts by it; toggling reverses order.
- [x] A toggle shows/hides hidden (dot) files. ("Hidden" checkbox.)
- [x] Type-ahead narrows the visible entries to those matching what the user
      types, within the current Panel. (Filter field, case-insensitive contains.)
- [x] Navigation re-lists asynchronously without blocking the UI.
      (`PanelModel.reload()` cancels in-flight + reloads via `Task.detached`.)

## Blocked by

- `01-panel-lists-local-folder`
