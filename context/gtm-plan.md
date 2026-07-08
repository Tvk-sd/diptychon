# Diptychon — Distribution & GTM Plan

> Snapshot: 2026-07-06. Pairs with `positioning-note.md` (sentiment + §GTM),
> `netnography/` (the coded evidence), and `docs/distribution.md` (the technical
> how-to-ship runbook). This doc is the **sequenced go-to-market**: who we tell,
> in what order, and how we know it's working.

---

## BLUF

Diptychon is a free, un-notarized beta today. The goal right now is **not** a big
launch. It is to earn a **small pool of the right early users** who give feedback and
become advocates, without burning the one-shot first impression on the channels that
decide this segment. Reach comes later, once the build is notarized and the trust
story (Issues 41/34) has shipped.

Two audiences, two jobs, never the same post:
- **Diptychon users** (Mac power users) → won by word-of-mouth in **r/macapps + Hacker News**.
- **Till's builder/PM audience** → **LinkedIn + Substack**, the "PM lesson from the builder's
  chair" narrative. Amplifies the person, not the download.

---

## Evidence base (why this plan, not a generic one)

From the netnography (`netnography/03` §3-4, `04` §4) and `positioning-note.md §GTM`:

1. **Values-hygiene is the buying argument.** Native, ~1.5 MB measured, no telemetry /
   100% local, no subscription. This segment *actively advertises* on exactly these.
   Make them prominent and **verifiable** (measured numbers, an open privacy policy).
2. **Proof culture.** These users run Little Snitch and screenshot data dialogs. They
   reward proof and **punish overclaiming**. Never imply the polished path works before
   it does.
3. **Communicate the segment boundary.** Do not market against ForkLift/QSpace on remote
   (SFTP/WebDAV is deliberately out of scope). Own the frame: *"the light, reliable,
   native dual-pane for local work."* Say it first, so no one's first review is "but no SFTP."
4. **Advocacy is the channel, and astroturf is fatal.** One convinced advocate carries
   weight; a fake-account push is smelled instantly and poisons the well
   (`netnography/00` §5 ethics). Show up as a real participant.

The opening (positioning-note "the read"): **win Marta's audience minus the "is it still
alive?" fear** — actively maintained, reversible, Finder-compatible, visibly lightweight.

---

## The big lever: notarization is a trust asset, not a distribution chore

For *this* audience, the $99/yr Apple Developer ID + notarization is not just polish. An
unsigned beta that throws a Gatekeeper warning is a **credibility cost** with people who
scrutinize exactly that. Notarizing before the real r/macapps + HN push materially
improves reception. Treat the $99 as a GTM line item, not an ops afterthought.
(Mechanics: `docs/distribution.md` → Target path.)

---

## Phases (with entry/exit criteria)

### Phase 0 — Ship an honest artifact (now)
- **Do:** produce the ad-hoc-signed `Diptychon.zip` (`docs/distribution.md` current path).
  Publish it, or hand it out, with the one-time "right-click → Open" instruction visible.
  The landing page already states "free beta, not yet notarized" and the 3 open-it steps.
- **Channel:** direct (DM / email / a GitHub Release). Not a broadcast.
- **Exit when:** the zip exists and at least a few people can install it unaided.

### Phase 1 — Seed 10–20 of the right testers (weeks, not a launch)
- **Goal:** feedback + the first genuine advocates. Small and high-signal.
- **Where:** the specific r/macapps / HN / Marta-community threads already surfaced in the
  netnography corpus. Participate honestly; offer the beta where it's *on-topic*, not as a drop.
- **Say:** lead with values-hygiene + the segment boundary; ask for feedback, don't pitch.
- **Watch:** do the trust concerns (persistence, operation visibility) show up? That validates
  Issues **41** (state persistence) and **34** (operation queue) as the pre-launch priorities.
- **Exit when:** ~10-20 real installs, a handful of unsolicited "this is nice" signals, and
  the top friction points are known.

### Phase 2 — Build-in-public, in parallel (ongoing, different audience)
- **Goal:** grow Till's audience + a soft indirect funnel. Does not depend on Phase 3.
- **Where:** LinkedIn (drip) + Substack (depth). Story = the *decisions*, not "download my app."
- **Note:** content lives in `~/Projects/till-writing`; cite Diptychon learnings via
  `source: diptychon#n`, never copy. (Till is writing these himself.)

### Phase 3 — The real launch (gated, not yet)
- **Entry gate (all three):**
  1. Notarized `.dmg` on GitHub Releases + Homebrew Cask (`brew install --cask diptychon`).
  2. The trust story shipped: Issues **41** + **34** in the build.
  3. Phase-1 feedback folded in; no known "looks broken" first-run friction.
- **Do:** one clean **Show HN** + one r/macapps post. Proof numbers, segment boundary stated,
  no overclaim. This is the single high-leverage shot; spend it once.
- **Don't:** launch before the gate. A loud push on a rough, unsigned beta wastes the shot.

---

## Channel playbook (quick reference)

| Channel | Audience | Job | Rule |
|---|---|---|---|
| **r/macapps** | Users | Adoption, advocacy | Participate, don't drop. Read the sub's self-promo rules. Values + proof + boundary. |
| **Hacker News** | Users / builders | Credibility spike | One honest *Show HN*, at Phase 3. Answer every comment. |
| **Marta / power-user forums** | Users | The wedge audience | "Actively maintained, reversible, Finder-compatible." Never regress a keyboard path. |
| **LinkedIn** | Till's PM peers | Personal brand | One lesson per post + a visual. Not a product ad. |
| **Substack** | Till's readers | Depth, owned audience | The decision arc. Cite `source: diptychon#n`. |

---

## Risks & guardrails

- **Overclaiming** → instant credibility loss. Every number on the site/README must be
  measured and re-verifiable.
- **Astroturf** → poisons r/macapps/HN. Honest presence only.
- **Remote-scope confusion** → state the boundary first, every time.
- **Premature launch** → the HN/r/macapps first impression is one-shot. Hold Phase 3 behind
  the gate.
- **Arch gap** → if the shipped zip is Apple-Silicon-only, Intel users hit a dead app. Ship
  **universal**, or say "Apple Silicon only" explicitly.

## Reversal fitness-function (remote)
Only reconsider remote (SFTP/WebDAV) if **≥ X validated requests come from our own user base**,
not from other tools' forums (`netnography/04` §5). Don't let broader-market demand blur the
segment.

---

## See also
- `positioning-note.md` — sentiment + §GTM (the read this plan executes).
- `netnography/` — the coded evidence corpus.
- `docs/distribution.md` — the technical shipping runbook (zip now, notarized .dmg later).
- `PROJECT-TRACKER.md` → *Backlog priority* — Issues 41/34 as the pre-launch trust story.
