# Automations — what Claude Code runs to verify Diptychon

_Last updated: 2026-06-25. Written for a non-developer reader. This explains the
automated checks an agent runs against this app: what they do, why macOS prompts
for permissions, why the mouse moves on its own, and how to tell which one is
running (and stop it)._

## BLUF

The automation you saw — **macOS asking for Desktop/Downloads access, Diptychon
opening on its own, the mouse taking over and clicking through the app, and
screenshots being captured** — is almost certainly the **XCUITest UI test suite**
(`DiptychonUITests`), started by the command `xcodebuild test`.

That is the *only* automation in this project that drives the real pointer and
captures screenshots. The other check (unit tests) never touches the screen. A
third kind (ad-hoc "drive the app" scripts) exists only as notes in `HANDOFF.md`,
not as committed code — an agent would have to write one on the spot to use it.

**This matters for the current bug:** the issue-21 memory runaway shows up under
this UI suite, not in normal use. Running the *whole* suite once crashed the
machine — so we run **one test at a time**, with a self-quit safety watchdog.

---

## The three kinds of automation

| What you observe | Which automation | What it actually is |
|---|---|---|
| Mouse moves by itself, clicks menus/rows, types; Diptychon opens; **screenshots**; macOS permission prompts | **XCUITest UI suite** (`DiptychonUITests`) | A real macOS UI-automation framework. It launches Diptychon and drives it like a robot user — synthetic clicks, typing, menu navigation — then auto-saves screenshots. |
| Nothing visible; finishes in seconds; no prompts, no mouse | **Unit tests** (`DiptychonTests`) | Pure logic checks (no window, no UI). Cheap and safe. Never touches the screen or your files. |
| Mouse takeover **without** the test framework (rare) | **Ad-hoc agent script** (not in repo) | One-off Swift/shell an agent writes to post real clicks (`CGEvent`) or grab a window screenshot (`screencapture`). Documented in `HANDOFF.md`; not committed, so only present if an agent just made one. |

---

## Why each thing happens (the parts that looked alarming)

**1. "It asked for access to Desktop and Downloads."**
Diptychon is a file manager and runs **with the macOS sandbox turned off** (a
deliberate decision — see `docs/adr/` ADR 0001). The first time it reads a
protected folder (Desktop, Downloads, Documents), macOS shows a one-time TCC
("Transparency, Consent & Control") permission prompt. During a UI test the robot
navigates into folders, which trips these prompts. This is macOS protecting your
files, not the app misbehaving. (Issue 10 added a "Full Disk Access" onboarding
flow specifically for this.)

**2. "The mouse took over and clicked through the app."**
That is exactly what XCUITest does — it posts real mouse and keyboard events to
exercise the app the way a person would. You temporarily lose pointer control
because the system is generating those clicks. It returns when the test ends.

**3. "I think it took screenshots."**
It did. XCUITest automatically attaches screenshots (per step, and always on
failure) into a results bundle: a `.xcresult` file under
`~/Library/Developer/Xcode/DerivedData/Diptychon-*/Logs/Test/`. They are not
saved to your Desktop; they live inside that bundle.

---

## How to tell which one is running

Run this in a terminal (or type it in the chat prompt prefixed with `! `):

```
pgrep -fl "Diptychon|xcodebuild|XCTRunner|testmanagerd"
```

- `xcodebuild` present → a test run is in progress.
- `XCTRunner` / `testmanagerd` present → it's specifically the **UI suite** (these
  are the components that drive the pointer).
- Only `Diptychon` present, nothing else → just the app running normally (e.g. an
  agent launched it to look at it), **not** a UI test.

Process / bundle identifiers for reference:
- App: `com.diptychon.app`
- Unit-test bundle: `com.diptychon.tests`
- UI-test bundle: `com.diptychon.uitests`

---

## How it gets started (the commands an agent uses)

- **Run everything (unit + UI):** `xcodebuild test -scheme Diptychon -destination 'platform=macOS'`
  — ⚠️ this includes the full UI suite, which is what crashed the machine on the
  issue-21 branch. Avoid until the runaway is fixed.
- **Run a single UI test (safe):**
  `xcodebuild test -scheme Diptychon -destination 'platform=macOS' -only-testing:DiptychonUITests/DiptychonUITests/<testName>`
- **Run only the harmless unit tests:**
  `xcodebuild test -scheme Diptychon -destination 'platform=macOS' -only-testing:DiptychonTests`

The UI tests that exist today (in `Tests/DiptychonUITests/DiptychonUITests.swift`):
`testLaunchesWithTwoPanels`, `testRenameRefreshesBothPanelsOnSameDir`,
`testSetAndUndoTagViaPicker`, `testGoToFolderNavigates`, `testToggleRightPanel`,
`testPreviewPaneShowsSelectedFile`, `testSidebarToggleAndNavigate`,
`testPinFolderAppearsNavigatesAndRemoves`, `testMissingPinnedFolderDegradesGracefully`.

---

## How to stop it / stay safe

- **Stop a run immediately:** `pkill -9 -f Diptychon; pkill -9 xcodebuild`
- **Never run the full UI suite on the `feat/21-unified-top-bar` branch** until the
  memory runaway is fixed — it can balloon to ~15–23 GB and crash the machine.
- **Self-quit watchdog (currently in the working tree, DEBUG-only):** the app is
  temporarily instrumented to watch its own memory and **force-quit itself at
  1.5 GB**, so a runaway can't reach the point of crashing the machine. It also
  writes a one-line-per-second log to the session scratchpad. This is diagnostic
  code and will be removed before anything is committed.

---

## Open questions (to confirm which automation hit *your* machine)

I could not fully pinpoint it from here — and neither could you — so these are the
signals that would settle it:

1. **Was a terminal/agent running `xcodebuild test`?** If yes → UI suite confirmed.
2. **Did the runaway happen during a visible click-through?** → UI suite. Did it
   happen with no mouse activity at all? → points elsewhere (a long-running app
   instance, or a stale leftover process).
3. **Is the code being run the committed branch or the local fix?** The memory fix
   is currently **uncommitted** — it lives only in this working copy. Any
   automation that builds from a fresh checkout, CI, or a different worktree is
   still running the *old, buggy* code, which would explain why "the problem
   persists" even though local manual tests look clean.

---

## What we know about the bug right now (context, not the fix doc)

- With the local (uncommitted) fix applied, the standalone app stays flat
  (~120–137 MB) at launch, 2 minutes idle, and through every pane toggle and
  forced window-grow — no runaway reproduced manually.
- The detailed runaway analysis and fix plan live in `PLAN.md`; project state in
  `HANDOFF.md` / `PROJECT-TRACKER.md`.
</content>
</invoke>
