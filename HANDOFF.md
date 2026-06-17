# HANDOFF — Diptychon

_Last updated: 2026-06-17_

Dual-panel, keyboard-first macOS file manager (Finder alternative, Nimble
Commander spirit). MVP in progress.

## Orientation (read these first)
- Product: `/.scratch/diptychon-mvp/PRD.md`
- Domain language: `/CONTEXT.md` (terms: Panel, Active/Inactive Panel, Panel
  Source, Operation — note "Operation", **not** "command")
- Decisions: `/docs/adr/0001..0004`
- Issues: `/.scratch/diptychon-mvp/issues/NN-*.md`
- Running state + gotchas: `/PROJECT-TRACKER.md`

## Build & run (no Xcode — SwiftPM + Command Line Tools)
```
./scripts/run.sh            # debug: build → wrap minimal .app → launch
./scripts/run.sh release    # release: optimized, much faster to open
DIPTYCHON_DIR=/path ...      # env override for starting directory
```
- CLT compiler+SDK MUST match (a mismatch broke all builds once; fixed by
  reinstalling CLT). `swift build` works now.
- **GUI gotchas already solved** (see PROJECT-TRACKER “Gotchas”):
  explicit AppKit entry (`App/main.swift` + `AppDelegate`) hosting SwiftUI via
  `NSHostingController`; SwiftUI `App`/`WindowGroup` lifecycle does NOT receive
  input under a hand-wrapped bundle.

