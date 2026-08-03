# The landing page distributes and learns; it does not validate

Decided 2026-08-04, after the Apple Developer membership was bought. Supersedes
the premise the site was built on — **not** the pricing model in ADR 0007, which
already anticipated this phase ("currently free, un-notarized beta").

## What changed

The site was built to answer *"should this be built?"* — a fake door. It pitches,
it captures an email, and the number of signups was the validation proxy. Issue
#55 pinned a bar on that proxy: ≥ 8 % of competitor-intent clicks convert.

Two facts killed the premise, both established 2026-08-03/04:

1. **Till builds and ships regardless.** He stated he would buy the developer
   licence at zero signups, and then did buy it. A proxy for a decision nobody
   is still making measures nothing.
2. **The licence turns the download real.** Until now `/download` served an
   un-notarized zip that Gatekeeper trashes — the site could not honestly offer
   it. With notarization (#69) it can.

A third fact reframes what to measure: a download is a commitment act, an email
address is close to none. The stronger signal replaces the weaker one.

## Considered Options

- **Keep the waitlist.** Cheapest, changes nothing. Rejected: it keeps measuring
  a decision that is already made, and it withholds a working build from people
  who came looking for one.
- **Flip the copy only** — swap "Email me at launch" for a download button, fix
  the "pre-launch" lines and the JSON-LD `offers`. Small, one deploy. Rejected
  as *sufficient*: it changes the words while leaving the page shaped like a
  persuasion funnel that ends in a form.
- **Restructure the home page around download and feedback; edit copy
  everywhere else** — chosen. The persuasion middle shrinks, the download rises
  to the top, and the form stops being a capture device and becomes the feedback
  channel. `/vs` and the four comparison pages keep their structure — they are
  already answer-first reference pages and work unchanged as entry points.

## Why

The job the page does changed, and a job change is a structure change, not a
vocabulary change. Old job: *convince a stranger that waiting is worth it* —
output is a number. New job: **put it in people's hands and learn what to build
next** — output is text and downloads.

That has three structural consequences the copy flip alone would not deliver:

- **Order.** A page whose job is distribution leads with the artifact. Today the
  download would sit below a pitch written to justify a wait that no longer
  exists.
- **The form's purpose inverts.** Step 2 today is a checkbox list
  (`persistence`, `keyboard`, `transfers`, …) — *our* hypotheses, which keep the
  respondent inside our frame. Learning needs their words, so free text is the
  instrument and the email becomes a callback number rather than a counter
  (#72).
- **Honesty stops being a liability.** "Pre-launch, no download" reads as a
  weakness on a waitlist page. "Free while in beta, here is what it does not do
  yet" reads as a reason to trust the download. The existing "stay where you
  are, if…" columns become an asset instead of a hedge.

**"Free while in beta", never bare "free".** Shipping free without the label is
the hardest pricing transition there is — charging later reads as a broken
promise to exactly the early users worth keeping. The label costs half a
sentence and keeps ADR 0007 intact and #66 open.

**"Open source" stays out of public copy** until #66 is decided. It is the only
irreversible move in this set: published code cannot be unpublished, while a
closed project can be opened any time. Ad variant E is therefore split — "Free,
no subscription, no telemetry" is testable today; the open-source half is not
advertised on a promise that may not be kept.

## Consequences

- **#55's GO bar is void, not adjusted.** It measured an instrument that no
  longer exists. Replaced in #73 by Till's time rule — one month without signal
  = stop — where signal means a clear CTR winner, 30+ usable free-text answers,
  and readable per-channel download counts.
- **Ordering is not negotiable.** #68 (is the first session survivable) and #69
  (notarized, verified download) both come before #71 (the flip). A page that
  promises a download which Gatekeeper trashes, or an app whose first thirty
  seconds nobody has watched, spends the one first impression each visitor has.
- **The machine layer ships with the copy, in one deploy.** JSON-LD `offers`,
  `llms.txt` and `llms-full.txt` are generated from the rendered pages; a page
  saying "free download" while its markup says `PreOrder` contradicts itself,
  which is the spam signal #67 warns about.
- **No telemetry, still.** ADR 0006 holds. The consequence is that the in-app
  feedback path (#72) is not a nicety — it is the entire measurement system, and
  a crash at a stranger's desk is invisible unless they write.
- **The demand test as designed is obsolete.** Five recruited sessions plus a
  day-10 retention check answered "is this wanted"; real users on a real build
  answer it better and cheaper. The pay-probe question it also carried moves
  into #66.
- **Reversible.** Nothing here forecloses charging later, and the site can go
  back to a capture page if the download turns out to be premature.
