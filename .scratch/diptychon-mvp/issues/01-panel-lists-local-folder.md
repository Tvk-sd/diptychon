# 01 — Panel lists a local folder

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

The tracer bullet: launch the app and see one Panel rendering the contents of a
real local directory. Introduce the Panel Source abstraction (ADR 0003) with a
single local-directory implementation, list its contents asynchronously, and
render them in a virtualized `Table` placed behind a narrow list protocol
(ADR 0002). Columns: name, size, modification date. Read-only, no navigation yet.

## Acceptance criteria

- [ ] App launches to a window containing one Panel.
- [ ] The Panel lists a real local directory's contents (name, size, date).
- [ ] Listing happens off the main thread; the UI never blocks while a directory
      loads.
- [ ] The file list is rendered via `Table` behind a list protocol so the
      implementation can later be swapped (ADR 0002).
- [ ] Panel Source is an abstraction with one local-directory implementation
      (ADR 0003).
- [ ] Performance: a real folder of ~50,000 files scrolls without visible
      stutter. (If it fails, the escape hatch in ADR 0002 applies — note it,
      don't block this slice.)

## Blocked by

None - can start immediately.
