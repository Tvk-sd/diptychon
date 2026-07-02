# 40 — Trim the directory load path (50k in seconds → sub-second)

Status: needs-triage

## Parent

`.scratch/diptychon-mvp/PRD.md` · follow-up to issue 22 (performance baselines).

## What to build

Cut the time a large folder takes to become interactive. Issue 22 measured the
baseline and it is **not** what "instant" implies: a 50k-file folder takes
**~4.6 s to load** (single panel) and **~6.5 s to fully interactive** (dual-panel
launch) on an M1 (Release, warm cache) — see `context/performance.md`. The load is
off-main so the UI never blocks, but ~92 µs/file is a real cost the user waits on.

Goal: materially reduce the per-file cost so a 50k folder loads in well under a
second, letting us make a *stronger* speed claim than "never blocks."

## Notes / design

- **Prime suspects** (`LocalDirectorySource.resourceKeys`, `LocalDirectorySource.swift`):
  two per-file resource keys prefetched for every row, both known-expensive:
  - **`contentTypeKey`** (UTType → the Kind column, issue 29).
  - **`localizedNameKey`** (Finder-style display name, e.g. "Musik" for Music).
- **Step 1 — confirm the cost before optimizing.** Don't guess: A/B the keys
  (load with/without each) via the `LoadPerformanceTests` fixture, or an
  Instruments Time Profiler run, to attribute the ~92 µs/file. Record which key
  dominates. (Issue 22 hypothesizes but did **not** measure per-key.)
- **Candidate fixes (pick after measuring):**
  - Derive `kind` lazily from the file extension (cheap string map) instead of a
    per-file UTType resolution; fall back to UTType only when the extension is
    unknown / when the row is actually shown.
  - Drop `localizedName` for non-system folders (it only differs for a handful of
    localized system dirs); use `name`/`lastPathComponent` otherwise.
  - Defer any residual per-file work to the ~visible rows (the table is already
    virtualized), computing the rest off-main after first paint.
- Keep the batched single `contentsOfDirectory(includingPropertiesForKeys:)` call —
  that part is already right (issue 01).

## Acceptance criteria

- [ ] Per-key cost is measured (A/B or Instruments) and recorded in
      `context/performance.md`, so the fix targets the real bottleneck.
- [ ] 50k-folder load drops materially — target **< 1 s** single-panel on the
      issue-22 reference machine, verified via `LoadPerformanceTests` + the
      real-app `list-load` log line.
- [ ] No regression to the Kind column (issue 29) or localized system-folder names
      (existing tests stay green; add coverage if kind derivation changes).
- [ ] `context/performance.md` + `competitor-benchmark.md` §4 updated with the new
      figures (and the speed claim strengthened if the number supports it).

## Out of scope

- A CI performance gate / regression budget (issue 22 out-of-scope still holds —
  record, don't gate).
- Scroll-FPS / render micro-optimization (the table is already virtualized; this
  is about the load, not the draw).

## Blocked by

- `22-performance-baseline-measurements` (baseline + repeatable harness) — done.

## Related

- `context/performance.md` (baseline + refresh method).
- `Sources/Diptychon/Panel/LocalDirectorySource.swift` (`resourceKeys`).
- issue 29 (Kind column — the reason `contentType` is on the load path).
