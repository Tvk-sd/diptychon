# 03 — Dual panels with focus switching

Status: done — merged (PR #3)

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Add the second Panel and the Active/Inactive concept (see `/CONTEXT.md`). Two
Panels side by side, each navigating independently. Exactly one is the Active
Panel; Tab switches focus. Selection state lives per Panel.

## Acceptance criteria

- [x] Two Panels render side by side, each with its own directory and navigation.
      (`WorkspaceView` HStack of two `PanelView`s, each its own `PanelModel`.)
- [x] Exactly one Panel is Active at any time; the Active Panel is visually
      distinct. (Accent border via `@FocusState`; click or Tab to activate.)
- [x] Tab moves focus between Panels.
- [x] Each Panel maintains its own selection. (Selection lives per `PanelModel`.)

## Blocked by

- `02-panel-navigation-sort-filter`
