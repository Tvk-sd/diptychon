# 17 — File-list polish (data-driven display)

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Apply the "data drives the form" principle (`context/dashboard-research.md`,
Principle 1) to the panel file list so each column's presentation matches its data
type — reducing visual noise and making rows faster to scan. A polish pass, to do
once higher-value features have landed.

## Candidate improvements (pick the high-value ones)

- **Numeric Size → right-aligned**, so digits line up by place value for easy
  comparison (today it's left-aligned text).
- **Dates → friendlier formatting / grouping** — e.g. relative ("Today", "Yesterday")
  or date-section grouping, instead of one long timestamp column to scan.
- **Categorical bits as chips/icons, not text** — tags already render as dots
  (issue 08); extend the same idea to any other categorical column we add (e.g.
  kind/badge) rather than plain words.
- **Truncation breathing room** — confirm long names truncate cleanly so other
  columns keep their space (largely done; verify under narrow panels).
- **Alignment consistency** — text columns left, numeric right, with consistent
  padding.

## Acceptance criteria

- [ ] The Size column is right-aligned and visually comparable down the column.
- [ ] Dates are presented in a scan-friendly way (relative and/or grouped), not a
      single dense timestamp string.
- [ ] Column alignment/padding is consistent (text left, numeric right).
- [ ] No regression to sorting, selection, or the existing tag dots.

## Notes

- The list is the AppKit `NSTableViewFileList` (ADR 0002) — alignment is per-cell
  (`NSTextField.alignment`); keep changes surgical.
- Keep it lightweight: this is presentation polish, not new data. Charts/timelines
  from the research are **out of scope** (no summary surface in a file manager).

## Blocked by

- `01-panel-lists-local-folder`