## Git state
- `main`: issues **01, 02, 03 merged** (PRs #1, #4, #3). Builds clean.
- Current branch: **`feat/04-operation-undo-spine`** — WIP committed locally
  (`6e65b7c`), **not pushed**, **2 open bugs** (below). No PR yet.

## Progress
| # | Title | State |
|---|-------|-------|
| 01 | Panel lists a local folder | ✅ merged |
| 02 | Navigation, sort, hidden, type-ahead | ✅ merged |
| 03 | Dual panels + focus | ✅ merged |
| 04 | Operation/undo spine + copy-to-Inactive | 🟡 WIP, 2 bugs |
| 05–10 | file ops, DnD, rename, tags, QuickLook/FSEvents, FDA onboarding | ⬜ |

## Architecture (issue 04)
- `Operations/Operation.swift` — `Operation` protocol (`title`, `isUndoable`,
  `apply(progress:)`, `revert()`), `CopyOperation` (records `createdURLs` for
  revert; `didOverwrite` → not undoable; rename/skip/overwrite), `detectCollisions`.
- `Operations/OperationCoordinator.swift` — `@MainActor @Observable`; undo/redo
  stacks; `run`/`undo`/`redo`; `running` (title+fraction); `cancel`.
- `Operations/Keymap.swift` — data-driven action→key table matched against
  `NSEvent` (keyCodes). Actions: copyToInactive (⌥⌘←/→), undo (⌘Z), redo (⇧⌘Z),
  goUp (⌘↑), switchPanel (Tab).
- `Panel/WorkspaceModel.swift` — `@Observable` owns `left`/`right` `PanelModel`,
  `coordinator`, `active: Side`, `pendingCopy`. `handleKeyDown` → `perform`.
- `Panel/WorkspaceView.swift` — two `PanelView`s; **NSEvent local monitor** is the
  sole keyboard authority; `active` derived from last-changed selection/directory
  (`onChange`); collision `confirmationDialog`; progress overlay.
- `Panel/PanelView.swift` — header (Up/path/Hidden/Filter) + `PanelFileList`;
  `isActive` border. No keyboard handling (monitor owns it). Double-click enters.
- `Panel/{PanelModel,FileListView,LocalDirectorySource,FileItem}.swift` —
  per issues 01–02 (Table behind `FileListView` protocol, `PanelSource` abstraction).

## Issue 04 — what WORKS (user-verified)
- ⌥⌘→/← copies Active selection into Inactive Panel’s dir.
- Collision dialog appears; **Keep Both** → `name 2.ext`; rename verified.
- `CopyOperation` logic unit-tested green (copy / rename-collision / revert /
  overwrite-not-undoable / detectCollisions) via swiftc temp-dir harness.

## Issue 04 — OPEN BUGS (must fix before PR)
### BUG A — single-click row selection is flaky (intermittent; often needs 2+ clicks)
The biggest UX problem. Selecting a row sometimes takes multiple clicks; pattern
unclear. Tried, none fully fixed:
1. `@FocusState` on PanelView root + `.focusable()` (issue 03 style) — selection
   worked but activating a panel took an extra click.
2. `@FocusState` bound to the `Table` — activated panel but **ate the row
   selection** (selection stayed empty → copy no-op'd). Confirmed via logging:
   `copy sources=0`.
3. Current: **no `@FocusState`**; `active` derived from `onChange` of each
   model’s `selection`/`directory`. Still flaky.
Hypotheses to investigate next:
- Two SwiftUI `Table`s sharing one window’s first-responder; clicking a row in the
  not-first-responder Table may register as focus-only on the first click.
- May need the **AppKit `NSTableView` escape hatch (ADR 0002)** for robust
  click/selection/first-responder behavior — note ADR 0002 frames this as a
  *performance* hatch, so confirm with a human before repurposing it for input.
- Try: explicit per-row tap that sets selection; or `.focusEffectDisabled`; or
  giving each Table a stable `id` and verifying selection binding isn’t reset by
  `visibleItems` recomputation on every render (sort/filter recompute → new array
  identity each pass — possible cause of selection churn; consider memoizing
  `visibleItems`).

### BUG B — ⌘Z undo does not remove the copied file ("copy is still there")
Now that copy works (op pushed to `undoStack`), undo should `revert()` (delete
`createdURLs`) and refresh both panels — but the copy remains visible.
Investigate (add temporary `print` like the prior pass, run binary with
`>/tmp/dipt.log 2>&1`, have user press ⌘Z, read log):
- Is ⌘Z reaching `handleKeyDown` (keyCode 6, command)? Or consumed by system
  Edit→Undo / a focused `TextField`’s field-editor undo?
- Is `undoStack` non-empty at undo time?
- Is `coordinator.running` stuck non-nil (would block undo via its guard)?
- Does `revert()` actually delete, and does `refreshBoth()` re-list? (Selection /
  cache could hide the removal — verify file is gone on disk.)

## How to work here (important)
- **The agent cannot drive mouse/keyboard.** Verify by: (a) unit-testing pure
  logic with a swiftc temp-dir harness (see Operation.swift test approach);
  (b) launching and **screenshotting** (window may open on a secondary display —
  list windows via a tiny CoreGraphics `CGWindowListCopyWindowInfo` helper, then
  `screencapture -x -R<x,y,w,h>` the region, or `-l<windowid>`); (c) asking the
  user to perform a scripted sequence while logging to `/tmp/dipt.log`.
- Run the **binary directly** (not via `open`) to capture stdout/stderr:
  `BIN="$(swift build --show-bin-path)/Diptychon"; ("$BIN" >/tmp/dipt.log 2>&1 &)`.
- Keep edits surgical; match existing style. Domain term is **Operation**.

## Next steps (ordered)
1. Fix BUG A (single-click select+activate). Start with the `visibleItems`
   identity hypothesis (memoize) — cheap and plausible.
2. Fix BUG B (undo) via logging pass.
3. Re-verify full issue-04 acceptance with user; remove any debug prints.
4. Update issue 04 file (checks + `ready-for-human`) + PROJECT-TRACKER; commit;
   push; open PR (base `main`). Merge bottom-up, do NOT `--delete-branch`
   mid-stack (it auto-closes stacked PRs — happened to #2; remade as #4).
5. Proceed to issue 05 (remaining file operations: copy/move/delete-to-trash,
   create folder/file, duplicate) — reuses the Operation spine.

## Acceptance still to confirm for issue 04
- [~] every op = Operation w/ inverse (done, spine in place)
- [x] ⌥⌘→/← copy to Inactive
- [ ] long copy: progress + cancel (overlay built; not stress-tested)
- [x] collisions resolved pre-write; overwrite says “cannot be undone”
- [ ] ⌘Z / ⇧⌘Z multi-level (BUG B)
- [x] hotkeys via action→key table
- (extra) single-click selection (BUG A) — not an acceptance item but blocks usability
