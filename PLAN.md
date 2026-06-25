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

### Remaining slices (after the fix is committed)
- **Slice 1 (done):** top bar + breadcrumb + Up + per-panel minimal label.
- **Slice 2:** back/forward history (`PanelModel` stack + ‹ › buttons).
- **Slice 3:** promote Filter → search in the bar; move hidden + tag controls into the
  bar; drop the old per-panel header row.

## Backlog
- **Ready for agent:** 12 (custom tag color registration).
- **Needs triage:** 18 (time-travel undo), 19 (command palette ⌘K),
  20 (virtual staging), 22 (performance baseline).
</content>
