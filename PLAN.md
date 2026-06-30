# PLAN

_No active task._

Last task: **issue 29 (Type column in the file list)** — done, user-verified, on branch
`feat/29-kind-column` (not pushed). Refined live with the PM beyond the original brief:
- Column **Name · Type · Date · Size**; "Date Modified" → "Date"; narrower widths.
- **Type** shows the short form (uppercased file extension: PDF/PNG/TXT), not the full
  UTType description; Folder → "Folder"; extension-less → "—".
- **Name flexes** (`.firstColumnOnlyAutoresizingStyle`); metadata columns fixed/grouped.
- **Default sort = Date, newest first.** `FileItem.kind` populated by both Local and
  Staging sources. 104 unit tests green.

Open issues remaining: **#18** operation history / time-travel undo (large, differentiation
bet) and **#22** performance baseline measurements (evidence, no UI). See tracker Status table.
