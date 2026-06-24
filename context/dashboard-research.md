# Data-Driven UI & Progressive Disclosure — Design Principles

General interface principles (from dashboard/data-display design) that guide
Diptychon broadly — the file list, panels, and any future overview surface.
Two big ideas: **let the data drive the form**, and **reveal complexity
progressively**.

---

## Principle 1 — Data drives the form

A truly usable UI matches its presentation to the *meaning and structure* of the
underlying data, rather than dumping everything as plain text. Choose the visual
treatment from the data type:

| Data type | Treatment | Why |
|-----------|-----------|-----|
| **Categorical** (few fixed values) | **Chips** (small capsules), not raw text | The structure is grasped at a glance |
| **Numeric** | **Right-align** | Digits line up by place value → easy comparison |
| **Time-ordered** | **Timeline** over a time-sorted table | Sequence is read directly |
| **Has a time dimension** | **Charts** | Trends/summaries are instant, no scanning timestamps |
| **Urgency** | **Color with meaning** (e.g. red = urgent) | Color signals state, not decoration |
| **People / authorship** | **Avatars** over names | Faster identification than reading a column |
| **Long text** | **Truncate** | Gives other columns breathing room; layout stays clean |

The throughline: reduce visual complexity by tuning the representation to the
logic and importance of the data.

### How it applies to Diptychon
- **Size** column → right-aligned numerics (compare at a glance).
- **Tags** → colored dots/chips, not text (already shipped, issue 08).
- **Long names** → truncated with `…` (already done).
- Future: a **timeline/grouped** view for date-heavy folders; **charts** only if
  we ever add a summary surface — not core to a file list.

---

## Principle 2 — Progressive disclosure

Sequence functionality so users aren't overwhelmed by a fully-loaded UI. Decide
what's visible immediately vs. what appears on demand.

**The spectrum of explicitness** — rank features by how often they're needed:
- **High explicitness:** primary actions always visible (global search, a "New"
  button).
- **Low explicitness:** secondary actions appear on interaction — e.g. a
  copy-cell icon that shows only on hover.

Concrete techniques:
1. **Popovers / modals** for rarely-used settings (e.g. "Share") — keep context,
   save space, vs. navigating to a whole new screen.
2. **Hover reveals** for row-level secondary actions (delete, etc.).
3. **Tooltips** to explain icons / ambiguous labels without permanent text clutter.
4. **Gestures** (swipe) on touch — reveal secondary actions, keep the main view clean.
5. **Onboarding by sequencing** — start with one tooltip on the most important
   action; the next step appears only after the user acts. Beats a six-bullet
   modal that's forgotten the moment it closes (learning happens *through* doing).
6. **Indicators for "invisible" UI** — small hints (e.g. a corner triangle = a
   comment exists) signal hidden functionality without crowding the design.

### How it applies to Diptychon
- **Context menus / hover** for secondary file actions (Open With shipped, issue 09;
  pin-remove for the sidebar should follow this).
- **Tooltips** on every icon-only control (the eye/hidden toggle, tag-filter menu,
  toolbar buttons) — already partly done; keep it consistent.
- **Sheets** for focused tasks (rename, tag picker, Go to Folder) instead of
  inline clutter — already the pattern.
- **First-run onboarding** (e.g. the Full Disk Access flow, issue 10) should be a
  single pointed nudge, not a wall of text — matches the "sequencing" rule.
- Keep the chrome calm: surface primary actions; tuck the rest into menus/hover.

---

## Using these docs
- **This doc** = cross-cutting principles → a checklist when designing any view.
- **`sidebar-research.md`** = the sidebar-specific application.
- Promoted to a real spec: **issue 17 — file-list polish** (Principle 1:
  right-aligned sizes, scan-friendly dates) — `.scratch/diptychon-mvp/issues/17-file-list-polish.md`.
