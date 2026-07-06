# Scope — Diptychon Landing Page

**Status:** v1 built + brand-aligned + impeccable-polished — approved "for now" (2026-07-06).
Files: `index.html` · `app-screenshot.png` · `icon.png`. Remaining blockers are content, not
design: the real `.dmg` on GitHub Releases (Download target) and a First-5-Minutes doc (guide
link, Issue 42).
**Owner:** Till
**One line:** A single, simple, clear page that gets the right macOS user to try Diptychon.

---

## 1. What it is (the promise in one breath)

> **Diptychon — a fast, keyboard-first, dual-panel file manager for macOS.**
> Two folders side by side, move files with one keystroke, undo anything. ~1.5 MB, native, no Electron.

The page's whole job is to make a Finder/Nimble-Commander-minded Mac user think
*"oh, that's for me"* in under 10 seconds, then act.

## 2. Who it's for

- Mac power users who live in the keyboard and find Finder slow / mouse-heavy.
- Ex-Windows / Linux users who miss a Norton/Total/Nimble Commander dual-panel workflow.
- People who care about a tiny native footprint (anti-Electron crowd).

Not for: casual Finder users who don't feel the pain. The page should *filter*, not convince everyone.

## 3. Primary goal & CTA

**Goal:** visitor tries Diptychon.
**One primary CTA.** Everything else is secondary.

**✅ CTA decided (D1 = option b):** a real **"Download for macOS"** button →
a signed/notarized `.dmg` published on **GitHub Releases**. Low friction, honest,
matches the "try it" goal.

### ⚠️ Prerequisite this CTA depends on (see §7 D1)
A `.dmg` must actually exist on GitHub Releases, and it should be **signed + notarized**
(Apple Developer account, ~$99/yr) so Gatekeeper opens it cleanly. Un-notarized still
works but forces a right-click→Open workaround — which dents the "simple" promise.
**This build/release work is the real blocker, not the page.** Page ships the moment
the `.dmg` link is live.

## 4. Page structure (single scroll, ~5 blocks)

Keep it to one page, no nav menu, no footer sprawl.

| # | Block | Job | Content |
|---|-------|-----|---------|
| 1 | **Hero** | Promise + primary CTA | Headline, one-line subhead, the CTA button, maybe a screenshot/GIF of the two panels + a send-across keystroke |
| 2 | **The "aha" visual** | Show, don't tell | One screenshot or short loop: two panels, `⌥⌘→` sends a file across |
| 3 | **Why (3–4 reasons)** | Differentiate | Two panels always · Keyboard-first but Finder-compatible · Reversible (multi-level ⌘Z) · Genuinely lightweight (~1.5 MB) |
| 4 | **Honest status** | Set expectations, build trust | "MVP, actively developed, native Swift. Here's exactly how to get it today." |
| 5 | **CTA repeat** | Convert the scrollers | Same primary action, restated |

That's the whole site. If a block doesn't move someone toward trying it, cut it.

## 4a. Onboarding emphasis (evidence-backed)

Netnography finding **N3 → Issue 42** (evidence T4, P3/W15): competing tools were *binned
purely over bad docs* ("pathetic docs binned it"); users want **text-first**, not video.
Docs/onboarding is called the **cheapest real moat** vs. Marta / Path Finder — adoption-
critical, not a nice-to-have.

Implication for the page: the biggest adoption risk for a keyboard-first dual-panel tool is
the **learning curve**. So the page must actively *defuse* it, not just claim "we have docs":

- A dedicated **"Learn it in five minutes"** block, placed after "Why" (once sold on what
  it does) and before the status block.
- **Text-first**, scannable: a 3-step mental model (open two panels → send → undo).
- A compact **keyboard cheat-sheet** — signals the whole thing is a *finite, learnable* set
  of keys, and doubles as proof of the keyboard-first claim + fits the monospace aesthetic.
