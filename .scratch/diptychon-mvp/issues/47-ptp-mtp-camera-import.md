# 47 — Import from PTP/MTP cameras (no volume mount)

Status: needs-triage
Category: enhancement

## Parent

`.scratch/diptychon-mvp/PRD.md`

## Summary

Many cameras connect over PTP/MTP and never mount as a `/Volumes` disk — macOS
exposes them only through ImageCapture, not the filesystem. Diptychon's sidebar
Devices section (issue 46) surfaces mounted volumes only, so these cameras stay
invisible. This issue covers browsing/importing photos from a camera that offers
no filesystem mount.

## Background

Split out of issue 46. During triage of 46 we scoped the Devices section to
**mounted volumes only** (SD cards, card readers, USB drives, cameras in
mass-storage mode) because those are cheap: `FileManager.mountedVolumeURLs` +
`NSWorkspace` mount notifications. PTP/MTP cameras are a categorically different
lift — a separate framework (`ImageCaptureCore` / `ICDeviceBrowser`), a
non-filesystem navigation model, and no `URL`-based panel source — so it was
deferred rather than bundled.

## Why this is bigger than #46

- Device discovery is via `ICDeviceBrowser`, not volume enumeration.
- Photos are enumerated as `ICCameraItem`s and must be downloaded, not opened
  in place — there's no path to hand a panel.
- It likely needs a new `PanelSource` variant (ADR 0003) or a dedicated import
  flow rather than reusing `navigateActive(to:)`.
- Entitlements/permissions differ (camera/ImageCapture access prompts).

## Open questions for triage

- **Is there real demand?** Most modern workflows pull cards via a reader (covered
  by #46). Confirm the JTBD before building — this may be YAGNI.
- Browse-in-panel vs. a dedicated "Import from camera" flow?
- Where do downloaded files land, and how does that interact with staging
  (issues 30–33)?

## Acceptance criteria

_To be defined during triage/grilling if this is picked up. Placeholder:_

- [ ] A PTP/MTP camera with no volume mount is discoverable in the app.
- [ ] Its photos can be browsed and copied to a chosen folder.

## Out of scope

- Mounted-volume cameras / SD cards / USB — issue 46.
- Tethered capture / remote shooting.
