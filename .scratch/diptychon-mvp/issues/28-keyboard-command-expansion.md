# 28 — Keyboard command expansion (Marta-informed)

Status: needs-triage

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Add the next batch of keyboard commands, informed by an analysis of Marta's
action/hotkey docs. Two principles guide the choices:

1. **Stay Mac-native.** Diptychon deliberately uses macOS conventions
   (⌘C/⌘V/⌘D/⌘⌫, Finder's ⌘[ / ⌘]) rather than Marta's Norton-Commander
   function keys (F5 copy, F6 move, F8 trash). We keep that — no F-keys.
2. **Bind capability that already exists first.** Several `PanelModel`
   properties (`showHidden`, `selection`, `searchQuery`) and the right-click
   "Open With" menu already work; they just have no chord. Those are the
   cheapest wins.

Every binding is data-driven: one row in `Keymap.default` + one `case` in
`WorkspaceModel.perform()`. No call-site key checks (issue 04 invariant).

## Notes / design

### Tier 1 — wire existing capability (≈2 lines each)

| Command | Chord | Backing | Notes |
|---|---|---|---|
| Show Hidden Files | `⌘⇧.` | `PanelModel.showHidden` | toggle on the Active Panel; pane-local (matches Marta) |
| Select All | `⌘A` | `selection` ← all `visibleItems` | confirm the focused `NSTableView` isn't already consuming ⌘A natively before adding |
| Select None | `Esc` | clear `selection` | **ordering**: Esc must still dismiss a presented sheet first; only clear selection when no modal is up |
| Invert Selection | `⌘⇧I` | toggle membership over `visibleItems` | |
| Focus Search | `⌘F` | focus the search field | Mac-native "find"; replaces Marta's ⌘P Look-up as the find entry point |

### Tier 2 — small new actions (one system call each)

| Command | Chord | Implementation |
|---|---|---|
| Reveal in Finder | `⇧⌘R` | `NSWorkspace.activateFileViewerSelecting(selectionURLs)` |
| Copy Path(s) | `⌥⌘C` | pasteboard write of joined paths (mirrors existing `clipboardCopy`) |
| Show File Info | `⌘I` | Finder "Get Info" on the selection |
| Open With… | `⌘↩` | surface the existing `NSTableViewFileList` Open-With menu from a chord (Marta-identical key) |
| Move to Inactive Pane | `⇧⌥⌘→` / `⇧⌥⌘←` | reuse `write(.move, …)`; the `OperationCoordinator` already supports move + undo. Mirrors the existing `copyToInactive` gesture |

### Binding map check (no conflicts with current keymap)

All proposed chords are free against `Keymap.default`. `⌘R` (rename) is
distinct from `⇧⌘R` (reveal); `⌘C` (clipboard copy) is distinct from `⌥⌘C`
(copy path); `↩` (open) is distinct from `⌘↩` (open with).

### Text-field coexistence

Like the existing ⌘T/⌘R/⇧⌘G chords, the new editing chords must be suppressed
while the Filter/rename field is focused. ⌘F (focus search) and ⌘A (select all
in a text field) need first-responder-aware handling — confirm against the
key-monitor logic in `WorkspaceView`.

## Acceptance criteria

- [ ] `⌘⇧.` toggles hidden files in the Active Panel.
- [ ] `⌘A` selects all visible items; `Esc` clears selection (only when no modal
      is open); `⌘⇧I` inverts selection — none move the cursor.
- [ ] `⌘F` focuses the search field.
- [ ] `⇧⌘R` reveals the selection in Finder; `⌥⌘C` copies its path(s); `⌘I`
      opens Get Info; `⌘↩` opens the Open-With menu.
- [ ] `⇧⌥⌘→/←` moves the selection into the Inactive Panel (undoable), with the
      right panel hidden it no-ops like `copyToInactive`.
- [ ] Every new command runs through the same code path as a future palette
      entry / menu item (one implementation, multiple entry points).

## Out of scope

- **Actions Panel / command palette** — already specced as issue **#19**
  (`command-palette.md`). This issue only feeds it: each new `AppAction` here
  must show up in that palette automatically.
- Marta's Look-up / Spotlight predicate search, Volumes / Recent Locations /
  Hierarchy menus (`⌥0/1/3`), Quick Select type-ahead. Larger; defer.
- Marta function-key scheme (F4–F8, F11, F12) — intentionally not adopted.

## Decisions

- **Palette binding: ⌘K** (resolved). Matches existing issue #19; ⌘⇧P is already
  taken by Show Preview in the toolbar, so ⌘K is also the only conflict-free choice.
- **⌘F targets the Filter field** (always-visible, in `TopBarView`), not the
  sidebar recursive-search field — "find within the current list" semantics, and
  no sidebar-reveal dance.
- **Esc / Select None** only fires when no modal is open; otherwise Esc is left
  for the sheet/dialog to consume (handled in `handleKeyDown`, not `perform`).
- **⌘I / Get Info** drives Finder via AppleScript (no public Get-Info API). Sandbox
  is off (ADR 0001) so no entitlement is needed, but the first call shows a one-time
  "Diptychon wants to control Finder" automation-consent prompt.

## Blocked by

- `04-command-undo-spine-copy-to-inactive` (data-driven `Keymap`) — done.

## Related

- `19-command-palette` — these commands populate it.
- `09-quicklook-openwith-fsevents` — Open-With menu logic to reuse (done).
