# 99 — Ultracite for the landing-page worker

Status: **CLOSED (2026-10-11)** — approved by Till, commit `dac6fe4` on `main`, not pushed. One decision stays with him: whether `ultracite fix` may run on `src/worker.js` (PLAN › Offen — bei Till)
Category: tooling

## Parent

`.scratch/diptychon-mvp/PRD.md`

## Problem

Till asked to set up [Ultracite](https://www.ultracite.ai/) — a zero-config
lint and format preset for JavaScript/TypeScript, built on Oxlint + Oxfmt.

The repo is a Swift app, so Ultracite has almost no surface here. Two
candidates existed:

1. `.scratch/landing-page` — hand-written HTML/CSS plus one Cloudflare Worker
   source file, `src/worker.js`.
2. `sandbox/raycast-extension` — the only real TypeScript project, with a
   `package.json`.

## Findings (trial run in a throwaway worktree)

**The Raycast extension is blocked.** Ultracite 8.0.0 requires ESLint 10;
`@raycast/eslint-config@2.2.0` pins ESLint 9 through `typescript-eslint@^8.62`.
`ultracite init` aborts with `ERESOLVE` on both the ESLint and the Biome route,
before changing any file. The two ways past it are both bad:

- let `init` remove Raycast's ESLint and Prettier setup — `ray lint` then loses
  its ESLint and Prettier steps;
- set `legacy-peer-deps=true` — both formatters then rewrite the same files.

Note: `ray lint` is already red on an unrelated point — `package.json:12`
carries `"license": "UNLICENSED"`, and Raycast's schema wants a constant there.
Out of scope for this issue.

**Unscoped, the landing page is a production-wide reformat.** Oxfmt formats
HTML, CSS and Markdown, not just JavaScript. A bare `ultracite fix` in that
folder rewrote 24 tracked files with ~21,500 changed lines, including the live
`index.html` (3,484 lines) and `page.css`. Changed whitespace between inline
elements can move the layout, and the ⌘K palette reads `#shortcuts` rows out of
the DOM, so that route needs a visual check of every page before a deploy.

## Decision

Scope Ultracite to the Worker source only. Till picked this over the whole-site
option.

Both configs carry `ignorePatterns: ["/*", "!/src/"]` (gitignore-style globs,
rooted at the config file). `ultracite check` then reports `1 files`.

## Outcome

Shipped as commit `dac6fe4`, merged to `main`, not pushed. Till picked the
scoped option over the whole-site one and approved the commit.

Added under `.scratch/landing-page/`:

- `package.json` — `private`, plus `check` and `fix` scripts
- `package-lock.json`
- `oxfmt.config.mts`, `oxlint.config.mts` — Ultracite preset + the `src/` scope
- `.gitignore` — `node_modules/`

No existing file was changed. Verified: `ultracite check` covers 1 file, and
`npx wrangler deploy --dry-run` still bundles the Worker and reads the 52
`dist/` assets. `wrangler.jsonc` points `assets.directory` at `./dist`, so the
new `node_modules/` and configs are not published.

## Open

`npx ultracite fix` would make 22 insertions and 11 deletions in
`src/worker.js`: formatting, plus `replaceAll`, `Number.parseInt` and sorted
object keys. All behaviour-preserving, but it edits the live download counter
and the notify handler, so it wants a `wrangler dev` test before it goes out.
About 25 further lint findings (`func-style`, `no-use-before-define`,
`sort-keys`, `prefer-response-static-json`) stay unfixed and are style
preferences, not defects.

Not set up, each a separate small ask: editor-on-save config (`--editors`),
agent rules (`--agents claude`), git pre-commit hooks (`--integrations`). The
hooks would run on every Swift commit at the repo root, so they are a poor fit.
