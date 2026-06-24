# Transferable Learnings — what Diptychon taught that outlives it

The other research docs (`dashboard-research.md`, `sidebar-research.md`,
`competitor-benchmark.md`) serve *Diptychon*. **This one serves future-you** — the
patterns from building a dual-panel native app that carry into the next product,
especially **AI products**, which are converging on multi-panel, left-to-right
work surfaces.

**Anchor rule for every entry:** name the concrete Diptychon moment that taught it,
the generalizable principle, and where it transfers. No platitudes without a
receipt.

> **One claim, sharpened up front.** It's tempting to say "all AI products are
> multi-panel." That's false — most are still single-column chat. The credible
> claim is that **multi-panel is the *maturity direction***: as a product moves
> from "give an answer" to "be a place you do work," it grows a second pane —
> Claude's artifacts panel, ChatGPT canvas, Cursor, v0. Diptychon is a small,
> honest lab for the problems that *every* product hits when it crosses that line.

---

## 1. The hard part of multi-pane isn't layout — it's "where does this action go?"

**Diptychon moment.** The whole app is two panels, but the real work went into
three `CONTEXT.md` concepts: **Active Panel** (exactly one, the source of
keyboard ops), **Inactive Panel**, and **Destination** — *resolved per gesture,
not fixed*. Paste (⌘V) targets the Active panel; the Commander gesture (⌥⌘→)
targets the Inactive one; drag-and-drop targets wherever you drop. We learned the
hard way that you can't derive "active" from selection (re-clicking an already-
selected row fires nothing), so active is set by which window-half was clicked.

**Principle.** In any multi-pane UI, layout is trivial and **focus + destination
routing is the entire game**. You must answer, explicitly and per-action: which
pane is authoritative right now, and where does the result land? Implicit answers
produce bugs the user experiences as "it did the thing in the wrong place."

**Where it transfers.** Every AI product that grows a second pane inherits this
exact problem. Chat + canvas: when the user says "make it blue," does that edit the
canvas selection or append to chat? An agent with a workspace: which artifact is
"active," and where does a generated file go? Build the **Active / Destination**
model *before* the second pane, not after. It's the load-bearing abstraction.

---

## 2. Let the data drive the form — readability is a rendering decision

**Diptychon moment.** From `dashboard-research.md`, applied in the file list:
**right-align numeric sizes** (digits line up by place value), **tags as colored
dots/chips** not text, **truncate long names**. Each treatment is chosen from the
data *type*, not applied uniformly.

**Principle.** A usable surface matches presentation to the *meaning and structure*
of the data, instead of dumping everything as flat text. Categorical → chips;
numeric → right-aligned; time-ordered → timeline; urgency → meaningful color.

**Where it transfers.** This is *acutely* relevant to AI products, which mostly
render model output as a wall of markdown. The same discipline applies to LLM
output and tool results: a list of statuses should be chips, a table of numbers
should right-align, a sequence of steps should be a timeline. **Don't render the
model's text — render the data the text describes.** It's the difference between an
AI feature that looks like a chat log and one that looks like a product.

---

## 3. Discoverability is the tax on every keyboard / power UI — pay it with progressive disclosure

**Diptychon moment.** Keyboard-first is fast but the chords are *invisible* — the
exact gap that drove issue 19 (a ⌘K command palette listing every command with its
chord). The same instinct shows up smaller everywhere: tooltips on icon-only
controls, hover-reveal for secondary row actions, sheets for focused tasks instead
of permanent chrome.

**Principle.** Power and discoverability trade off, and the resolution is
**progressive disclosure**: surface the primary action, tuck the rest behind
hover / palette / menu, and give people a single place to *find* capability
(the palette) without cluttering the default view.

**Where it transfers.** AI products have the worst discoverability problem in
software: the input is a blank box and the user has no idea what's possible ("what
can I ask?", "what can the agent do?"). The answers are the same primitives —
a command palette, suggested actions, slash-commands, example chips. The blank
prompt is a keyboard UI with no key legend; treat it like one.

---

## 4. Restraint is a feature — define the deliberate "don'ts"

**Diptychon moment.** The sidebar spec (issue 16) *explicitly excludes* Recents,
Tags, and iCloud/Locations from v1 — "less than Finder" is the goal, not a
compromise. The benchmark's §3 lists remote mounts, archive browsing, and
folder-sync as deliberate ➖, not gaps. The product's one durable differentiator —
**lightweight** — is defended entirely by saying no.

**Principle.** Positioning lives in what you refuse to build. A feature list with no
explicit non-scope has no identity; the deliberate-don'ts *are* the shape.

**Where it transfers.** AI products bloat fastest of all — every capability feels
free to bolt on. The discipline of a written "deliberately out of scope" list (and
a bar to flip an item: "does this break the one thing we're actually differentiated
on?") is what keeps an AI product from becoming an everything-drawer that's good at
nothing.

---

## 5. Reversibility is the trust layer — and it matters more when an AI acts

**Diptychon moment.** ADR 0004: a reversible `Operation` spine where every action
(copy/move/trash/rename) records its own inverse, powering multi-level undo. We
built it *before* most operations existed, so every later op inherited undo for
free. Overwrites are the one explicitly non-undoable case — and we surface that
honestly rather than pretending.

**Principle.** When software takes consequential actions on a user's behalf,
**recording the inverse is what makes the action safe to offer.** "You can't mess
this up" lets users move faster than "are you sure?" ever will.

**Where it transfers.** This is the single most important learning for **agentic
AI**. An agent that edits files, sends messages, or changes data is a file manager
with a non-deterministic operator at the wheel. The reversible-Operation pattern —
every agent action carries its undo, the few irreversible ones are flagged loudly —
is the difference between an agent users trust with real work and a demo they
babysit. Build the undo spine first; let the actions inherit it.

---

## 6. When the framework fights you, drop to the layer that owns the problem

**Diptychon moment.** SwiftUI `Table` fought us across issues 03/04/06 — it swallows
clicks, can't combine row-drag with reliable single-click selection, echoes stale
selection bindings. The fix wasn't more SwiftUI workarounds; it was dropping to
AppKit `NSTableView` behind an unchanged `FileListView` protocol (ADR 0002). The
seam meant only the list layer changed. The flip side: we *didn't* over-abstract —
`PanelSource` (ADR 0003) is one deliberate seam we knew we'd cash in (staging
panel, future remote/archive sources), not speculative flexibility everywhere.

**Principle.** High-level frameworks optimize the common case; when your problem
isn't the common case, fighting upward costs more than dropping down. Put **one
well-placed seam** at the boundary so you can drop a layer without rewriting the
app — but only seams you'll actually use.

**Where it transfers.** Directly to AI engineering. High-level agent frameworks are
SwiftUI `Table`: wonderful until your use case isn't theirs, at which point you
fight the abstraction instead of the problem. Keep a seam between your app and the
framework so you can drop to the **raw model API** when you need control — and
resist abstracting every model/provider behind config you'll never vary.

---

## How to use this doc
- **When starting a new product** (especially AI): read §1 and §5 *before* you
  design the second pane or give an agent write-access. They're the expensive
  lessons to learn late.
- **When a surface feels noisy or unreadable:** §2 and §3.
- **When scope is creeping:** §4.
- **Pairs with:** `dashboard-research.md` (§2 in depth), `competitor-benchmark.md`
  §3 (§4 in depth), and the issue spine — `18` (reversibility surfaced), `19`
  (discoverability surfaced).
