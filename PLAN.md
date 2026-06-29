# PLAN — Issue 26 follow-up: right-align row tag dots

Branch: `fix/26-tag-filter-menu-dot-grey` (off `main`).

## Done this session
Issue 26 (tag-filter menu dot grey) — **fixed + committed + user-verified.** Render
fix (`FinderTagColor.menuSwatch`, non-template NSImage) + data fix
(`FinderTag.distinctByName`). 82 unit tests green. Recovered from two stashes (one
mislabeled "issue-29"); both dropped after the commit.

## Active task — dot positioning (user request 2026-06-30)
Right now the **row** tag dots trail the filename, so they sit at different x-positions
per row (see user screenshot, blue line). Want: all dots **right-aligned into one
vertical column** at the right edge of the Name column — under the Name sort arrow —
with clear space from the names, stacked in a clean line.

- Lives in `FinderTagDotsView` placement within the Name cell, `NSTableViewFileList.swift`.
- Likely approach: pin the dots stack to the **trailing** edge of the name cell (fixed
  right inset) instead of flowing right after the text; verify with the 3-file repro
  in `/private/tmp/diptychon-issue26-repro` (recreate via scratchpad script — Desktop
  normalizes tag colors, use /tmp).
- Open question: behavior when the name is long enough to reach the dot column
  (truncate the name before the dots so they stay aligned).
- Decide: fold into issue 26's branch as a polish commit, or a new issue (relates to
  issue 17 file-list polish). Lean: same branch, separate commit.
