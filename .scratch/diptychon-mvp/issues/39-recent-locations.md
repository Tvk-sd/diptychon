# 39 — Recent locations

Status: needs-triage (2026-07-02) — drafted from Marta gap analysis
(`context/competitor-benchmark.md` §5). Small, self-contained; complements the
sidebar (issue 16) without being the sidebar. **Sequencing: do AFTER #41 (soft dep).**
Recents persists to app prefs — it should reuse #41's persistence store + schema/
versioning rather than a competing path. Clean, near-AFK follow-up **once #41 lands**;
not AFK before then.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Track the folders the user has recently visited and let them **jump back to a recent
location** quickly — a lightweight history, distinct from pinned Favorites (which are
deliberate, permanent) and from the sidebar's fixed places (issue 16).

Marta's model (our reference): a *Recent Locations* action surfaces recently visited
folders for fast return navigation.

## Notes / design

- **Recents ≠ Favorites ≠ sidebar places.** Recents is *automatic + ephemeral*
  (auto-populated by navigation, capped, MRU-ordered). Favorites/sidebar (issue 16)
  are *manual + permanent*. The sidebar research (issue 16 / `sidebar-research.md`)
  explicitly dropped Recents from the sidebar v1 — this issue delivers it as its own
  quick-access surface instead, keeping the sidebar restrained.
- **Capture point:** record a location when a pane's folder changes (successful
  navigation). Dedupe (bump existing to top), cap the list (e.g. last 15–20 — pick in
  plan), MRU order.
- **Scope of history:** app-global vs per-pane — decide in plan. Lean **app-global**
  (simpler, matches "where was I recently"); the chosen recent applies to the active
  pane when picked.
- **Surface:** a picker — command palette (issue 19) entry ("Recent Locations") and/or
  a small dropdown from the path bar (issue 15). Keyboard-selectable, consistent with
  Go to Folder (issue 15).
- **Persistence:** persist across launches (a short recents list is expected to
  survive a restart), stored in app prefs/Application Support.
- **Privacy:** it's local-only nav history; still, offer a "clear recents" affordance
  and don't record transient/virtual views (e.g. a disk-usage result view, issue 35).

## Acceptance criteria

- [ ] Visited folders are recorded automatically, deduped, MRU-ordered, and capped.
- [ ] The user can open a recents picker and jump the active pane to a chosen recent
      location (keyboard-operable).
- [ ] Recents persist across app launches and can be cleared.
- [ ] Recents is distinct from Favorites/sidebar (auto vs manual) and does not clutter
      the sidebar (issue 16 stays as specced).
- [ ] Transient/virtual views (e.g. disk-usage results) are not recorded as recents.
- [ ] `context/competitor-benchmark.md` §5 gap row for Recent Locations flips to ✅.

## Out of scope

- Full navigation back/forward history per pane (browser-style ⌘[ / ⌘]) — related but
  a separate concern; file if wanted.
- Recent *files* (this is recent *folders*).
- Syncing recents across devices.

## Blocked by

- `15-path-bar-go-to-folder` (the jump-to-folder mechanism + a natural surface) — done.
- `41-state-persistence` (**soft dep** — reuse its app-prefs persistence store/schema;
  do 39 after 41 to avoid a competing persistence path).

## Related

- `context/competitor-benchmark.md` §5 (Marta deep-dive).
- `16-left-sidebar` / `sidebar-research.md` (why Recents lives here, not in the
  sidebar).
- `19-command-palette` (picker surface).
