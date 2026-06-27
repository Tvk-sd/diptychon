# Diptychon — Project Tracker

Dual-panel macOS file manager. MVP PRD: `.scratch/diptychon-mvp/PRD.md`.

## Build & run
Real Xcode project (Xcode 26.5). The `.xcodeproj` is generated from `project.yml`
by [XcodeGen](https://github.com/yonaskolb/XcodeGen) and is **gitignored** —
regenerate it after pulling or editing `project.yml`.
```
brew install xcodegen          # one-time
xcodegen generate              # (re)create Diptychon.xcodeproj from project.yml
open Diptychon.xcodeproj       # or build/test from the CLI:
xcodebuild -scheme Diptychon -destination 'platform=macOS' build
xcodebuild -scheme Diptychon -destination 'platform=macOS' test    # runs XCUITests
DIPTYCHON_DIR=/path            # env override for the initial folder (read by WorkspaceView)
```
Signing: ad-hoc / "Sign to Run Locally" (no Apple Developer team needed); app
sandbox OFF via `Resources/Diptychon.entitlements` (ADR 0001). Notarization /
hardened runtime deferred to issue 10.

XCUITest target `DiptychonUITests` lets the agent self-verify the UI (launch +
assert state) instead of the manual "you click, I read logs" loop used for 01–07.

_History: 01–07 were built with Command Line Tools + SwiftPM and a hand-wrapped
`.app` (no Xcode). Migrated to Xcode on 2026-06-22 (branch `chore/xcode-migration`).
The CLT compiler/SDK-mismatch hazard from that era is gone — Xcode bundles a
matched toolchain._

### Issue 04 outcome (2026-06-18)
Reversible-`Operation` spine (ADR 0004): `Operation` protocol + `CopyOperation`
(records created URLs for revert; overwrite = not undoable), `OperationCoordinator`
(undo/redo stacks, progress, cancel), data-driven `Keymap`. Commander gesture
⌥⌘→/← copies Active selection into Inactive Panel; collision dialog
(overwrite/keep-both/skip) pre-write; ⌘Z/⇧⌘Z multi-level. Keyboard owned by an
`NSEvent` local monitor (a focused `Table` swallows arrow keys otherwise); active
Panel set by which window-half was clicked; double-click-to-open also via the
monitor. User-verified end to end.

Bugs found + fixed this slice (good lessons):
- **QWERTZ keyboard**: matching ⌘Z by hardware keyCode 6 = `y` on German layout.
  Fix: match letters by character, arrows/Tab by keyCode.
- **Single-click selection eaten** by a `.onTapGesture(count: 2)` on the Name
  cell. Fix: no tap gesture; double-click via mouse monitor; `Table` keeps native
  single-click select.
- **Active-panel switching** can't derive from selection changes (re-clicking an
  already-selected row fires nothing). Fix: `leftMouseDown` monitor sets active by
  window half.
- `visibleItems` recomputed every render -> cache it (recompute on filter/sort/
  contents change only).

### Issue 05 outcome (2026-06-18)
Remaining core operations on the 04 spine: `MoveOperation`, `TrashOperation`
(`trashItem`, revert restores from Trash), `CreateOperation` (folder/file,
`untitled …`); Duplicate reuses `CopyOperation` into the same dir. Real
`NSPasteboard` clipboard: ⌘C / ⌘V (copy into Active) / ⌥⌘V (move into Active,
Finder convention); ⌘⌫ Trash, ⌘D Duplicate, ⇧⌘N New Folder, ⌃⌘N New File.
Collision flow generalized to any copy/move (`write(kind:)`). All new ops
unit-tested vs temp dirs; user-verified end to end.

### Issue 06 outcome (2026-06-18)
Drag & drop, routed through the same `write(kind:)` Operations (free progress,
collision dialog, undo). Drag between Panels, into subfolders (with hover
highlight), and to/from Finder. **Took the ADR 0002 AppKit escape hatch**:
SwiftUI `Table` can't combine row-drag with reliable single-click selection, so
`PanelFileList` now aliases `NSTableViewFileList` (NSViewRepresentable over
NSTableView). Only the list layer changed; `FileListView` protocol unchanged.
This also pre-empts the 50k-row perf trigger. Drag defaults to copy (move-on-drag
deferred). `WorkspaceModel.write` generalized to target any directory.

**Lesson:** SwiftUI `Table` fought us on input across issues 03/04/06 (focus,
tap, drag all swallow clicks). AppKit `NSTableView` is the right home for the
file list. Prefer it for future list work.

