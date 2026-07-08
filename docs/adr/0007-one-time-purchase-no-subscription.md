# One-time purchase, no subscription

Diptychon will be sold as a **one-time purchase** (currently free,
un-notarized beta). Decided 2026-07-07 alongside the demand-test design. The
anchor price used in the demand-test pay-probe is a *test input*, not part of
this decision — the model is decided, the number is not.

## Considered Options

- **Subscription** — best recurring economics, but the netnography codes
  subscription fatigue as a top trend (T-A "anti-abo"): Path Finder's move to
  a yearly license is held against it, and Setapp-only distribution draws the
  same complaint. Selling this segment a subscription attacks our own wedge.
  Rejected.
- **Freemium / feature-gated free tier** — Nimble Commander's paywall reads as
  friction in the sentiment data; a gated dual-pane app undercuts the "calm,
  complete tool" story. Rejected.
- **One-time purchase; later revenue via paid upgrades or rebundling, never
  recurring billing** — chosen.

## Why

- **Segment-aligned:** "one-time purchase, no subscription" is a buying
  argument competitors advertise (netnography T-A); it appears in the GTM
  values-hygiene trio (native · one-time · no telemetry) as something we lead
  with, not merely offer.
- **Coherent with ADR 0006:** no subscription means no account system, no
  entitlement server, no recurring phone-home — the license can be validated
  offline. The business model and the privacy commitment reinforce each other.
- **Scope-honest:** a lightweight tool with deliberate non-goals (competitor
  benchmark §3) doesn't generate the continuous feature stream a subscription
  implicitly promises.

## Consequences

- Revenue is front-loaded. How later development gets funded is an **open
  business case** — candidates include paid major-version upgrades, low-priced
  paid update packs, or rebundling — but every candidate must satisfy the same
  constraint: a purchase the user makes once and owns, never recurring billing.
- Licensing implementation must work **offline** and without an account
  (aligns with ADR 0006); pick mechanism when monetization ships.
- The actual price is an open input, currently being probed in the demand
  test. Record the chosen number in `PROJECT-TRACKER.md` when set — this ADR
  doesn't pin it.
- Public copy may say "no subscription" as a promise; walking it back later
  would burn the trust positioning, so treat this as one-way unless the
  product thesis itself changes.
