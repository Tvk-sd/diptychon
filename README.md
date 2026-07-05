# Diptychon

A fast, keyboard-first, **dual-panel** file manager for macOS — a lightweight Finder
alternative in the spirit of Nimble Commander. The name (a *diptych*, a two-panel work)
reflects the dual-panel core: two directories side by side, so you can see source and
destination at once and move files between them without copy-paste juggling.

> **Status:** MVP. Actively developed. Native Swift / SwiftUI / AppKit — **no Electron,
> no bundled runtime.** The release app is **~1.5 MB** (Apple Silicon) / **~3 MB**
> universal.

---

## Why Diptychon

- **Two Panels, always.** The Commander workflow: the **Active Panel** is your source,
  the **Inactive Panel** your destination. One keystroke sends files across.
- **Keyboard-first, not keyboard-hostile.** Chorded gestures for power, but Finder's
  own conventions (`⌘C`/`⌘V`, `⌘⇧G`, `Space` for QuickLook) so muscle memory transfers.
- **You can't easily mess it up.** File operations are a **reversible Operation** model:
  multi-level `⌘Z` across move / copy / trash / rename, with a toast telling you exactly
  what was undone.
- **Finder-compatible, never parallel.** Tags are real Apple Finder tags (they
  round-trip both ways); the clipboard uses Finder's conventions. Diptychon rides the
  ecosystem instead of inventing a private one.
- **Genuinely lightweight.** Pure native stack, one small binary — the footprint is the
  proof, not a slogan.

---

## Install & run

Diptychon is built from source with Xcode. The `.xcodeproj` is **generated** from
`project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen) and is gitignored —
regenerate it after cloning or after editing `project.yml`.

```sh
brew install xcodegen          # one-time
xcodegen generate              # create Diptychon.xcodeproj from project.yml
open Diptychon.xcodeproj        # build & run in Xcode (⌘R)
```

Or from the command line:

```sh
xcodebuild -scheme Diptychon -destination 'platform=macOS' build
xcodebuild -scheme Diptychon -destination 'platform=macOS' test   # unit + UI tests
```

- **Requirements:** macOS + Xcode 26.5.
- **Signing:** ad-hoc ("Sign to Run Locally") — no Apple Developer team needed.
- **Full Disk Access:** some file operations need it; Diptychon guides you through
  granting it on first use.
- **Start folder:** set `DIPTYCHON_DIR=/some/path` to override the initial directory.

**Shipping it to someone else?** See **[docs/distribution.md](docs/distribution.md)** —
how to package a build and hand it to testers (and the Gatekeeper step they'll hit).

---

## The 60-second model

1. **Two Panels, side by side.** Each shows one directory.
2. **One is Active** (accent border). Press **`Tab`** to switch which Panel is Active.
3. **The Active Panel is the source; the Inactive Panel is the destination** for the
   Commander gesture: **`⌥⌘→` / `⌥⌘←`** copies the Active selection into the Inactive
   Panel. (`⇧` added → *move* instead of copy.)
4. **Everything is undoable.** `⌘Z` steps back through your operations (except
   overwrites, which are destructive by nature and say so).

That's the whole mental model. Full walkthrough → **[docs/user-guide.md](docs/user-guide.md)**.
Every shortcut → **[docs/keyboard-reference.md](docs/keyboard-reference.md)**.

---

## What it does

- **Dual Panels** with an Active/Inactive focus model (`Tab` to switch).
- **Commander gestures** — copy (`⌥⌘→/←`) or move (`⌥⇧⌘→/←`) to the Inactive Panel.
- **Reversible operations** — multi-level undo/redo (`⌘Z` / `⇧⌘Z`) with an on-screen
  toast naming what was reversed.
- **Finder tags** — set/clear real Apple tags that round-trip with Finder; filter a
  Panel by tag.
- **Staging** — collect files from anywhere into a virtual set, then act on them
  together (`⌘⇧S` to stage, `⌘⇧B` to show/hide).
- **QuickLook** (`Space`) and an inline **preview / inspector** pane.
- **Navigation** — clickable path bar, Go to Folder (`⌘⇧G`), back/forward (`⌘[` / `⌘]`),
  a left sidebar of places, and **type-ahead filter** (`⌘F`).
- **Renaming** — inline single-file rename (`⌘R`) and multi-file **batch rename** with
  live preview.
- **Drag & drop** to and from Finder.
- **Command palette** (`⌘K`) — run any action by name.

---

## What it deliberately does *not* do

These are **choices**, not gaps — they defend "lightweight":

- **No remote / cloud mounts** (SFTP, S3, WebDAV…). Diptychon is local-first. (The
  internal *Panel Source* abstraction leaves the door open, but the MVP is local only.)
- **No archive-as-folder**, no folder **sync/compare**.
- **A sidebar smaller than Finder's** — just the places people actually jump to.

If your core job is remote server access, a tool like ForkLift fits better — and
that's fine. Diptychon aims to be the light, reliable, native dual-panel for **local**
work.

---

## Honest performance notes

Measured on Apple M1 / macOS 26.5.1 / arm64, Release build, warm cache:

- **Cold launch → first Panel interactive:** ~716 ms.
- **Large folders stay responsive:** directory loads run off the main thread — the UI
  **never freezes**; you get a loading state, then rows.
- **Not "instant" on huge folders, though:** a 50,000-file folder takes ~4.6 s to load
  (single Panel) / ~6.5 s to become fully interactive (dual-Panel launch). It stays
  scrollable while it loads — it just isn't instant. We'd rather say this plainly than
  overclaim.

---

## Project layout

| Path | What |
|------|------|
| `Sources/Diptychon/` | App source (Swift/SwiftUI/AppKit) |
| `Tests/` | Unit + UI tests |
| `CONTEXT.md` | Domain language — the canonical vocabulary (Panel, Active/Inactive, Operation, Tag…) |
| `docs/adr/` | Architecture Decision Records |
| `docs/user-guide.md` | Full user walkthrough |
| `docs/keyboard-reference.md` | Complete keyboard cheat-sheet |
| `docs/distribution.md` | Packaging + tester handoff runbook |
| `PROJECT-TRACKER.md` | Shipped work + backlog priority |
| `.scratch/diptychon-mvp/` | PRD + issue files |
| `context/` | Positioning, competitor benchmark, research notes |

---

## Contributing / conventions

- **Vocabulary is load-bearing.** Use the terms in [`CONTEXT.md`](CONTEXT.md) — *Panel*
  (not pane/window), *Active/Inactive Panel*, *Operation*, *Tag*. Docs and code stay
  aligned to it.
- **New `.swift` files are auto-globbed** by XcodeGen — after adding one, run
  `xcodegen generate`; never hand-edit the `.xcodeproj`.
- Issues and PRDs live as markdown under `.scratch/diptychon-mvp/`.
