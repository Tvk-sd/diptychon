# File operations are reversible Commands with multi-level undo

Every file operation (move, rename, delete-to-trash, copy) is modeled from day 1
as a **Command that knows its own inverse**. This powers a multi-level undo stack
(⌘Z / ⇧⌘Z). Undo is an architectural shape, not a UI add-on: retrofitting it
later would mean rewriting every operation, so it is built in from the start.

## Considered Options

- **Add undo later** — rejected: each operation would have to be rewritten to be
  reversible; expensive retrofit.
- **Model every operation as a reversible Command from the start** — chosen.

## Consequences

- Multi-level undo/redo is cheap once the Command architecture exists.
- **Overwrites are explicitly not undoable** — copying/moving over an existing
  file destroys the original; no inverse can restore it. The MVP's pre-write
  collision resolution is the real safeguard; undo covers everything else. The UI
  must make this limit clear at the collision-resolution step.
- Each new operation type must define its inverse to participate in undo.
