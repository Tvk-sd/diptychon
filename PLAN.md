# PLAN — Issue 08: Finder tags

Real Apple Finder tags, round-trip compatible with Finder. Spec:
`.scratch/diptychon-mvp/issues/08-finder-tags.md`. Branch: `feat/08-finder-tags`.

## What I understood
Read/write tags via the `com.apple.metadata:_kMDItemUserTags` extended attribute
(a binary plist of `"name\nColorIndex"` strings, color 0–7). Display color dot +
name on rows, set/remove on the selection (undoable), create new tags + pick from
the system list, and filter the Active Panel by tag. Round-trip fidelity with
Finder is the bar — the app keeps NO parallel tag store (CONTEXT.md → Tag).

## Assumptions (challenge these)
- **Built-in 7 colors first.** The 8 indices (0 none, 1 grey … 7 purple — verify
  order against Finder) are stable and well-documented. Read/write of these is the
  committed scope.
- **Custom-color system-list parity is the RISK, scoped last.** A brand-new tag's
  color shows in Finder's *sidebar* only if registered in Finder's separate system
  tag list (undocumented `com.apple.finder` store). Setting the xattr alone colors
  the file dot but may not register the tag system-wide. If full parity proves
  fragile, we land xattr-correct tags + built-in colors and split exotic
  custom-color registration into a follow-up issue. **Flagging now, not at the end.**
- Sandbox is OFF (ADR 0001) → direct xattr read/write is allowed.
- Tag-set/remove is modeled as one undoable `Operation` (reuses the 04 spine).
- I'll prefer the low-level xattr codec over `URLResourceValues.tagNames` so the
  color index is explicit and matches Finder's on-disk format exactly.

## Approach — vertical slices (tracer-bullet), TDD where logic is pure
1. **Tag model + xattr codec (pure, unit-tested).** `FinderTag { name; color }` +
   encode/decode `[FinderTag]` ↔ the `_kMDItemUserTags` binary-plist payload.
   `DiptychonTests/FinderTagCodecTests`: round-trip a known byte payload; decode a
   real Finder-written sample; handle empty/no-xattr.
2. **Read + display (AC1).** Read tags into `FileItem` (in `LocalDirectorySource`
   via the xattr); render color dot(s) + name in `NSTableViewFileList`. Verify:
   tag a file in Finder → it shows here.
3. **Set / remove (AC2).** `SetTagsOperation` (undoable: revert restores prior
   xattr) on the selection. Verify: set here → shows in Finder; ⌘Z restores.
4. **Filter by tag (AC4).** Extend the Active Panel's visible-items pipeline with a
   tag filter (reuses `recomputeVisible`). Verify: pick a tag → only matching rows.
5. **New tag + system list (AC3) — the risk slice.** UI to create a tag (name +
   color) and pick from existing system tags. Probe how far xattr-only gets us vs.
   needing the Finder system-list write; report and decide scope.

## "Done" = checkable
- A tag set in Diptychon appears in Finder with the **same name + built-in color**,
  and a tag set in Finder appears here (the round-trip, for built-in colors).
- Set/remove is undoable (⌘Z restores the exact prior tag set).
- Active Panel filters to a single chosen tag.
- New unit tests (codec) + a UI test (set tag → row shows the dot) pass via
  `xcodebuild -scheme Diptychon test`.
- Custom-color system-list parity: either done, or explicitly split to a follow-up
  with a written rationale.

## Decisions (2026-06-22)
- **Multi-tag display:** up to 3 color dots, then “+N”.
- **AC3 scope:** built-in 7 colors round-trip solidly + create new tags
  (xattr-correct); custom-color Finder *sidebar* registration → follow-up issue if
  it proves fragile.

## Progress
- [x] Slice 1 — FinderTag model + xattr codec + unit tests (7 tests green)
- [x] Slice 2 — read + display dots (AC1) — verified by screenshot + I/O unit tests
- [x] Slice 3 — set/remove undoable (AC2) — ⌘T picker, SetTagsOperation; unit + UI tests; whole row clickable (verified real mouse)
- [ ] Slice 4 — filter by tag (AC4)
- [ ] Slice 5 — new tag + system list (AC3, risk)
