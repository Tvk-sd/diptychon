# PLAN

_No active task._

Last task: **issue 41 — Reliable state persistence** — core shipped + real-app verified,
on branch `feat/41-state-persistence` (not pushed/merged). Outcome folded into
`PROJECT-TRACKER.md` (Status row 41) and the issue file.

- Durable mechanism: versioned `Codable` snapshot (`WorkspaceState.swift`), restore-on-
  launch with unmounted-vs-gone resolution, debounced save + synchronous flush on quit
  (`willTerminate`), drive unmount/remount handling. Persists per-pane **folder + sort**
  and the **staging set** (path refs, graceful degrade).
- Verified through the real app: save-on-quit writes a clean versioned blob; restore
  reopens distinct per-pane folder + sort (left `/tmp` name-asc, right home date-desc).
- `DIPTYCHON_DIR` launch override disables persistence (deterministic test/dev launches).
- 129 unit tests + full UI suite green.

**Deferred (documented in the issue AC):**
- Tabs (#38), columns/view-mode (#27/29/37) — features don't exist yet; schema is
  additive so they slot in later with no format churn.
- **Split ratio** — SwiftUI `HSplitView` exposes no bindable fraction; would require
  replacing the working panel container (issue 13). A follow-up when appetite shows.
