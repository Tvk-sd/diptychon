# Design

Visual system of the Diptychon web surfaces (`.scratch/landing-page/` → diptychon.com). Captured from shipped code; light theme added 2026-07-08.

## Theme

Dual-theme, system-following (`prefers-color-scheme`) with a nav toggle persisting to `localStorage("theme")` and stamping `data-theme` on `<html>`. All colors flow through tokens on `:root`; components never hardcode hex.

## Color tokens

| Token | Dark | Light | Role |
|---|---|---|---|
| `--bg` | `#0b0b0d` | `#f6f6f4` | page ground |
| `--bg-raise` | `#131316` | `#ffffff` | cards, inputs, keycaps |
| `--bg-inset` | `#101013` | `#efefec` | group headers, table heads |
| `--hover` | `#17171b` | `#f1f1ee` | row hover |
| `--line` | `#232327` | `#d9d9d4` | control edges (inputs, keycaps, toggle) |
| `--line-soft` | `#303038` | `#d8d8d2` | the lattice: rails, cross rules, dividers — deliberately the strongest line on the page |
| `--line-strong` | `#33333a` | `#c9c9c4` | keycap bottoms, checkbox borders |
| `--leader` | `#2a2a2f` | `#d8d8d3` | dotted leaders, `//` glyphs |
| `--ink` | `#f2f1ec` | `#1a1a1c` | headings, primary text (warm off-white / near-black) |
| `--ink-dim` | `#a4a3a0` | `#52525a` | body copy |
| `--ink-faint` | `#6d6c6a` | `#6b6b70` | labels, captions (AA at small mono sizes) |
| `--accent` | `#0a84ff` | `#0066d6` | links, primary buttons (Apple blue, darkened for light-mode AA) |
| `--accent-hover` | `#3a9bff` | `#0a84ff` | hover states |
| `--err` | `#ff7a6b` | `#b3362a` | form errors |
| `--warn` | `#c9803a` | `#a05f1d` | "not planned" tags |

Strategy: restrained — tinted neutrals + one accent. The accent is the app's own Apple-blue selection color (brand-derived, not invented).

## Typography

- `--sans`: `-apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui` — body, headings.
- `--mono`: `ui-monospace, "SF Mono", Menlo` — the identity face: labels, keycaps, speclines, captions, nav brand.
- Body 17px/1.6; h1 `clamp(34px, 6vw, 56px)`, weight 600, `-.02em`.
- Recurring motif: mono micro-label (12px, `.14em` tracking, uppercase) — a deliberate, named brand system, one per section.

## The hairline lattice (decisive structure system)

Diptychon's UI is two panels sharing one divider; the site borrows that anatomy. Structure is **drawn, not boxed**: every container is a cell in a continuous net of 1px rules. No bubbles, no cards, no shadows — lines carry the hierarchy.

1. **Two rails.** Vertical hairlines at the content column's edges (`--maxw`), running unbroken from viewport top to bottom. All content lives between them. On small screens the rails stay visible at ~18px inset — the lattice is the identity on every device.
2. **Full-bleed cross rules.** Section boundaries are horizontal hairlines spanning the whole viewport, crossing the rails.
3. **Lines connect or die.** Every rule starts and ends at another rule or the viewport edge. Exception, borrowed from the app: a divider between sibling columns may end at its section's bounds (like the panel divider ending at the window chrome).
4. **Cells, not cards.** Containers are lattice-bounded regions: square corners (`border-radius:0`), no shadows, no own frames. At most `--bg-inset` tints a cell.
5. **Controls keep their shape.** Buttons, inputs, keycaps, checkboxes are physical controls — small radii allowed, may sit raised. The lattice never rounds; controls never grow into boxes.
6. **Three stroke words, one weight (1px):** solid `--line-soft` = structure (rails, cross rules, dividers) · dotted `--leader` = in-row leaders · dashed = intra-cell subdivision (group headers). Solid `--line` stays reserved for control edges. Weight hierarchy is inverted on purpose: the lattice (`--line-soft`) is *stronger* than control borders — the net is the loudest chrome, controls sit beneath it.
7. **Adjacent cells share one line.** Never two parallel rules side by side; no double borders.

Canonical applications: the hero signup is a full-bleed band between two cross rules; the command reference is a **scrollable command panel** (fixed-height cell, internal scroll, sticky group headers) — the app's panel as a page element.

## Components

- **Keycap (`kbd`, `.sc-key`)**: mono chip on `--bg-raise`, 1px `--line` border with `--line-strong` bottom edge.
- **Dotted-leader row (`.sc-row`)**: action left, dotted `--leader` line, keys right. The shortcut-reference grammar.
- **Buttons**: `.btn-primary` solid accent + white ink; `.btn-secondary` mono, 1px border. Labels are verb+object ("Email me at launch").
- **Containers**: never boxed — lattice cells per the rules above, square, unshadowed. Controls (buttons, inputs, keycaps) keep radii ≤9px and may sit raised on `--bg-raise`.
- **Command panel**: fixed-height scrollable cell (`max-height:min(480px,68vh)`) between two cross rules; group headers sticky on `--bg`.
- **Nav**: sticky, blurred (`backdrop-filter`), theme-aware translucent bg.

## Layout

- Content column `--maxw: 1080px` (940px on subpages), 24px gutters.
- Sections separated by `--line-soft` hairlines, 72px vertical padding (56px mobile).
- Shortcut reference: two balanced columns of group boxes (`.sc-col`), single column ≤760px.

## Motion

Minimal by intent: 0.12–0.15s ease color/border transitions only. No entrance animations. `prefers-reduced-motion` disables the theme cross-fade.
