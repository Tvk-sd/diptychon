# PLAN — Issue 41: Reliable state persistence

Branch: `feat/41-state-persistence` · Issue: `.scratch/diptychon-mvp/issues/41-state-persistence.md`

## What I understood

Make Diptychon remember its workspace across app launches and drive unmounts, so a
returning user finds panes as they left them. The issue owns the **save/restore
mechanism** (cross-cutting); sibling issues (#38 tabs, #27/29 columns, #37 view mode)
own the *shape* of future state.

## Governing principle (JTBD)

The job is **continuity**; the emotional job is **trust**. Decision rule for every
restore behavior (per the issue's JTBD header): **a restore that confuses is worse than
no restore — when in doubt, restore less / fall back safely.** Corollary: reliability
of the **core** restore (folder, sort, layout) outranks **breadth**. This is *why* the
scope below is "mechanism + what exists" rather than "cover every AC box": a rock-solid
narrow restore serves the job better than a wide one that occasionally breaks a pane or
hides files.

## Reality gap (why scope is reframed)

Persistence can only save state that exists. Codebase audit found most AC-referenced
state is **not built yet**:

| AC item | Exists today? |
|---|---|
| Per-pane folder | ✅ `PanelModel.directory` |
| Per-pane sort col/dir | ✅ `PanelModel.sortOrder` (session-only) |
| Sidebar / right-panel visibility | ✅ already persisted (UserDefaults + `didSet`) |
| Split ratio | ⚠️ session-only `HSplitView`; needs wiring |
| Column widths / shown columns | ❌ hardcoded (issues 27/29) |
| View/display mode | ❌ single mode only (issue 37) |
| Open tabs per pane | ❌ tabs don't exist (issue 38) |
| Remount restore / missing-folder fallback | ❌ no mount/unmount handling |
| Staging set | exists, **explicitly session-only** (`StagingStore`) |

No snapshot/save layer exists — each persisted value self-saves via its own `didSet`
into `UserDefaults`. No versioning, no on-quit hook.

## Decisions (defaults chosen; user AFK at plan time — confirm on return)

1. **Scope = mechanism + what exists.** Build the durable, versioned snapshot +
   save/restore hook + mount/unmount handling. Persist folder, sort, split ratio,
   staging. Schema designed so tabs/columns/view-mode slot in later without rewrite.
   *Not* building #38/#27/#29/#37 here.
2. **Staging = persist as path refs**, degrading gracefully when an item is gone
   (per issue 33).
3. **Store = one versioned `Codable` snapshot under a single `UserDefaults` key**
   (`workspaceState`), JSON-encoded. Rationale: consistent with existing UserDefaults
   convention, atomic, no Application Support file/dir management. Versioning via a
   `schemaVersion` field + tolerant decode.
4. **Existing per-property flags stay as-is** (sidebarVisible, rightPanelVisible,
   previewVisible, pinnedFolders, openWithFavorites). Surgical — don't churn working
   persistence. New snapshot covers only newly-persisted state.
5. **Save timing:** debounced save on relevant changes + a hard save on graceful quit
   via a minimal `AppDelegate.applicationWillTerminate` (no AppDelegate today).

## Explicitly NOT persisted (deliberate, per issue)

- Active filters (type-ahead `filter`, `tagFilter`, `searchQuery`) — panes reopen
  **unfiltered**. Automatic: simply not in the snapshot.
- Transient/virtual views (disk-usage results, staging previews). Automatic.

## Design

### Snapshot schema (new `WorkspaceState.swift`)
```
struct WorkspaceState: Codable {
  var schemaVersion: Int         // = 1
  var left: PaneState
  var right: PaneState
  var splitRatio: Double?        // nil until wired / if deferred
  var staging: [String]          // ordered paths
  // future: tabs, columns, viewMode — additive, optional
}
struct PaneState: Codable {
  var directoryPath: String
  var sort: PaneSort
  // future: columnWidths, shownColumns, viewMode
}
struct PaneSort: Codable { var column: Column; var ascending: Bool }
enum Column: String, Codable { case name, kind, date, size }
```
- Pure `encode(_:)` / `decode(_:)` helpers, mirroring `PinnedFolders`/`FavoriteApps`.
- **Tolerant decode:** unknown/old `schemaVersion` or missing keys → return defaults,
  never crash or wipe (optionals + try? per field). Unit-tested.

### Sort mapping (`PanelModel`)
- `KeyPathComparator<FileItem>` ↔ `PaneSort`: helper translating the 4 columns
  (`name`/`kind`/`date`/`size`) and direction. Column set already exists
  (`NSTableViewFileList.Column`).

### Restore on launch (`WorkspaceModel.init`)
**This is where the trust bar is won or lost** (principle above) — the hardest,
most test-worthy logic. Per pane, resolve `directoryPath`:
- Exists & reachable → use it.
- On an **unmounted volume** (path under a `/Volumes/X` not currently mounted) →
  keep a pending-restore target, open a safe fallback now, restore on remount.
- **Permanently gone** → nearest existing ancestor, else `URL.startDirectory` (home).
  Never a broken/empty pane.

### Mount/unmount (`WorkspaceModel`)
- Observe `NSWorkspace.shared.notificationCenter` `didMount` / `didUnmount`.
- Unmount: if a pane's directory is on that volume, remember its path, navigate pane
  to fallback (no broken pane / spinner).
- Mount: if a pane has a pending target on that volume, restore it.

### Save hook
- `WorkspaceModel.saveState()` builds the snapshot and writes the UserDefaults key.
- Debounced trigger on: pane directory change, sort change, staging change,
  split-ratio change.
- `AppDelegate.applicationWillTerminate` → `saveState()` (flush, undebounced).
  Wire via `NSApplicationDelegateAdaptor` in `DiptychonApp`.

### Split ratio — flagged risk
`HSplitView` doesn't expose its fraction in SwiftUI. Persisting it cleanly may require
replacing `HSplitView` with a custom GeometryReader + draggable divider bound to a
stored fraction — a layout change that violates "surgical". **Plan: investigate a
lightweight binding first; if it needs replacing HSplitView, DEFER split-ratio to a
follow-up and ship the rest.** `splitRatio` stays optional in the schema either way.

## Files

**New**
- `Sources/Diptychon/Panel/WorkspaceState.swift` — Codable snapshot + encode/decode +
  versioned/tolerant decode + path-resolution helpers.
- `Sources/Diptychon/App/AppDelegate.swift` — `applicationWillTerminate` → save.
- `Tests/DiptychonTests/WorkspaceStateTests.swift` — encode/decode round-trip,
  schema-tolerance (old/unknown version → defaults), sort mapping, ancestor fallback.

**Modify**
- `Sources/Diptychon/Panel/WorkspaceModel.swift` — snapshot()/restore()/saveState()
  (debounced), mount/unmount observers, restore-on-init, didSet wiring.
- `Sources/Diptychon/Panel/PanelModel.swift` — sort↔PaneSort helpers; restore(from:).
- `Sources/Diptychon/App/DiptychonApp.swift` — `NSApplicationDelegateAdaptor`.
- `Sources/Diptychon/Panel/WorkspaceView.swift` — split-ratio binding (if feasible).

XcodeGen auto-globs new `.swift` files — run `xcodegen generate` after adding files.

## Steps

1. `WorkspaceState.swift` + encode/decode + tolerant versioned decode. **Tests first.**
2. Sort↔PaneSort mapping on `PanelModel` + `PaneState` restore. Tests.
3. `WorkspaceModel`: snapshot() / saveState() (debounced) / restore-on-init with
   path-resolution fallback. Tests for fallback logic.
4. `AppDelegate` + `NSApplicationDelegateAdaptor` wiring; flush save on terminate.
5. Mount/unmount observers + remount restore.
6. Split-ratio: investigate binding; wire or defer per risk note.
7. `xcodegen generate`, build, and **verify through the real app** (quit + relaunch;
   simulate unmount) — not just unit tests.

## Acceptance mapping

- Folder + sort + (layout flags) restore on relaunch → steps 1–3. ✅ in scope.
- Tabs restore → **deferred** (tabs don't exist; #38).
- Columns/view-mode restore → **deferred** (don't exist; #27/29/37).
- Split ratio restore → step 6, **may defer** (risk).
- Remount restore + missing-folder fallback → steps 3, 5. ✅
- Schema-versioned, tolerant → step 1. ✅
- Transient views not persisted → automatic. ✅
- Filters not restored → automatic. ✅
- Staging persistence → steps 1, 3 (persist path refs, graceful degrade). ✅

## Open questions for user

- Confirm scope decision (#1) and staging decision (#2) above.
- OK to defer split-ratio if it requires replacing `HSplitView`?
- Should deferred AC items (tabs/columns/view-mode) be reflected back into the issue
  file as explicit dependencies, or tracked here only?