- One secondary CTA to the full **5-minute guide** (docs / README).
- Message = reassurance: *"No manual required — the model is two panels and a handful of keys."*

## 5. Copy direction

- Voice: confident, concrete, no marketing fluff. The README voice already nails it
  ("the footprint is the proof, not a slogan") — reuse that tone.
- Lead with the *workflow*, not the tech. "See source and destination at once" beats
  "SwiftUI/AppKit" in the hero (tech goes in block 4).

**Hero headline candidates** (pick/kill later):
- "Two folders. One keystroke. Zero copy-paste juggling."
- "The dual-panel file manager Finder never gave you."
- "Move files at the speed of your keyboard."

## 6. Explicitly out of scope (protect the "very very simple")

- No multi-page site, no blog, no nav bar, no login.
- No pricing / no signup flow (it's free/source right now).
- No feature-by-feature comparison table with Finder.
- No animations beyond one hero visual.
- No analytics/marketing stack decisions yet.

## 7. Open decisions (need Till)

**D1 — Primary CTA / how to "try it". ✅ DECIDED = (b).**
  Real **"Download for macOS"** button → signed/notarized `.dmg` on GitHub Releases.
  - **Depends on:** a packaged build existing on GitHub Releases. Signing + notarization
    (Apple Developer account, ~$99/yr) strongly recommended so Gatekeeper opens it cleanly.
  - **Fallback if the build slips:** temporarily point the button at the GitHub repo /
    build-from-source instructions and swap to the `.dmg` link when ready — **the page
    structure and copy don't change**, only the button's href.
  - Rejected: (c) waitlist/email capture — changes the page's job from "try" to "capture",
    contradicts the stated goal.

**D2 — Where does it live?** Domain / GitHub Pages / other host? Affects nothing about the
  scope, but needed before build.

**D3 — Hero visual.** Static screenshot vs. short screen-recording loop of the send-across
  gesture. The loop sells the workflow far better but costs more to make.

## 8. "Done" looks like

A single scrollable page where a target user, in ~10 seconds, understands what Diptychon
is, why it's different, and has one obvious, *honest* way to get it — with nothing on the
page that doesn't serve that.

---

## 9. Style research (visual direction)

Method: Till supplies **3 reference sites** that inspire him → I analyse each for what to
*steal* and what to *avoid*, then synthesise one buildable direction (type, colour, spacing,
motion) that fits Diptychon's "fast, native, honest, lightweight" character. No mood-board
sprawl — the output is a short, opinionated spec the HTML build can follow directly.

### Reference sites (analysed)

| # | Site | Why it fits Diptychon | **Steal** | **Avoid** |
|---|------|-----------------------|-----------|-----------|
| 1 | **zed.dev** | Closest analog: native, Rust-fast, *downloadable* desktop dev tool. | Dark, minimal hero: bold headline ("Your last next editor") + one-line subhead + **shortcut letters on the buttons** ("Download **D**" / "Clone source **C**"). 3 crisp one-word benefits (Fast/Agentic/Collaborative). "Available for macOS…" line under the CTA. One big real product visual. | Its live agent/collab dashboard sprawl — Diptychon is single-user local, don't fake that surface. |
| 2 | **linear.app** | The gold standard of *quiet premium* restraint. | Huge confident type, tight vertical rhythm, generous whitespace, muted palette + one restrained accent, high-craft real-data product screenshots, tasteful subtle motion. | Heavy custom gradients + dense dashboards + "teams & AI agents" framing. Matching Linear's polish needs world-class imagery — expensive, and the SaaS-platform vibe contradicts a 1.5 MB local tool. |
| 3 | **factory.ai** | Confident technical data-language, uppercase monospace micro-labels. | Monospace labels for technical detail (SIGNALS / THROUGHPUT / CYCLE TIME) — great for file-manager language (paths, tags, keystrokes). "Download" as a first-class hero button. | Gradient-texture overload + faux enterprise dashboards. Maximal and heavy — the opposite of "genuinely lightweight." |

**The through-line to steal:** dark-first · one big *real* product visual · large declarative headline + short subhead · **one** primary CTA · monospace for technical accents · lots of breathing room · few words.
**The through-line to avoid:** gradient soup, faux dashboards, and "AI/agents/teams" copy energy — none of it is Diptychon.

### Synthesised direction (buildable)

- **Overall vibe:** *Zed's honesty + Linear's restraint, minus the gradients.* Dark, crisp,
  keyboard-forward, native-feeling. The page should feel as fast and light as the app.
- **Type:** clean grotesk for headings + body (Inter / Geist family); **monospace** (SF Mono /
  JetBrains Mono feel) for UI labels, file paths, tags, and rendered **keyboard keys**. Big hero
  scale, tight leading.
- **Colour:** near-black background (~`#0C0D0E`), off-white text, **one** accent only — mapped to
  the Download CTA *and* the highlighted "send-across" keystroke. Single accent = Zed discipline,
  not Factory gradient soup. (Accent pick is a micro-decision — a considered macOS-native blue is
  the safe default.)
- **Layout & spacing:** single column, max content width ~1000–1100px, generous vertical rhythm,
  no nav bar. One big hero product shot of the two panels.
- **Motion:** minimal — at most one subtle loop of the `⌥⌘→` send-across gesture, honouring
  `prefers-reduced-motion`. Nothing decorative. Fast load is part of the pitch.
- **Signature move (steal from Zed):** render the **keyboard shortcut on the CTA** — e.g.
  a `⌘`-key glyph on the Download button, and show real key glyphs (`⌥⌘→`, `⌘Z`, `Space`) in the
  "Why" block. This is the one distinctive thread that ties the *page* to the *product* — no
  generic template has it.
- **Anti-patterns for *this* product:** heavy gradients, faux dashboards, Electron-y visual bloat,
  or any borrowed "AI/agents/teams" framing.

> Guardrail: the style must *reinforce* the value prop. A tiny, keyboard-fast, native app must
> feel crisp and lightweight on the page too — visual weight is a broken promise.

### Direction chosen (via `prototype.html`, 2026-07-06)

Ran 3 radically different variants (A Split / B Terminal / C Loud). **Verdict = C's look × B's
content:**
- **From C (keep):** the loud copy ("Move files at the speed of your keyboard"), the oversized
  type, and the **giant keycap hotkey display** (⌥ + ⌘ + → as physical keys). Bold indigo +
  lime accent.
- **From B (keep):** the clear prose **description**, the **KEY BINDINGS** section, and the
  **WHY** list — B's content clarity, rendered in C's bold visual language (bindings as keycap
  tiles).
- Dropped: the original dark dev-tool look (index.html v1), Variant A (light editorial),
  Variant B's terminal chrome.

**Palette correction (2026-07-06):** the loud indigo/lime was invented and clashed with the
actual product. Repalette derived from the real build — the **app icon** (charcoal tile +
warm off-white pixel monogram) and the app's **single functional accent, macOS blue `#0A84FF`**
(how it marks the active panel). Final direction: **dark charcoal `#161514` + warm off-white
`#ece9e3` + macOS blue used sparingly.** Kept from the loud variant: oversized type, the keycap
hero display (now styled as the icon's tile), the bold copy. Real app icon is now the nav logo +
favicon (`icon.png`); real screenshot is `app-screenshot.png`.

`prototype.html` deleted (its job — picking a direction — is done). Next: `impeccable` polish
pass (reduce blue further, spacing/typographic discipline, contrast/a11y).

---

### Next step
D1 is resolved (real download button). Scope is **build-ready** — the page can be built now
and go live the moment a `.dmg` link exists on GitHub Releases (until then, the button falls
back to the GitHub repo per §7 D1). Remaining page-level picks are cosmetic: **D2** host/domain
and **D3** hero visual. Say the word and I turn this into a single self-contained HTML page or
an Artifact.
