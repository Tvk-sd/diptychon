# Google Ads Setup — reach-test read (paste-ready)

> Snapshot: 2026-07-07. Executes Track B of `channel-plan.md`. Goal: a **capture-rate
> read**, not scale. Landing = **`diptychon.com/?src=gads`** (home capture page; decided
> 2026-07-07). Pairs with `competitor-facts.md` (keyword targets) + the live `src` attribution.

## The values-consistent measurement (read first)

**No Google conversion tag on the site** — it would contradict the "no telemetry" brand and
the first-party `src` attribution we built. So:
- Ads bids for **clicks** (it can't see the signup — the signup lives in our KV).
- You compute the result yourself:
  - **capture-rate(gads) = `signups:src:gads` ÷ Google-Ads-clicks** (clicks from the Ads dashboard).
  - **cost-per-signup = spend ÷ `signups:src:gads`.**
- Read `signups:src:gads`: `npx wrangler kv key get "signups:src:gads" --binding DOWNLOADS --remote`.

## Campaign settings

- **Type:** Search. **Networks:** Display **off**, Search Partners **off** (cleaner data).
- **Locations:** start focused — **US, UK, CA, AU, DE** (site is English; DE searchers still
  use English terms). Tighten to one geo if spend scatters.
- **Language:** English.
- **Budget:** **€10/day** (~€70/wk). It's a ratio read, not reach — cap it.
- **Bidding:** **Maximize clicks** with a **max CPC ≈ €0.60–0.90** (no conversion signal on
  site, so don't use Max-conversions). Niche terms are cheap; the cap stops broad overpay.
- **Final URL (all ads):** `https://diptychon.com/?src=gads`

## Ad group 1 — Competitor-intent (highest conversion)

Keywords (phrase match `"..."`; add exact `[...]` once you see which convert):
```
"marta alternative"
"forklift alternative"
"nimble commander alternative"
"path finder alternative"
"commander one alternative"
"total commander for mac"
"total commander mac alternative"
```

## Ad group 2 — Category-intent

```
"dual pane file manager mac"
"dual panel file manager macos"
"two panel file manager mac"
"keyboard file manager mac"
"lightweight file manager mac"
"finder alternative mac"
"mac file manager keyboard"
```

## Negative keywords (campaign-level)

```
windows, linux, ios, iphone, ipad, android
free            (low fit for a one-time-buy — optional, saves budget)
how to, tutorial, guide
crack, torrent, serial
"finder not working", "finder crash"   (support intent, not switchers)
```

## Responsive Search Ad (one per ad group; reuse copy)

**⚠ Trademark rule:** you may *bid* on competitor names, but do **not** put "Marta / ForkLift /
Path Finder / Total Commander" in the ad **text** — it can get disapproved. Keep text generic.

**Honesty:** the landing is "Notify me at launch," not a download — so at least two headlines
must signal *coming soon*, or clickers expecting a download bounce (and pollute the read).

**Headlines** (≤30 chars each — Google rotates them):
```
Keyboard-First File Manager
Dual-Pane Mac File Manager
A Faster Finder for macOS
Native, ~1.4 MB, No Bloat
One-Time Buy, No Subscription
Move Files in One Keystroke
The Anti-Electron File Manager
No Telemetry. Native. Tiny.
Two Folders, One Keystroke
Undo Any File Move
Coming Soon — Join the Beta
Get Notified at Launch
For Mac Keyboard Power Users
Lightweight Mac File Manager
```

**Descriptions** (≤90 chars each):
```
Dual-pane, keyboard-first, native macOS. ~1.4 MB. One-time purchase, no telemetry.
Coming soon. Leave your email and get one heads-up the day it's ready. No spam.
Move files between two folders with a single key. Undo anything. Real Finder tags.
A tiny, native alternative to heavier Mac file managers. One person, not a company.
```

**Extensions:**
- **Sitelink:** "Compare vs other file managers" → `https://diptychon.com/vs?src=gads` (your only
  page where competitor names are fine — it's editorial, not ad text).
- **Callouts:** `~1.4 MB` · `One-time purchase` · `No telemetry` · `Keyboard-first`.

## Read + decide (ties to reach-test.md)

- Weekly: `signups:src:gads`, Ads clicks + spend → capture-rate + cost-per-signup, per ad group.
- **GO:** competitor-intent converts at a healthy rate (set the bar once you see baseline; e.g.
  ≥8–10%) at a sane cost-per-signup → that's a launch channel. Notarize, then point it at a real
  download + the warm list.
- **ITERATE:** clicks, weak capture → message/landing problem (cheap to fix).
- **STOP:** no sane-cost right-fit signups → paid intent isn't affordable here; lean on organic.

## Honest caveats

- **Ad-blocker sub-segment** (Little Snitch crowd, netnography T-C) under-samples on paid → read
  Ads *together* with organic `src`, don't judge demand on Ads alone.
- Competitor-intent volume is **niche** → low clicks/day is expected; that's fine for a ratio read.
- No real CPC/volume numbers yet — sanity-check in Ads' Keyword Planner before pushing budget.
