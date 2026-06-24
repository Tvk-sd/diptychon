# Sidebar — Research & Design Principles

Reference notes for the Diptychon left sidebar. Goal: a clean, Notion-style
navigation rail — **lighter than Finder's** (no iCloud/Locations/Tags sprawl),
just the places people actually jump to.

---

## 1. Core principles

### Clustering — group related items
Put items that belong together in the same section, and keep different *kinds* of
items apart. Concretely:
- Group items of the same **purpose** (e.g. all "places you navigate to").
- Keep **navigation** items separate from **action** items (e.g. don't mix
  "Documents" with "Settings").

Why: a grouped list is read as a few chunks, not N individual rows — users locate
things by section first, then scan within it.

### Grouping for clarity — make the groups visible
Reinforce the clusters with **section headers**, **spacing**, and light **dividers**.
The visual breaks are what let the eye treat each group as a unit.

### Progressive disclosure — don't show everything at once
Secondary controls appear on demand, not permanently:
- A `•••` overflow per section (show more / reorder / hide).
- "Show N" — cap how many rows a section shows, with a "More…" affordance.
- Rarely-used actions (remove a pin, edit) surface on hover or in a context menu.

Why: keeps the rail calm; the structure stays legible even as content grows.

---

## 2. Notion sidebar anatomy (the reference)

What Notion's sidebar does, top to bottom:
- **Top:** workspace switcher, **Search** (⌘K), and top-level tabs (Home, Inbox…).
- **Home is sectioned:** *Recents*, *Favorites*, plus workspace/teamspace groups.
  Each section can be customized via `•••` — show count, move up/down, hide.
- **Bottom: quick entry** — a persistent "New" button (⌘N) to create without
  hunting through menus.
- **Collapsible:** toggle the whole rail with `⌘\`; `>>`/`<<` buttons too.
- **Direct manipulation:** drag-and-drop to reorder/reorganize; nesting via toggles.

Takeaways for us: **sections with headers**, a **collapse toggle + shortcut**,
**drag to manage**, and a **persistent entry point** at the bottom.

---

## 3. What this means for Diptychon (v1 scope)

A file-manager sidebar, not a document outline. Decided scope:

- **Favorites (standard places)** — Home, Desktop, Documents, Downloads,
  Applications. Each with an icon. (Cluster: "system places".)
- **Pinned folders (user-added)** — the user pins their own folders and removes
  them. (Cluster: "my places".) Drag a folder in, or an "Add to Sidebar" action;
  remove via hover/context menu (progressive disclosure).
- **Interaction:** clicking an item navigates the **Active Panel** there
  (consistent with Go to Folder, issue 15).
- **Collapse:** a toolbar toggle + keyboard shortcut, like the preview pane and
  right-panel toggles — and persisted.
- **Deliberately excluded from v1** (keep it "less than Finder"): Recents, Tags,
  iCloud/Locations. Easy to add later as new sections once the frame exists.

Open questions to resolve in the issue:
- Where does the collapse toggle live (toolbar vs. an inline `<<`)?
- How is a folder pinned — drag-in, context-menu "Add to Sidebar", or both?
- Standard places: fixed list, or also hideable?
