# Competitor landing page research — depth &amp; content benchmark

**Date:** 2026-08-11
**Purpose:** benchmark how deep/long competitor own-marketing pages are and what they
contain, to evolve Diptychon's `index.html` design. Not a fact-comparison (that's `/vs.html`
+ issue #67's A2 pages) — this is about page *structure and content depth*, on the vendors'
own sites.
**Scope:** ForkLift, Path Finder, Marta, Nimble Commander, Commander One — official homepages,
fetched live.

## Diptychon today (baseline)

Single page, ~7 sections: Nav → Hero (h1 + demo video + email-notify form) → 3 USP blocks
(h3 each) → Shortcuts section → Compare teaser (links to `/vs`) → closing CTA (h2) → Footer.
No FAQ, no testimonials, no pricing, no press logos — expected, pre-launch/free-beta.

## Comparison table

| | ForkLift | Path Finder | Marta | Nimble Commander | Commander One | **Diptychon** |
|---|---|---|---|---|---|---|
| Length | Long (34 headings, 29 feature blocks) | Medium-long, 9 sections + 2 modals | Short, 4 blocks, ~450 words | Medium, ~5 blocks | Medium, 6 sections (+ separate pricing page) | Medium, ~7 sections |
| Per-feature screenshots | No (icons only) | Partial (1 hero + demo video) | 2 features get GIFs | No (icons only) | Yes — 4 feature screenshots | 1 hero demo video only |
| Pricing on page | No (off to `/store`) | No (hidden behind Chargebee checkout) | No (Patreon link only, beta) | N/A (free) | No (separate `/purchase.html`), but clear once there ($29.99 / $99.99) | N/A (free beta) |
| FAQ | No | No (referenced, not shown) | No | No | Yes (on purchase page) | No (FAQ lives on `/vs`-family pages only) |
| Testimonials / reviews | Footer star rating only (4.6, 374) | Section exists, content didn't render (unconfirmed) | None | None | Press citations, not customer quotes (6 outlets) | None |
| Competitor comparison table | None | None | None | Self-vs-self only (MAS vs Standalone) | None | **Yes — `/vs` + 4 A2 pages** (unique to Diptychon) |
| Video/demo | None | Yes, dedicated section | None (2 GIFs only) | Screenshot carousel only | None | Yes, in hero |

## What stands out

1. **None of the five competitors compare themselves to named rivals on their own site.**
   Nimble Commander's table is edition-vs-edition, not vs-competitor. Diptychon's `/vs` +
   the four A2 pages (#67) are the one asset nobody else in the category has. The home page
   already teases it (`#compare` → `/vs`) — that's correctly the sharpest wedge, not a gap.
2. **Per-feature visual proof is the biggest real content gap** among competitors themselves —
   ForkLift and Nimble Commander both list 10-29 features as icon+text only, zero screenshots
   per claim. Commander One is the outlier that shows a screenshot per feature block and reads
   more convincing for it. Diptychon's shortcuts section is currently text/keycap-only —
   candidate to add 1-2 screenshots or short GIFs to the shortcuts or USP blocks, not more text.
3. **Pricing transparency is inconsistent and mostly evasive** (ForkLift, Path Finder both hide
   price behind a click; Commander One is the one that's upfront once you reach the page).
   Not actionable now (Diptychon is free-beta), but relevant for when a paid tier ships — ties
   to the "buy once, no update window" wedge already logged in #67. Worth deciding on price
   transparency as a stance before that copy is written, not after.
4. **Social proof is thin across the whole category** — nobody has real customer testimonials
   with names; only Commander One has real (press) citations. Confirms #67's finding that press
   outreach is a weak lever right now — nothing to catch up to here, category-wide gap.
5. **Copy style splits into two camps**: spec-sheet/enumeration (ForkLift, Nimble Commander,
   Marta — terse, benefit-free, feature-name-as-headline) vs. superlative-but-unproven
   (Path Finder: "#1", "revolutionized", no numbers backing it). Diptychon's current copy
   ("Give your keyboard the file manager", honest `/vs` framing) already sits closer to the
   evidence-based end that #67's citation research says AI search actually rewards — no change
   indicated, this validates the existing direction rather than suggesting a new one.

## Recommendations (ranked)

1. **Add 1-2 real screenshots or a short GIF to the shortcuts section.** Cheapest, most
   concrete gap found — competitors with per-feature visuals (Commander One, Marta's 2 GIFs)
   read more convincing than the icon-only ones. Diptychon already has `demo.mp4` /
   `demo-poster.jpg` assets to draw a clip from.
2. **No FAQ needed on the home page.** Category norm is FAQ-if-anywhere on a
   pricing/purchase page, not the home page — Diptychon already follows this pattern
   (FAQ lives on the `/vs`-family pages). Leave as is.
3. **Hold off on a testimonials section.** Whole category is thin here and #67 already
   concluded press outreach isn't a near-term lever. Revisit once there's real user feedback
   to quote (ties to #72, feedback channel).
4. **When pricing ships, default to showing the number on-page**, not behind a checkout
   click — Commander One is the credible example, ForkLift/Path Finder read evasive by
   comparison. Flag for whoever writes that page later.

## Not researched

Total Commander (Windows-only, already covered as a longtail page in #67, not a native
macOS competitor with its own Mac-facing landing page). muCommander, Directory Opus — not
in the existing `/vs` competitor set, skipped to stay consistent with it.
