# Session retro — 2026-06-27

A straight reflection on the session that shipped issue #28 (keyboard commands +
Open-With favorites), the branch cleanup, and issue #19 (command palette + file-row
hover). Written for you, not for the repo's permanent record — kept honest, including
where I cost us time.

## What we actually shipped
- **#28** keyboard expansion + customisable Open-With favorites → merged to `main`.
- **Branch hygiene** → landed the stacked architecture work, pruned everything to a
  clean `main`-only tree.
- **#19** ⌘K command palette + row-hover highlight → PR #29 open against `main`.

Most of it went smoothly. One thing did not: the **file-row hover took ~15
iterations**. That's the part worth dissecting, because almost all the wasted time was
avoidable.

## Where the time actually went (owning it)
The hover bug was real from the first attempt — but I spent most of those iterations
**guessing at the visual** and being **misled by my own tests** instead of isolating
the problem. Three times I had "evidence" that pointed the wrong way:
1. Synthetic mouse events that don't drive macOS tracking → working code looked dead.
2. A test window I assumed was centred but wasn't → my synthetic cursor missed it.
3. A test instance stuck on a permission prompt with **zero files loaded** → nothing
   to hover over.

The fix that should have come on iteration 2, not 12: **force the hover state on at
launch and screenshot it** (proves rendering with no input), and **separately log the
state-setter** (proves the event path). The moment I split "is it being set?" from "is
it being drawn?", it collapsed in one step. That's on me — I know that technique; I
reached for it late. (It's now written up as transferable-learnings §14 so I don't
repeat it.)

## What you could have flagged earlier (the useful part)
You're not a developer, and you don't need to be — but a few small moves from your seat
would have short-circuited the loop. In rough order of leverage:

1. **Describe exactly what you see, not just "doesn't work."**
   "still not visible" and "still not works" each cost a full round-trip. The single
   most valuable thing a non-coder can give in a UI bug is a *precise symptom*:
   *nothing at all? a flash then gone? the wrong row lights up? right behaviour, ugly
   colour?* Each of those points at a different layer. Proof: your best feedback —
   "it scrolls when I move the cursor, and the arrows only move through 4 commands" —
   was instantly diagnosable. I fixed that in one pass. Specific beats fast.

2. **Offer the real-mouse observation sooner.**
   The breakthrough came when you moved your *real* mouse over a logging build and I
   read the trace. That could have happened five rounds earlier. When an agent is
   clearly flailing on something only reproducible by hand, "want me to just do X and
   tell you precisely what happens?" is a superpower. (I should also have *asked* for
   it earlier — shared blame.)

3. **Hand me the environment facts only you can see.**
   Your app prompts for folder access on launch (TCC), opens its window off-centre, and
   you run in dark mode. I burned iterations *discovering* each of those. A one-liner —
   "heads up, it asks for Desktop permission when it starts" — would have killed the
   empty-panels confusion outright.

4. **Call the loop.**
   After 2–3 failed "try it now" rounds, you're allowed to say *"stop guessing —
   instrument it and prove it works before you show me again."* That's legitimate
   steering, and it forces me off the guess-and-check treadmill. You don't have to wait
   for me to self-correct.

## What worked well (so we keep doing it)
- **Your show → test → confirm rhythm.** "Open the app, let me try it" is the right
  loop; it caught real issues (the palette hover design mismatch, the scroll bug) that
  no test would have.
- **Crisp decisions when I surfaced them.** Merge method, branch base, palette key,
  scope — you answered the AskUserQuestion prompts decisively and we moved.
- **You trusted me to drive the git surgery** (stacked branches → clean `main`) but I
  kept it gated behind a written plan + your approval. That balance felt right.

## A protocol for next time we're stuck on a UI thing
When a visual change doesn't appear after **two** attempts, we switch modes:
1. I stop tuning pixels and **instrument** — force the state on, screenshot, log the
   setter — and tell you what I find before changing anything.
2. You give me the **precise symptom** in one line, and any **environment quirk** you
   know.
3. If it's only reproducible by hand, we do **one real-mouse/real-click pass** against
   a logging build early, not late.

## Bigger project takeaway
Diptychon keeps teaching the same meta-lesson (it's why we dropped to AppKit in issue
06, why XCUITest drag is unreliable, why §12 and §14 exist): **features that depend on
real cursor/event behaviour are not reliably testable by synthetic input or unit
tests.** Budget a human-in-the-loop or a forced-render harness for them up front — don't
discover it mid-bug.
