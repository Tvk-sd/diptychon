# PLAN

## Active: issue 21 — unified top bar (branch `feat/21-unified-top-bar`)

### ✅ Slice 1 runaway — FIXED & verified (breadcrumb `trail()` infinite loop)

**Symptom:** clicking a folder pegged **99% CPU + ballooned RAM**, freezing the Mac.

**Confirmed root cause:** `TopBarView.trail(of:)` (the new breadcrumb) walked
`url.deletingLastPathComponent()` in a `while true` until `parent == url`. That never
converges for the **directory-style URLs `contentsOfDirectory` returns** — which is
what `directory` becomes after a folder click. NB: these URLs are *absolute* (e.g.
`file:///Users/Till/Music/`), not relative — an empirical test (`scratchpad/
source_test.swift`) showed every real listed folder URL diverges, while synthetic
`URL(fileURLWithPath:"/a/b")` terminates. So *every* folder click hit it. Brand-new
slice-1 code ⇒ exactly why "it worked before slice 1."

**Evidence (two independent receipts):**
1. Background-watchdog probe on the real folder-click: `WATCHDOG KILL cpu=99%
   rss=953MB ws=0 content=0 top=1 apply=0 setFrame=0` — stuck inside one
   `TopBarView.body`; `WindowMinWidth` (`apply`/`setFrame`) completely uninvolved.
2. `source_test.swift`: every real `contentsOfDirectory` folder URL diverges in the
   old `trail()`; the fixed `trail()` returns correct bounded crumbs for all.

**`WindowMinWidth` was a red herring** — the edge-trigger change (`WorkspaceView.swift`)
is real hardening (kept, per user) but did NOT cause or fix this.

**The fix (committed):** `trail()` now builds the breadcrumb from the *absolute,
standardized* path's `pathComponents` — bounded, can't diverge for any input. Verified
in isolation tests AND by the user on the real app (folder clicks, hotkeys, resizing
all flat).

**Thread 2 (URL source) — CLOSED:** not a navigation bug; `contentsOfDirectory`
directory URLs simply don't converge under `deletingLastPathComponent()`. Bounded
`trail()` is the complete fix; no source change needed.

**Thread 3 (testPinFolder fails) — diagnosed, NOT an app bug:** fails at line 282
(first assertion) because the sidebar-visible tests assume `app.tables.element(boundBy:
0)` is the left file panel, but the sidebar `List` also registers as a table on this
macOS, shifting the index. Affects the 3 sidebar-visible UI tests. Fix = give panel
tables stable a11y identifiers + update those tests (separate small work; needs a UI
run to verify). Unrelated to the runaway.

**Lessons logged** in `context/transferable-learnings.md` §10 (don't conclude without
reproducing — I twice declared `WindowMinWidth` fixed without a real repro; and test
with *real* inputs — synthetic URLs hid the divergence).

### Remaining slices
- **Slice 1 (done, PR #21):** top bar + breadcrumb + Up + per-panel minimal label.

- **Slice 2 (IN PROGRESS): back/forward history.** Per-panel browser-style history.
  - `PanelModel`: add `backStack`/`forwardStack` (`[URL]`), `canGoBack`/`canGoForward`.
    Route every dir change through a private `pushHistoryAndGo(to:)` that appends the
    current dir to `backStack`, clears `forwardStack`, then sets `directory` +
    `afterNavigation()`. `navigate(into:)`, `go(to:)`, `navigateUp()` call it.
    `goBack()`/`goForward()` move between stacks (no history push) + `afterNavigation()`.
  - `AppAction`: add `.goBack`/`.goForward`. `Keymap`: ⌘[ → back, ⌘] → forward (Finder
    convention). `WorkspaceModel.handleKeyDown`: dispatch to `activeModel`.
  - `TopBarView`: ‹ › buttons before Up (chevron.left/right), disabled via
    `canGoBack`/`canGoForward`, `.help("Back (⌘[)")` / `("Forward (⌘])")`.
  - Tests: unit-test the stack transitions in `DiptychonTests` (temp dirs; assert
    `directory` + `canGoBack`/`canGoForward` synchronously — independent of async
    reload). Skip UI tests for now (sidebar table-index fragility — see issue 23).
  - Decisions: history is per-panel; navigating anywhere new clears forward (browser
    norm); back/forward reuse `afterNavigation()` so filter/selection reset stays
    consistent.

- **Slice 2 design tweaks (approved, building):**
  1. TopBar button order → `^ ‹ ›` (Up left of back/forward, per user).
  2. Top bar scoped to **panels only**: sidebar + preview rise to the title bar;
     the bar + its divider move *inside* the panel column (VStack), pushing only the
     panel tops down. Restructure `WorkspaceView`: outer HStack = sidebar | (VStack:
     topbar/divider/panels) | preview.

- **Slice 3 (building): real recursive search.** The sidebar field becomes Search
  (pure; go-to-folder stays on ⇧⌘G). Decisions: results render **in the active panel**
  (Finder-style, reusing the list); scope is the **active panel's subtree**; hidden/tag
  controls and per-panel headers stay as-is (no UI consolidation — user dropped it).
  - `RecursiveSearch.run` — bounded, cancellable off-main walk (cap 1000, cancels on
    each keystroke) so searching Home can't peg CPU/RAM (transferable-learnings §10).
  - `PanelModel`: `searchQuery` (debounced ~250ms) → `searchResults`; `visibleItems`
    branches to the results while `isSearching`; navigation/showHidden re-sync; clearing
    exits search. Activating a result reuses open/navigate.
  - `SidebarView`: field → Search (magnifier + clear button), bound to the active panel.
  - `PanelView`: header shows result count; empty state when no matches.
  - Deferred: showing each result's location (relative path) — needs a Table column.

## Backlog
- **Ready for agent:** 12 (custom tag color registration).
- **Needs triage:** 18 (time-travel undo), 19 (command palette ⌘K),
  20 (virtual staging), 22 (performance baseline).
</content>
