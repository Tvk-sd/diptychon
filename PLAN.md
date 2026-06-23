# PLAN — Issue 10: Full Disk Access onboarding

Spec: `.scratch/diptychon-mvp/issues/10-full-disk-access-onboarding.md`.
Branch: `feat/10-full-disk-access`. **HITL** — the real grant + UX sign-off happen
on-device (can't be tested headless).

## What I understood
FDA can't be requested programmatically (ADR 0001). The app must **detect** when
it's missing, **guide** the user to System Settings → Privacy & Security → Full
Disk Access, and **recover** (re-list directories) once granted — no forced restart.
Since the app is non-sandboxed, it already reads home + most folders without FDA;
FDA only unlocks protected areas (Mail, Safari, other apps' data, some system dirs).

## Decision (confirmed with user)
**Non-blocking banner + inline.** A dismissible top-of-window banner when access is
missing ("Some folders need Full Disk Access — Open Settings / Dismiss"); the app
stays fully usable. PLUS inline "Open Settings" guidance when a *specific*
protected folder fails to load on a permission error. Auto-recover on return from
Settings.

## Approach — slices
1. **Detection + Settings deep-link.** `FullDiskAccess` helper:
   `static var isGranted: Bool` (probe an FDA-gated path — list `~/Library/Safari`,
   fall back to the user `com.apple.TCC/TCC.db` readability) and
   `static func openSettings()` → `x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles`.
2. **Global banner (non-blocking).** `WorkspaceModel`: `fdaMissing` +
   `fdaBannerDismissed` → `showFDABanner`. `WorkspaceView` renders the banner above
   the panels with Open Settings / Dismiss.
3. **Recovery.** Observe `NSApplication.didBecomeActiveNotification` (user returns
   from Settings) → re-probe; if now granted, hide the banner and `refreshBoth()`.
   No restart.
4. **Inline per-folder guidance.** Map a permission failure in `PanelModel.reload`
   (NSFileReadNoPermissionError) to `accessDenied`; `PanelView`'s `.failed` view
   shows an "Open Full Disk Access Settings" button in that case.

## "Done" = checkable (HITL)
- With FDA off, launch shows the banner; the app still lists accessible folders.
- Navigating into a protected folder shows inline "Open Settings" rather than a
  bare error.
- "Open Settings" lands on the correct Privacy → Full Disk Access pane.
- After granting + returning to the app, the banner disappears and panels list
  normally with no restart.
- **Human UX review + on-device grant test** (the HITL bar) — handed to user.

## Risks / notes
- The FDA probe is heuristic (no public "amIGrantedFDA" API). `~/Library/Safari`
  is the conventional gate; verify on-device it flips correctly before/after grant.
- Build-verifiable only up to the UI; the grant flow itself needs the user.

## Progress
- [ ] Slice 1 — detection + openSettings
- [ ] Slice 2 — non-blocking banner
- [ ] Slice 3 — recovery on app-active
- [ ] Slice 4 — inline per-folder permission guidance
