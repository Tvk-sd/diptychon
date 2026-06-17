# 10 — First-run Full Disk Access onboarding

Status: ready-for-human

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A first-run flow that detects missing Full Disk Access and guides the user to
grant it (System Settings → Privacy & Security → Full Disk Access). Full Disk
Access cannot be requested programmatically (ADR 0001), so the app must detect
the lack of access and walk the user through enabling it, then recover gracefully
once granted.

HITL: the macOS permission grant cannot be tested headless, and the onboarding
UX needs human design review and on-device verification.

## Acceptance criteria

- [ ] On launch without Full Disk Access, the app detects it and shows clear
      guidance instead of silently failing to read directories.
- [ ] The flow links/points the user to the correct System Settings pane.
- [ ] After the user grants access, the app recovers and lists directories
      normally (no forced restart, or a clearly communicated one).
- [ ] UX reviewed by a human and verified on a real device.

## Blocked by

- `01-panel-lists-local-folder`
