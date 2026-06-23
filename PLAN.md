# PLAN — Issue 09: QuickLook, Open with, FSEvents

Spec: `.scratch/diptychon-mvp/issues/09-quicklook-openwith-fsevents.md`.
Branch: `feat/09-quicklook-openwith-fsevents` (off `main`).

## What I understood
Three macOS integrations on the existing dual-panel app:
1. **Open** — Return / double-click on a *file* opens it in its default app
   (folders still navigate); plus an explicit **"Open with"** app chooser.
2. **QuickLook** — spacebar previews the selected file(s).
3. **FSEvents** — a Panel auto-refreshes when its directory changes on disk
   (created/deleted/renamed by another app), no manual refresh.

## Assumptions (challenge these)
- These are **OS-integration** features (NSWorkspace, QLPreviewPanel, FSEvents),
  so they're verified by build + manual/screenshot, not unit tests — **except**
  the directory watcher, which I'll cover with a real temp-dir integration test.
- Spacebar = QuickLook is global to the Active Panel's selection (matches Finder).
- "Open with" lives on a **right-click context menu** on rows (the list is the
  AppKit `NSTableViewFileList`, so this is an `NSMenu`). No new hotkey needed.
- Opening multiple selected files at once is fine (Finder opens each).
- Directory watching is **non-recursive, one directory per Panel** (we only show
  one level). A lightweight `DispatchSource` vnode watch on the directory fd,
  debounced, is enough and simpler than the FSEventStream C API. Re-armed on every
  navigation/reload; cancelled on deinit.
- Our own file ops already call `refresh()`; the watcher may double-fire on them —
  harmless (reload is idempotent + cancels in-flight), debounce smooths it.

## Approach — vertical slices
1. **Open in default app (AC2a).** `WorkspaceModel.openSelection()`: single folder
   → navigate (today's behavior); file(s) → `NSWorkspace.open`. Route Return
   (add to `Keymap`) and the existing double-click here. Small.
2. **Open with chooser (AC2b).** Right-click `NSMenu` on the list: "Open",
   "Open With ▸" submenu built from `NSWorkspace.urlsForApplications(toOpen:)`
   + "Other…" (`NSOpenPanel` → `open(_:withApplicationAt:)`). Add menu support to
   `NSTableViewFileList` (respect the row under the cursor / current selection).
3. **QuickLook (AC1).** A `QuickLookController` (NSObject, `QLPreviewPanelDataSource`
   + `Delegate`) holding the current URLs; spacebar (keyCode 49) toggles
   `QLPreviewPanel.shared()` for the Active selection. Add `.preview` `AppAction`.
4. **FSEvents live update (AC3).** `Panel/DirectoryWatcher.swift` — `DispatchSource`
   on the directory fd (`.write` mask), ~150ms debounce, callback → `reload()`.
   `PanelModel` owns one, (re)created in `reload()`, torn down on deinit.
   Integration test: watch a temp dir, create a file, expect the callback.

## "Done" = checkable
- Return / double-click opens a file in its default app; folders still navigate.
- Right-click → "Open With" lists real candidate apps and "Other…"; each launches
  the file in the chosen app.
- Spacebar opens a QuickLook preview of the selection; spacebar/esc closes it.
- Creating/deleting/renaming a file in a Panel's directory from another app (e.g.
  Finder/`touch`) updates the Panel within ~1s with no manual refresh.
- `xcodebuild ... test` green (incl. the new `DirectoryWatcher` test); user-verified
  end to end.

## Open questions / risks
- **QLPreviewPanel + SwiftUI responder chain**: the panel wants a responder to
  own it. If `orderFront` + manual data source isn't enough, may need a tiny
  `NSViewRepresentable` to sit in the responder chain. Flagging as the riskiest bit.
- **Watcher vs. our own ops**: double refresh (mitigated by debounce); revisit if
  it flickers.

## Progress
- [ ] Slice 1 — open in default app (AC2a)
- [ ] Slice 2 — open with chooser (AC2b)
- [ ] Slice 3 — QuickLook spacebar (AC1)
- [ ] Slice 4 — FSEvents live update (AC3)
