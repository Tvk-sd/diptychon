# Competitor Benchmark — Diptychon vs. the field

Where Diptychon sits among macOS file managers. The point of this doc is **not**
a feature scoreboard — it's to make our positioning legible: for each capability,
what we ship, and just as importantly, what we **deliberately don't**.

> **Sourcing note.** The *Diptychon* column is grounded in shipped issues
> (`PROJECT-TRACKER.md`, `.scratch/diptychon-mvp/issues/`). The competitor columns
> are from general product knowledge and should be spot-checked before this doc is
> published or quoted — capabilities and even product availability change
> (see the per-tool caveats in §1).

---

## 1. The competitive set — two tiers

Finder is not our feature peer. It's the **incumbent default** — the thing every
Mac user already has and already knows. Beating Finder is about *familiarity +
restraint*, not feature count. Our actual feature peers are the dual-panel
"Commander" lineage.

**Tier 1 — the incumbent (the familiarity bar):**
- **Finder** — single-pane (column/list/gallery), tag-native, Spotlight, AirDrop,
  iCloud. The default; defines what users expect a Mac file action to feel like.

**Tier 2 — dual-panel peers (the "done right" bar):**
- **Nimble Commander** — our spiritual model: dual-pane, keyboard-first, fast,
  macOS-native feel. `CONTEXT.md` names it explicitly.
- **Marta** — free, dual-pane, keyboard-driven; the closest "Total Commander for
  macOS" in spirit. *(Caveat: development cadence has been intermittent.)*
- **ForkLift** — dual-pane with a strong remote/cloud-mount story (SFTP, S3, etc.).
- **Path Finder** — long-running power-user Finder replacement. *(Caveat: I believe
  Cocoatech wound down active development — verify status before citing it as a
  live competitor.)*

**Lineage ancestor (context, not a macOS rival):**
- **Total Commander** (Windows) — where the dual-pane + F-key Commander gestures
  originate. We inherit the *paradigm*, not the UI.

---

## 2. Capability matrix

Legend: ✅ ships · 🔄 backlog/planned · ➖ deliberately out of scope · ❔ varies/unsure

| Capability | Diptychon | Finder | Nimble Cmdr | Marta | ForkLift |
|---|---|---|---|---|---|
| **Dual side-by-side panels** | ✅ core (issue 03) | ➖ single-pane | ✅ | ✅ | ✅ |
| **Active/Inactive focus model** | ✅ Tab + click, accent border (03) | ➖ | ✅ | ✅ | ✅ |
| **Commander "copy to other panel"** | ✅ ⌥⌘→/← (04) | ➖ | ✅ | ✅ | ✅ |
| **Multi-level undo/redo of file ops** | ✅ reversible Operation spine, ⌘Z/⇧⌘Z (04/05) | ❔ limited | ❔ | ❔ | ❔ |
| **Pre-write collision dialog** (overwrite/keep-both/skip) | ✅ (04/05) | ✅ replace/keep-both | ✅ | ❔ | ✅ |
| **Clipboard cut/copy/paste** (⌘C/⌘V/⌥⌘V) | ✅ Finder convention (05) | ✅ | ✅ | ✅ | ✅ |
| **Drag & drop incl. to/from Finder** | ✅ (06) | ✅ | ✅ | ✅ | ✅ |
| **Batch rename** | ✅ 4 modes, live preview (07) | ✅ (Rename Items) | ✅ | ❔ | ✅ |
| **Inline single-file rename** | 🔄 backlog (11) | ✅ | ✅ | ✅ | ✅ |
| **Finder tags — real, round-trip** | ✅ writes Apple xattr (08) | ✅ native | ❔ | ❔ | ❔ |
| **Filter panel by tag** | ✅ per-panel (08) | ❔ via Smart Folders | ❔ | ❔ | ❔ |
| **QuickLook (spacebar)** | ✅ (09) | ✅ | ✅ | ✅ | ✅ |
| **Open With ▸** | ✅ right-click (09) | ✅ | ✅ | ✅ | ✅ |
| **Live folder refresh (FSEvents)** | ✅ debounced (09) | ✅ | ✅ | ✅ | ✅ |
| **Inline preview / inspector pane** | ✅ toggleable, ⇧⌘P (14) | ✅ Preview pane | ✅ | ❔ | ✅ |
| **Path bar + Go to Folder (⇧⌘G)** | ✅ clickable breadcrumb (15) | ✅ | ✅ | ✅ | ✅ |
| **Type-ahead filter / hidden toggle** | ✅ (02) | ❔ type-select only | ✅ | ✅ | ✅ |
| **Large-folder perf (50k+ virtualized)** | ✅ verified (01/06) | ✅ | ✅ | ❔ | ❔ |
| **Left sidebar (places + pinned)** | 🔄 backlog, spec'd (16) | ✅ rich (Locations/Tags/iCloud) | ✅ | ❔ | ✅ |
| **Remote/cloud mounts** (SFTP/S3/…) | ➖ out of scope (local-only MVP) | ➖ | ❔ | ➖ | ✅ flagship |
| **Built-in archive browse/extract** | ➖ out of scope (modeled as future `PanelSource`) | ❔ extract only | ✅ | ❔ | ✅ |
| **Dual-pane sync / compare folders** | ➖ not planned | ➖ | ✅ | ❔ | ✅ |

> Every ➖ in the Diptychon column is a *choice*, not a gap — see §3.

---

## 3. Our positioning — what we deliberately don't do

The product thesis from `CONTEXT.md`: *"a lightweight Finder alternative in the
spirit of Nimble Commander."* **Lightweight** is the operative word, and it's
defended by saying no:

- **No remote/cloud mounts.** That's ForkLift's flagship and a whole protocol
  surface. MVP is local-only — but the `PanelSource` abstraction (ADR 0003) means
  a future remote source could plug in *without* reworking the rest of the app.
- **No archive-as-folder, no folder-sync/compare.** Power-Commander features that
  add real weight. Out of scope; the `PanelSource` seam keeps the door open.
- **A sidebar "less than Finder."** The sidebar spec (issue 16, `sidebar-research.md`)
  explicitly drops Recents, Tags, and iCloud/Locations from v1 — just the places
  people actually jump to. Restraint *is* the feature.
- **Finder-compatible, never parallel.** Tags write real Apple xattrs and
  round-trip (issue 08); clipboard uses Finder's ⌘C/⌘V/⌥⌘V conventions (05). We
  ride the ecosystem instead of inventing a private one.

### Where we actually try to win
1. **Dual-panel + Commander gestures done natively** — the Nimble Commander
   workflow with a calmer, more macOS-native surface.
2. **A genuinely reversible operation model** — multi-level undo across copy/move/
   trash/rename (ADR 0004) is stronger than most file managers, which treat file
   ops as fire-and-forget.
3. **Keyboard-first without being hostile** — type-ahead, chorded gestures, Go to
   Folder — but with Finder conventions so the muscle memory transfers.

---

## 4. How to use this doc
- **Positioning checks:** when tempted to add a feature, find its row. If it's a ➖,
  the bar to flip it is "does this break *lightweight*?"
- **Pairs with:** `sidebar-research.md` (the "less than Finder" sidebar),
  `dashboard-research.md` (data-driven display), and the forthcoming
  `transferable-learnings.md` (what generalizes beyond Diptychon).
- **Maintenance:** spot-check competitor columns before any external use; refresh
  the Diptychon column as backlog items (11, 16, 17) ship.