### Issue 07 outcome (2026-06-18)
Batch rename on the Active selection, one undoable `RenameOperation` (two-phase
temp→final so intra-batch swaps don't collide). Sheet modeled on Finder, four
exclusive modes: Replace Text / Add Text / Name + Number / Case. Live
before/after preview; collisions flagged red + Rename disabled. Opened with ⌘R.
Pure `RenameRule` + collision detection unit-tested.

Bug fixed: **NSTableView multi-select was wiped by two-way selection binding** —
`updateNSView` ran on every re-render and `syncSelection` echoed a stale binding
back onto the table, clearing in-progress ⌘/⇧-click selection. Fix: track
`lastPublished`; only push binding→table on *external* changes (e.g. nav), never
echo what the table just published. (General lesson for NSViewRepresentable
two-way bindings.)

Split out: inline single-file rename → issue 11 (Finder-style click/Return).

### Gotchas (no-Xcode / SwiftPM bundle) — RESOLVED by Xcode migration (2026-06-22)
- ~~**SwiftUI needs `NSHostingController`, not the `App`/`WindowGroup` lifecycle.**
  Under a hand-wrapped `.app`, SwiftUI windows render but get NO input events.~~
  Gone on real Xcode: `App/DiptychonApp.swift` is now a plain `@main struct ... : App`
  with `WindowGroup { WorkspaceView() }`; input routes correctly. (`main.swift` +
  `AppDelegate` deleted.)
- ~~Window may open on an external display / wrong Space~~ — the manual primary-screen
  placement hack is gone with the hand-wrapped bundle; `WindowGroup` + `.defaultSize`.
- Localized folder names (`Musik` vs `Music`) only show once app is localized;
  `localizedNameKey` falls back to raw on-disk name otherwise.

## Status
| Issue | Title | State |
|-------|-------|-------|
| 01 | Panel lists a local folder (tracer bullet) | ✅ done, PR #1 |
| 02 | Panel navigation, sort, hidden toggle, type-ahead | ✅ done, PR #2 |
| 03 | Dual panels + focus switching | ✅ done, PR #3 |
| 04 | Operation/undo spine + copy-to-Inactive | ✅ done, PR #5 |
| 05 | Remaining file operations + clipboard | ✅ done, PR #6 |
| 06 | Drag & drop (+ AppKit list hatch) | ✅ done, PR #7 |
| 07 | Batch rename | ✅ done, PR #8 (+ QA fixes #10 refresh-both-panels, #11 case-only rename) |
| — | **Xcode migration** | ✅ done 2026-06-22, PR #9 |
| 08 | Finder tags (real Apple tags, round-trip) | ✅ done, PR #12 (all 4 ACs, user-verified); sidebar-color follow-up split |
| 09 | QuickLook / Open-with / FSEvents | ✅ done, PR #13 (all 3 ACs, user-verified) |
| 10 | Full Disk Access onboarding | ✅ done, PR #14 (all ACs, user-verified) — **MVP complete** |
| 11 | Inline single-file rename | ✅ done, PR pending — user-verified (⌘R / slow-click) |
| 12 | Custom tag color registration (Finder sidebar) | 🚫 wontfix — ADR 0005 (forging Finder's private store too fragile; file xattr already works) |
| 13 | Panel resize + collapse/expand right panel | ✅ done, PR #16 |
| 14 | Inline preview / inspector pane | ✅ done, PR #15 (raised in 09) |
| 15 | Path bar / Go to Folder | ✅ done, PR #17 |
| 16 | Left sidebar (places + pinned folders) | ✅ done, PR pending — all 3 slices, user-verified |
| 17 | File-list polish (data-driven display) | ✅ done, PR pending — Size right-aligned + scan-friendly dates |
| 18 | Operation history / time-travel undo | ⬜ needs-triage — differentiation bet, `context/competitor-benchmark.md` §3 |
| 19 | Command palette (⌘K) | ⬜ needs-triage — differentiation bet, `context/competitor-benchmark.md` §3 |
| 20 | Virtual staging panel | ⬜ needs-triage — differentiation bet, `context/competitor-benchmark.md` §3 |
| 21 | Unified top bar (breadcrumb, back/forward, search) | ✅ done on branch `feat/21-unified-top-bar`, PR #21 open — slices 1–3 + redesign, user-verified |
| 22 | Performance baseline measurements | ⬜ needs-triage — unblocks speed claim, `context/competitor-benchmark.md` §4 |
| — | **Architecture review** — all 5 deepenings (#1 settle-hook, #2 presentedSheet, #3 Panel Source inject, #4 SelectionEchoGuard, #5 compileVisible) + self-overwrite data-loss fix | ✅ done on branch `improve-codebase-architecture`, pushed, user-verified — QA filed #25/#26/#27 (see outcome below) |
| 25 | Double-click opens entire selection, not clicked row | ⬜ needs-triage — found in QA, product call needed (`.scratch/diptychon-mvp/issues/25-*`) |
| 28 | Keyboard command expansion (Marta-informed) + Open-With favorites | ✅ done on branch `feat/28-keyboard-commands` (off `improve-codebase-architecture`), user-verified — commit `2bdad9d` |

## Decision (2026-06-19): migrate to Xcode before issues 08–10
The no-Xcode SwiftPM + hand-wrapped `.app` setup carried us through 01–07 but
cost many manual test round-trips and forced bundle/window workarounds. Moving to
a real Xcode project to gain: XCUITest (agent-driven UI verification),
entitlements/signing (needed for issue 10 Full Disk Access), packaging (ADR 0001:
Releases + Homebrew Cask), previews/debugger/Instruments. Migration is low-risk —
code is plain Swift; the `@main App` lifecycle replaces the AppDelegate/NSWindow
workaround, while the `NSEvent` monitor and `NSTableView` list stay. Full plan in
HANDOFF.md “NEXT TASK”.

### Issue 08 progress (2026-06-23) — Finder tags, slices 1–3 (branch `feat/08-finder-tags`)
Real Apple Finder tags via the `com.apple.metadata:_kMDItemUserTags` xattr (a
binary-plist array of `"name\nColorIndex"` strings; index 6 = Red, confirmed
against a Finder-written sample). Built in vertical slices, TDD where pure:
- **Slice 1** — `FinderTag` + `FinderTagCodec` (pure encode/decode), 7 unit tests.
- **Slice 2 (AC1)** — read tags into `FileItem` (only `getxattr` when the batched
  `tagNames` flags a file as tagged); show ≤3 color dots + “+N” in the name cell
  (`NameCellView`/`FinderTagDotsView`), names in tooltip/accessibility.
- **Slice 3 (AC2)** — ⌘T `TagPickerSheet` over the selection; toggling a tag is one
  undoable `SetTagsOperation` (ADR 0004), reflected live + in Finder.
- **Slice 4 (AC4)** — filter the Active Panel by tag: `PanelModel.tagFilter` applied
  through a pure, unit-tested `PanelModel.applyFilters`; per-panel header tag menu
  lists the tags present, toggles/clears, cleared on navigation.
- **Slice 5 (AC3)** — `TagPickerSheet` new-tag composer (name + built-in color, one
  undoable op via `toggleTag`) + a "custom tags in use" section
  (`WorkspaceModel.customTagsInUse`) to re-apply existing tags.
- **Scoped follow-up:** custom-color Finder *sidebar* registration needs Finder's
  undocumented system tag store; deferred. We write tag name + color correctly to
  the xattr, so the file's dot is right and it round-trips.
- Tests: 26 green (23 unit + 3 UI); picker UI test asserts the file's real xattr.

### Issue 09 outcome (2026-06-23) — QuickLook / Open-with / FSEvents (branch `feat/09-…`)
Three macOS integrations, built in 4 slices, user-verified end to end:
- **AC2a open** — Return / double-click: a single folder navigates, file(s) open via
  `NSWorkspace` (`WorkspaceModel.openSelection`). New `↩` keymap entry.
- **AC2b open with** — `FileTableView` right-click menu (Open / Open With ▸ candidate
  apps via `NSWorkspace.urlsForApplications` + Other… via `NSOpenPanel`), targeting
  the clicked row or the selection.
- **AC1 QuickLook** — `QuickLookController` (`QLPreviewPanelDataSource`) +
  `togglePreview` drive the shared `QLPreviewPanel` on space (keyCode 49).
- **AC3 FSEvents** — `DirectoryWatcher` (`DispatchSource` vnode, debounced) → live
  refresh; `refresh()` no longer flips to the loading spinner (no flash).
- **Bonus fix:** the key monitor now ignores hotkeys while a text field is first
  responder, so plain ␣/↩/⇥ reach the Filter/rename/new-tag editors (latent bug:
  Return/Tab were hijacked mid-type).
- Tests: 28 green (25 unit + 3 UI), incl. 2 temp-dir `DirectoryWatcher` tests.
- Split out: **issue 14** (inline preview pane, distinct from floating QuickLook).

### Issue 10 outcome (2026-06-23) — Full Disk Access onboarding (branch `feat/10-…`)
FDA can't be requested in code (ADR 0001), so the app detects its absence and
guides the user. **Non-blocking, inline-first** (a global banner was prototyped
then dropped in UX review — felt like an ecommerce banner):
- `FullDiskAccess` helper — `isGranted` probe (lists `~/Library/Safari`, falls
  back to user `com.apple.TCC/TCC.db`) + `openSettings()` deep-link to the
  Privacy → Full Disk Access pane (confirmed correct on-device).
- **App menu** — Diptychon ▸ **Full Disk Access…** (⌘, Preferences slot,
  `CommandGroup(.appSettings)`).
- **Inline guidance** — `PanelModel.accessDenied` (NSFileReadNoPermissionError)
  shows a centered lock + message + "Open Full Disk Access Settings" in the
  folder's failed state.
- **Recovery** — `recheckFullDiskAccess` on app reactivation re-lists a panel
  that was permission-blocked once access is granted (no restart).
- HITL bar met: grant round-trip + UX reviewed by the user on a real device.
- Surfaced gap → **issue 15** (path bar / Go to Folder): no way to reach
  arbitrary folders like `~/Library`.
- 28 tests green (no new unit tests — the grant flow is OS-gated / HITL).

### Issue 14 outcome (2026-06-24) — Inline preview / inspector pane (PR #15)
First post-MVP feature. A toggleable right-side pane (off by default, ~300px)
previewing the Active Panel's selection — distinct from the floating spacebar
QuickLook (09).
- `WorkspaceModel.previewVisible` (UserDefaults-persisted); toolbar button
  (`sidebar.right`) + ⇧⌘P toggle.
- `PreviewPane`: single selection → live `QLPreviewView` + metadata (name, kind,
  size, created/modified); none/multiple → placeholder. Follows `activeModel`.
- Header tightened so it never wraps when the pane narrows the panels: the
  "Hidden" checkbox became a compact eye/eye.slash icon; path yields width first;
  Filter field flexes (70–160).
- 26 tests (22 unit + 4 UI), incl. `testPreviewPaneShowsSelectedFile`.
- **Test hardening:** `testLaunchesWithTwoPanels` repointed from the user's HOME
  (which can stall on a TCC prompt under XCUITest → panels stuck "Loading…") to a
  temp dir. Lesson: UI tests must control their directory, never rely on HOME.

### Issue 13 outcome (2026-06-24) — Panel resize + collapse right panel (PR pending)
- **Resize:** `HSplitView` draggable divider between the two file panels (min 240
  each); ratio holds for the session.
- **Collapse:** toolbar `rectangle.split.2x1` + ⌥⌘S toggle `rightPanelVisible`
  (registered default true, UserDefaults-persisted). Left fills when hidden.
- **Coherence:** hiding forces active=left; mouse half-detection forces left;
  ⌥⌘→ no-ops; Tab re-opens + focuses the right panel; restore keeps the right
  `PanelModel` (dir + selection).
- 27 tests (22 unit + 5 UI), incl. `testToggleRightPanel`.
- **Two gotchas (see PLAN/commit):** HSplitView can't drop a conditional child
  (swap the whole container); launch-arg/default-true needs `register` +
  `bool(forKey:)`, not `object as? Bool`.

### Issue 15 outcome (2026-06-24) — Path bar / Go to Folder (PR pending)
- **Go to Folder (⇧⌘G):** `GoToFolderSheet` pre-filled with the active path;
  `PathInput.resolve` (pure: `~` expansion, standardize, dir-exists check; 6 unit
  tests) gates navigation, invalid paths show an inline error.
- **Clickable path:** the header path is a menu of ancestor folders (jump up to
  any) + "Go to Folder…". `PanelModel.go(to:)`.
- 34 tests (28 unit + 6 UI), incl. `testGoToFolderNavigates`.
- Note: ⇧⌘G (a Keymap chord) is inactive while the Filter field is focused — same
  as ⌘T/⌘R; the path-menu item is the always-available mouse path.
- **Dev-loop reminder reinforced:** `pkill -f Diptychon` before every test run —
  leftover manual instances foreground over the XCUITest app and cause spurious
  failures (bundle-id gotcha).

**Gotcha (SwiftUI + XCUITest):** a `.plain` Button's hit area for *synthetic*
clicks is the rendered content, not the framed row; a real pointer respects
`.contentShape`. Verified full-row clicking with a `CGEvent` injection script and
asserted the on-disk xattr. Lesson: test UI against on-disk state, not the AX tree.

### Issue 16 outcome (2026-06-24) — Left sidebar (places + pinned folders) (PR pending)
A calm, Notion-style left sidebar (lighter than Finder), built in 3 slices,
user-verified end to end. Research: `context/sidebar-research.md`.
- **Slice 1 — scaffold + toggle + navigate.** `WorkspaceModel.sidebarVisible`
  (registered default true, UserDefaults-persisted) + `navigateActive(to:)`.
  `SidebarView`/`SidebarPlace`: **Places** (Home, Desktop, Documents, Downloads,
  Applications via `FileManager.url(for:in:)`, SF icons) + **Pinned** section.
  Clicking a row navigates the Active Panel; the active dir's row highlights.
  Layout `Sidebar | HSplitView(panels) | PreviewPane`; toolbar `sidebar.leading`
  toggle. Mouse active-panel boundary now accounts for sidebar + preview widths.
- **Slice 2 — pinning via context menu.** `PinnedFolders` pure helper
  (add/remove/dedup by standardized path, path↔URL encode/decode; 6 unit tests).
  `WorkspaceModel.pinnedFolders` ([URL] backed by [String] in UserDefaults) +
  `pin`/`unpin`. "Add to Sidebar" on a single-folder right-click menu (new `onPin`
  closure threaded NSTableViewFileList → PanelView → WorkspaceView, added to the
  `FileListView` protocol). Pinned rows navigate; "Remove from Sidebar" unpins.
- **Slice 3 — drag-to-pin + resilience.** Drop a folder anywhere on the sidebar to
  pin (`.dropDestination(for: URL)`, folders-only, accent-border highlight).
  Missing pinned folders render greyed + non-navigable (`folder.badge.questionmark`,
  click re-checks existence → no-op) but stay listed so they're removable.
- **UX calls:** **folders-only** (sidebar is a navigation surface — files aren't
  pinnable; a file-bookmarks feature would be separate). Sidebar toggle is
  **toolbar-button only** — ⌃⌘S was dropped (awkward claw; ⌥⌘S already went to the
  right panel in issue 13, so the Apple convention was already broken).
- Tests: 36 green (34 unit + UI: `testSidebarToggleAndNavigate`,
  `testPinFolderAppearsNavigatesAndRemoves`, `testMissingPinnedFolderDegradesGracefully`).
  Drag-to-pin verified by dogfooding (XCUITest drag is unreliable — ADR 0002 context).

### Issue 21 outcome (2026-06-25) — Unified top bar (branch `feat/21-unified-top-bar`, PR #21 open)
Foundational chrome, built in slices, user-verified end to end. Full root-cause
write-ups + debugging lessons in `context/transferable-learnings.md` (§7–§11).
- **Slice 1 — top bar.** `TopBarView`: Up + clickable breadcrumb of the active
  panel's path; navigation pulled out of per-panel headers into one bar.
  - **Critical fix:** the first breadcrumb walked `deletingLastPathComponent()` in a
    `while true` that never converges for the directory-style URLs
    `contentsOfDirectory(at:)` returns → pinned CPU ~99% / ballooned RAM. Rebuilt
    from the absolute path's `pathComponents` (bounded). `WindowMinWidth` hardened
    into an edge-triggered window grow. (§7–§10.)
- **Slice 2 — per-panel back/forward history.** `PanelModel.backStack/forwardStack`,
  `canGoBack/canGoForward`; every dir change routes through `pushHistoryAndGo`
  (push prior, clear forward); `goBack/goForward` shuttle the stacks. ⌘[ / ⌘] +
  ‹ › buttons. `NavigationHistoryTests` (synchronous stack assertions).
- **Top-bar redesign.** Bar scoped to the panel column (sidebar + preview rise to the
  title bar; only panel tops pushed down); full-width divider under the title bar;
  theme-adaptive sidebar tint; square active-panel ring. Filter moved into the bar
  (active panel). Go-to-Folder button removed; the sidebar field replaced it (then
  became Search). ⇧⌘G still opens the Go-to-Folder sheet.
- **Slice 3 — recursive file search.** Sidebar field = Search (pure). `RecursiveSearch.run`
  — a `nonisolated async` walk that runs off-main while honouring the caller's
  cancellation (each keystroke abandons the prior walk); results render **in the
  active panel** (Finder-style, reusing list/sort/open). `PanelModel.searchQuery`
  (debounced) → `searchResults`; `visibleItems` branches while `isSearching`;
  Searching… → results / "No results". **Bounded on both axes (§10):** ≤1000 matches
  AND ≤100k entries scanned; no per-entry metadata prefetch + `.skipsPackageDescendants`
  → Home search dropped from many seconds to a beat. `SearchTests` (nested match,
  hidden visibility, empty query).
- **Fixes (all the §11 content-blind-geometry-router trap):** the `leftMouseDown`
  monitor re-activated a panel from any click's x-position. (a) It measured the
  top-bar band from the full-size content view's top (behind the title bar) → clicking
  the bar Filter stole the panel; fixed to measure from `contentLayoutRect`. (b) It
  also fired for sidebar/preview clicks → with the right panel active, clicking the
  sidebar flipped to left and navigated the wrong side; now only clicks inside the
  panels' x-range re-activate.
- **New §11 learning recorded:** routing by geometry is content-blind, and a
  coordinate-space mismatch fails silently — `context/transferable-learnings.md` §11.
- **Process learnings:** new source files need `xcodegen generate` (the `.xcodeproj`
  is gitignored); and UI tests fail if a manually-launched app instance is running
  (bundle-id collision) — quit it first.
- **Deferred:** showing each search result's location (relative path) — needs a Table
  column. ⇧⌘G could later focus the sidebar field instead of the redundant sheet.
- Commits on branch: `22fdb58`-era slice 1 → `e1f7b64` slice 2 → `e6ccc97` redesign →
  `518354b` §11 docs → `1fc8dad` slice 3 → `abd2a64` sidebar-click fix. All pushed.

### Issue 17 outcome (2026-06-24) — File-list polish (data-driven display) (PR pending)
Presentation pass applying "data drives the form" (`context/dashboard-research.md`
§1) to the AppKit file list — no new data, just treatment matched to each column.
- **Size → right-aligned + monospaced digits** (cell *and* column header) so values
  line up by place value for at-a-glance comparison.
- **Dates → scan-friendly tiers** via a pure, unit-tested `FileDateFormatter`:
  today/yesterday keep the time ("Today 13:20"), same-year files drop year + time
  ("15 May"), older files show the year without time ("15 Nov 2024"). Cuts the
  dense `MMM d, yyyy at h:mm` timestamp down to what's worth scanning.
- Name stays left; Date stays left (it's text); only the numeric Size flips right —
  consistent text-left / numeric-right alignment.
- No regression to sorting (still keyed on `sizeForSort`/`dateForSort`), selection,
  or the issue-08 tag dots.
- Tests: 4 new `FileDateFormatterTests` (fixed `now` + UTC calendar, no clock/TZ
  flakiness); all unit tests green; UI tests green in isolation. Verified on screen.
- **Narrow-panel handling (iterated in review with the user):** with sidebar +
  two panels (+ preview), panels got too narrow and Size/Date were pushed
  off-screen. Final design (after trying responsive column-hiding, which the user
  rejected — he wanted nothing hidden):
  - **Name column** starts compact (210px, ~25% smaller) and the user's
    drag-resize sticks; `.lastColumnOnlyAutoresizingStyle` so only Date takes up
    slack (no trailing gap), Name is left alone. Name truncates with the full name
    in a tooltip.
  - **Horizontal scroll** (`hasHorizontalScroller`) so narrow panels scroll to
    reach Size/Date rather than hiding them; columns stay user-resizable/reorderable.
    A folder load resets the scroll to the left (Name-first) via `syncContents`.
  - **Window layout:** a real `NSWindow.contentMinSize` that tracks the open
    regions (`WindowMinWidth` accessor) — the window can't shrink below what fits
    (sidebar always visible, nothing clipped), and **opening the preview compresses
    the panels** within the current window (panel min 180) rather than growing it;
    it only grows when panels would otherwise fall below 180. Default 1280×720.
  - **Toolbar background made visible** (`.toolbarBackground(.visible,
    for: .windowToolbar)`) so the panel divider no longer bleeds up through the
    title-bar area.
- Out of scope (per spec): charts/timelines/date-section grouping — no summary
  surface in a file manager.

### Issue 11 outcome (2026-06-24) — Inline single-file rename (PR pending)
Finder-style in-place rename, reusing the issue-04/07 `RenameOperation` (one
undoable step). Decisions made with the user:
- **Triggers:** **⌘R** on a single selection (2+ still opens the batch sheet) **and
  slow-click** (click an already-selected row's name). **Return stays "open"** — the
  user kept the issue-09 behaviour rather than Finder's Return=rename.
- Commit on Return / click-away; **Escape** cancels; base name pre-selected so the
  extension is preserved; **collision → beep + revert** (case-only self-rename
  allowed, mirroring issue 07's volume-aware guard).
- `PanelModel.inlineRenameRequest` token + `WorkspaceModel.renameInline(_:to:)`;
  new `onRename`/`renameRequest` threaded through `FileListView`.

**Hard-won AppKit lesson (don't rediscover):** making the name cell's `NSTextField`
editable wrecked the table's normal behaviour — clicks stole focus (keyboard
shortcuts passed through), right-clicks hit the field instead of the row menu, and
every file name flipped from `AXStaticText` to `AXTextField` (broke all 9 UI tests'
`staticTexts[name]` lookups + VoiceOver). Fix that keeps the cell behaving like a
plain label: `EditableNameTextField` that (a) overrides `accessibilityRole()` →
`.staticText` unless actively editing, and (b) overrides `hitTest` → `nil` unless
editing, so it's transparent to the mouse. Editing is driven **programmatically**
via `editColumn` (⌘R) or a custom slow-click in `FileTableView.mouseDown` (guards
double-click=open and drag). The field is flipped editable only for the duration of
the edit. Result: selection, right-click menus, AX, and all tests behave as before.
- Tests: 47 green (38 unit + 9 UI). `testRenameRefreshesBothPanelsOnSameDir`
  rewritten to drive the inline editor (and still proves both panels refresh).

### Issue 01 outcome (2026-06-17)
Tracer bullet works: app launches to one Panel listing a real directory
(name/size/date) via SwiftUI `Table`. Two ADR seams shipped:
- **ADR 0003** `PanelSource` protocol + `LocalDirectorySource` (loads off-main
  via `Task.detached`, prefetches resource keys).
- **ADR 0002** `FileListView` protocol + `TableFileListView`, swappable via the
  `PanelFileList` typealias.
Verified by screenshot on home dir and on a 50k-file folder (loaded off-thread,
virtualized render, no block/crash). Subjective scroll-smoothness left for human.

Open polish (non-blocking): empty files render "Zero KB"; folders show no size
by design.

### Issue 02 outcome (2026-06-17)
Single Panel now navigable: enter dir (Return / double-click), up (⌘↑ / button),
column-header sort (toggle reverses), Hidden checkbox, type-ahead Filter field.
`PanelModel` v2 owns `directory: URL` and rebuilds `LocalDirectorySource` per
load (cancels in-flight task on rapid nav). `FileListView` protocol widened to
carry selection + sortOrder bindings + `onActivate` (still impl-agnostic, ADR
0002). `FileItem` gained non-optional `sizeForSort`/`dateForSort` (Optional isn't
Comparable). Verified interactively by user.

### Issue 03 outcome (2026-06-17)
`WorkspaceView` renders two Panels side by side, each owning its own `PanelModel`
(-> independent dir, nav, selection). Active Panel tracked via `@FocusState`,
shown with an accent border; Tab flips active, clicking a panel activates it. Nav
keys gated by `isActive`. `PanelView` no longer owns its model (parent owns).
`URL.startDirectory` moved to WorkspaceView. Window widened to 1100x620.
Verified interactively by user (Tab + click focus, independent nav, per-panel
selection).

### Architecture review (2026-06-26) — deepening candidates; #1 shipped (branch `improve-codebase-architecture`)

`/improve-codebase-architecture` surfaced **5 deepening candidates** (the HTML
report was temp-only; this is the durable record).

**Shipped — candidate #1 (Strong): one settle hook for Panel refresh.** Collapsed 9
per-call refresh closures into `OperationCoordinator.onOperationSettled` (wired once
in `WorkspaceModel.init`; undo/redo inherit it); removed the dead `refresh:`
parameter strand (`PendingWrite.refresh` + the param threaded through
`write`/`runWrite`/`resolvePendingWrite`). New `OperationCoordinatorTests` — the
refresh wiring had no test surface before. Commit `907d9c4`. ADR-0004 untouched.

**Data-loss fix found during its QA.** Pasting a file into its own folder + Overwrite
resolved `dest == src`; `CopyOperation` removed the source then failed to re-copy,
destroying it (overwrites aren't undoable, ADR-0004). `MoveOperation` already guarded
the same-dir no-op; `CopyOperation` didn't. Guard added; `.rename` (Duplicate)
unaffected. `CopyOverwriteTests` covers the basic case, a symlink-resolved source,
and the real `NSPasteboard` round-trip (the reported path). Commit `60a8a3f`,
user-verified live. Learnings in `context/transferable-learnings.md` §12–§13.

**Shipped — candidate #3 (Worth exploring): inject the Panel Source factory.**
`PanelModel.reload()` hard-constructed `LocalDirectorySource`, so the ADR-0003
`PanelSource` protocol was a one-adapter hypothetical seam. Injected a
`makeSource: (URL, Bool) -> PanelSource` factory (default builds the real source —
every caller unchanged; a factory, not an instance, since the source rebuilds per
load as directory/showHidden change). `FakeSource` in `PanelSourceInjectionTests`
is the second adapter that makes the seam real: drives a whole `PanelModel` (load
state machine, accessDenied, filter) with no filesystem. Commit `4b2fad5`. No
behavior change. Scope: navigation stays URL-coupled, so true non-local sources
(tag/search) still need a separate generalization.

**Shipped — candidate #2 (command routing vs UI-state), narrow cut.** Initially
skipped (the naive "extract a ViewState bag" fails the deletion test — a state bag
has no behavior → a *shallow* module). Revisited and built the one defensible cut: the
four independent modal flags (`pendingWrite`/`renaming`/`tagging`/`goingToFolder`)
collapsed into one `presentedSheet: Sheet?` enum — one value ⇒ exactly one modal, the
invariant now structural (previously nothing stopped two modals). Computed
`pendingCollision`/`sheetItem` keep the collision `confirmationDialog` + a single
`.sheet(item:)`. Commit `060baf5`, all four modals user-verified live. (The broader
"router vs state" split stays a mirage — not done.)

**Shipped — candidate #4 (Worth exploring): extract `SelectionEchoGuard`.** The
AppKit↔SwiftUI selection echo rule was two ad-hoc Coordinator fields
(`isSyncingSelection`, `lastPublished`) + two guards ~120 lines apart — the logic
behind selection thrash, untestable without a live `NSTableView`. Pulled into a pure
`SelectionEchoGuard` (echo suppression + reentrancy); Coordinator keeps only the
imperative table I/O. `SelectionEchoGuardTests` covers both directions. Commit
`901b463`, user-verified live (multi-select hold, nav-clears). Note: report said "4
fields" but only 2 were the echo-guard; a generic `TwoWayBinding` would be a
one-adapter hypothetical seam, so it stays selection-specific.

**Shipped — candidate #5 (Speculative): extract pure `compileVisible`.** Lifted
`PanelModel.recomputeVisible`'s base→filter→sort pipeline into a pure static
`compileVisible(loaded:searchResults:isSearching:filter:tagName:sort:)`. `applyFilters`
was already pure+tested (`PanelFilterTests`); this also pins base-set selection (search
vs loaded) + sort. `VisibleItemsTests`. Commit `c3cc180`, no behavior change.

**All 5 deepening candidates now addressed** (#1, #3, #4 shipped; #2 narrow cut
shipped; #5 shipped). 70 tests green. Three bugs/features surfaced during QA: issue
#25 (double-click selection), #26 (tag filter menu dot grey), #27 (tags column).

### Issue 28 outcome (2026-06-27) — Keyboard command expansion + Open-With favorites (branch `feat/28-keyboard-commands`, off `improve-codebase-architecture`)
Marta-informed keyboard pass + a customizable Open-With menu, user-verified end to
end ("all work perfectly"). Spec: `.scratch/diptychon-mvp/issues/28-keyboard-command-expansion.md`.
- **10 new Mac-native commands**, each one `Keymap.default` row + one `perform()` case
  (the data-driven `Keymap` from issue 04 paid off): ⌘⇧. show hidden · ⌘A / ⎋ / ⌘⇧I
  select all/none/invert · ⌘F focus Filter · ⇧⌘R reveal in Finder · ⌥⌘C copy path(s) ·
  ⌘I Get Info (Finder AppleScript; one-time automation consent) · ⌘↩ Open With ·
  ⇧⌥⌘→/← move selection into the inactive panel (undoable).
- **Mac-native over Marta's F-keys** (deliberate — keeps the app's existing identity).
  Two boundary-crossers needed real plumbing: ⌘F focus goes through an observed token
  (`filterFocusRequest`) since the `NSEvent` monitor can't set SwiftUI focus; ⌘↩ uses a
  standalone `OpenWithController` because the table's row-context menu can't be reached
  from a global chord. ⎋ yields to an open sheet/dialog (`handleKeyDown` guard) rather
  than swallowing it.
- **Open-With favorites:** favorite apps pin to the top of the ⌘↩ menu, managed in-menu
  (Add to Favorites… / Remove submenu), persisted to UserDefaults `openWithFavorites`.
  Pure `FavoriteApps` helper (mirrors `PinnedFolders`) + 6 unit tests. **76 tests green.**
- **Process note (reinforces issue-21):** new `.swift` files are auto-globbed by
  XcodeGen from `project.yml` — `xcodegen generate`, never hand-edit the gitignored
  `project.pbxproj`. Verified the build/tests through the regenerated project.
- Branch is stacked on `improve-codebase-architecture` (the feature depends on its
  `presentedSheet` / `SelectionEchoGuard` work — it does not apply to `main`).

### Issue 12 decision (2026-06-27) — Custom tag color registration: wontfix (ADR 0005)
Investigated read-only and **deliberately not built** — resolved via the issue's own
AC3 fallback (documented rationale instead of a fragile write). The custom-tag→color
mapping lives in an undocumented, Finder-owned, version-sensitive store
(`SyncedPreferences` plist wasn't even present on the dev machine); forging it risks
desyncing the user's real tags for a cosmetic, different-app gain. The file-level tag
xattr already round-trips (name + color) and the 7 built-in colors are unaffected.
No Finder mutation, no code. Decision + rationale: `docs/adr/0005-…md` and
`.scratch/diptychon-mvp/issues/12-…md`. Lesson: transferable-learnings §4 (restraint).
**Not an open thread.**
