# Diptychon — MVP PRD

Status: ready-for-human

A fast, keyboard-first, dual-panel file manager for macOS — a lightweight Finder
alternative in the spirit of Nimble Commander. This PRD defines the MVP only.

Domain terms used here are defined in `/CONTEXT.md`. Architectural decisions are
recorded in `/docs/adr/`; this PRD does not restate them.

## Goal

Prove the product: a Mac user can drive two folders side by side, entirely from
the keyboard, faster than Finder, and can batch-rename and Finder-tag files
without leaving the app.

## Non-goals (deliberately deferred)

Tabs · global tag view (all files with tag X, location-independent) · regex
rename (→ v1.1) · browsing archives as folders · network volumes (SMB/FTP) ·
hotkey remapping UI · App Store build · code signing / notarization.

## Platform & distribution

- macOS 14 Sonoma minimum.
- Pure SwiftUI; file list via `Table` behind a narrow protocol (ADR 0002).
- Non-sandboxed, Full Disk Access; direct distribution via GitHub Releases +
  Homebrew Cask (ADR 0001).
- MIT license.

## MVP scope

### 1. Dual-panel core
- Two panels, one local directory each (ADR 0003: Panel Source abstraction,
  local-only implementation).
- Exactly one Active Panel; the other is Inactive. Focus switches via Tab.
- Per-panel navigation: enter/leave directories, breadcrumb/path, keyboard-first.
- Type-ahead filter within a panel.
- Column display + sorting; toggle hidden files.

### 2. Performance
- Asynchronous directory listing — never block the UI thread.
- Virtualized rendering (`Table`).
- Lazy thumbnails with caching.
- Acceptance check: a real folder of ~50,000 files scrolls and keyboard-navigates
  without visible stutter. If it fails, swap only the list layer for AppKit
  `NSTableView` behind the protocol (ADR 0002).

### 3. File operations (as reversible Commands — ADR 0004)
- Copy / Move / Delete-to-Trash with progress + cancel.
- Pre-write collision resolution (overwrite / rename / skip) — the real safeguard
  against data loss.
- Create folder/file, duplicate.
- Multi-level undo/redo (⌘Z / ⇧⌘Z). Overwrites are not undoable and the UI says
  so at the collision step.

### 4. Interaction model (two gestures, ADR-adjacent)
- Clipboard: ⌘C / ⌘V — paste targets the **Active Panel**.
- Commander gesture: ⌥⌘→ / ⌥⌘← — copies the selection straight to the
  **Inactive Panel**, no clipboard.
- Drag & drop always available: within a panel, between panels, and to/from
  external apps (Finder etc.).
- Default hotkeys are Mac-style and data-driven (action → key table) from day 1;
  the remapping UI is post-MVP.

### 5. Batch rename
- Transformations: find & replace (plain text), sequential numbering,
  prefix/suffix, case change.
- Live before/after preview table before anything is written.
- Collision detection — block and show when two files would collide.
- Operates on the selection in the Active Panel.

### 6. Finder tags
- Real Apple tags, round-trip compatible (ADR-adjacent; see `/CONTEXT.md` → Tag).
- Display tags (color dot + name) on files.
- Set / remove tags on the selection.
- Create a new tag; choose from the system tag list.
- Filter the Active Panel by tag.

### 7. macOS integration
- QuickLook (spacebar preview).
- FSEvents — panels update live when their directory changes.
- "Open with" / default app.
- First-run onboarding for Full Disk Access (cannot be requested
  programmatically; must guide the user to System Settings → Privacy).

## Open threads (not blocking the MVP)
- Code signing / notarization timing (currently deferred; revisit before wider
  reach).
- Sorting/column defaults — to be decided during build.

## Suggested build order
MVP → V1 (tabs, global tag view, regex rename, hotkey remapping UI) →
V1.x polish (themes, archives, signing/notarization/auto-update).
