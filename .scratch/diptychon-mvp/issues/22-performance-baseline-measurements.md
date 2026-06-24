# 22 — Performance baseline measurements

Status: needs-triage

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Capture a small, repeatable set of **performance measurements** so "fast" becomes
evidence rather than a claim. Today the app is *architected* for speed (off-main
loads, virtualized `NSTableView`, cached `visibleItems`, debounced FSEvents) and a
50k-file folder is spot-verified to not block — but there are **no numbers**. Issue
01 even notes "subjective scroll-smoothness left for human."

This unblocks the speed claim in `context/competitor-benchmark.md` §4, which today
deliberately stops at *"instant on huge folders (50k verified)"* with no figure.

## Notes / design

- **Two headline metrics (minimum):**
  1. **Cold-launch time** — app launch → first panel interactive.
  2. **Large-folder time-to-interactive** — navigate into a 50k-file folder →
     list rendered + scrollable. Reuse the 50k fixture from issue 01.
- **Method (decide in plan):**
  - Cheapest: `os_signpost` / `OSLog` intervals around `LocalDirectorySource`
    load + first render, read in Instruments or Console. No new deps.
  - Or a tiny `XCTest` `measure {}` block over the load path (the pure/off-main
    parts), so it can run in CI and catch regressions.
- **Conditions:** Release build, arm64, warm filesystem cache; note machine + OS.
  Record raw numbers, not a pass/fail — this is a baseline, not a gate (yet).
- **Where it lives:** a short results block in `PROJECT-TRACKER.md` (or a
  `context/performance.md`), with the date + machine, so the benchmark doc can cite
  a real figure.
- **Footprint is already measured** (benchmark §4: ~1.5 MB arm64 / ~3 MB
  universal) — this issue is *only* runtime speed.

## Acceptance criteria

- [ ] Cold-launch time and 50k-folder time-to-interactive are measured on a Release
      build and recorded with date + machine + OS.
- [ ] The measurement method is repeatable (documented commands or a `measure {}`
      test) so the numbers can be refreshed after future changes.
- [ ] `context/competitor-benchmark.md` §4 is updated to cite the real figures and
      drop the "not yet benchmarked" caveat.

## Out of scope

- A CI performance gate / regression budget (record baselines first; gate later).
- Scroll-FPS / micro-benchmarks beyond the two headline metrics.

## Blocked by

- `01-panel-lists-local-folder` (off-main load + the 50k fixture) — done.

## Related

- `context/competitor-benchmark.md` §4 (Footprint & performance).
