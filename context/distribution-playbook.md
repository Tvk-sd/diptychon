# Distribution Playbook — seven follower-free channels, mapped onto Diptychon

> Snapshot: 2026-08-06. Source: ["Do Not Waste the Next 12 Months Building an
> Audience — 7 Distribution Channels That Don't Need a Single Follower"](https://capitalofone.substack.com/p/do-not-waste-the-next-12-months-building)
> (Capital of One, Substack). This doc maps the article's seven channels onto
> Diptychon's post-ADR-0008 reality and says, per channel: fit, action, or
> deliberate skip — with reasons. It **updates** `channel-plan.md` (snapshot
> 2026-07-07, capture-page era) rather than replacing `gtm-plan.md` (phases and
> community conduct still hold).
>
> ⚠️ Sourcing caveat, in the house style: the remote environment's network
> policy blocks substack.com, so this summary was reconstructed from search
> excerpts, not a full read of the article. The seven channels and the
> closing rule are confirmed across multiple excerpts; per-channel nuance may
> be lossy. Worth one read from Till's machine before acting on details.

---

## The article's thesis, and why it fits this project

**Claim:** "Build an audience first" is bad default advice. An audience is one
distribution channel among many — the slowest, most uncertain, most crowded
one. Seven plays get a product in front of buyers with zero followers, zero
personal brand, zero years of daily posting. Core principle: **go where people
already are and give them a reason to care.**

**Closing rule:** pick **one compounding channel + one fast channel**. Two
slow plays = no visible result for six months and a motivation crater.

Why this lands here: Till is a solo builder without a Mac-audience following,
and the project's own evidence already points the same way — the netnography
says advocacy is earned, not broadcast (`gtm-plan.md` §evidence), A3 roundup
outreach is dead (#67), and ADR 0008 just re-pointed the website from
capturing emails to distributing a real download. The article is close to a
description of the strategy this repo has been converging on. What it adds is
a checklist of channels we haven't consciously triaged — that triage is below.

---

## Verdict table

| # | Article channel | Speed | Fit for Diptychon | Verdict |
|---|---|---|---|---|
| 1 | MCP servers / registries | compounding | Wrong product shape — GUI app, not an agent tool. The *registry* idea maps to **Homebrew Cask + Mac app directories** | **Adapt** |
| 2 | AEO (answer-engine optimization) | compounding | Already our strongest asset (`/vs` + four A2 pages, JSON-LD, answer-first) | **Continue** (in flight, #67) |
| 3 | Programmatic SEO | compounding | Small-scale honest variant only; template-spam contradicts the brand | **Adapt, capped** |
| 4 | Free tools (engineering-as-marketing) | compounding | The app itself is the free tool ("free while in beta", ADR 0008); one candidate side-tool | **Partially in place** |
| 5 | Shareable artifacts | compounding | No telemetry (ADR 0006) + a file manager's output is private file work — weak natural share loop | **Mostly skip**; one cheap candidate |
| 6 | Newsletter acquisitions / sponsorships | fast | Niche Mac newsletters are affordable and reach exactly the segment ads under-sample | **Test** (the fast channel) |
| 7 | Affiliate programs | fast | No price, no checkout yet (#66 open); one-time-purchase economics make thin cuts | **Defer** until #66 |

The pick, per the article's rule: **compounding = AEO (already running)**,
**fast = one paid newsletter placement test**, with Google Ads
(`channel-plan.md` Track B) as the incumbent alternative for the fast slot.
Details and the decision Till owns are at the end.

---

## 1 · MCP servers → registries where *this* audience already searches

**Article:** publish an MCP server and list it in the registries (official MCP
registry, Smithery, mcp.so, PulseMCP) so AI agents — and the people browsing
those directories — find you. Distribution via being *listed where lookups
happen*, not via being followed.

**Honest fit check:** Diptychon is a GUI file manager, not an API surface. An
MCP server ("let an agent drive file operations") is a different product with
real security stakes, and nothing in the netnography says our segment wants
it. Building one *for distribution* would be a stunt. **Skip the literal
channel.**

**What transfers — the registry principle.** Our audience's lookup registries
already exist:

- **Homebrew Cask** — already the target path in `docs/distribution.md`.
  `brew install --cask diptychon` is not just install convenience: a cask
  makes the app appear in `brew search`, on formulae.brew.sh, and in the
  scripts/dotfiles this segment shares. For keyboard-first Mac developers the
  cask **is** the MCP-registry equivalent. Blocked by notarization (#69);
  submit the cask in the same work session as the first notarized release.
- **Directory listings, once — not as a campaign:** AlternativeTo (the
  "Marta alternative" lookups happen there too), MacUpdate, and the relevant
  GitHub awesome-lists (`awesome-mac` and kin — already flagged in #67 as the
  realistic third track). One accurate listing each, `?src=` on every link
  (`alternativeto`, `macupdate`, `awesomemac`), then leave them alone.
  No review-farming, no fake ratings — ADR 0006's honesty logic applies to
  listings too.

**Cost:** hours, one-time. **Attribution:** `?src=` per directory; cask
installs are countable only as GitHub release-asset downloads (imperfect,
note it in #73's readout rather than pretending precision).

---

## 2 · AEO — continue; this is the compounding channel

**Article:** ~60 % of Google searches end without a click; the new game is
being **the source the AI answer cites**, not the link the person clicks.

**Where we stand:** this is the one channel where Diptychon is ahead of the
article. Built in #67: `/vs` plus four answer-first comparison pages,
`FAQPage`/`SoftwareApplication` JSON-LD generated from the rendered DOM,
sitemap, E-E-A-T author lines — and the evidence discipline the citation
studies reward (KDD 2024: +30–40 % citation frequency from exactly three
things — backed numbers, linked primary sources, attributed statements).
Also built and correctly labeled as unproven: `llms.txt` (~97 % of published
ones get zero requests; don't credit it if reach rises).

**What the flip (#71) must not break:** the machine layer currently says
`PreOrder` and the pages say "no download yet". The moment the download is
real, visible copy and JSON-LD `offers` flip **in the same deploy** —
a page whose markup contradicts its copy is the spam signal #67 warns about.
This is already an ADR 0008 consequence; it is repeated here because it is
the single cheapest way to damage the compounding channel.

**One addition worth making (already scoped in #67):** the **"update window"
explainer** — name the category ("the clause that turns a purchase into a
rental with extra steps"), show how to check any vendor's license for one,
state Diptychon's line ("buy once, updates included, no expiry date").
Category-naming explainers are precisely what AI answers lift. **Gate
unchanged:** ForkLift's license finding is web-search-grade only; vendor-
direct verification before a word of it ships.

**Cost:** already sunk; explainer ≈ one page. **Measure:** downloads by
`?src`, plus the pending re-verification list in #67.

---

## 3 · Programmatic SEO — the capped, honest variant

**Article:** Shopify's Business Name Generator: one free tool wrapped in
200+ landing pages targeting ~20,000 keywords. Templates × data = pages that
each answer one narrow query.

**Honest fit check:** the full version of this play — hundreds of templated
thin pages — is exactly the listicle-war content the SERP scan showed page
one drowning in, and it contradicts every line of `PRODUCT.md` (say the
number, concede honestly). A brand whose `/vs` page works *because people
believe it* cannot also run a content farm. **The scale is capped by how much
true, specific content we actually have.**

**What we can generate truthfully:**

- **The keyboard reference as pages (#42, already open).** The docs
  generator's output, placed at `diptychon.com/docs`, is legitimate
  programmatic content: one page per task/shortcut group answers real
  long-tail queries ("move files between folders keyboard mac",
  "batch rename keyboard macos") with content that exists because the app
  does — not content invented for SEO. Prerequisite: #42's correctness fix
  (⌘←/⌘→, not `⌘[`/`⌘]`; Terminal/Gadgets/Suche/Queue missing).
- **Remaining A2 targets** from `channel-plan.md` not yet built
  (`nimble commander alternative`, `commander one alternative`,
  `lightweight file manager mac`, `dual pane file manager mac`) — same
  `/vs` quality bar or not at all: verified claims, "stay where you are if…"
  column, dated sources.

**Not doing:** auto-generated "X vs Y for Z" matrices, city/persona pages, or
any page whose only reason to exist is a keyword. (Same reasoning that killed
the PBN idea in #67 — the trust asset is worth more than the traffic.)

**Cost:** #42 is already owed; A2 pages ≈ half a day each. **Measure:**
`?src=docs`, per-page `?src` slugs as in #67.

---

## 4 · Free tools — the app is the free tool right now

**Article:** ship a small free tool adjacent to the paid product; the tool
earns search traffic and hands its users to the product.

**Where we stand:** ADR 0008 made this the *current pricing state*: Diptychon
is "free while in beta" — never bare "free" — until #66 decides the model.
For the beta phase, product and free tool are the same artifact, and the
distribution job is putting it in hands (#69 → #71). The channel is
therefore largely **already in place**, not a new build.

**One candidate side-tool, parked:** an **update-window license checker** — a
static page where you pick a vendor and see what their license actually
renews (data: the vendor-verified table behind `/vs`). It's the free-tool
form of the §2 explainer and shares its verification gate. Build only if the
explainer page demonstrably draws citations/traffic first; a tool nobody
queries is a maintenance liability with our 6-source verification burden
attached.

**Not doing:** speculative utilities (tag inspectors, file-dedupers) invented
to have a free tool. Every shipped surface inherits the brand's verification
and honesty costs; small team, spend them where the evidence is.

---

## 5 · Shareable artifacts — mostly skip, one cheap exception

**Article:** design product output that users show other people
(Spotify-Wrapped-class loops); each share is distribution nobody paid for.

**Honest fit check:** two structural blockers. ADR 0006: no telemetry, so no
"your year in files" aggregate exists to render. And a file manager's output
is *someone's file system* — private by nature, not showable. Forcing a share
loop here would be borrowed clothing. **Skip as a strategy.**

**The one cheap exception:** a **printable / wallpaper-grade shortcut
cheat-sheet** generated from the same source of truth as the keyboard
reference (#42). Keyboard people genuinely trade cheat-sheets; it's the one
artifact of ours that is *meant* to be shown around, and it carries the
brand's strongest visual identity (keycaps, mono type — "the keyboard is the
brand", `PRODUCT.md`). Footer: `diptychon.com/docs?src=cheatsheet`. Half a
day, after #42 lands, not before.

---

## 6 · Newsletter sponsorships — the fast-channel test

**Article:** rent someone else's audience instead of building your own — buy
placements in (or outright acquire) newsletters whose readers are your
buyers. Fast because the audience already exists; you pay with money instead
of years.

**Fit check:** acquiring a newsletter is out (capital, and running one is the
audience-building trap with extra steps). **Sponsorship placements** are the
real option, and they fix a known hole: `channel-plan.md` notes the
values-hygiene sub-segment runs ad-blockers, so Google Ads *under-samples*
our best users. Newsletter sponsorships are native content — they reach
ad-blocker users. And they answer the need left by A3's death (#67): a paid,
labeled placement is the honest version of the third-party mention the
roundups were supposed to provide.

**How to run it (one test, not a program):**

1. Shortlist 3–5 indie Mac/dev newsletters whose archive shows tools like
   ours (Mac power-user, developer-tool, or Apple-indie beats). Selection
   from Till's machine — the network policy here blocks most vendor sites.
2. Ask for the rate card **and** list size / open rate; niche indie
   newsletters commonly price low hundreds of € per placement. Set the cap
   the way Track B set €10/day: **one placement, one read**.
3. Copy in the house voice — the wedge line (native · ~1.4 MB · keyboard-
   first · one-time model pending, "free while in beta" · no telemetry) and
   nothing a reader could call overclaimed. The sponsor label is fine: this
   segment punishes astroturf, not disclosed ads (`gtm-plan.md` §evidence 4).
4. Link with `?src=<newsletter-slug>`. Read **downloads per €** against
   Google Ads' cost-per-download once both have data.

**Gate:** only after #69 + #71 — a sponsorship pointing at a Gatekeeper-
trashed zip or a waitlist burns the placement *and* the impression
(`gtm-plan.md`: the one-shot first impression is the scarce asset).

---

## 7 · Affiliate programs — defer until #66

**Article:** let other people sell for you for a cut; recurring-revenue
products pay 30–50 % recurring and affiliates queue up.

**Fit check, in one line:** we have nothing to pay a cut *from*. Pricing is
undecided (#66), checkout doesn't exist, and the models on the table
(one-time purchase per ADR 0007, open-core variants in #66) all pay a
one-time low-tens-of-€ commission at best — not the recurring 30–50 % that
makes affiliate channels self-sustaining. An affiliate program for a product
with no price is not a channel, it's a promise we can't spec.

**Revisit trigger:** #66 decided **and** first paying customers exist. If the
answer is one-time purchase, the realistic form is the payment platform's
built-in affiliate/referral option (Paddle/Gumroad-class, if one is chosen) —
zero-build — plus the honesty rule that any affiliate copy meets the same
claims bar as our own pages. Until then: **parked, deliberately.**

---

## The pick (article rule: one compounding + one fast)

- **Compounding: AEO (§2) — already chosen by the work.** `/vs` + A2 + the
  machine layer is live and improving; the marginal cost of continuing is the
  lowest of any channel on this list. §1's registry listings and §3's docs
  pages are the same bet through other doors and ride along.
- **Fast: one newsletter sponsorship test (§6)** — *or* re-arming Track B
  Google Ads. Both are paid, capped, `?src`-attributed reads; the
  sponsorship reaches the ad-blocker cohort ads miss, ads have the
  already-built campaign structure. **This is Till's call** (budget +
  shortlist need his machine anyway) — one of the two, not both at once,
  so the download counts stay readable per channel (#73's time rule: one
  month without signal = stop).

Sequence stays the roadmap's: **#68 → #69 → #71**, then the fast-channel
test. Nothing in this playbook jumps that queue; every channel above points
at a download that must first exist and survive its first thirty seconds.

## What we are deliberately not doing (so nobody re-litigates it silently)

- **12 months of audience-building** — the article's own anti-pattern; also
  `gtm-plan.md` already routes Till's builder audience to LinkedIn/Substack
  as a *separate* narrative, not as Diptychon's channel.
- **A literal MCP server** (§1), **PBN/satellite blogs** (#67, fatal to the
  trust asset), **template-scale pSEO** (§3), **forced share loops** (§5),
  **an affiliate program before a price exists** (§7), **newsletter
  acquisition** (§6).

## Measure (unchanged instruments, this doc adds only slugs)

Per ADR 0008 / #73: **downloads by `?src`** and **free-text feedback** are
the readout; one month without signal on a channel = stop. New slugs this
doc introduces when their surfaces ship: `alternativeto`, `macupdate`,
`awesomemac`, `docs`, `cheatsheet`, `<newsletter-slug>`.

## See also

- `channel-plan.md` — 2026-07-07 snapshot (capture-page era); Track B ads
  structure is still the reference for the paid test.
- `gtm-plan.md` — phases, community conduct, the one-shot-impression rule.
- `docs/adr/0008-landing-page-is-distribution-not-fake-door.md` — why
  downloads replaced signups as the signal.
- `.scratch/diptychon-mvp/issues/67-a2-longtail-comparison-pages.md` — AEO
  state of the art in this repo, llms.txt evidence, A3 post-mortem.
- `docs/distribution.md` — the technical ship runbook (cask lives there).
