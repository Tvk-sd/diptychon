# 03 — Dual panels with focus switching

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Add the second Panel and the Active/Inactive concept (see `/CONTEXT.md`). Two
Panels side by side, each navigating independently. Exactly one is the Active
Panel; Tab switches focus. Selection state lives per Panel.

## Acceptance criteria

- [ ] Two Panels render side by side, each with its own directory and navigation.
- [ ] Exactly one Panel is Active at any time; the Active Panel is visually
      distinct.
- [ ] Tab moves focus between Panels.
- [ ] Each Panel maintains its own selection.

## Blocked by

- `02-panel-navigation-sort-filter`
