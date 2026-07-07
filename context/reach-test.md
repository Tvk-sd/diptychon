# Reach & Interest-Capture Test — can I get the right strangers to say "yes, I want this"?

> Snapshot: 2026-07-07. Answers the rung the netnography and the pull-test skip:
> **reach**. Pairs with `gtm-plan.md` (this de-risks its "reach comes later"
> assumption) and `demand-test.md` (the pull/usability rung, run *after* this on the
> warm list). Grounded in `netnography/` (segment + verifiable-claims norm).

## The three rungs (so we stop conflating them)

1. **Latent interest** — segment is unhappy with Finder alternatives → **done** (netnography).
2. **Reachable, convertible interest** — *can I get right-fit strangers in front of the
   promise, via which channel, and get a low-commitment "yes"?* → **this doc.**
3. **Pull** — do they keep it once they try? → `demand-test.md`, later, on the warm list.

## The hard constraint (read first)

**Do not route reach traffic to the download** — it's ad-hoc, `spctl: rejected`, and
Sequoia trashes it. And **do not spend r/macapps + HN yet** — they're the one-shot
channels that decide this segment; burning them on a broken funnel is unrecoverable.

So while un-notarized: **capture interest, don't convert to install.** Swap the page's
primary CTA from "Download" → **"Get notified at launch"** (email). This decouples the
reach test from the $99 notarization blocker entirely.

## The reusable core — a capture page (build this once, feed it from any channel)

The page's job: make a Finder/Nimble/Total-Commander-minded user think *"that's for me"*
in <10s (per landing SCOPE), then capture a low-commitment yes.

- **Filtering promise** (verbatim from SCOPE): fast, keyboard-first, dual-panel, ~1.5 MB,
  native, no Electron, one-time purchase, no telemetry. Let it **repel** casual Finder
  users and remote-first users on purpose.
- **Primary ask:** email — *"Notify me when it's ready."* (Not "download.")
- **Wishes micro-survey (3 taps, optional, right after signup):** *which matters most to
  you?* → checkboxes seeded from the JTBDs: persistence · keyboard-trust · transfer queue
  · preview · **remote (SFTP/WebDAV)** · batch-rename · local search. Two jobs at once:
  (a) it **self-segments** — a remote-first signup flags themselves as out-of-scope; (b)
  it turns traffic into a **ranked wishlist** (first-party, extends the netnography).
- **Verifiable claims only** (netnography norm: unbacked claims don't count) — measured
  app size, an open privacy policy line. This *is* the values-hygiene pitch.
- **Prereq:** take the capture page **out from behind Cloudflare Zero Trust** (or ship a
  public capture variant). Gated = zero reach.

## Channels — fast vs. slow, and their role

| Channel | Speed | Role | Note |
|---|---|---|---|
| **Light seeding** (comment in an existing "Finder alternative" thread; niche Mac Discords/Mastodon Mac-dev circles) | days | fast read on convertible interest | *Not* the r/macapps front page — save that |
| **Tiny paid probe** (Reddit or Google Ads on high-intent terms, €50–100 cap) | days | buys a clean, comparable capture-rate read per channel | Optional; fastest way to compare channels honestly |
| **SEO + AI-search content** ("Finder alternative macOS", "dual-pane file manager Mac", "Total Commander for Mac") | weeks–months | compounding, evergreen, high-intent | **Start now** so it's warm by launch; won't deliver this week. AI-search (Claude/Perplexity) rewards citable, specific content |
| **r/macapps + HN** | one-shot | the real launch channel | **Hold until notarized** + warm list ready |

## What you measure (traffic is vanity)

- **Capture rate = visits → email**, *by channel.* That's the signal — which channel
  delivers *convertible* right-fit interest, not just clicks.
- **Wishes distribution** — validates/extends the JTBD ranking with first-party data;
  flags positioning risk if the values-hygiene angle doesn't pull.
- **Out-of-segment share** — how many signups are remote-first (self-flagged). High share
  = your reachable traffic skews to a job you don't serve → positioning/keyword problem.

## Decide (set before running)

- **GO (a channel works)** → a channel converts right-fit visitors to signups at a healthy
  rate (set your own bar; e.g. 10%+ on high-intent traffic). **That's your launch channel.**
  Now the $99 + notarization pays off: notarize, then launch to the **warm list**.
- **ITERATE (traffic, no capture)** → people arrive but don't sign up. **Positioning /
  message problem**, not reach — the promise isn't landing. Rework the page's first breath,
  re-test. (Cheaper to fix than product.)
- **STOP (can't reach them)** → no channel delivers right-fit traffic at sane cost. The
  segment is real but **not economically reachable** at your scale — rethink go-to-market
  (or accept it's a tiny, hand-sold tool).

## How this re-sequences everything

- **Now (pre-$99):** capture page live + public → 1 fast seeding move + optional tiny paid
  probe → SEO/AI content started in parallel. Measure capture rate + wishes.
- **If a channel converts:** buy the license, notarize, then spend r/macapps + HN on a
  **working** download to a warm list — the one-shot fired once, at full strength.
- **Then, and only then:** run `demand-test.md` (pull) on the people who actually showed up.

The old plan built the perfect 5-person session before knowing if 5 were reachable. This
flips it: **prove reach + capture the list first; perfect the try-and-keep second.**
