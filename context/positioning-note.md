# Positioning Note — community sentiment & the gap for Diptychon

> Snapshot: 2026-06-26. Pairs with `competitor-benchmark.md` (the feature/footprint
> scoreboard). This note is the *market-sentiment* layer: what users actually say
> about the dual-pane peers, and where that leaves Diptychon.

> **Sourcing caveat.** Straight Reddit threads barely surfaced (US-only search,
> thin recent Reddit indexing). Evidence is review sites, one Hacker News thread,
> an Applefritter forum comparison, and Marta's GitHub issues. **Directional
> sentiment, not a rigorous review scrape** — re-verify (actual r/macapps threads,
> App Store review exports) before banking real positioning on it.

> **Update 2026-07-02 — deeper sourcing now exists.** A structured netnography
> (`context/netnography/`) since gathered r/macapps threads (via `old.reddit.com`),
> Hacker News, and the Applefritter comparison into a coded corpus. It **confirms**
> this note's core read and adds the GTM section below (§GTM). Where the two differ,
> the netnography is the better-sourced layer.

---

## What the community says

### ForkLift 4
- **Loves:** sync (claimed ~20× faster), broad remote protocols (SFTP/S3/WebDAV/
  Drive/Dropbox…), regex batch rename, modern redesign.
- **Gripes (loud):**
  - **Lost keyboard file-selection** (spacebar) that v3 had — reportedly no intent
    to fix. Power users are specifically angry.
  - v4 rewrite shipped **buggy**: settings not saving, undeletable theme profiles,
    broken cut/paste, inconsistent tags, FTP broken on upgrade.
  - Redesign felt **less macOS-standard** to long-time users.
  - Net: "rough at launch, stable now, incremental for v3 owners."

### Marta
- **Loves:** near-cult devotion (*"greatest macOS file manager by light years"*),
  keyboard-first speed, dual-pane, themes + plugin/scripting, native feel.
- **The worry:** **development pace / single-dev bus-factor.** Couldn't confirm
  "abandoned" *or* "active" for 2025 — loudest public signals (beta announcements)
  skew old. Continuity is the recurring anxiety, not capability.

### Nimble Commander
- **Loves:** blazing C++ performance, low memory, 100+ hotkeys, archive-as-folder,
  remote mounts.
- **Gripes:** **paywall** ($29.99) gates key features; **steep learning curve**;
  limited view-layout customization; **no plugin support**.

---

## Cross-cutting themes → implications

| Community signal | Implication for Diptychon |
|---|---|
| Keyboard control is the #1 thing power users rate; ForkLift losing spacebar-select is a real grievance | Validates the keyboard-first bet. **Never regress a keyboard path** — this audience punishes that hardest. |
| Rewrites + feature-creep breed instability (ForkLift 4 bugs) | Restraint + the **reversible operation spine** is a *trust* story: "small, stable, undoable." |
| Marta's love is real; its weakness is reliability/continuity, not features | Clearest **opening**: take Marta's audience minus the "is it still alive?" fear — calm, native, *actively developed*, Finder-compatible. |
| Nimble's paywall + learning curve = friction | "Keyboard-first *without being hostile*" + a lean ramp is a wedge — if pricing doesn't replicate the friction. |

---

## The read (one-liner)

**Marta proves demand for lean keyboard-first dual-pane on macOS; its weakness is
continuity, not capability — that's the gap Diptychon is best shaped to take.**
Don't fight ForkLift (remote/power, out of scope) or Nimble (raw C++ speed) head-on.
**Win Marta's audience with fewer doubts:** actively maintained + reversible +
Finder-compatible + visibly lightweight (~3 MB).

Open question this raises for the roadmap: **pricing/distribution** (Nimble's
paywall friction is instructive) — not yet decided.

---

## GTM implications (netnography, 2026-07-02)

From the coded corpus (`context/netnography/03-synthese-kundenwuensche.md` §3–4,
`04-diptychon-mapping.md` §4). Three moves, all already true of Diptychon — the work
is making them **visible**, not building them:

1. **Lead with values-hygiene, and prove it.** Native / ~3 MB, **one-time purchase
   (no subscription)**, **no telemetry / 100% local** are *actively advertised buying
   arguments* in this segment (trends T-A/T-B/T-C) — competitors sell on exactly
   these. Put them prominent on the site/README, with **verifiable** numbers (measured
   bundle size from `competitor-benchmark.md` §4; an open, plain-language privacy
   policy). This audience runs Little Snitch and posts screenshots of data dialogs —
   it rewards proof and punishes overclaiming ("proof culture", netnography §4).
2. **Anti-subscription is moral, not just economic.** "Renting software" /
   "monetization optimization stuff" is spoken with contempt. If pricing lands here,
   a fair one-time purchase with free updates is itself a positioning asset — align
   the pricing decision (open question above) with this.
3. **Communicate the segment boundary — don't fake remote.** The single strongest
   *unmet* job in the broader market is remote mounts (SFTP/WebDAV), which Diptychon
   deliberately excludes (`competitor-benchmark.md` §3). Do **not** market against
   ForkLift/QSpace on remote. Own the frame: *"the light, reliable, native dual-pane
   for local work"* (Personas B/C). Clarity protects the positioning; pretending
   otherwise invites the one review that says "but it can't do SFTP".

**Distribution.** Word-of-mouth in r/macapps + HN decides this segment (one convinced
advocate carries weight). Presence there should be honest, not astroturf (see the
study's ethics, `00-methodik-und-ethik.md` §5).

**Product ties-in:** the trust story is carried by issues **41** (state persistence —
"never forgets") and **34** (visible, controllable operation queue). See
`PROJECT-TRACKER.md` → *Backlog priority*.

---

## Sources
- ForkLift 4 review — https://www.atpeaz.com/forklift-4-review-comparison-with-forklift-3/
- ForkLift on Setapp (user reviews) — https://setapp.com/apps/forklift/customer-reviews
- ForkLift 4 (MacStories) — https://www.macstories.net/news/binarynights-releases-forklift-4-a-major-update-its-file-management-and-transfer-utility-for-mac/
- Marta praise (Hacker News) — https://news.ycombinator.com/item?id=32336600
- Marta issue tracker (GitHub) — https://github.com/marta-file-manager/marta-issues/issues
- Nimble Commander pros/cons (Eltima) — https://mac.eltima.com/best-file-manager.html
- macOS file-manager comparison (Applefritter) — https://www.applefritter.com/content/comparing-macos-file-managers-remote-server-access
