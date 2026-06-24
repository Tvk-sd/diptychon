# 16 — Left sidebar (places + pinned folders)

Status: done — branch `feat/16-left-sidebar` (3 slices, user-verified); see PROJECT-TRACKER issue 16 outcome

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A clean, collapsible **left sidebar** for fast navigation — Notion-style, and
deliberately **lighter than Finder's** (no iCloud/Locations/Recents/Tags sprawl
in v1). Research + principles: `context/sidebar-research.md` and
`context/dashboard-research.md` (clustering, visible grouping, progressive
disclosure).

Two sections:
1. **Places** — the standard spots: Home, Desktop, Documents, Downloads,
   Applications (each with an icon).
2. **Pinned** — folders the user adds themselves, and can remove.

Clicking any item navigates the **Active Panel** there (consistent with Go to
Folder, issue 15).

## Notes / design (apply the research)

- **Clustering + visible grouping:** two sections with headers + spacing/divider;
  Places vs. Pinned are distinct clusters.
- **Progressive disclosure:** the remove-pin control appears on hover / in a
  context menu, not as permanent chrome.
- **Collapse:** a toolbar toggle (e.g. `sidebar.leading`) + keyboard shortcut,
  persisted across launches — same pattern as the preview pane (issue 14) and
  right-panel toggle (issue 13). Consider `⌃⌘S` or similar (decide in plan;
  avoid clashing with existing chords).
- **Pinning:** drag a folder onto the sidebar to pin it (Notion-like), and/or a
  context-menu "Add to Sidebar" on a folder row. Persist pinned paths in
  `UserDefaults`. Remove via hover affordance / context menu.
- **Layout:** sits left of the panels (outermost), so the order is
  `Sidebar | HSplitView(panels) | PreviewPane`. Give it a sensible fixed/min width.
- **Model:** `WorkspaceModel` owns `sidebarVisible` (persisted) + `pinnedFolders:
  [URL]` (persisted); reuse `navigateActive(to:)` from issue 15. `PathInput`-style
  validation for pinned paths that no longer exist (skip / show greyed).
- Keep `PanelSource` (ADR 0003) in mind, but v1 items are just local directories.

## Acceptance criteria

- [ ] A left sidebar shows a **Places** section (Home, Desktop, Documents,
      Downloads, Applications) and a **Pinned** section, with clear grouping.
- [ ] Clicking a sidebar item navigates the Active Panel to that folder.
- [ ] The user can pin a folder (drag-in and/or "Add to Sidebar") and remove a
      pin; pinned folders persist across launches.
- [ ] The sidebar can be collapsed/expanded via a toolbar button **and** a
      keyboard shortcut; the state persists.
- [ ] Visual style stays clean and lighter than Finder (no Recents/Tags/iCloud in
      v1); a missing pinned folder degrades gracefully (no crash).

## Out of scope (future sections)

- Recents, Tags, iCloud/Locations — add as new sections once the frame exists.

## Blocked by

- `03-dual-panels-focus`

## Related

- `15-path-bar-go-to-folder` (shares `navigateActive`)
- `13-panel-resize-and-toggle` / `14-inline-preview-pane` (toggle + layout patterns)
