# PLAN

_No active task._

Last task: **issue 45 — Persist the pane split ratio** — ✅ done + real-app verified,
branch `feat/45-persist-split-ratio` (`3629835`, not pushed/merged). Outcome folded into
`PROJECT-TRACKER.md` (rows 41/45) and the issue file.

- `SplitPane` (bindable divider fraction, absolute-pointer drag, min-width clamp) replaces
  `HSplitView`; split ratio round-trips via `WorkspaceState.splitRatio`. Completes #41's
  last deferred AC.
- **Also fixed a latent #41 quit-clobber**: SwiftUI evaluates the `@State` `WorkspaceModel`
  initializer twice; both instances registered a `willTerminate` save in `init()`, so on
  quit the discarded throwaway wrote its untouched defaults last — wiping folder/sort **and**
  ratio to home/0.5. Fix: save-side registration (`trackChangesForSave` + terminate flush)
  moved out of `init()` into `startPersistence()`, called once from the view's `.onAppear`;
  only the rendered instance arms saves.
- 134 unit tests green (129 + 5 `SplitPane` clamp tests).
