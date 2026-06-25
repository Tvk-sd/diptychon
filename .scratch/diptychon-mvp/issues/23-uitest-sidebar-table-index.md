# 23 — UI tests: fragile table indexing breaks when the sidebar is visible

Status: ready-for-agent — found while fixing the issue-21 breadcrumb runaway

## Parent

`.scratch/diptychon-mvp/PRD.md`

## Problem

The three UI tests that launch with `-sidebarVisible YES` —
`testPinFolderAppearsNavigatesAndRemoves`, `testSidebarToggleAndNavigate`,
`testMissingPinnedFolderDegradesGracefully` — locate the left file panel via
`app.tables.element(boundBy: 0)`. That assumption is wrong when the sidebar is
visible: the sidebar `List` (`SidebarView`) also surfaces as a `table` in the
accessibility tree on the current macOS (26.5), so `boundBy: 0` resolves to the
**sidebar**, not the left file panel. The first assertion then times out, e.g.
`testPinFolder` fails at line 282 (`leftTable.staticTexts[folderName]
.waitForExistence(timeout: 10)`).

This is a **test-harness fragility, not an app bug** — confirmed deterministic
(survives `defaults delete com.diptychon.app`), and unrelated to the issue-21
breadcrumb runaway (fixed separately in `feat/21-unified-top-bar`). The tests with
the sidebar hidden (`boundBy: 0/1` = the two panels) are unaffected.

## What to build

Make the panel-table lookup robust instead of positional:

- Give each file-list table a stable **accessibility identifier** (e.g.
  `panel-left` / `panel-right`) in `NSTableViewFileList` / `PanelView` (pass the
  side down so the id is deterministic).
- Update the sidebar-visible tests to target `app.tables["panel-left"]` (and the
  sidebar via its existing `accessibilityIdentifier("sidebar")`) instead of
  `boundBy:` indices.
- Optionally audit the other UI tests for the same positional assumption.

## Acceptance criteria

- [ ] Panel file-list tables expose stable a11y identifiers for left/right.
- [ ] The three sidebar-visible UI tests pass reliably (run in isolation, after
      `pkill -9 -f Diptychon`), targeting tables by identifier, not index.
- [ ] No remaining `app.tables.element(boundBy:)` assumption that breaks when the
      sidebar is visible.

## Notes

Diagnosed 2026-06-25. Verifying the fix needs a UI-test run (XCUITest takes over the
pointer ~1 min per the automation notes in `context/automations-learnings.md`).
