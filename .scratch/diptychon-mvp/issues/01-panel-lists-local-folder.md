# 01 — Panel lists a local folder

Status: done — merged (PR #1)

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

The tracer bullet: launch the app and see one Panel rendering the contents of a
real local directory. Introduce the Panel Source abstraction (ADR 0003) with a
single local-directory implementation, list its contents asynchronously, and
render them in a virtualized `Table` placed behind a narrow list protocol
(ADR 0002). Columns: name, size, modification date. Read-only, no navigation yet.

## Acceptance criteria

- [x] App launches to a window containing one Panel.
- [x] The Panel lists a real local directory's contents (name, size, date).
- [x] Listing happens off the main thread; the UI never blocks while a directory
      loads. (`LocalDirectorySource.load()` runs the enumeration in a
      `Task.detached`; window stayed live while 50k entries loaded.)
- [x] The file list is rendered via `Table` behind a list protocol so the
      implementation can later be swapped (ADR 0002). (`FileListView` protocol +
      `TableFileListView`, selected via the `PanelFileList` typealias.)
- [x] Panel Source is an abstraction with one local-directory implementation
      (ADR 0003). (`PanelSource` protocol + `LocalDirectorySource`.)
- [~] Performance: a real folder of ~50,000 files loaded off-thread and rendered
      via the virtualized `Table` without blocking or crashing (verified). The
      *subjective* "scrolls without visible stutter" is left for human interactive
      confirmation; ADR 0002's escape hatch applies if it stutters.

## Blocked by

None - can start immediately.

## Comments

**2026-06-17 (agent):** Implemented on branch `feat/01-panel-lists-local-folder`.
Built with SwiftPM (no Xcode); run via `./scripts/run.sh`. Files: `Package.swift`,
`Sources/Diptychon/{App,Panel}/*.swift`, `Resources/Info.plist`, `scripts/run.sh`.
Verified by screenshot on the home dir and on a generated 50k-file folder.

Blocker hit + resolved: the machine's Command Line Tools shipped a mismatched
compiler/SDK, breaking all Swift builds (SPM and `swiftc`). Fixed by reinstalling
CLT. No code cause.

For review: confirm scroll feels smooth on a large real folder (only objective
perf was verified here). The window may open on a secondary display.
