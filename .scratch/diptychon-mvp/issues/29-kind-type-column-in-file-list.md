# 29 — Kind (type) column in the file list

Status: ✅ done — implemented + user-verified 2026-06-30 (branch `feat/29-kind-column`)

## Parent

`.scratch/diptychon-mvp/PRD.md` (relates to issue 17, file-list polish; issue 27, tags column)

## What to build

Add a **Kind** column to the file-list `Table` (`NSTableViewFileList`), alongside
Name / Size / Date Modified. It shows each row's file type the way Finder's "Kind"
column does — e.g. "Folder", "PNG image", "PDF Document", "Plain Text Document".

Today the panel shows the type only implicitly via the leading icon; a Kind column
makes type scannable and sortable (group all images, all folders, etc.).

## Default treatment (chosen to keep this AFK; change in review if wanted)

- **Source of truth:** derive a human-readable kind from the file's `UTType`
  (`UTType(filenameExtension:)` / resource value `.contentTypeKey`, then
  `.localizedDescription`). Folders show "Folder". Unknown/extension-less files
  fall back to "Document" (or the raw UTI description if available).
- **Where the value lives:** add a stored `kind: String` to `FileItem`, populated by
  `LocalDirectorySource` at list time (next to `isDirectory` / `size`). This keeps the
  cell render cheap and makes the column sortable through the existing
  string-keyed sort path (see below). `kind` joins `Hashable` equality so a type
  change marks the row changed on reload, consistent with `tags`/`size`.
- **Cell:** plain secondary-colored text, same style as the Size/Date cells.
- **Sort:** wire a new `Column.kind` sortKey to `KeyPathComparator(\FileItem.kind)`
  in `sortDescriptorsDidChange` (mirror the `size`/`date` cases). Header click
  toggles ascending/descending like the other columns.
- **Column:** user-resizable/reorderable, modest starting width (~120), consistent
  with issue 17's column behavior. Place it at the **right end** (after Date Modified)
  by default.

## Implementation pointers

- `Sources/Diptychon/Panel/NSTableViewFileList.swift`
  - `addColumn(table, id: Column.kind, title: "Kind", width: 120, sortKey: "kind")`,
    added **last** so it's the rightmost column
  - add `kind` to the `Column` enum
  - note: the table uses `.lastColumnOnlyAutoresizingStyle`, so once Kind is last it
    becomes the column that absorbs width on window resize (previously Date). Keep this
    if acceptable, or set a fixed/smaller resizing behavior so Name stays the flexible
    one — confirm in review.
  - render in `tableView(_:viewFor:row:)` under `case Column.kind`
  - add `case Column.kind:` to `sortDescriptorsDidChange` and `descriptorFor`
- `Sources/Diptychon/Panel/FileItem.swift` — add `var kind: String = ""`
- `Sources/Diptychon/Panel/LocalDirectorySource.swift` — populate `kind`
- `FileListView.swift` (`TableFileListView`, the SwiftUI reference impl) — optional:
  add the matching `TableColumn("Kind", value: \.kind)` to keep it in parity.

## Acceptance criteria

- [x] A type column appears in the file list showing each row's file type.
- [x] Folders read "Folder"; files show their type.
- [x] Extension-less / unknown files show a sensible fallback (dash), no crash, no blank noise.
- [x] Clicking the header sorts by type (toggle asc/desc).
- [x] Column is resizable/reorderable and doesn't break Name-first scroll behavior (issue 17).

## Outcome (2026-06-30) — adjusted live with the PM

Built per the brief, then refined in review:
- **Header label "Type"** (not "Kind"); **short value** = uppercased file extension
  ("PDF", "PNG", "TXT") rather than the full UTType description ("PDF document"). Folder
  → "Folder"; extension-less → content-type's canonical extension, else "—".
- **Column order Name · Type · Date · Size**; "Date Modified" → "Date"; narrower widths
  (180 / 100 / 140 / 70).
- **Name is the flexible column** (`.firstColumnOnlyAutoresizingStyle`) so the metadata
  columns stay grouped at fixed widths — reverses issue 17's "Date absorbs slack."
- **Default sort = Date, newest first** (`KeyPathComparator(\.dateForSort, .reverse)`).
- `FileItem.kind` populated by `LocalDirectorySource` **and** `StagingSource` (Type shows
  in the staging pane too). 104 unit tests green (`KindColumnTests`).

## Blocked by

None — can start immediately. Independent of issue 27 (Tags column); both add a
column to the same table, so land whichever is convenient first and rebase the other.
