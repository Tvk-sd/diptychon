# PLAN — Issue 14: Inline preview / inspector pane

Spec: `.scratch/diptychon-mvp/issues/14-inline-preview-pane.md`.
Branch: `feat/14-inline-preview`.

## What I understood
A toggleable **right-side preview pane** that shows a live preview of the Active
Panel's current selection (a `QLPreviewView`, inline — not the floating spacebar
QuickLook), plus basic metadata (name, kind, size, created/modified). Follows the
active panel; off by default; visibility persists.

## Assumptions (challenge these)
- **Right-side pane, ~300px, toggleable, off by default.** At ~1100px the dual
  panels + a narrow preview fit; default-off means no disruption for people who
  don't want it. (Issue 13 will later let the right *file* panel collapse to free
  more room; this works standalone before that.)
- **Toggle = a window toolbar button** (Finder-style `sidebar.right` icon) + a
  keyboard shortcut (⇧⌘P). Adds a native titlebar toolbar — also the future home
  for issue 13's collapse button.
- Preview follows `model.activeModel` selection; switching panels updates it.
- Single selection → preview + metadata; none → placeholder; multiple → a short
  "N items selected" summary (QLPreviewView previews one item).
- Persist visibility across launches via `UserDefaults` (cheap) — satisfies the
  "persists per session (ideally across launches)" AC.
- Verified by build + screenshot (OS-rendered preview; little pure logic to unit-test).

## Approach — slices
1. **Pane scaffold + toggle.** `WorkspaceModel.previewVisible` (UserDefaults-backed);
   toolbar toggle button + ⇧⌘P; add a right pane (Divider + fixed-width container)
   to `WorkspaceView` shown when visible, with a placeholder body.
2. **Preview + metadata.** `QuickLookPreview` (`NSViewRepresentable` over
   `QLPreviewView`) + a metadata section (name, kind, size, created/modified),
   driven by the active selection; placeholder for none/multiple.

## "Done" = checkable
- A toolbar button / ⇧⌘P shows & hides the right preview pane; state survives relaunch.
- With a file selected in the active panel, the pane shows its QuickLook preview +
  metadata; selecting another file (or switching panels) updates it live.
- No selection → tidy placeholder; multiple → "N items selected".
- Dual-panel layout stays coherent (pane is additive on the right).
- Build green; verified on-screen.

## Risks
- `QLPreviewView` inside SwiftUI: ensure it updates its `previewItem` on selection
  change (the `updateNSView` path). Minor.
- Toolbar adds titlebar chrome — first toolbar in the app; confirm it looks native.

## Progress
- [ ] Slice 1 — pane scaffold + toolbar/shortcut toggle (persisted)
- [ ] Slice 2 — QLPreviewView + metadata, live on active selection
