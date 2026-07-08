# No telemetry; all data stays on the user's machine

Diptychon collects nothing and phones home for nothing. No analytics SDK, no
crash reporter that transmits, no in-app usage tracking, no third-party tags on
the website. This was implicit in the build from day one; the netnography
(2026-07-02) turned it into an explicit, load-bearing commitment: in this
segment, "no telemetry / 100% local" is an actively advertised buying argument,
not a hygiene footnote.

We decided to make **no-telemetry a product commitment**, not a current
implementation detail.

## Considered Options

- **Privacy-friendly analytics** (self-hosted Plausible-style, or Apple's
  opt-in app analytics) — still telemetry to this audience; they run Little
  Snitch and screenshot outbound connections. Rejected.
- **Opt-in crash/usage reporting** — the consent dialog itself contradicts the
  "nothing to consent to" story, and partial data is weak anyway. Rejected.
- **Nothing leaves the machine; measure server-side and first-party only** —
  chosen.

## Why

- The segment sells on this. Competitors advertise native/local/no-tracking as
  headline features (netnography trends T-A/T-B/T-C); the community rewards
  proof and punishes overclaiming ("proof culture"). A verifiable absolute —
  *zero* outbound — is the strongest claimable position.
- It compounds with the rest of the positioning: lightweight, one-time
  purchase (ADR 0007), reversible operations. One coherent trust story.
- We already paid for it once: the Google Ads setup (2026-07-07) deliberately
  runs **without a conversion tag**, accepting blunter measurement, because a
  tag would contradict the brand. A commitment we pay real money to keep is a
  decision — this ADR records it.

## Consequences

- **In-app:** no network calls except those the user explicitly triggers.
  Usage insight (issue #48) must be **local-only** — written to disk for the
  user (and the demand test) to read, never transmitted.
- **Website/funnel:** measurement stays first-party and server-side (the KV
  download counter, `src` attribution). No third-party pixels, ever.
- **Support cost:** no crash telemetry means diagnosing from user-supplied
  logs and reproduction — accepted; the segment is technical.
- **Marketing must stay verifiable:** the claim is "zero outbound connections"
  — any future feature that needs one (update check, license validation) must
  either work offline or be user-initiated and documented, and the copy
  updated *before* it ships.
