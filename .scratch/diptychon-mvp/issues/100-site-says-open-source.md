# 100 — The site says Diptychon is open source

Status: **CLOSED (2026-10-11)** — shipped as `4898e9f`, pushed, deployed and verified live on diptychon.com and www.diptychon.com.
Category: landing page

## Parent

`.scratch/diptychon-mvp/PRD.md` · decision record: `docs/adr/0011-diptychon-is-mit-licensed.md`

## Problem

ADR 0011 (2026-09-26) licensed Diptychon under MIT and closed every repo-side
item — `LICENSE`, `README.md`, `PRD.md`, `project.yml`,
`Resources/THIRD-PARTY-NOTICES.txt`. It left one thing open on purpose, under
Consequences:

> The website is unaffected: it says "free" and makes no claim about the
> licence. Saying "open source" there is now true but remains a separate
> decision about the page.

That was still true: `index.html` had zero mentions of "open source" or "MIT".

## Decision

Till's call, 2026-10-11: say it, once. Open source is a trust signal for this
audience and it is now simply a fact. "Free forever" stays unsaid — ADR 0011 is
explicit that MIT makes existing copies irrevocable, not future releases.

## What shipped

One line in the shared footer, under the existing fine print:

```html
<p class="fine">Native macOS, 2.7&nbsp;MB.<br>Built by Till von Krueger.<br>Free and open source — <a href="https://github.com/Tvk-sd/diptychon">MIT on GitHub</a>.</p>
```

The footer is shared, so "once" means once per page — 13 live pages. The 9
hand-written pages were edited directly; the 4 `/docs` pages come from
`scripts/generate-docs.mjs`, so the template there was edited and the pages
regenerated. `dir-linear.html` and the `index-prev-*` drafts were left alone:
they are not in `dist/` and are not served.

`llms.txt` carries the same fact in prose, next to the existing "it is free"
sentence, for the AI crawlers that read it.

### The CSS detail

`.fcol a` is `display:block`, which would have dropped the link onto its own
line. One scoped rule fixes it, in both places the footer CSS lives — `page.css`
(12 pages) and the inline `<style>` in `index.html`:

```css
.fcol .fine a{display:inline;color:var(--ink);padding:0}.fcol .fine a:hover,.fcol .fine a:focus-visible{text-decoration:underline}
```

Colour was decided on measured contrast, not taste. Against the fine print it
sits in, `var(--ink-dim)` — the grey every other footer link uses — reaches only
1.46:1 in light and 2.08:1 in dark, under the 3:1 a link marked by colour alone
needs. `var(--ink)` reaches 3.28:1 and 4.64:1, and the underline on hover and
keyboard focus is the non-colour cue. `var(--accent)` was rendered and rejected:
it would be the only blue in the footer and reads as a mistake. Till picked the
stronger one from a rendered A/B.

## The contradiction it exposed

Two comparison rows said the opposite of the new footer line, and both were
simply wrong since ADR 0011:

- `path-finder-alternative.html` — the "Open source" row had Diptychon as **No**.
  Now **Yes**.
- `vs.html` — the "Native / open-source" row had Diptychon as "Swift, native".
  Now "Swift, native, open-source".

Both rows are mirrored in `llms-full.txt` and were fixed there too. No other
live page, and no repo doc, carries a claim that contradicts it.

## Verification

- 33 files changed. Exactly one mention per live page, root and `dist/`
  identical for all of them.
- Rendered headless from `dist/` at 1280 px and 390 px, light and dark, for both
  CSS paths (`index.html` inline, `vs.html` via `page.css`). The link sits inside
  the fine print and does not wrap onto its own line.
- `scripts/generate-docs.mjs` bumps a date stamp on every run; the four `/docs`
  pages therefore also show `2026-09-22` → `2026-10-11`. Content is otherwise
  unchanged. Pre-existing behaviour, not introduced here.

## Outcome

Commit `4898e9f` on `main`, pushed. Deployed with a bare `npx wrangler deploy`
from `.scratch/landing-page` (16 assets changed, version
`7ef01b75-6d4f-49c3-ba5a-ed6c9f7d066b`); both custom domains took the trigger.
Verified by `curl` against diptychon.com and www.diptychon.com: the footer line,
the corrected Open-source rows in the page and in `llms-full.txt`, and the new
CSS rule in `page.css` are all live.

Nothing is left open here.
