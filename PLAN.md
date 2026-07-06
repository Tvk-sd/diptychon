# PLAN

_No active task._

Last task: **issue 44 — Customizable hotkeys** — ✅ done + user-verified, branch
`feat/44-customizable-hotkeys` (`d05727e`, not pushed/merged). Outcome folded into
`PROJECT-TRACKER.md` (row 44) and the issue file.

- `HotkeyManager` (@Observable singleton): effective map = `Keymap.default` + per-action
  overrides, persisted as one JSON blob in `UserDefaults`; steal-and-unbind on conflict;
  structural keys locked + non-stealable; unknown/corrupt store falls back to defaults.
- `AppAction` → String raw id + `CaseIterable` + `displayName`; `KeyChord`/`KeyTrigger`
  `Codable`+`Equatable`. All consumers (2 dispatch sites + palette hint) read the
  effective map; palette hint made a live closure.
- New Settings window (⌘,): Shortcuts recorder tab (a `ChordRecorder` reference type owns
  the NSEvent monitor — mutating `@State` from an AppKit closure went stale) + Full Disk
  Access tab (FDA moved off the ⌘, app-menu slot the Settings scene now owns).
- 11 `HotkeyManagerTests`; 145 total green.

Carry-over: `feat/46-sidebar-devices` still needs a rebase on `main` to inherit the
#45 quit-clobber fix (see [[swiftui-state-init-runs-twice]]).
