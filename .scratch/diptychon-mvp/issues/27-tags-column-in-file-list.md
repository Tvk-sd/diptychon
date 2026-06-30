# 27 — Sort the file list by tag

Status: wontfix — superseded by issue 26 + tag filter (decision 2026-06-30)

## Parent

`.scratch/diptychon-mvp/PRD.md` (relates to issue 08 Finder tags; 26 tag dots)

## Decision (2026-06-30) — not building this

**Resolved: wontfix.** Triaged from a full "Tags column" → rescoped to sort-by-tag →
dropped entirely. Issue 26 already gave tags their visual home (row dots
right-aligned under the Name arrow, colors fixed), and the **tag-filter menu**
(issue 08/26) already does the real job — focus on one tag. The only remaining
candidate, **sort by tag**, is a weaker version of that same need: filtering groups a
tag's files better than sorting does, so sort-by-tag adds a code path + a palette/menu
command for near-zero gain over what exists. A permanent names column was already
rejected as visual weight against the "less than Finder / lightweight" identity
(transferable-learnings §4).

Net: nothing to build. The scannable dots (26) + filter (08/26) cover tags in the
list. Revisit only if a concrete, recurring need to *order* files by tag (distinct
from filtering) actually shows up in use. **Not an open thread.**

---

_Rescope/triage analysis retained below for the record; superseded by the decision above._

## Triage note (2026-06-30) — rescoped from a full Tags column

Originally this issue was a dedicated **Tags column** (dots + names, sortable,
resizable). Issue 26's follow-up overtook most of that rationale:
- **Scannable** — row tag dots are now right-aligned in a clean column under the
  Name sort arrow (no longer "unaligned dots trailing the name").
- **Focus on one tag** — the tag-filter menu (issue 08/26) already does "show only
  my Red files."
- **Color** — fixed in issue 26.

What remained from the old scope was (a) tag **names** always visible in a column,
and (b) **sort by tag**. We dropped (a): a permanent names column adds visual weight
for files with 0–2 tags and cuts against the "less than Finder / lightweight"
identity (transferable-learnings §4); names already surface in the row dot's tooltip
on demand. We kept (b) as the one genuine capability gap — **this issue is now just
sort-by-tag.** Note it partially overlaps the existing tag *filter* (filter = focus
on one tag; sort = group all tags together); ship only if grouping-by-tag is wanted
beyond filtering.

## What to build

Let the user **sort the active panel's files by their tags**, reusing the existing
`sortOrder` / `KeyPathComparator<FileItem>` infrastructure — **without** adding a
visible Tags column.

- **Sort key:** the file's tags joined as a stable string (first-seen order, names
  lowercased); untagged files sort **last** (a tagged-vs-untagged split is the main
  point). Toggle ascending/descending like the other sort keys.
- **Trigger (no column header exists to click):** add a **"Sort by Tag"** command to
  the ⌘K command palette (issue 19) and the View/sort menu, toggling asc/desc and
  reflecting the active sort the same way the column sorts do. *Recommended over a
  one-off narrow column, which reintroduces the visual weight we just removed.*
- Keep it a pure, testable comparator (mirrors `RenameRule` / `distinctByName`):
  the tag-sort-key derivation unit-tests with no UI.

## Acceptance criteria

- [ ] A "Sort by Tag" action (palette + menu) sorts the active panel by tag.
- [ ] Untagged files group together at the bottom (ascending); toggling reverses.
- [ ] Tag sort key is derived by a pure function with unit tests (stable order,
      untagged-last, case-insensitive).
- [ ] No new always-visible column; row dots (issue 26) are unchanged.
- [ ] Sorting integrates with the existing `sortOrder` flow (no separate code path).

## Open question for the implementer

If palette/menu-triggered sort feels hidden in testing, the fallback is a **narrow,
non-resizable Tags column** whose only job is a clickable sort header (dots already
render in the Name cell). Prefer the palette/menu first; escalate only if needed.

## Blocked by

None. Shares the tag-color source of truth with issue 26 (already merged).
