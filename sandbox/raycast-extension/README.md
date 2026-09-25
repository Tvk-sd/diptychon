# Diptychon for Raycast — demand test

A local, unpublished Raycast extension. It exists to answer one question before
any Swift is written for issue 49:

> Is "jump straight to the folder" a real daily need, or does it only sound good?

It lives in `sandbox/` because the canonical repo structure asks one question of
that folder — *War das ein Versuch?* — and the answer here is yes. If the job
proves itself, this graduates out of `sandbox/`. If it does not, it gets
archived and the answer was cheap.

## Why this shape

Research on 2026-09-25 (written up in `.scratch/diptychon-mvp/issues/56-global-file-search-hotkey.md`)
measured the whole Raycast store: 3,308 extensions, median 76 installs for
anything published in the last 24 months. The store is not a distribution
channel for Diptychon, and a Diptychon extension can by construction only be
installed by someone who already runs Diptychon. So this is not a growth bet —
it is a one-week experiment with a named exit.

## Commands

| Command | Mode | What it does |
|---|---|---|
| **Open Finder Selection** | no-view | Hands the Finder selection to Diptychon. A folder opens in the Active Panel; a file opens its folder and highlights the file. |
| **Pinned Folders** | view | Lists the folders already pinned in Diptychon's sidebar and jumps to one. |
| **Workspace** | view | Shows the folders Diptychon has open, plus anything staged, and jumps to either panel. |

## How it talks to Diptychon

No app changes. Two existing surfaces, both verified on 2026-09-25 against the
installed build:

- **Navigation** — `open -b com.diptychon.app <path>` (what Raycast's `open()` runs),
  which lands in `.onOpenURL`
  (`Sources/Diptychon/Panel/WorkspaceView.swift:40`) and routes through
  `navigateIfPath` (`Sources/Diptychon/Panel/PanelModel.swift:613`). The app
  already resolves a file to its parent folder and highlights it, so this
  extension adds no behaviour of its own.
- **Reading state** — `defaults export com.diptychon.app -`, then `plutil` for
  `pinnedFolders` and the `workspaceState` blob.

Nothing here writes to Diptychon, mutates a file, or sends anything anywhere.
That matches issue 49's standing rule for unauthenticated surfaces: navigation
verbs only, no delete/move/rename/execute — ever.

## Known limits, stated rather than hidden

1. **It cannot read a Diptychon selection.** Raycast's `getSelectedFinderItems()`
   answers only for Finder and rejects when Finder is not frontmost. There is no
   API for any other file manager (`raycast/extensions#6837`, open since 2023,
   never triaged). For a Finder *replacement*, this is the whole point being
   missed — and hitting that wall in daily use is the actual result this
   experiment is here to produce.
2. **The state is the last saved state.** Diptychon writes on a 500 ms debounce,
   so a folder changed a moment ago may not show yet.
3. **Which panel is Active is not persisted.** The Workspace command therefore
   says Left and Right, not Active and Inactive.
4. **One destination per jump.** Selecting five files in Finder opens the first
   and says so; the Active Panel is one place.

## Running it

Raycast must be installed and set up first.

```
cd sandbox/raycast-extension
npm install
npm run dev
```

`npm run dev` registers the commands in Raycast while it runs. Stop it and they
disappear — nothing is installed permanently, nothing is published.

## Not publishable yet

`license` is `UNLICENSED` on purpose. The Raycast store requires MIT, and
whether Diptychon's code is published and under which licence is still open
(issue 66, and PLAN.md › Offen — bei Till). ADR 0008 is the reason to wait:
published code cannot be unpublished. Do not change this field to MIT as a
convenience — it would pre-decide an open question.

One consequence: `npm run lint` reports exactly one error —
`package.json 12:13 must be equal to constant` — because the store schema pins
`license` to `MIT`. `npm run build` accepts `UNLICENSED` (verified 2026-09-25).
Whether `npm run dev` also accepts it is **unconfirmed** — `ray develop` needs a
signed-in Raycast, so it could not be run here. If it errors on the licence, that
is the question surfacing, not a bug to silence.
