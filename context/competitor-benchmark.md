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
| **Large-folder perf (50k+ virtualized)** | 🔶 non-blocking, ~4.6s load (22) | ✅ | ✅ | ❔ | ❔ |
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

## 4. Footprint & performance

### Footprint — a first-class differentiator
The release `.app` is **~1.5 MB** (arm64; the bundle is essentially one binary —
no embedded frameworks, no asset catalog), ~365 KB zipped. A **universal** build
(Apple Silicon + Intel) roughly doubles the binary to **~3 MB**; signing/
notarization adds almost nothing. So the honest headline is **"~3 MB universal."**

Why it's this small: pure Swift / SwiftUI / AppKit linking the system frameworks —
no bundled runtime, no Chromium. This is the most *visceral* proof of the
"lightweight" thesis — it makes the positioning tangible instead of a slogan.

| App | Approx. download size | Stack |
|---|---|---|
| **Diptychon** | **~1.5 MB (arm64) / ~3 MB universal** | native Swift/SwiftUI/AppKit |
| Marta | ~10–15 MB ❔ | native |
| Nimble Commander | ~20 MB+ ❔ | native |
| ForkLift | ~30–40 MB ❔ | native |
| Path Finder | ~30–60 MB ❔ | native |
| (any Electron file manager) | 100–200 MB+ | bundled Chromium |

> ❔ Competitor sizes are from memory — **verify before publishing**. The
> Diptychon figure is measured (Release build, 2026-06-24).

**What size proves:** native + lightweight. **What it does *not* prove:** runtime
speed — don't let the two blur.

### Performance — measured (issue 22)
Baselines on Apple M1 / macOS 26.5.1 / arm64, Release build, warm cache
(2026-07-02). Full method + refresh commands: `context/performance.md`.
- **Cold launch → first panel interactive:** ~716 ms (small folder).
- **Directory loads run off-main** (`Task.detached`, prefetched resource keys) —
  the UI **never blocks**; you get a loading state, then rows (issue 01).
- **Virtualized `NSTableView`** render (O(visible rows), not O(items)).
- `visibleItems` cached (issue 04); FSEvents refresh debounced (issue 09).

**⚠️ Correction — do NOT claim "instant on huge folders."** The measurement
contradicts it: a **50k-file folder takes ~4.6 s to load** (single panel) and
**~6.5 s to become fully interactive** (dual-panel launch). It never *blocks* —
but it is not *instant*. Honest, defensible claim:
> *"Stays responsive on huge folders — never freezes the UI; a 50k-file folder
> stays scrollable while it loads."*

**Follow-up (candidate, not filed):** ~92 µs/file is dominated by two per-file
resource keys — `contentType` (Kind column) and `localizedName`. Trimming the load
path could cut the 50k number materially; needs an Instruments/A-B confirmation
first (`context/performance.md`).

---

## 5. Marta deep-dive — full tool inventory & gaps

Marta is our closest spiritual peer ("Total Commander for macOS"), so it's worth a
one-competitor deep read rather than a single matrix row. Sourced from
[marta.sh/docs](https://marta.sh/docs/) + homepage (read 2026-07-02).

**Where Diptychon already leads Marta:** reversible multi-level undo (Marta has an
operation *queue* but no undo spine); real Finder-tag round-trip + per-panel tag
filter (not a Marta concept); virtual staging panel (issues 20/30–33, no Marta
analogue). Those stay our wins — don't trade them away chasing parity.

**Deliberately out of scope** (see §3 — not gaps): archive-as-folder,
remote/cloud mounts, folder sync-compare.

### Gap table — Marta tools Diptychon lacks
Legend: ❌ absent · 🟡 partial · 🔄 backlog · ➖ deliberate

| Marta tool | What it does | Diptychon | Verdict |
|---|---|---|---|
| **Operation Queue** | Queued ops, shared across windows, progress bar, **pause/cancel**, keyboard-driven (`=`) | ❌ ops run off-main but no surfaced queue/pause/cancel | **Top gap** — extends our reversible-op lead (issue 34) |
| **Analyze Disk Usage** | Recursive size scan → sorted-desc virtual view | ❌ | **File** (issue 35) |
| **Gadgets** | User-defined actions running external apps/executables on the selection | ❌ | **Gadgets-lite** (issue 36) |
| **Flatten** | Recursive folder → one flat file list | ❌ | Candidate — cheap, pairs with disk-usage |
| **Look Up** | System-global search via Spotlight indices | ❌ | Candidate |
| **Embedded Terminal (etty)** | Per-pane pty, dir-synced (`⌘O`) | ❌ | Weight risk — tension w/ "lightweight" |
| **Multi-column brief display mode** | 1/2/3-column view alongside table | ❌ table-only | Candidate |
| **Tabs** (per pane) | Multiple tabs | ❌ | Table-stakes eventually |
| **Recent Locations** | Visited-folder history | ❌ | Candidate |
| **Favorites / Volumes** | Pinned places + volume list | 🔄 sidebar (issue 16) | Covered by backlog |
| **Hierarchy parents menu** (`⌥0`) | Keyboard breadcrumbs | 🟡 have path bar | Minor |
| **Clone folder to other pane** | Point inactive pane at active folder | ❌ (have copy-*files*, not clone-*view*) | Minor |
| **Regex quick search** | Filter by substring **or** regex | 🟡 substring type-ahead only | Minor |
| **Decoupled selection** | Move cursor without losing selection | ❌ Finder-style | UX-divergence decision, not a bug |
| **Action Bar** | Button strip + hotkey cheat sheet below panes | ❌ (have command palette, issue 19) | Deferred |
| **Extensibility suite** | Lua plugin API · config DSL · configurable keybindings · themes · fonts · CLI | ❌ none | ➖ mostly *against* the lightweight/Finder-native thesis — **not** parity targets (except Gadgets-lite, issue 36) |

> **PM note.** Marta's extensibility is its moat *and* its weight. Don't chase
> plugin/theme/DSL parity — it fights "lightweight + Finder muscle memory." The
> three worth filing (34/35/36) are the ones that either extend an existing
> Diptychon strength (the op queue) or are self-contained, high-utility, low-weight.

---

## 6. How to use this doc
- **Positioning checks:** when tempted to add a feature, find its row. If it's a ➖,
  the bar to flip it is "does this break *lightweight*?"
- **Pairs with:** `sidebar-research.md` (the "less than Finder" sidebar),
  `dashboard-research.md` (data-driven display), and `transferable-learnings.md`
  (what generalizes beyond Diptychon — §3 here is its restraint case study).
- **Maintenance:** spot-check competitor columns before any external use; refresh
  the Diptychon column as backlog items (11, 16, 17) ship.
