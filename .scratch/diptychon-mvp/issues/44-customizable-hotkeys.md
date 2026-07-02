# 44 — Customizable hotkeys (user-remappable keymap)

Status: needs-triage

## Parent

`.scratch/diptychon-mvp/PRD.md` (relates to issue 28, keyboard command expansion;
issue 19, command palette)

## What to build

Let the user reassign the key chord for any `AppAction`, persist those overrides,
and reset them back to the defaults. Today every binding is hardcoded in
`Keymap.default` (`Operations/Keymap.swift:86`) — a `static let` array with no
user-facing way to change it. The header comment already anticipates this:
*"Kept separate from the keys so a remapping UI can be added later (PRD: hotkeys
are data-driven from day 1)."* This issue delivers that remapping layer.

## Notes / design

The data model is already the right shape — `AppAction` (the *what*) is separate
from `KeyChord` (the *key*), and `Keymap.action(for:in:)` already takes the map as
a parameter. Three things are missing: a **resolved** map (defaults + user
overrides), **persistence**, and a **UI** to edit it.

### Resolved keymap

- Introduce an effective map = `Keymap.default` with per-action overrides layered
  on top. A user override either **rebinds** an action to a new chord or **clears**
  it (unbound).
- Every consumer must read the *effective* map, not `Keymap.default` directly. Two
  call sites do today:
  - `Keymap.action(for:)` default arg (`Keymap.swift:129`) — key dispatch.
  - The command palette's reverse look-up of an action's chord for its shortcut
    hint (`CommandPalette.swift`, issue 19). The palette must show the user's chord,
    not the default.
- Reverse look-up currently assumes one chord per action; keep that invariant
  (one chord per action) to avoid ambiguity in the palette hint.

### Persistence

- Store overrides in `UserDefaults` (single key, e.g. `hotkeyOverrides`), encoded
  as `AppAction` → serialized `KeyChord`. `KeyChord`/`KeyTrigger` need `Codable`
  (they aren't today) — or a small DTO. `KeyTrigger.character` and `.code` must
  both round-trip.
- Load at launch, apply over the defaults. Missing/corrupt data falls back to
  defaults silently.

### Conflict handling

- A chord may only map to one action. On assign, if the chord is already bound,
  either reject with a "already used by X" message or offer to steal it (unbinding
  the previous owner). Pick one in triage — **reject-with-message** is the simpler
  default.
- Guard the chords that aren't really free: `Tab` (switch panel), `↩`/`␣`
  (open/preview), `⌫`, `⎋` collide with table/first-responder behavior. Decide
  whether those are editable at all or locked.

### Capture UI

- A Settings/Preferences pane listing every `AppAction` with its current chord and
  a "record shortcut" affordance: click a row, press the chord, it captures the
  next `NSEvent` key-down (modifiers + trigger) and writes the override.
- Include **Reset to Defaults** (all) and per-row **clear**.
- The recorder must distinguish character-triggered keys (layout-aware) from
  code-triggered keys (arrows/Tab), matching `KeyTrigger`'s existing split
  (`Keymap.swift:43-49`).

### Text-field coexistence (unchanged invariant)

Rebinding must not break the existing first-responder suppression — editing chords
stay suppressed while the Filter/rename field is focused
(`WorkspaceView` key-monitor). A user-assigned chord inherits the same rule.

## Acceptance criteria

- [ ] User can reassign any editable `AppAction` to a new chord from a Settings pane.
- [ ] The new chord fires the action through the same path as a default binding
      (no call-site key checks — issue 04 invariant holds).
- [ ] Overrides persist across app relaunch.
- [ ] Assigning a chord already in use is handled deterministically (reject **or**
      steal — whichever triage picks), never silently double-bound.
- [ ] The command palette shows each action's **effective** chord, not the default.
- [ ] Reset to Defaults restores the original `Keymap.default` exactly.
- [ ] Locked/edit-restricted chords (Tab, ↩, ␣, ⌫, ⎋ — final list decided in
      triage) can't be reassigned into a broken state.

## Out of scope

- Multiple chords per action (chord chords / sequences). One chord per action.
- Import/export of keymap profiles, or shareable presets.
- Per-panel or context-specific bindings — the map stays global.
- Remapping menu-bar `.keyboardShortcut` items that AppKit owns (the app's chords
  go through the `NSEvent` monitor; system menu shortcuts are separate).

## Open questions (for triage)

- Conflict policy: reject-with-message vs. steal-and-unbind.
- Which chords are locked from editing (structural keys).
- Where the Settings entry point lives (⌘, standard Preferences, vs. a palette command).

## Blocked by

- `04-command-undo-spine-copy-to-inactive` (data-driven `Keymap`) — done.
- `28-keyboard-command-expansion` (full `AppAction` set to expose) — done.

## Related

- `19-command-palette` — must render the effective chord as each command's hint.
- `28-keyboard-command-expansion` — established the current binding set.

## Comments

> *This issue was generated by AI at the user's request.*
