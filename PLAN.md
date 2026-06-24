# PLAN — Issue 16: Left sidebar (places + pinned folders)

Spec: `.scratch/diptychon-mvp/issues/16-left-sidebar.md`.
Research: `context/sidebar-research.md`, `context/dashboard-research.md`.
Branch: `feat/16-left-sidebar`.

## Resolved open questions
1. **Collapse shortcut → ⌃⌘S** (Control-⌘-S, Apple's standard "Show/Hide Sidebar").
   Keeps the family legible: **⌃⌘S = left sidebar** (Apple convention), **⌥⌘S =
   right file panel** (issue 13), **⇧⌘P = preview** (issue 14). Plus a toolbar
   button (`sidebar.leading`).
2. **Pinning → context-menu first, drag second.** "Add to Sidebar" on a folder's
   right-click menu (reliable, reuses the existing `FileTableView` NSMenu) is the
   committed path; **drag-a-folder-onto-the-sidebar** is added after. Remove a pin
   via its row's context menu / hover affordance (progressive disclosure).
3. **Standard places → fixed list** in v1 (not hideable). Defer hiding to later.

## Layout & defaults
- Order: **`Sidebar | HSplitView(panels) | PreviewPane`** — sidebar outermost-left,
  fixed width ~200.
- `sidebarVisible` defaults **true** (registered default, like `rightPanelVisible`),
  persisted. Toggle = toolbar button + ⌃⌘S.
- Clicking any item → `navigateActive(to:)` (reuse issue 15). Highlight the item
  whose URL matches the Active Panel's directory.

## Architecture
- `WorkspaceModel`:
  - `sidebarVisible: Bool` (registered default true; persisted).
  - `pinnedFolders: [URL]` backed by a `[String]` paths array in `UserDefaults`
    (add/remove/dedup; skip-or-grey ones that no longer exist).
  - `pin(_:)` / `unpin(_:)`; reuse `navigateActive(to:)`.
- `Panel/Sidebar.swift` — `SidebarView(model:)`: **Places** section (static
  standard URLs) + **Pinned** section, section headers + divider (clustering /
  visible grouping). Row = icon + name; click navigates; pinned row has a
  remove action on hover/context-menu.
- `Panel/SidebarPlace.swift` (or inline) — the 5 standard places (Home, Desktop,
  Documents, Downloads, Applications) via `FileManager.url(for:in:)`, with SF icons.
- `WorkspaceView` — prepend the sidebar to the `HStack`; add the toolbar toggle.
- `NSTableViewFileList` context menu — add "Add to Sidebar" for folder rows
  (calls back via a new `onPin: (URL) -> Void` closure, like `onDrop`).
- Persistence helper kept tiny + unit-testable (paths ↔ URLs, dedup, drop-missing).

## Slices
1. **Scaffold + toggle + navigate.** `sidebarVisible` (persisted) + toolbar button
   + ⌃⌘S; `SidebarView` with the Places section (+ empty Pinned section); click a
   place → active panel navigates. Layout wired. (Pinned shows but is empty.)
2. **Pinning via context menu.** `pinnedFolders` persistence + `pin/unpin`;
   "Add to Sidebar" in the folder context menu; Pinned section lists them, click
   navigates, remove via context menu. Unit test the persistence/dedup; UI test
   add→appears→click navigates.
3. **Drag-to-pin + resilience.** Drop a folder onto the sidebar to pin; missing
   pinned folders degrade gracefully (greyed/skipped, no crash).

## "Done" = checkable
- Sidebar shows Places + Pinned with clear grouping; ⌃⌘S / toolbar toggles it;
  state persists.
- Clicking a place or a pin navigates the Active Panel there.
- "Add to Sidebar" (and drag-in) pins a folder; removing un-pins; pins persist
  across launches; a deleted pinned folder doesn't crash.
- Unit tests (pin persistence) + UI tests (toggle, navigate, add→navigate) green;
  verified on-screen.

## Risks
- Three left-side toggles now (sidebar/right-panel/preview) — keep toolbar icons +
  shortcuts distinct (icon set: `sidebar.leading`, `rectangle.split.2x1`,
  `sidebar.right`).
- Window gets busy at 1100px with sidebar + 2 panels + preview — sidebar is
  collapsible and ~200px; fine. (Resizable sidebar = future.)

## Progress
- [x] Slice 1 — scaffold + toggle (⌃⌘S) + Places navigate
  - `WorkspaceModel.sidebarVisible` (registered default true, persisted) +
    `navigateActive(to url:)`. `SidebarView`/`SidebarPlace` (Places: Home, Desktop,
    Documents, Downloads, Applications; empty Pinned). Layout `Sidebar | HSplitView
    | Preview`; toolbar `sidebar.leading` toggle (⌃⌘S). Mouse active-panel boundary
    now accounts for sidebar + preview widths. UI test `testSidebarToggleAndNavigate`
    (navigates to /Applications to avoid the Home/Desktop TCC-prompt hang). Verified
    on screen.
- [x] Slice 2 — pinning via context menu (persist) + remove
  - `PinnedFolders` pure helper (add/remove/dedup by standardized path, encode/
    decode paths) + 6 unit tests. `WorkspaceModel.pinnedFolders` ([URL] backed by
    [String] in UserDefaults) + `pin`/`unpin`. "Add to Sidebar" on a single-folder
    context menu (new `onPin` closure threaded NSTableViewFileList → PanelView →
    WorkspaceView; added to the FileListView protocol). Sidebar Pinned section
    lists pins (a11y id `pinned:<name>`), click navigates, "Remove from Sidebar"
    context menu. UI test `testPinFolderAppearsNavigatesAndRemoves`.
- [ ] Slice 3 — drag-to-pin + missing-folder resilience
