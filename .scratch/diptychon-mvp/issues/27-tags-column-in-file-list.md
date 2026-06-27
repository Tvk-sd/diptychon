# 27 — Tags column in the file list

Status: ready-for-agent — requested in QA 2026-06-27

## Parent

`.scratch/diptychon-mvp/PRD.md` (relates to issue 08, Finder tags; issue 17, file-list polish)

## What to build

Add a **Tags** column to the file-list `Table` (`NSTableViewFileList`), alongside
Name / Size / Date Modified. Today tags only appear as small color dots trailing the
name; a dedicated column makes them scannable and sortable.

Default treatment (chosen here to keep this AFK; change in review if wanted):
- Show the file's tags as **color dots + names** in the cell (reuse the existing
  `FinderTagDotsView` rendering for the dots so colors stay consistent — see issue 26).
- Untagged files render an empty cell.
- **Sort** by the file's tags joined as a stable string (first-seen order, names
  lowercased); untagged sort last. Header click toggles ascending/descending like the
  other columns.
- Column is user-resizable/reorderable and starts at a modest width, consistent with
  issue 17's column behavior.

## Acceptance criteria

- [ ] A "Tags" column appears in the file list with dots + names per file.
- [ ] Dot colors match the file's tag colors (and the fixed menu swatch, issue 26).
- [ ] Clicking the Tags header sorts by tags (toggle asc/desc); untagged rows group
      together.
- [ ] Column is resizable/reorderable and doesn't break the existing Name-first
      scroll behavior (issue 17).
- [ ] Untagged files show an empty Tags cell, no placeholder noise.

## Blocked by

None — can start immediately. (Shares the tag-color source of truth with issue 26;
land #26 first if convenient so both use one mapping, but not a hard dependency.)
