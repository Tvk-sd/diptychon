# Keyboard reference

Every default shortcut in Diptychon, grouped by task. Bindings are **data-driven**:
they come from `Keymap.default` (`Sources/Diptychon/Operations/Keymap.swift`), the same
table the app dispatches against.

This file used to *claim* it was generated from that table and then drift anyway — it
documented `⌘[` for history months after ⌘← took over, and missed eleven bindings.
`DocsKeyboardReferenceTests` now checks both directions on every test run: no binding
missing here, nothing here that the app doesn't dispatch. When it fails it prints the
correct table.

> Notation: `⌃` Control · `⌥` Option · `⇧` Shift · `⌘` Command — always in that order,
> matching what the menus and the shortcut editor show. `↩` Return · `␣` Space ·
> `⇥` Tab · `⌫` Delete/Backspace · `⎋` Escape.

**Everything below can be rebound** in Settings (`⌘,`) → Shortcuts, except the
structural keys `⇥`, `↩`, `␣`, `⌫` and `⎋`, which navigation and selection depend on.
The menus show your *current* binding, not the default.

## Panels & navigation

| Shortcut | Action |
|----------|--------|
| `⇥` | Switch the Active Panel |
| `↩` | Open the selected folder/file |
| `⌘↑` | Go up (leave the current directory) |
| `⌘←` | Back in this panel's history |
| `⌘→` | Forward in this panel's history |
| `⌘[` | Back — US-layout alias |
| `⌘]` | Forward — US-layout alias |
| `⇧⌘G` | Go to Folder (type a path) |
| `⇧⌘.` | Show/hide hidden files |
| `⌘B` | Show/hide the sidebar |

> History runs on ⌘←/⌘→ because they work on every keyboard layout. The bracket pair is
> kept as an alias for US layouts — on a German layout `[` is ⌥5, so that chord can
> never match.

## Search & filter

| Shortcut | Action |
|----------|--------|
| `⌘F` | Focus **Search** — recursive, from the sidebar |
| `⇧⌘F` | Focus **Filter** — narrows the Active Panel's current folder |

## Selection

| Shortcut | Action |
|----------|--------|
| `⌘A` | Select all |
| `⎋` | Clear selection |
| `⇧⌘I` | Invert selection |

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
| `⌘R` | Rename (inline for one item, batch sheet for several) |
| `⇧⌘N` | New folder |
| `⌃⌘N` | New file |
| `⌘Z` | Undo the last operation |
| `⇧⌘Z` | Redo |

> Undo is multi-level and reversible across move/copy/trash/rename. **Overwrites are
> the exception** — they destroy the original and cannot be undone; Diptychon tells you
> so rather than offering a misleading undo.

## Tags & staging

Staging is a holding pen: collect files from different folders, then operate on the
set as one.

| Shortcut | Action |
|----------|--------|
| `⌘T` | Show/edit Finder tags for the selection |
| `⇧⌘S` | Add the selection to Staging |
| `⇧⌘B` | Show/hide the Staging panel |
| `⌫` | Remove from Staging (when the Staging panel is focused — no disk delete) |

## View & tools

| Shortcut | Action |
|----------|--------|
| `␣` | QuickLook preview |
| `⌘I` | Get Info |
| `⌘↩` | Open With… |
| `⇧⌘R` | Reveal in Finder |
| `⌥⌘C` | Copy path(s) |
| `⌘J` | Show/hide the embedded terminal, opened in the Active Panel's folder |
| `⌘1` | Toggle brief view (1–3 name-only columns) in the Active Panel — column count via palette/menu |
| `⌘K` | Command palette (run any action by name) |

---

Prefer the mouse? Everything here is also reachable by click, context menu, the menu
bar, or the command palette (`⌘K`). See the **[user guide](user-guide.md)** for the
workflows these shortcuts serve.
