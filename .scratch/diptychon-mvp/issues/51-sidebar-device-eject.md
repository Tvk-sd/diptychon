# 51 — Eject a device from the sidebar

Status: **done — user-verified 2026-07-12** (uncommitted). Hover ⏏ button +
right-click "Eject" on Devices rows; success prunes the row via the #46 unmount
observer, failure surfaces a toast. Verified live against a mounted DMG for all
three paths: hover-eject, context-menu-eject, and busy-volume failure. Bonus:
the busy case yields macOS's own native Force-Eject dialog on top of our toast —
no extra code. Filed from Till's #46 review ("es gibt kein eject button / oder
rechts klick für it"); the affordance was deferred out of #46 (triage
2026-07-05) and the first real review hit the gap immediately.
Category: enhancement

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A per-volume **eject affordance** on rows in the sidebar's Devices section
(issue 46). A device you can see but not eject is only half-managed — today the
user must round-trip through Finder to unmount, which undercuts the "Finder
replacement" positioning (see `context/finder-replacement-runbook.md`).

Two entry points, matching Finder's conventions:

1. **Hover eject button** on the row (⏏ glyph, trailing edge) — the primary,
   discoverable affordance.
2. **Context menu** on the row with an "Eject" item — the right-click path Till
   reached for first.

## Notes / design

- Unmount via `NSWorkspace.shared.unmountAndEjectDevice(at:)` (or
  `FileManager.unmountVolume(at:options:completionHandler:)` for async +
  error reporting — prefer this; it distinguishes "busy volume" errors).
- **Failure case is the real work:** volume busy (open file, Terminal cd'd into
  it) → show a clear, non-blocking error (the operation-toast pattern from #18
  fits) — not a silent no-op.
- The disappear-on-eject path already works and is covered by #46's ACs (the
  issue-41 unmount observer prunes the row and relocates panels showing the
  volume). This issue is only about *triggering* the eject from inside the app.
- Keep scope tight: no "eject all", no force-eject. Follow-ups if demanded.

## Acceptance criteria

- [x] Hovering a Devices row shows an eject button; clicking it unmounts the
      volume and the row disappears (existing #46 live-update path).
- [x] Right-clicking a Devices row offers "Eject"; same behavior.
- [x] Ejecting a volume a panel is currently showing relocates that panel
      (already #46 behavior — must still hold when triggered from inside).
- [x] A busy/failed eject surfaces a visible error message and the row stays.
      (Also gets macOS's native Force-Eject prompt for free.)
- [x] Places/Pinned rows show no eject affordance (eject UI is on `deviceRow` only).

## References

- `46-sidebar-devices-cameras-sd-cards.md` (parent feature; deferral note under
  "Notes / design")
- Issue 41 mount/unmount observer (`WorkspaceModel` volume notifications)

## Comments

**2026-07-11 (Till, via session):** Found during #46 review — expected an eject
button or right-click on the device row; neither exists.
