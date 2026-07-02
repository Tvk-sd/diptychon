# 36 — Gadgets-lite: user-defined external-tool actions

Status: needs-triage (2026-07-02) — drafted from Marta gap analysis
(`context/competitor-benchmark.md` §5). The 80/20 slice of Marta's extensibility
suite — deliberately **not** a plugin API.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Let a user define lightweight custom actions ("gadgets") that **run an external app
or command-line tool against the current selection** — without a plugin runtime, DSL,
or scripting language.

Marta's model (our reference): gadgets are two types — an **application launcher**
("open selection in App X") and an **executable launcher** (run `/path/to/tool` with
args + working directory). They're regular bindable actions and support substitution
variables like `${active.selection.paths}`, `${inactive.folder.path}`,
`${current.file.path}`, `${user.home}`.

**Why this and not the full suite:** Marta's Lua plugin API / config DSL / theming
fight our "lightweight + Finder muscle memory" thesis (§5 PM note). Gadgets-lite is
the one extensibility feature that's genuinely high-utility, self-contained, and
low-weight — "run my tool on these files" covers most real power-user extension needs
without opening a scripting surface.

## Notes / design

- **Two gadget types, mirroring Marta:**
  1. **Application** — open the selection with a chosen `.app` (this is "Open With"
     but *saved and named*; may partly reuse issue 09's Open With plumbing).
  2. **Executable** — run a binary/script with an argument template + optional
     working directory.
- **Substitution variables (v1 minimum):**
  `${active.selection.paths}`, `${active.selection.names}`, `${current.file.path}`,
  `${active.folder.path}`, `${inactive.folder.path}`, `${user.home}`. Multi-select
  path/name variables expand to multiple argv entries (not one space-joined string) —
  match Marta so filenames with spaces are safe.
- **Where gadgets live:** a small user config (JSON in Application Support, or a
  Preferences pane if one exists). Keep it declarative — id, name, type, target,
  args, workingDirectory. **No embedded scripting language** — that's the line we're
  holding.
- **Surfacing:** each gadget appears as an action in the command palette (issue 19)
  and is hotkey-bindable if/when a binding surface exists (issue 28 keyboard
  expansion). It can also appear in a context menu.
- **Safety — this executes arbitrary user commands.** It runs with the user's own
  privileges (same as Terminal), so no new privilege boundary is crossed, but:
  - argv-array execution, **never** shell-string interpolation (avoid injection via
    filenames).
  - Show the user what will run; consider a confirm for executable gadgets on first
    run.
  - Respect sandbox/entitlements — verify a sandboxed build can spawn external
    processes; if entitlements block it, note the constraint in the plan (may need a
    non-sandboxed build or a specific entitlement).
- **Non-goal:** capturing/streaming tool output into the UI. Fire-and-forget (or hand
  off to the embedded terminal if that ever lands). Output handling can be a later
  issue.

## Acceptance criteria

- [ ] A user can define an **application** gadget and an **executable** gadget in a
      declarative config (no scripting language involved).
- [ ] Gadgets run against the current selection using substitution variables;
      multi-file selections expand to multiple argv entries (space-safe).
- [ ] Gadgets appear as runnable actions in the command palette.
- [ ] Executable gadgets run via argv array (no shell-string interpolation);
      filenames with spaces/quotes are handled safely.
- [ ] Sandbox/entitlement behavior for spawning external processes is verified and
      documented (works, or the constraint is recorded).
- [ ] `context/competitor-benchmark.md` §5 gap row for Gadgets flips to ✅ and the
      "extensibility = ➖" note is updated to reflect the one shipped exception.

## Out of scope

- A Lua/JS/any plugin/scripting API, config DSL, custom themes, custom fonts —
  explicitly **against** the positioning (§3/§5).
- Capturing, displaying, or streaming external-tool stdout/stderr in-app.
- A GUI gadget *builder* — a documented config format is enough for v1.
- Sharing/importing gadget bundles.

## Blocked by

- `19-command-palette` (surface to run gadgets from) — done.
- Coordinates with `09-quicklook-openwith-fsevents` (Open With plumbing to reuse)
  and `28-keyboard-command-expansion` (optional hotkey binding).

## Related

- `context/competitor-benchmark.md` §5 (Marta deep-dive — extensibility PM note).
- `CONTEXT.md` (lightweight thesis — the reason this is *lite*, not a plugin API).
