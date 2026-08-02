# Keyboard reference

Every default shortcut in Diptychon, grouped by task. Bindings are **data-driven** —
this table is generated from the same `Keymap.default` the app dispatches against
(`Sources/Diptychon/Operations/Keymap.swift`), so it stays honest.

> Notation: `⌘` Command · `⌥` Option · `⇧` Shift · `⌃` Control · `↩` Return · `␣` Space
> · `⌫` Delete/Backspace · `⎋` Escape.

## Panels & navigation

| Shortcut | Action |
|----------|--------|
| `Tab` | Switch the Active Panel |
| `↩` | Open the selected folder/file |
| `⌘↑` | Go up (leave the current directory) |
| `⌘[` | Go back |
| `⌘]` | Go forward |
| `⌘⇧G` | Go to Folder (type a path) |
| `⌘F` | Focus the type-ahead Filter |
| `⌘⇧.` | Show/hide hidden files |
| `⌘B` | Show/hide the sidebar |

## Selection

| Shortcut | Action |
|----------|--------|
| `⌘A` | Select all |
| `⎋` | Clear selection |
| `⌘⇧I` | Invert selection |

## Commander gestures (across Panels)

The Active Panel is the source; the Inactive Panel is the destination. The arrow
direction is simply which side is inactive.

| Shortcut | Action |
|----------|--------|
| `⌥⌘→` / `⌥⌘←` | **Copy** the Active selection into the Inactive Panel |
| `⌥⇧⌘→` / `⌥⇧⌘←` | **Move** the Active selection into the Inactive Panel |

## File operations

| Shortcut | Action |
|----------|--------|
| `⌘C` | Copy to clipboard |
| `⌘V` | Paste (copy) into the Active Panel |
| `⌥⌘V` | Paste-**move** into the Active Panel |
| `⌘D` | Duplicate |
| `⌘⌫` | Move to Trash |
| `⌘R` | Rename (inline) |
| `⌘⇧N` | New folder |
| `⌃⌘N` | New file |
| `⌘Z` | Undo the last operation |
| `⇧⌘Z` | Redo |

> Undo is multi-level and reversible across move/copy/trash/rename. **Overwrites are
> the exception** — they destroy the original and cannot be undone; Diptychon tells you
> so rather than offering a misleading undo.

## Tags & staging

| Shortcut | Action |
|----------|--------|
| `⌘T` | Show/edit Finder tags for the selection |
| `⌘⇧S` | Add the selection to Staging |
| `⌘⇧B` | Show/hide the Staging panel |
| `⌫` | Remove from Staging (when the Staging panel is focused) |

## View & tools

| Shortcut | Action |
|----------|--------|
| `␣` | QuickLook preview |
| `⌘I` | Get Info |
| `⌘↩` | Open With… |
| `⇧⌘R` | Reveal in Finder |
| `⌥⌘C` | Copy path(s) |
| `⌘⇧T` | Open in Terminal (the Active Panel’s folder) |
| `⌘K` | Command palette (run any action by name) |

---

Prefer the mouse? Everything here is also reachable by click, context menu, or the
command palette (`⌘K`). See the **[user guide](user-guide.md)** for the workflows these
shortcuts serve.
