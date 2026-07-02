# 43 — Local instant search (not Spotlight-dependent)

Status: needs-triage (2026-07-02) — drafted from netnography finding N5
(`context/netnography/04-diptychon-mapping.md` §3) / JTBD-6, P9
(`context/netnography/03-synthese-kundenwuensche.md`). Validate demand in our own
segment before heavy build (see below).

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A **fast, local, recursive find-in-folder** search that walks the current directory
tree directly — **independent of Spotlight** — so results appear even where Spotlight
is blind (network shares, unindexed volumes, freshly changed files).

**Netnography backing** (`context/netnography/`, JTBD-6 / P9): a concrete, sharp pain
point — *"My big problem with QSPACE is the file search. I have folders with a huge
number of files and they are networked. Pathfinder and Forklift search locally in the
folder once loaded. Qspace (like Finder) uses Spotlight and Spotlight doesn't find
anything on the network, which limits my productivity a lot."* (S5). Local search is
exactly the kind of capability that fits a **local-first** tool cleanly.

## Distinction from what we already have

- **Type-ahead filter (issue 02)** filters the *currently loaded* folder by name —
  shallow, single level. This issue is **recursive** search across the subtree.
- Not Spotlight/`NSMetadataQuery`: those are what fail the user above. Walk the tree
  ourselves (reuse `LocalDirectorySource` traversal + the off-main posture from issue
  01), so it works on any mounted path including network folders.

## Notes / design

- **Off-main + streaming results.** A deep tree is expensive; run the walk off the main
  thread (issue 01 posture) and **stream matches in** as found, cancelable — never
  freeze the UI (consistent with issue 22 baselines). Show a running/among-results
  state.
- **Match model (v1):** substring on filename; consider glob/wildcards
  (`report*.pdf`) since power users expect them; regex is a stretch. Decide in plan.
- **Result presentation:** decide in plan — either a results list in the active pane
  (like Marta's "Flatten"/virtual view, cf. issue 35's virtual-view pattern) or a
  dedicated overlay. Reuse the virtualized list so large result sets stay smooth.
- **Scope for v1:** name-based search within the active pane's current folder subtree.
  **Content/full-text search is out** (heavy; that's a different feature).
- **Interaction with staging (issues 30–33):** results should be selectable and
  stage-able / actionable like normal rows.
- **Cancellation:** tie into the same cancel affordance as long operations where it
  makes sense; a search must be abortable.

## Demand check first (PM note)

The netnography evidence is a **single strong voice** (one detailed complaint), and the
pain is most acute for *networked* folders — a use case adjacent to the remote story we
deliberately keep out of scope. Before a heavy build, confirm the job exists in
**Diptychon's own local segment** (Persona B/C), not just the broader market. Cheapest
first step: recursive **name** search over local subtrees (clearly in-scope, useful on
its own); defer anything network-specific.

## Acceptance criteria

- [ ] A recursive, name-based search over the active pane's folder subtree returns
      matches without relying on Spotlight (works on unindexed / network paths).
- [ ] The search runs off-main, streams results, and is cancelable — no UI freeze on a
      large tree (no regression vs issue 22).
- [ ] Results are presented in a virtualized surface and are selectable/actionable
      (including stage-able) like normal rows.
- [ ] Content/full-text search is explicitly excluded from v1.

## Out of scope

- Content / full-text search (v1 is name/glob only).
- Spotlight/`NSMetadataQuery` integration (the point is to *not* depend on it).
- Saved searches / smart folders.
- Remote-protocol search (no remote sources in MVP — see benchmark §3).

## Blocked by

- `01-panel-lists-local-folder` (off-main traversal + virtualized list) — done.
- `02-panel-navigation-sort-filter` (the shallow filter this extends) — done.

## Related

- `context/netnography/04-diptychon-mapping.md` §3 N5; `03` JTBD-6 / P9.
- `35-analyze-disk-usage` (shares the recursive-walk + virtual-view pattern).
- `30-stage-and-view-files` (results should be stage-able).
