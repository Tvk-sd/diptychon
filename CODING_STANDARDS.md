# Coding Standards

Scar tissue, not a style guide. Every rule here exists because breaking it
already cost a real bug — the issue number is the justification. Generic Swift
and SwiftUI advice is deliberately absent: `/code-review` carries its own
baseline, and the compiler and tests cover the rest.

**A rule earns its place by having an issue number.** If a convention has no
incident behind it, it doesn't belong in this file.

Vocabulary follows `CONTEXT.md` — say _panel_, not pane.

---

## 1. Hotkeys go through `AppAction` + `Keymap`, never `.keyboardShortcut`

An app-global `NSEvent` local monitor owns the keyboard
(`Sources/Diptychon/Operations/HotkeyManager.swift`). It sees the key event
before SwiftUI does, so a `.keyboardShortcut` modifier on a view is silently
dead — the monitor swallows the event and the view's handler never runs.

**How:** add a case to `AppAction`, a binding to `Keymap.default`
(`Sources/Diptychon/Operations/Keymap.swift`), and a `perform` case. Nothing
else. `docs/keyboard-reference.md` is generated from `Keymap.default`, so it
stays honest for free.

**Chord choice:** prefer `⌘` / `⌘⇧` and keycode-based chords. Control-combos get
eaten by the system on the primary dev machine, and the DE keyboard layout makes
character chords on `[`, `]`, `@` untypeable. See issue 44 (rebinding) and issue
60 (`⌘←/→` history).

## 2. Never arm persistence from an `@Observable` model's `init`

SwiftUI constructs `@State` models more than once and discards the extra
instances. A save observer registered in `init` therefore survives on a
throwaway instance and writes _its_ stale snapshot over the real one at quit —
the user loses their workspace. This was issue 45.

**How:** the model exposes `startPersistence()`; the view arms it from
`.onAppear`. See `Sources/Diptychon/Panel/WorkspaceView.swift:30` for the live
call site, and `WorkspaceModel.observeTerminationForSave()` for what it arms.
The same applies to any observer with a write side effect, not just saves.

## 3. Run the full test suite before a merge, not just the touched area

```
xcodebuild -scheme Diptychon -destination 'platform=macOS' test
```

The scheme runs `DiptychonTests` **and** `DiptychonUITests`. Running only the
suites related to the change is what let a recursive-filter edit on
`feat/fuzzy-search` break an injected-source test elsewhere and ship red to
`main`.

If a UI test fails with "automation mode timeout", "runner hung", or a bogus
"not hittable", that's a `testmanagerd` wedge, not your change: `pkill -x
testmanagerd`, wait, retry. Confirm it's genuinely a wedge before dismissing a
red test.
