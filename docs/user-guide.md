# Diptychon user guide

A task-by-task walkthrough. For the bare shortcut list, see
[keyboard-reference.md](keyboard-reference.md). Terms here follow
[`CONTEXT.md`](../CONTEXT.md) exactly — **Panel**, **Active/Inactive Panel**,
**Operation**, **Tag**.

---

## 1. The dual-Panel model

Diptychon shows two **Panels** side by side, each listing one directory. Exactly one is
the **Active Panel** (marked with an accent border) — it has focus and is the source of
keyboard-driven Operations. The other is the **Inactive Panel**.

- **Switch which Panel is Active:** `Tab`, or click into a Panel.
- **Why two?** So the source and the destination are both on screen. Moving files is a
  single gesture, not a copy-paste round trip through one window.

The **Destination** of an Operation is resolved *per gesture*, not fixed:

| Gesture | Destination |
|---------|-------------|
| Commander copy/move (`⌥⌘→/←`) | the **Inactive Panel** |
| Clipboard paste (`⌘V`) | the **Active Panel** |
| Drag & drop | wherever you drop |

---

## 2. Navigating

- **Open / enter:** `↩` or double-click. **Go up:** `⌘↑`.
- **Back / forward:** `⌘[` / `⌘]` (Finder convention).
- **Path bar:** the breadcrumb above each Panel is clickable — jump to any ancestor.
- **Go to Folder:** `⌘⇧G`, then type or paste a path.
- **Sidebar:** `⌘B` shows/hides a left sidebar of places you pin. It's deliberately
  smaller than Finder's — just the jumping-off points people actually use.
- **Type-ahead Filter:** `⌘F` focuses the Filter; start typing to narrow the current
  Panel by name. **Show hidden files:** `⌘⇧.`.

---

## 3. Selecting

Selection is independent of opening. Use `⌘A` (all), `⎋` (none), `⌘⇧I` (invert), plus
the usual click / `⇧`-click / `⌘`-click. Most Operations act on the **selection** if
there is one, otherwise on the item under the cursor.

---

## 4. Moving & copying files

**The Commander way (across Panels):** point the Inactive Panel at your destination,
select in the Active Panel, then:

- `⌥⌘→` / `⌥⌘←` — **copy** the selection into the Inactive Panel.
- `⌥⇧⌘→` / `⌥⇧⌘←` — **move** it instead.

**The Finder way (clipboard):** `⌘C` to copy, `⌘V` to paste into the Active Panel, or
`⌥⌘V` to paste-move. Also: `⌘D` duplicate, `⌘⌫` move to Trash, `⌘⇧N` new folder,
`⌃⌘N` new file.

**Name collisions** are caught *before* anything is written — you choose overwrite,
keep-both, or skip.

---

## 5. Undo — the safety net

Every file Operation records its own inverse, so **`⌘Z` undoes multi-level** across
move / copy / trash / rename, and `⇧⌘Z` redoes. Each undo/redo flashes a **toast**
naming exactly what was reversed ("Undone — Moved 12 items"), so blind `⌘Z` never
leaves you guessing.

**The one exception: overwrites.** When an Operation overwrites an existing file, the
original is gone — that can't be reversed. Diptychon says so honestly ("Can't undo — files
were overwritten") rather than offering a misleading undo.

---

## 6. Finder tags

`⌘T` opens tagging for the selection. These are **real Apple Finder tags** stored on the
file — set one here and it shows in Finder; tag in Finder and it shows here. Diptychon
keeps **no parallel tag system**. You can also **filter a Panel by tag** to focus on
just the tagged items.

---

## 7. Staging — collect, then act

Staging is a virtual set you fill from anywhere, then operate on as a group — useful when
the files you care about are scattered across folders.

- **Add selection to Staging:** `⌘⇧S`.
- **Show/hide the Staging panel:** `⌘⇧B`.
- **Remove from Staging:** `⌫` while the Staging panel is focused.

Staging collects *references* to files — it doesn't move or copy anything until you run
an Operation on the staged set.

---

## 8. Previewing & inspecting

- **QuickLook:** `␣` — the same floating preview as Finder.
- **Inline preview / inspector pane:** a dockable pane showing the selected item's
  preview and details, for when you want it always-on rather than a spacebar pop.
- **Get Info:** `⌘I`. **Reveal in Finder:** `⇧⌘R`. **Open With…:** `⌘↩`.
  **Copy path(s):** `⌥⌘C`.

---

## 9. Renaming

- **One file, inline:** `⌘R` renames in place.
- **Many files, batch:** the batch-rename tool offers multiple modes (find/replace,
  numbering, etc.) with a **live preview** so you see the result before committing.

---

## 10. Drag & drop

Drag within a Panel, between Panels, and **to/from Finder** — Diptychon interoperates
with the rest of the system rather than being a walled garden.

---

## 11. The command palette

`⌘K` opens the command palette: start typing an action's name and run it with `↩`. Every
action shows its keyboard shortcut next to it, so the palette doubles as a discovery
tool while you learn the chords.

---

## 12. What Diptychon doesn't do (on purpose)

- **No remote / cloud mounts** (SFTP, S3, WebDAV) — Diptychon is local-first.
- **No archive-as-folder**, no folder **sync/compare**.
- **A restrained sidebar** — less than Finder's, by design.

These keep the app light. If remote server access is your core job, a tool like ForkLift
is the better fit — Diptychon is the light, reliable, native dual-Panel for **local** work.

---

*See also:* [keyboard-reference.md](keyboard-reference.md) ·
[../README.md](../README.md) · [../CONTEXT.md](../CONTEXT.md) (domain vocabulary).
