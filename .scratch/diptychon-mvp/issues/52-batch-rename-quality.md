# 52 — Batch rename: undo must actually work + ascending-number prefix mode

Status: ready-for-agent (2026-07-12) — reporter (Till) named two concrete gaps
after judging the current implementation "not good".

## Parent

`.scratch/diptychon-mvp/PRD.md`

## The two requirements

### 1. Undo of a batch rename must work — verify through the real app, then fix if needed

Reporter: "es ist nicht gut, wenn man Batch Rename nicht rückgängig machen kann."

The code *claims* this already works: commit `14a9553` shipped batch rename as
"one undoable Operation" (`BatchRenameSheet.swift`, `RenameRule.swift`). The
reporter's experience contradicts that claim, so treat it as unverified:

- Reproduce in the running app (fresh pid, real files, not a synthetic test —
  see `verify-through-real-call-path` learning): batch-rename ≥3 files via ⌘R,
  then ⌘Z. Expected: ALL names revert in one step, with the undo toast naming
  the operation. Then ⇧⌘Z redoes it.
- If undo does not revert (or only partially reverts), fix so the whole batch is
  one undo unit. Cover: collision/skip cases (what does undo do when some items
  were skipped?), and undo after the selection changed.
- Add a UI/integration test for batch-rename → undo → redo.
- **Consequence for /vs (honesty guardrail):** the Sources block on
  diptychon.com/vs states the batch rename is "one undoable operation". If the
  real-app check falsifies that, correct the page in the same change.

### 2. New mode: ascending number prefix, keeping the current names

Reporter: "eine Nummerierung, die von 0 aufsteigend geht — einfach eine Nummer
vor den aktuellen Ordnern oder Files angeben."

- New rename mode (or extension of Add Text): prefix each selected item with an
  ascending index, **preserving the existing name**: `0 report.pdf`,
  `1 photo.jpg`, `2 assets/` …
- Start value is user-editable, default **0**; ascending in selection order
  (document which order that is — visual order of the panel is the expectation).
- Decide and document: separator between number and name (space? `_`? user
  choice?), optional zero-padding (the Format mode already has a padding
  concept to reuse).
- Difference to the existing Format mode: Format REPLACES the name with
  `<name><counter>`; this new mode KEEPS the name and prepends the counter.
- Live preview in the sheet should show resulting names before commit (if the
  sheet has no preview yet, this is the moment to add it — it directly answers
  the reporter's trust problem with the feature).

## Acceptance criteria

1. Batch rename of N items reverts completely with one ⌘Z in the running app
   (verified against a fresh app instance, not just tests).
2. A user can select files/folders, choose "number ascending", accept default 0
   (or set another start), and get `0 <name>`, `1 <name>`, … with names intact.
3. Sheet shows a preview of the resulting names before applying.
4. /vs Sources claim about undoable batch rename is consistent with reality.

## Notes

- Regex/EXIF tokens remain deferred (v1.1, see capture-form wish) — NOT in scope here.
- Competitor baseline in `context/competitor-facts.md` (2026-07-11): ForkLift,
  Nimble Commander, Path Finder have batch rename; Marta doesn't. An undo-safe,
  preview-first batch rename is the differentiator worth protecting.
