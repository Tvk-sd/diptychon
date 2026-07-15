# Gadgets — user-defined external-tool actions

Gadgets let you run an external app or command-line tool against the current
selection, straight from the ⌘K command palette (issue 36). They are
**declarative** — no plugin API, no scripting language; that's the product line.

## Quick start

1. **⌘K → "Gadgets: Edit Config…"** — creates the config with a working starter
   on first use and opens it in your editor.
2. Edit, save, then **⌘K → "Gadgets: Reload"** — it reports how many gadgets
   loaded and lists any config errors.
3. **Select one or more files**, then **⌘K, type the gadget's name, ↩**.

Example — a "Zip Selection" gadget:

```json
{
  "id": "zip-selection",
  "name": "Zip Selection",
  "type": "executable",
  "target": "/usr/bin/zip",
  "args": ["-r", "Diptychon-Test.zip", "${active.selection.names}"],
  "workingDirectory": "${active.folder.path}"
}
```

Select files → ⌘K → "zip" → ↩. The first run of an executable gadget shows a
one-time confirmation with the exact command; after that, `Diptychon-Test.zip`
appears in the active folder. A gadget that uses selection variables is greyed
out in the palette until something is selected — if a gadget looks disabled,
that's almost always why.

## Where gadgets live

`~/Library/Application Support/Diptychon/gadgets.json`

The easiest way in: open the palette (⌘K) and run **Gadgets: Edit Config…** —
it creates the file with a working starter on first use and opens it. After
editing, run **Gadgets: Reload** (also in the palette); it reports what loaded
and lists any config errors.

## Format

```json
{
  "gadgets": [
    {
      "id": "open-in-pixelmator",
      "name": "Open in Pixelmator",
      "type": "application",
      "target": "/Applications/Pixelmator Pro.app"
    },
    {
      "id": "optimize-pngs",
      "name": "Optimize PNGs",
      "type": "executable",
      "target": "/opt/homebrew/bin/oxipng",
      "args": ["-o", "4", "${active.selection.paths}"],
      "workingDirectory": "${active.folder.path}"
    }
  ]
}
```

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Unique key. Also remembers the one-time run confirmation. |
| `name` | yes | The title shown in the palette (category "Gadgets"). |
| `type` | yes | `application` (open selection with an .app — a saved "Open With") or `executable` (run a binary). |
| `target` | yes | Path to the `.app` or binary. Single-value variables allowed. |
| `args` | no | argv template, `executable` only. |
| `workingDirectory` | no | Working dir, `executable` only. Single-value variables allowed. |

Top-level keys starting with `"//"` are ignored — use them for comments.
A malformed entry is skipped (and reported on reload) without dropping the rest.

## Substitution variables

| Variable | Value |
|---|---|
| `${active.selection.paths}` | Absolute paths of the selection — **multi-value** |
| `${active.selection.names}` | File names of the selection — **multi-value** |
| `${current.file.path}` | The first selected file's absolute path |
| `${active.folder.path}` | The active panel's folder |
| `${inactive.folder.path}` | The other panel's folder |
| `${user.home}` | Your home directory |

**Multi-value expansion is argv-safe:** an argument containing a multi-value
variable becomes one argv entry *per selected file* — `"--f=${active.selection.paths}"`
with two files selected becomes `--f=/a one.txt` and `--f=/b.txt`. Never a
space-joined string, so filenames with spaces need no quoting. Only one
multi-value variable per argument; unknown variables are an error, not passed
through.

A gadget that references selection variables is greyed in the palette until
something is selected. Application gadgets always act on the selection.

## Safety

- Executable gadgets run via an **argv array** — never through a shell, so a
  hostile filename can't inject commands.
- The **first run** of each executable gadget shows a confirmation with the
  exact expanded command (one-time per gadget id).
- Commands run with your own user privileges, same as Terminal. Output is not
  captured — gadgets are fire-and-forget.

## Out of scope (deliberate)

Scripting/plugin runtimes, capturing tool output, a GUI editor, hotkey binding
for gadgets (palette-only in v1 — the keymap's `AppAction` surface is static;
a follow-up issue covers binding if demand shows).
