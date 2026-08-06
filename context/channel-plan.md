# Channel Plan — feed the capture page, measure capture-rate

> **2026-08-06:** superseded in part — ADR 0008 retired the capture page this
> plan feeds. The post-download channel picture is `distribution-playbook.md`;
> Track B's ads structure below remains the reference for a paid test.

> Snapshot: 2026-07-07. Executes `reach-test.md` now that the capture page is live
> (diptychon.com). Two tracks in parallel: **SEO/AI slow-burn** (backbone) + **Google
> Search Ads** (fast read). Grounded in the netnography segment and a SERP scan
> (2026-07-07). Success = **capture-rate by channel**, not traffic.

## The SERP reality (why this shape)

Page one of "finder alternative mac" is a **listicle war** — owned by review/roundup
sites (XDA, TheSweetBits, Tenorshare, FileMinutes, Tokie, ftp-mac, SimplyMac) and
competitor product pages, **not** product homepages. Consequences:
- Ranking a homepage for the head term is a months-long slog → **don't fight it head-on.**
- Real leverage: **(a) get into the roundups**, **(b) long-tail + competitor queries**
  where intent is sharp and competition thin, **(c) be AI-citable** (Claude/Perplexity
  synthesize from those roundups + a factual "vs" page).
- **Google Ads = the shortcut over the listicle wall** for a niche budget — especially
  competitor-intent terms.

## Track A — SEO / AI slow-burn (free, compounding, start now)

**A1 · An AI-citable comparison page.** A factual `/vs` page (or section): Diptychon vs
Marta / ForkLift / Nimble Commander / Path Finder, on the axes the segment decides by
(native + size, keyboard, one-time-buy, no telemetry, persistence, undo). Verifiable
claims only (measured ~1.4 MB, open privacy line — netnography norm). This is what AI
search extracts and what a roundup author copies. **Highest-leverage single asset.**

**A2 · Long-tail / competitor content targets** (win these, not the head term):
- `marta alternative mac`, `forklift alternative`, `nimble commander alternative`,
  `path finder alternative`, `total commander for mac`
- `lightweight file manager mac`, `keyboard file manager mac`, `dual pane file manager mac`,
  `finder alternative no electron`, `two panel file manager macos`
Each → a focused section/page answering that exact query, linking to the capture page.

**A3 · Roundup outreach (often > own ranking).** Email the authors of the live roundups
(XDA, TheSweetBits, FileMinutes, Tokie, SimplyMac, Tenorshare) to include Diptychon.
Pitch = the wedge: *"native ~1.4 MB, keyboard-first, one-time purchase, no telemetry —
the anti-Electron dual-pane."* Offer a build + the verifiable specs. Track who lists it.

## Track B — Google Search Ads (paid, parallel, fast read)

Purpose: buy the same high-intent search **now** while SEO warms up, and get a
capture-rate signal per intent-type in weeks, not months. **Small budget — this is a
read, not a scale play.**

**Structure — 2 ad groups:**
1. **Competitor-intent** (highest conversion): `marta alternative`, `forklift alternative`,
   `nimble commander alternative`, `path finder alternative`, `commander one alternative`,
   `total commander for mac`. Phrase/exact match to control spend.
2. **Category-intent:** `dual pane file manager mac`, `finder alternative keyboard`,
   `lightweight file manager mac`, `two panel file manager macos`. Phrase match.

**Negatives:** `windows`, `linux`, `ios`, `iphone`, `android`, `free` (optional — low-fit
for a one-time-buy), `how to`, `tutorial`, `finder not working` (support intent).

**Budget:** start **€10/day** (~€70/week), single-region test (your core geo). Enough for
a directional cost-per-signup; not enough to distort. Cap it — the goal is the ratio.

**Ad copy (honest, or it bounces):** the landing is a *capture* page, not a download.
Signal "coming soon / join the beta" so a searcher who wanted to try *now* isn't baited.
Lean on the wedge: keyboard-first · dual-pane · ~1.4 MB · one-time · no telemetry.

**Landing:** the capture page (later: a query-matched variant per ad group if it converts).

## ❗ Prerequisite for ALL of this — per-channel attribution

Right now `/api/notify` stores email + wishes but **not where the signup came from** — so
you can capture, but you **cannot compare** Google Ads vs SEO vs seeding. Without this the
whole "capture-rate by channel" goal is impossible. Fix (small):
- Tag every inbound link with `?src=` (`?src=gads`, `?src=mastodon`, roundups `?src=xda`…).
- Page reads `src` from the URL, includes it in the `/api/notify` POST.
- Worker stores `src` on the signup record; add a `signups:src:<src>` counter.
Then capture-rate per channel is a KV read. **Build this before spending on ads.**

## Measure (the only numbers that matter)

- **Capture-rate = signups / clicks (or sessions), by `src`.** The comparator across channels.
- **Cost-per-signup** for Google Ads (spend / signups) — is paid intent affordable here?
- **Wishes distribution** + **out-of-segment share** (remote self-flag) — fit of the traffic.
- Traffic/impressions/CTR are diagnostics, **not** the goal.

## Honest caveats

- **Values-hygiene sub-segment runs ad-blockers** (Little Snitch crowd, netnography T-C) →
  Google Ads *under-samples* your most values-driven users. Paid = fast but slightly biased;
  SEO/organic reaches them. Read the two together.
- Ad → "notify me" (not download) is a deliberate mismatch: a lower capture-rate here isn't
  failure, it's the reach test's actual question — *do they want it enough to wait?*
- No real keyword volumes/CPCs yet (no Keyword Planner pull) — validate in Ads' own
  forecaster before committing budget.

## Decide (ties to reach-test.md GO/ITERATE/STOP)

- **GO** → a channel converts right-fit clicks to signups at a healthy rate (set the bar in
  Ads once you see baseline; e.g. ≥8–10% on competitor-intent) at a sane cost-per-signup.
  That's your launch channel → notarize, then point it at a real download + warm list.
- **ITERATE** → traffic, weak capture → message/landing problem (cheaper to fix than product).
- **STOP** → no channel delivers right-fit signups at sane cost → not economically reachable
  at your scale; rethink GTM (or accept a tiny hand-sold tool).

## Sequence

- **Week 0:** build `src` attribution (prerequisite) · draft the `/vs` page (A1) · set up the
  Ads campaign (paused) · draft roundup outreach.
- **Week 1:** Ads live at €10/day · send 5–8 roundup pitches · publish A1 + 2–3 A2 targets.
- **Weeks 2–4:** read capture-rate by `src`, cost-per-signup, wishes. Then GO/ITERATE/STOP.
