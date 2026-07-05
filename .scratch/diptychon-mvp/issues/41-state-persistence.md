# 41 — Reliable state persistence

Status: **in-progress / core shipped** (2026-07-03, branch `feat/41-state-persistence`)
— drafted from netnography finding N1 (`context/netnography/04-diptychon-mapping.md`
§3, N1) / JTBD-1 (`context/netnography/03-synthese-kundenwuensche.md`). Top-candidate,
cross-cutting; the recommended slot `40` was taken by load-path-optimization, so `41`.

**Shipped:** the durable mechanism — versioned `Codable` snapshot, restore-on-launch
with unmounted-vs-gone resolution, debounced save + synchronous flush on quit, drive
unmount/remount handling — persisting the state that **exists today**: per-pane folder
+ sort, and the staging set (path refs, graceful degrade). Verified through the real
app (save-on-quit + restore of distinct per-pane folder/sort). 129 unit tests green
(+ full UI suite).
**Deferred:** tabs (#38), columns/view-mode (#27/29/37) — those features don't exist
yet, so there's nothing to persist; the schema is additive so they slot in later.
**Split ratio deferred** — SwiftUI `HSplitView` exposes no bindable fraction; wiring it
would mean replacing the working panel container (issue 13), which the governing
principle (core-restore reliability > breadth) says isn't worth the risk now.
**Decision:** a `DIPTYCHON_DIR` launch override disables persistence (deterministic
test/dev launches), mirroring the `-sidebarVisible`/`-previewVisible` launch args.

## Job to be Done

**The job:** *"I want to find my workspace exactly as I left it — without setting it
up again every time."* Users don't hire Diptychon to "save settings"; they hire it for
**continuity**. Per Christensen's logic, a file manager that forgets on restart **gets
fired**, however good the rest is — and the corpus documents exactly that.

- **Functional** — sort, folder, layout, and mount state survive restart & drive
  unmount; setup work disappears. *(JTBD-1, P1/W2)*
- **Emotional** — **trust, not friction.** No "where did my files go?" moment, no daily
  annoyance over lost settings. Quiet reliability. *(the "boring reliability" virtue)*
- **Social** — **credibility with a discerning peer group** (TC refugees, power users).
  A tool that forgets reads as "unfinished/amateur"; one that never forgets reads as
  "trustworthy/grown-up." *(S6 public forum ask; N1 "delegitimizes rivals instantly")*

Evidence O-Ton (S6): *"Is there any TC alternative for mac that can **at least**
remember its UI settings?"* — the "at least" signals users treat this as table stakes,
not a feature. Source: `context/netnography/03-synthese-kundenwuensche.md` JTBD-1;
`context/netnography/04-diptychon-mapping.md` §3 N1.

### Governing principle (from the emotional job)

**A restore that confuses is worse than no restore.** The emotional job is *trust* —
the win condition is the absence of a "where did my files go?" moment. So the decision
rule for every restore behavior is: **when in doubt, restore less / fall back safely
rather than restore something stale, hidden, or broken.** The filter-exclusion and the
missing-folder fallback below are the *same* rule applied twice; apply it to any future
state type too. Corollary: reliability of the **core** restore (folder, sort, layout)
outranks **breadth** of what's restored — a rock-solid narrow restore beats a wide one
that occasionally confuses.

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

- [x] After quit + relaunch, each pane restores its folder + **sort** (verified live).
      Column widths / shown columns / view mode **deferred** — not modeled yet (#27/29/37).
- [ ] Open tabs and their folders are restored per pane — **deferred**: tabs don't
      exist yet (#38). Schema is additive; slots in when 38 lands.
- [~] Window layout: **sidebar visibility** restored (pre-existing). **Split ratio
      deferred** — `HSplitView` has no bindable fraction; not worth replacing the
      container now (governing principle: core reliability > breadth).
- [x] Unmounting then remounting a drive restores the affected pane to its prior
      folder; a permanently-missing folder degrades to nearest ancestor / home (no
      broken pane). Logic unit-tested; wiring via `NSWorkspace` notifications.
- [x] Persisted state survives an app version update (schema is versioned; unknown
      keys ignored, newer/garbage blobs fall back to defaults — never crash or wipe).
- [x] Transient/virtual views (disk-usage results, staging previews) are not persisted.
- [x] Active filters (type-ahead, tag) are **not** restored — panes reopen unfiltered
      (simply absent from the snapshot).
- [x] Staging set restored as path refs, degrading gracefully when an item is gone
      (`StagingSource` greys out missing entries, issue 33).

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
