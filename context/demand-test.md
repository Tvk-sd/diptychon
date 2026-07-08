# Demand Test — does the right user *pull*?

> Snapshot: 2026-07-07. The validation step **before** `gtm-plan.md`'s sequenced
> rollout and before spending $99 on notarization. Grounded in `netnography/` (the
> segment + JTBDs) and `positioning-note.md`. Pairs with `docs/distribution.md`
> (why the download is broken — that's a *funnel* problem, deliberately out of scope
> here).

## The one question

Not "is it usable?" (that's usability). **Does a right-fit user *pull* — keep it and
want more, unprompted, after doing real work on their own files?** Politeness ("cool,
nice") is not demand. The signal is **unprompted return** + **switching intent** +
**a specific referral**.

Why this gates the license: a file manager fights entrenched muscle memory, so the bar
is pull, not approval. If pull is real, the broken download (notarization, $99) becomes
the bottleneck worth paying to remove. If it isn't, $99 buys a smooth door to a room
no one wants to enter.

## Who — recruit 5 (screener)

Segment (from netnography), **must-have all**:
- Daily Mac user who **lives in the keyboard** and finds Finder slow/mouse-heavy.
- Daily finder user who **lives in the file manager** to organise artefact heavy work. 
- Cares about **native / lightweight / no-telemetry / one-time-buy** (values-hygiene).

**SHould have** (relevant but does not fit the power user hypothesis I currently have )
- Has **tool-hopped** file managers (Marta / ForkLift / Nimble / Path Finder) or comes
  from **Total/Norton Commander** (dual-pane muscle memory).

**Must-NOT** (screen out — they'll give misleading reads):
- Casual Finder users who don't feel the pain → won't pull regardless (page should
  *filter* these, per landing SCOPE).
- **Remote-first** users (SFTP/WebDAV as the core job) → JTBD-5 is deliberately out of
  Diptychon's scope; they'll reject for a reason you won't fix.

Mix to beat friendliness bias: **2 from your network + 3 network-of-network / cold**
(people who've publicly hunted a "Finder alternative"). Close friends inflate the read.

## Delivery — bypass the broken funnel

The download is confirmed broken (ad-hoc, `spctl: rejected` → Sequoia trashes it). That
is **not** part of this test. Hand-install so friction can't contaminate the demand read:
- send the zip + 3-line note and be on a call to unblock.
- Log install friction **separately** — it's the funnel evidence the license later fixes,
  not a demand signal.

## The session (~30–40 min, per person)

1. **Frame, don't sell:** "I built a dual-pane file manager. I want your honest read, not
   encouragement — if it's not for you, that's the most useful thing you can tell me."
2. **Install together** (friction → separate log).
3. **Real task, their files — then shut up.** Give one real job they'd normally do in
   Finder/their tool; do **not** demo:
   - organize a messy Downloads/Desktop folder, **or**
   - move a batch between two folders, **or**
   - rename a series (JTBD-7), **or**
   - find a file in a deep/nested tree (JTBD-6, the search we just shipped).
   Watch the hand: where do they light up? where do they stall? do they reach for a
   keystroke that isn't there? (This is the §14/§21 move — real input, watch the hand.)
4. **Demand probes (and not moving goalposts):**
   - **Sean-Ellis PMF:** "If you could no longer use Diptychon, how would you feel —
     *very* disappointed / somewhat / not?" **+ why.** (≥40% "very" among fit users =
     signal; at N=5 it's directional — the *why* matters more than the %.)
      - if more than 3 people would say they would be very disappointed.
   - **Switching:** "What would you use it *instead of* — and would you actually switch?"
     (Switching intent > compliment. Entrenched-tool inertia is the real adversary.)
      - if more tan 2 person reopend the app in the next 10 days
   - **Referral:** "Who *specifically* needs this?" — a named person, not "lots of people."
      - if one person gets mentioned that could use it 
   - **Values probe (segment-specific):** does "native, ~1.5 MB, no telemetry, one-time
     buy" read as a *reason to switch* or a nice-to-have? (T-A/T-B/T-C say it should pull.)
   - **Pay probe (one-time buy — model decided):** "If this were a **one-time €5,99**,
     would you buy *today*?" Watch the flinch, not the polite yes. (Anchor: Nimble
     Commander / ForkLift ≈ $30; Diptychon is leaner + newer → test below them. Swap
     €19 for your real candidate; if you want price sensitivity, also ask "at what price
     is it *too cheap to trust* / *too expensive*?")

## The retention test — the real signal

**Do not decide from the session.** A file manager's demand lives in whether they open
it **again, unprompted, days later**. So:
- Leave it installed. **Do not remind or nudge.**
- ~Day 10: check whether they opened it on their own (ask, or read it from the **#48
  usage instrumentation** if that ships first — that's exactly what it's for).
- Unprompted re-open on real work = the strongest pre-launch demand signal there is.

## Decide — set BEFORE running (no moving goalposts)

- **GO** to buying the lisence when:
- **≥3/5 "If you could not use Dyptichon - how would you feel: if very disapointed"** AND
  **≥2/5 re-opened dyptichon unprompted** within 10 days AND 
- **≥1 person refferal in the interview or after**. 
- ITERATE but don't buy yet if there is feedback about usability and some delight. There's a **product gap** — most likely one of the netnography's under-served JTBDs (persistence JTBD-1, keyboard-trust JTBD-2). which means I would have to recheck the entry to the markets and then retest it.  
- **STOP / RETHINK** if it is politeness only, with no return, no referral, and when they keep reaching for
  their old tool. **Demand problem, not a door problem** — $99 wouldn't have helped.

## Anti-bias guardrails (so the test can't flatter you)

- Recruit ≥3 who don't owe you niceness.
- **Separate usability from demand:** a confusing UI is fixable and is *not* "no demand."
- **Don't demo.** Narrating features contaminates the pull signal.
- Install friction ≠ demand read (you hand-delivered) — but *do* log it; it's the funnel
  problem the license fixes.

## Timeline

- **Week 0:** recruit 5 + finalize screener.
- **Week 1:** 5 install-and-task sessions.
- **Week 1–2:** leave installed, no nudge.
- **~Day 10:** retention check + PMF follow-up → GO / ITERATE / STOP.

## Decided (2026-07-07)

1. **Monetization = one-time purchase** (segment-aligned, T-A anti-abo). Pay-probe names
   a concrete candidate price (€19 anchor above) so the signal is sharp. Only open sub-
   choice left: the *actual* number to test — pick it before session 1.
2. **Recruit split = 2 network + 3 cold-ish** (public "Finder alternative" tool-hoppers),
   to balance speed against friendliness bias.
