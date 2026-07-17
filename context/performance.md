# Performance baselines (issue 22)

Runtime-speed baselines so "fast" is evidence, not a claim. Footprint is tracked
separately (`context/competitor-benchmark.md` §4: ~1.5 MB arm64 / ~3 MB universal).

These are **baselines, not a gate** — recorded to catch regressions and to let the
benchmark doc cite real figures. A CI perf budget is deliberately out of scope.

## Conditions

- **Machine:** Apple M1, macOS 26.5.1, arm64
- **Build:** Release (`-O`), `SWIFT_ENABLE_TESTABILITY=YES` (needed for `@testable`
  in the in-target test; negligible on this I/O-bound path)
- **Filesystem cache:** warm (repeated loads of the same directory)
- **Date:** 2026-07-02

## Numbers

| Metric | Value | How measured |
| --- | --- | --- |
| Cold launch → first panel interactive (small folder, 3 items) | **~716 ms** | real app, `Perf` log line |
| 50k-folder load (off-main enumeration + row build), single panel | **~4.6 s** | real app, `list-load` log line |
| 50k-folder load, `measure {}` average (n=10) | **4.876 s** (RSD 4.0%) | `LoadPerformanceTests` |
| 50k folder → **fully interactive** (dual-panel launch, both panels load) | **~6.5 s** | real app, `cold-launch` log line |

## Headline finding — "instant on 50k" is false; "never blocks" is true

The load runs **off-main** (`Task.detached`), so the UI never freezes — you get a
loading state, then rows. That responsiveness claim holds. But the folder is **not**
interactive for ~4.6 s (single panel) to ~6.5 s (dual-panel). The prior benchmark
plan to claim *"instant on huge folders — 50k verified"* is **not supported** — see
§4 update. Honest framing: *"stays responsive on huge folders; never blocks the UI."*

### Where the ~4.6 s goes (hypothesis, not yet measured per-key)

~92 µs/file. The dominant suspects are two per-file resource keys prefetched in
`LocalDirectorySource.resourceKeys`: **`contentType`** (UTType → Kind column, issue
29) and **`localizedName`** (Finder-style display name). Both are known-expensive.
Confirming this (e.g. an Instruments run or a keys-on/off A/B) and trimming the load
path is a **candidate follow-up** — out of scope for this baseline issue.

## How to refresh

**Repeatable load number (CI-able):**
```
xcodegen generate   # if project.yml / sources changed
xcodebuild -project Diptychon.xcodeproj -scheme Diptychon -configuration Release \
  -destination 'platform=macOS' SWIFT_ENABLE_TESTABILITY=YES \
  -only-testing:DiptychonTests/LoadPerformanceTests test
# Override fixture size for a faster local run: DIPTYCHON_PERF_FILE_COUNT=5000
```

**Real-app numbers (cold-launch + in-app load), no Instruments:**
```
# Build the Release app (the test run above produces it), then launch it pointed
# at a folder and read the unified log:
DIPTYCHON_DIR=/path/to/folder \
  <DerivedData>/Build/Products/Release/Diptychon.app/Contents/MacOS/Diptychon &
/usr/bin/log show --last 2m \
  --predicate 'subsystem == "com.diptychon.app"' --info --style compact \
  | grep -E 'cold-launch|list-load'
```
The `Perf` helper (`Sources/Diptychon/App/Perf.swift`) emits both lines to the
unified log — no Instruments required.

## Memory footprint (added 2026-07-17)

Same machine as above, Release build from main `9082296`, `footprint(1)`
(`phys_footprint`, the Activity-Monitor-style number). Fixture: 50k empty files
(`seq -f "file%05g.txt" 1 50000 | xargs touch`). Note: `DIPTYCHON_DIR` seeds
**both** panels with the fixture, so the 50k number below covers ~100k loaded rows.

| Scenario | Footprint | Peak |
| --- | --- | --- |
| Idle, empty folder (8 s after launch) | **35 MB** | 40 MB |
| 50k fixture, both panels (20 s after launch) | **231 MB** | 264 MB |
| Derived: per 50k-file panel | **~100 MB** (≈2 KB/row) | — |
| Reference: live instance after ~1 day real use | 100 MB | — |

**Finder comparison (single run — record, don't market):** Finder on the same
machine went 104 MB → 367 MB opening the same 50k fixture (+263 MB for one window)
and held ~369 MB after the window closed. Caveats before this appears on /vs or
anywhere public: long-running Finder instance (not clean-room), footprint depends
on Finder's view mode (icon view builds thumbnails), n=1. Needs a scripted
repeatable run first — same bar as the load-time numbers above.

The ~2 KB/row suggests materialized `URL` + resource values per row model; any trim
shares the `LocalDirectorySource` load path with issue 40 and should ride along there.

**How to refresh:**
```
# Build Release (see above), then:
DIPTYCHON_DIR=/path/to/fixture <Release>/Diptychon.app/Contents/MacOS/Diptychon & P=$!
sleep 20; footprint $P | grep phys_footprint; kill $P
```
