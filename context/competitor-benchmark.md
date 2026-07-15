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
| **Multi-level undo/redo of file ops** | ✅ reversible Operation spine, ⌘Z/⇧⌘Z (04/05) | 🟡 limited/single-step | 🟡 partial (in-place rename) | ❌ op *queue*, no undo spine | ✅ multi-level, logged into Activity |
| **Operation *legibility* — visible/scrubbable timeline** (issue 18) | 🔄 spine exists but **invisible + LIFO-only** (18) | ❌ undo invisible | 🟡 live op *queue* only (not undo history) | 🟡 live op *queue* only | 🟡 **Activity/Log** pane (closest) — but not scrub-to-a-point |
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
**Measured on the actually-shipped Release build (2026-07-08, `dist/Diptychon.zip`):**
it's a **universal** binary (Intel `x86_64` **+** Apple Silicon `arm64`) and *still* tiny:
- **Download (.zip): ~1.37 MB**
- **Installed (.app): ~5.4 MB** (the universal Mach-O is ~5.27 MB — both slices)

The site's public claim — **"1.4 MB download, 5 MB installed"** — is **accurate**. (An
earlier version of this section estimated "~1.5 MB arm64 / ~3 MB universal / ~365 KB
zipped" — that was wrong; the real *universal* build zips to 1.37 MB. This is the
corrected, measured figure.)

Why it's this small: pure Swift / SwiftUI / AppKit linking the system frameworks —
no bundled runtime, no Chromium. A **universal** build that still downloads at ~1.4 MB
is a *stronger* flex than an arm64-only one — the most *visceral* proof of the
"lightweight" thesis, and it makes the positioning tangible instead of a slogan.

| App | Approx. download | Stack |
|---|---|---|
| **Diptychon** | **~1.4 MB** (universal `.zip`) | native Swift/SwiftUI/AppKit |
| ForkLift 4 | **~16.3 MB** (verified) | native Swift |
| Marta | ~10–15 MB ❔ | native |
| Nimble Commander | ~20 MB+ ❔ | native |
| Path Finder | ~30–60 MB ❔ | native |
| (any Electron file manager) | 100–200 MB+ | bundled Chromium |

> Diptychon = measured 2026-07-08. ForkLift = MacUpdate (verified — see
> `competitor-facts.md`). Other competitor sizes are still estimates (❔) —
> **verify before publishing.**

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
| **Gadgets** | User-defined actions running external apps/executables on the selection | ✅ Gadgets-lite (issue 36): declarative `gadgets.json`, ⌘K palette, 6 substitution variables — no scripting runtime | Shipped — the one extensibility exception (see `docs/gadgets.md`) |
| **Flatten** | Recursive folder → one flat file list | ❌ | Candidate — cheap, pairs with disk-usage |
| **Look Up** | System-global search via Spotlight indices | ❌ | Candidate |
| **Embedded Terminal (etty)** | Per-pane pty, dir-synced (`⌘O`) | ❌ | Weight risk — tension w/ "lightweight" |
| **Multi-column brief display mode** | 1/2/3-column view alongside table | ❌ table-only | **File** (issue 37) |
| **Tabs** (per pane) | Multiple tabs | ❌ | **File** (issue 38) |
| **Recent Locations** | Visited-folder history | ❌ | **File** (issue 39) |
| **Favorites / Volumes** | Pinned places + volume list | 🔄 sidebar (issue 16) | Covered by backlog |
| **Hierarchy parents menu** (`⌥0`) | Keyboard breadcrumbs | 🟡 have path bar | Minor |
| **Clone folder to other pane** | Point inactive pane at active folder | ❌ (have copy-*files*, not clone-*view*) | Minor |
| **Regex quick search** | Filter by substring **or** regex | 🟡 substring type-ahead only | Minor |
| **Decoupled selection** | Move cursor without losing selection | ❌ Finder-style | UX-divergence decision, not a bug |
| **Action Bar** | Button strip + hotkey cheat sheet below panes | ❌ (have command palette, issue 19) | Deferred |
| **Extensibility suite** | Lua plugin API · config DSL · configurable keybindings · themes · fonts · CLI | ✅ Gadgets-lite only (issue 36, shipped) | ➖ mostly *against* the lightweight/Finder-native thesis — **not** parity targets; Gadgets-lite is the one shipped exception |

