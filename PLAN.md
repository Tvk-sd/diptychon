# PLAN

_No active task._

Last task: **issue 26 (tag-filter menu dot grey) + row-dot alignment follow-up** —
done, user-verified, committed on `fix/26-tag-filter-menu-dot-grey`. Render fix
(`FinderTagColor.menuSwatch`) + data fix (`FinderTag.distinctByName`, 82 tests green) +
row tag dots right-aligned into one column under the Name sort arrow (`NameCellView`
constraints, trailing inset +2, tuned live). Branch is off `main`, not yet PR'd.

Open candidates (see `PROJECT-TRACKER.md`): #27 tags column in file list (shares the
tag-color source of truth — good next), the new #29 Kind/Type column (issue file
exists, no code yet), and the #18/#20/#22 backlog.
