# 26 — Tag filter menu dot shows grey, not the tag's color

Status: ready-for-agent — found in QA 2026-06-27

## Parent

`.scratch/diptychon-mvp/PRD.md` (relates to issue 08, Finder tags)

## What to build

In the Panel header's tag-filter menu (the tag icon → dropdown), each tag is listed
with a colored dot. The dot renders **grey** even when the tag has a color: a file
tagged **Green** shows a correct green dot on its row, but the same tag in the filter
menu shows grey while labelled "Green" (see QA screenshot 2026-06-27).

The two color paths disagree:
- **Row dot** (correct): `FinderTagDotsView` in `NSTableViewFileList` renders the
  tag's color green.
- **Menu dot** (wrong): the filter menu uses
  `Color(nsColor: tag.color.nsColor ?? .secondaryLabelColor)` — it falls back to grey
  whenever `tag.color.nsColor` is nil.

Make the menu swatch match the row dot. Confirm the root cause first — likely one of:
1. `PanelModel.availableTags` dedups tags by **name** and keeps the first seen, so a
   same-named tag with `.none` color (e.g. a custom "Green" with no Finder color
   index) shadows the real built-in green; or
2. a built-in `FinderTagColor` case is unmapped in `FinderTagColor.nsColor` (so the
   row's render path and `nsColor` disagree).

Fix the actual source of the disagreement, not just the menu's fallback.

## Acceptance criteria

- [ ] In the tag-filter menu, a tag's dot matches the color shown on the file rows
      (a Green tag shows green in both places).
- [ ] All built-in Finder colors render correctly in the menu.
- [ ] A genuinely color-less tag (`.none`) still renders a neutral/grey dot — the
      fallback is correct only for that case.
- [ ] Row dot and menu dot share one color-mapping source of truth (no second,
      divergent mapping).

## Blocked by

None — can start immediately.
