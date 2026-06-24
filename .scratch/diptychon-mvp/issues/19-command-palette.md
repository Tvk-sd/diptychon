# 19 — Command palette (⌘K)

Status: needs-triage

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

A Linear/Raycast-style **command palette** (⌘K): a search field over every
command, showing each one's keyboard chord, run on Enter. Three wins at once —
power-user speed, **discoverability** of the keyboard-first UI, and living
documentation of the keymap.

The differentiation: Finder is menu-first by legacy and can't easily retrofit
this. For a keyboard-first app, a palette is the answer to the genre's biggest
weakness — hidden chords (the progressive-disclosure gap our own research docs
keep flagging). See `context/competitor-benchmark.md` §3 ("keyboard-first without
being hostile").

## Notes / design

- **Source of truth:** drive the list from the data-driven `Keymap` (issue 04) so
  the palette and the chords never drift. Each entry: command title, chord glyphs,
  optional subtitle/category.
- **Fuzzy search** over titles (and maybe categories). Arrow keys to move, Enter to
  run, Esc to dismiss. Open with ⌘K.
- **What's in v1 (decide in plan):**
  - **Commands only (recommended):** the existing Operations + toggles (New Folder,
    Trash, Duplicate, Batch Rename, Tag…, Toggle Preview, Go to Folder, Toggle
    Sidebar, etc.). Tight, ships fast.
  - **Stretch:** also navigation targets (Places, pinned folders from issue 16) and
    recent folders — turns ⌘K into a "go anywhere / do anything" bar. Defer until
    commands-only proves the surface.
- **Context awareness:** disable/grey commands that don't apply to the current
  selection (e.g. Batch Rename with nothing selected), mirroring menu en/disable.
- **Reuse, don't fork:** running a palette entry must call the *same* code path as
  the chord/menu (one command implementation, three entry points: chord, menu,
  palette). No duplicated action logic.
- **Text-field coexistence:** ⌘K must work even while the Filter field is focused
  (unlike the ⌘T/⌘R/⇧⌘G chords that are suppressed there) — it's the universal
  entry point. Confirm against the key-monitor / first-responder handling (issue 09).
- **Surface:** centered floating sheet/overlay; progressive disclosure — nothing
  permanent.

## Acceptance criteria

- [ ] ⌘K opens a searchable palette listing the app's commands, each with its
      keyboard chord shown.
- [ ] Typing fuzzy-filters; Enter runs the selected command via the same code path
      as its chord/menu; Esc dismisses.
- [ ] Commands that don't apply to the current selection are disabled/greyed,
      consistent with the menus.
- [ ] ⌘K opens even when a text field (Filter/rename) is focused.

## Out of scope

- Navigation targets / recent folders / "go anywhere" mode (stretch above).
- Natural-language commands — see issue dependency note in `competitor-benchmark.md`
  (the AI moonshot rides on this palette + the reversible spine; not this issue).

## Blocked by

- `04-command-undo-spine-copy-to-inactive` (the data-driven `Keymap`) — done.

## Related

- `18-operation-history-time-travel-undo` (palette can expose "Undo to…").
- `16-left-sidebar` (its Places/Pinned could feed the stretch navigation mode).
