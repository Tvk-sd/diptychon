# 44 — Customizable hotkeys (user-remappable keymap)

Status: done (2026-07-06, branch `feat/44-customizable-hotkeys`, commit `d05727e`) —
user-remappable keymap: rebind/clear any action, steal-and-unbind on conflict, structural
keys locked, overrides persist, Reset to Defaults. Editor lives in a new Settings window
(⌘,) Shortcuts tab; Full Disk Access moved to a sibling tab (Settings now owns ⌘,).
Effective map (defaults+overrides) read by both dispatch sites + the live palette hint.
145 tests green; real-app verified. See agent brief below for original spec.

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

---

> *This was generated by AI during triage.*

## Agent Brief

**Category:** enhancement
**Summary:** Let users rebind or clear the key chord for any action, persist those overrides, and reset to defaults — the effective keymap is defaults + user overrides.

**Current behavior:**
Every binding is hardcoded in the default keymap (a static array pairing an `AppAction` with a `KeyChord`). The model already separates the *what* (`AppAction`) from the *key* (`KeyChord`), and keymap lookup already accepts the map as a parameter — but there is no user-facing way to change bindings, no persistence, and no editing UI. Current invariant: one chord per action.

**Desired behavior:**
An **effective keymap** = defaults with per-action user overrides layered on top; an override either rebinds an action to a new chord or clears it (unbound). Every consumer reads the effective map — both key dispatch and the command palette's reverse look-up of an action's chord for its shortcut hint (the palette must show the user's chord, not the default). Overrides persist and can be reset to defaults. Keep the one-chord-per-action invariant.

**Key interfaces:**
- `KeyChord` / `KeyTrigger` must round-trip (make them `Codable`, or add a small DTO); both the character form and the key-code form of a trigger must serialize.
- An effective-keymap provider (`defaults + overrides`) exposing both lookups: chord → action (dispatch) and action → chord (palette hint). All sites that read the default map directly must read this instead.
- Persistence: a single `UserDefaults` key (e.g. `hotkeyOverrides`) encoding `AppAction` → serialized chord (or "unbound").
- A remapping UI to view defaults, set/clear an override per action, and reset all. If the UI is too large for one pass, land the resolved map + persistence + reset first (palette and dispatch already reading the effective map) and note the UI as a follow-up.

**Acceptance criteria:**
- [ ] Rebinding an action to a new chord makes the new chord invoke it and the old chord no longer does.
- [ ] Clearing an action's binding leaves it unbound (no chord invokes it).
- [ ] The command palette shows the user's effective chord as the hint, not the default.
- [ ] Overrides survive quit + relaunch.
- [ ] A reset restores every binding to `Keymap.default`.
- [ ] Actions with no override keep their default chord.
- [ ] `KeyChord`/`KeyTrigger` round-trip through encode/decode for both character- and code-based triggers.

**Out of scope:**
- Multiple chords per action or chord sequences (keep one chord per action).
- Adding new actions or new default bindings (that's issue 28).
- A full conflict-resolution manager — decide minimal handling for two actions claiming one chord (last-write-wins or reject) and state it; don't build more.