> **PM note.** Marta's extensibility is its moat *and* its weight. Don't chase
> plugin/theme/DSL parity — it fights "lightweight + Finder muscle memory." The
> three worth filing (34/35/36) are the ones that either extend an existing
> Diptychon strength (the op queue) or are self-contained, high-utility, low-weight.

---

## 6. Issue 18 — Operation *legibility*: where we stand

**The trait.** *Legibility* = can the user **see what just happened** and **reverse to a
chosen point** — not just fire blind ⌘Z. The reversible Operation spine (ADR 0004)
already makes actions undoable; issue 18 makes that spine **visible and scrubbable**
("you moved 12 files to /Archive 8 min ago → Undo back to here"). Reversibility is
*done*; **legibility is the gap** (see transferable-learnings §5; 2026-06-30 retro).

**Legibility ladder — the fitness function (test where any tool stands, don't assert):**

| Level | Definition | Who |
|---|---|---|
| **L0** | Operation invisible, no undo | Finder (moves) |
| **L1** | Blind LIFO undo (⌘Z), no visibility of *what* reverts | **Diptychon today**; Finder (partial); Marta/Nimble (+ live queue) |
| **L2** | Persistent, **visible activity log** of past operations | **ForkLift** (Activity/Log pane) |
| **L3** | **Scrubbable timeline** — click any past point, "undo back to here" w/ legible summary | **nobody ships** — issue 18 target |

**Standing: Diptychon = L1 today → L3 target.** We *lead* on the underlying spine
(multi-level, real inverses) but *trail ForkLift on visibility* — they surface ops in an
Activity/Log pane, we surface nothing yet. The whitespace we'd own outright is **L3**,
the scrub-to-a-point interaction no competitor has.

**How to test standing (both risks):**
- *Feasibility* — a working spike: render the existing Operation stack as a list, wire
  "undo back to index N". Cheap; the spine already exists.
- *Demand* — a **legibility probe / fake-door**: the undo toast (#18 Tier 1) is the seed;
  instrument whether users open/act on history before building the full timeline. Gate
  L3 on that signal (2026-06-30 retro: scrubbable timeline deferred until demand shows).

**User-need evidence (live dig, 2026-07-02):**
- *"Not sure if there is a way to find a log of actions. That's something I would love to
  see… a history of user actions."* — HN, dsego (Mar 2025). Same comment calls blind
  Finder undo **"potentially destructive"** (undo after reformatting an SD card) → a
  *visible* timeline is **safer**, not just nicer.
- User moved **thousands** of files to the wrong folder; Finder has no undo; wants **a log
  of moves to restore from** — Apple Community.
- *"the issue is undo… and it also covers e.g. renames"* — HN, eviks. Multi-op undo across
  move/rename, not just trash-restore.

**Competitive read.** Multi-level undo is **commoditizing** (ForkLift ✅; Double Commander
shipped it; Trove has per-panel undo stacks). A **visible log** exists (ForkLift). The
**scrubbable-to-a-point timeline is unclaimed.** But demand is **latent, not loud** —
acute-but-rare pain, individual voices not upvote piles. So scope issue 18 as a
**trust/safety/legibility** play (reinforces positioning-note's "small, stable, undoable"),
**not** a growth headline; keep **moves + bulk ops** as the wedge.

*Sources: HN [43498984](https://news.ycombinator.com/item?id=43498984),
[37403773](https://news.ycombinator.com/item?id=37403773); Apple
[254492651](https://discussions.apple.com/thread/254492651); [ForkLift version
history](https://binarynights.com/versionhistory);
[Trove](https://apps.apple.com/lu/app/trove-file-explorer/id6757410257).*

---

## 7. How to use this doc
- **Positioning checks:** when tempted to add a feature, find its row. If it's a ➖,
  the bar to flip it is "does this break *lightweight*?"
- **Pairs with:** `sidebar-research.md` (the "less than Finder" sidebar),
  `dashboard-research.md` (data-driven display), and `transferable-learnings.md`
  (what generalizes beyond Diptychon — §3 here is its restraint case study).
- **Maintenance:** spot-check competitor columns before any external use; refresh
  the Diptychon column as backlog items (11, 16, 17) ship.
