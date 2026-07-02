# 41 — Reliable state persistence

Status: needs-triage (2026-07-02) — drafted from netnography finding N1
(`context/netnography/04-diptychon-mapping.md` §3, N1) / JTBD-1
(`context/netnography/03-synthese-kundenwuensche.md`). Top-candidate, cross-cutting;
the recommended slot `40` was taken by load-path-optimization, so this is `41`.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Make Diptychon **remember its state across app launches and drive unmounts**, so a
returning user finds their workspace exactly as they left it — sort order, column
widths, view mode, open tabs, and folder/mount state — without re-configuring anything.

JTBD-1 (verbatim): *"When I restart my Mac or unmount a drive, I want sort order,
column widths, tabs, and view to be preserved, so I don't have to set everything up
again each time."* Evidence: P1/W2. User O-Ton from the corpus: *"Is there any TC
alternative for mac that can at least remember its UI settings?"* (S6).

## Why this matters (positioning)

- **Underserved.** No competitor advertises reliable state persistence — this is a
  differentiator through "boring reliability", a core Diptychon virtue.
- **It delegitimizes rivals instantly.** A tool that forgets your setup reads as
  unfinished; one that never forgets reads as trustworthy.
- **On-strategy.** Fits the "light, reliable, native dual-pane for local work"
  positioning (Persona B/C) without adding surface area.

## Scope — what must survive a restart / remount

- **Per-pane view state:** sort column + direction, column widths (and which columns
  are shown, cf. issues 27/29), view/display mode (cf. issue 37).
- **Tabs:** open tabs and their folders per pane (cf. issue 38 — see boundary below).
- **Location state:** each pane's current folder; and the graceful **remount**
  behavior — when a drive comes back, restore the pane to where it was.
- **Window/layout:** pane split ratio and sidebar visibility (cf. issues 13/16).
- **Explicitly NOT persisted — active filters.** Type-ahead filter and tag filter
  (issues 02/08) must **not** survive a restart. Restoring a stale filter would hide
  files on launch and read as "where did my files go?" — a trust-breaker in a tool
  whose whole pitch is reliability. Panes always reopen **unfiltered**. (State this as
  a deliberate decision, not an omission.)
- **Staging set — decision required (default: persist).** The virtual staging set
  (issues 20/30–33) is a flagship, user-curated selection, not a transient view. A
  user who spent effort staging files would likely expect it back after a restart, so
  the **recommended default is to persist the staged set** (as path references,
  degrading gracefully per issue 33 when a staged item is gone). Confirm in plan;
  whatever is chosen, make it explicit — do not leave staging's persistence ambiguous.
  (Note: this is the *staged set itself*; transient staging **previews** are still not
  persisted — see below.)

## Notes / design

- **Boundary vs issue 38 (Per-Pane Tabs).** Issue 38 produces per-*tab* state
  *within a session*. This issue (N1) is the **persistence guarantee across
  sessions** — what survives restart/remount — which is cross-cutting and owns the
  save/restore mechanism. 38 defines the state shape; 41 makes it durable.
- **Where state lives:** app prefs / Application Support (consistent with issue 39's
  recents persistence). Decide the exact store + schema/versioning in plan.
- **When to save:** on relevant state changes (debounced) and on graceful quit;
  don't lose state on an unclean exit if avoidable.
- **Unmount vs missing folder.** Distinguish "drive temporarily unmounted" (remember
  and restore on remount) from "folder permanently gone" (fall back sensibly — e.g.
  nearest existing ancestor or home — never a broken/empty pane). Decide fallback in
  plan.
- **Schema evolution.** Persisted state must tolerate app updates — version the
  format and degrade gracefully on unknown/old keys rather than crash or wipe.
- **Don't persist transient/virtual views** (e.g. disk-usage result view, issue 35;
  staging previews). Cf. issue 39's same exclusion.

## Acceptance criteria

- [ ] After quit + relaunch, each pane restores its folder, sort, column widths,
      shown columns, and view mode.
- [ ] Open tabs and their folders are restored per pane on relaunch.
- [ ] Window layout (split ratio, sidebar visibility) is restored.
- [ ] Unmounting then remounting a drive restores the affected pane to its prior
      folder; a permanently-missing folder degrades to a sensible fallback (no broken
      pane).
- [ ] Persisted state survives an app version update (schema is versioned; unknown
      keys don't crash or wipe state).
- [ ] Transient/virtual views (disk-usage results, staging previews) are not
      persisted.
- [ ] Active filters (type-ahead, tag) are **not** restored — panes reopen unfiltered.
- [ ] Staging-set persistence behaves per the plan decision (recommended: staged set
      restored as path refs, degrading gracefully when an item is gone).

## Out of scope

- Full session history / time-travel of past layouts (this is "restore last state",
  not a timeline).
- Syncing state across devices.
- Recent *locations* history — that's issue 39 (complementary, separate surface).

## Related

- `context/netnography/04-diptychon-mapping.md` §3 N1 (top candidate) and §6 step 1.
- `context/netnography/03-synthese-kundenwuensche.md` JTBD-1, priority table row 1.
- `38-per-pane-tabs` (defines tab/per-pane state; 41 makes it durable).
- `37-multi-column-brief-display-mode`, `27`/`29` (view + columns state to persist).
- `13-panel-resize-and-toggle`, `16-left-sidebar` (layout state to persist).
- `39-recent-locations` (also persists to app prefs; distinct: history vs last-state).
