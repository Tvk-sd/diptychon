# Product

## Register

brand

> Scope note: this repo holds both the Diptychon macOS app (SwiftUI — impeccable doesn't touch it) and its web surfaces under `.scratch/landing-page/` (diptychon.com). Design work here targets the web surfaces, which are brand-register: they exist to earn trust and a download.

## Users

Keyboard-first Mac power users — developers, PMs, writers who live in shortcuts and find Finder slow for file work. They evaluate tools skeptically, notice craft, and are allergic to marketing speak. Context when visiting: they arrived from an ad, a comparison search ("Marta vs ForkLift"), or a roundup, deciding in under a minute whether this tool is worth downloading.

## Product Purpose

Diptychon is a fast, keyboard-first dual-panel file manager for macOS: native Swift, ~2.7 MB, free, no telemetry, undo anything. The site distributes and learns (ADR 0008): its single job is a notarized download, counted first-party in KV with `?src` attribution. Success = a visitor understands in one screen what the app is, what it deliberately does not do, and leaves with it on their Mac.

## Brand Personality

Ehrlich · präzise · handwerklich (honest, precise, crafted). The voice states facts with units (2.7 MB, macOS 14+), concedes what competitors do better, and never uses superlatives it can't measure. Emotional goal: the quiet confidence of a well-made tool — Zed/Linear craft bar.

## Anti-references

- Generic SaaS landing pages: gradient heroes, metric walls, testimonial carousels, urgency banners.
- Electron/web-wrapper aesthetic — the product's whole point is native smallness.
- Newsletter-farm signup patterns (vague "join the list", hidden cadence). Every capture states exactly what will be sent.
- Marketing buzzwords (seamless, supercharge, blazing).

## Design Principles

1. **Say the number.** Claims carry units and dates or they don't ship.
2. **The keyboard is the brand.** Mono type, keycaps, and command-palette motifs are identity, not decoration.
3. **Concede honestly.** Pages admit trade-offs (no remote drives, no archive browsing) — trust is the conversion lever.
4. **One action per page.** Everything funnels to the download; the sponsor note is the one deliberate exception.
5. **Native-Apple grammar.** SF Pro/SF Mono, Apple-blue accent, system light/dark — the site should feel like the app.

## Accessibility & Inclusion

WCAG 2.1 AA: ≥4.5:1 body contrast in both themes, visible focus states, `prefers-reduced-motion` respected, keyboard-operable throughout (non-negotiable given the audience), semantic HTML with labeled forms.
