# 09 — QuickLook, Open with, FSEvents live update

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Core macOS integration: spacebar QuickLook preview of the selected file,
"Open with" / default-app launching, and live Panel updates via FSEvents so a
Panel reflects external changes to its directory without a manual refresh.

## Acceptance criteria

- [ ] Spacebar previews the selected file via QuickLook.
- [ ] A file can be opened with its default app, and an explicit "Open with"
      choice works.
- [ ] When a Panel's directory changes on disk (created/deleted/renamed by
      another app), the Panel updates automatically via FSEvents.

## Blocked by

- `03-dual-panels-focus`
