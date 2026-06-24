# PLAN — Issue 15: Path bar / Go to Folder

Spec: `.scratch/diptychon-mvp/issues/15-path-bar-go-to-folder.md`.
Branch: `feat/15-path-bar`.

## What I understood
A way to navigate the Active Panel to an arbitrary directory (today only
double-click-in + go-up). Two parts: a **Go to Folder…** entry (type/paste a path,
⇧⌘G) and a **clickable path control** in the header that reflects the current
directory and lets you jump to an ancestor.

## Approach
- **Path resolution (pure, testable):** `PathInput.resolve(_:) -> URL?` — expand
  `~`, standardize, return the URL only if it exists and is a directory; else nil.
  Unit-tested (tilde, missing, file-not-dir, trailing slash).
- **Go to Folder sheet (⇧⌘G):** `AppAction.goToFolder` + `Keymap` (⇧⌘G) →
  `WorkspaceModel.goingToFolder` (sheet). `GoToFolderSheet` pre-filled with the
  Active Panel's path; Return/Go validates via `PathInput.resolve` → navigate, or
  shows an inline "Not a folder / doesn't exist" error (no crash).
- **Header path control (breadcrumb-as-menu):** replace the static `Text(title)`
  with a `Menu` whose label is the path; items = ancestor directories (each jumps
  there) + a divider + "Go to Folder…". Compact — fits the tight header, gives
  click-to-navigate (ancestors) and editing (the sheet).
- **Plumbing:** `PanelModel.go(to url:)` sets `directory` + `afterNavigation()`;
  `WorkspaceModel.navigateActive(to:)` / `navigateActive(toPath:)`.

## "Done" = checkable
- ⇧⌘G (and clicking the path → "Go to Folder…") opens an entry; typing a valid
  path (incl. `~/…`) jumps the Active Panel there.
- An invalid / non-directory path shows a clear error, no crash, panel unchanged.
- The header path menu lists ancestors; picking one navigates there.
- `PathInput` unit tests + build green; verified on-screen (e.g. reach ~/Library).

## Risks / notes
- Keep ⇧⌘G out of the NSEvent keymap conflicts — it's a new chord; the monitor
  passes unknown chords through, and we add it to `Keymap` so it's handled there
  consistently (route → set `goingToFolder = true`).
- Symlinks: resolve/standardize but don't over-engineer.

## Progress
- [x] Slice 1 — `PathInput.resolve` (pure) + 6 unit tests.
- [x] Slice 2 — Go to Folder sheet (⇧⌘G) + `PanelModel.go(to:)` /
      `WorkspaceModel.navigateActive(toPath:)`; `testGoToFolderNavigates`.
- [x] Slice 3 — header path = menu of ancestor folders + "Go to Folder…".

## Notes
- ⇧⌘G is a Keymap chord, so (like ⌘T/⌘R) it's inactive while the Filter field is
  the first responder — consistent with the rest of the app; the path-menu's
  "Go to Folder…" is the always-available mouse path.
- 34 tests green (28 unit + 6 UI). NB: always `pkill -f Diptychon` before a test
  run — leftover manual instances foreground over the test app (bundle-id gotcha)
  and cause spurious UI failures.
