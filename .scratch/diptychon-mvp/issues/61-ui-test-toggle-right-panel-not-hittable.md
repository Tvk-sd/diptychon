# 61 — UI test `testToggleRightPanel` fails: toggle button "not hittable"

Status: needs-triage (filed 2026-07-15 during issue 36 close-out)

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What happens

`DiptychonUITests.testToggleRightPanel` fails on this machine with

```
Element Button, {{1538.5, 814.0}, {15.0, 12.0}}, identifier: 'toggle-right-panel',
label: 'rectangle.split.2x1' is not hittable
```

The element is **found** (identifier resolves, frame is reported) but XCUITest
refuses the click. Verified on two commits on 2026-07-15:

- `feat/36-gadgets-lite` working tree (pre-commit) — fails
- `main` @ `83e213a` — fails **identically**, same coordinates

So this is a pre-existing environment/layout issue, not a regression from issue 36.
The other 8 UI tests pass.

## Hypotheses (unverified)

- Window is positioned so the bottom-bar button sits outside the visible screen
  area / under the Dock, or another window overlaps it (frame y=814, x=1538 —
  depends on display layout at test time).
- The button's 15×12 pt hit area is too small once AX scroll-into-view gives up.
- `context/automations-learnings.md` and the macOS-UI-render-debugging learnings
  (window position matters; synthetic events vs tracking areas) are the places to
  start.

## Acceptance criteria

- [ ] Root cause identified (environment vs. real layout bug).
- [ ] `testToggleRightPanel` passes reliably in a full-suite run on this machine.
- [ ] If environmental: test hardened (e.g. position window deterministically at
      launch, or scroll/hover before click) so the suite is machine-independent.

## Comments

> *Filed by AI while closing issue 36 — the failure blocked declaring the full
> suite green and was bisected to pre-exist on main.*
