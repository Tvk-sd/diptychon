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

## 7. An infinite loop needs a "feedback writer" — find the one thing that writes back

**Diptychon moment.** Issue 21 slice 1 pegged the CPU to 99% and ballooned RAM until
the Mac froze. Instead of bisecting by running it (it crashed the machine), we
inventoried *everything slice 1 changed* and asked which code could write back into
the layout system mid-pass. Exactly one could: `WindowMinWidth.apply` calling
`window.setFrame`, whose forced relayout re-invokes `updateNSView`, which calls
`setFrame` again. The breadcrumb, the new `VStack`, the per-panel label — all pure
rendering, incapable of looping. We found the culprit by elimination, without a repro.

**Principle.** A one-directional transform can't loop; an infinite loop requires a
*cycle* — something that, during the pass, mutates an input the pass depends on. To
locate an unexplained runaway, don't trace forward from the start; **inventory the
writers-back in the changed surface.** There's usually exactly one, and it's the bug.

**Where it transfers.** Agent loops and chains that never terminate: find the step
that feeds its own input — a tool whose output re-triggers planning, a scratchpad the
planner both reads and appends to, a "reflect" step that always finds more to do. The
diagnosis is identical: which single step closes the cycle? Fix that, not the symptom.

---

## 8. Terminate on a logical state change, not on a measurement the loop perturbs

**Diptychon moment.** The old `WindowMinWidth` stopped only when `current < minWidth`
was false, where `current` was the window's *measured* content width read mid-relayout
— a value the loop's own `setFrame` was actively disturbing. In a flat `HStack` it
settled in one step; nested in a `VStack`+`HSplitView` the measurement never reliably
reached `minWidth`, so the brake never engaged. The fix keyed termination on a
**logical** condition: act only when `minWidth` actually *increased* (a pane opened),
updating the baseline *before* the side effect so the triggered relayout sees "no
change" and stops.

**Principle.** A loop's stop condition must not depend on a quantity the loop's own
action changes. Brake on a **discrete state transition you control**, recorded before
you cause the side effect — not on a re-measurement of the thing you're perturbing.

**Where it transfers.** Agent stop conditions. "Stop when the output looks complete"
or "when the model seems confident" are perturbable measurements — they loop or halt
wrong. Prefer explicit logical state: a tool returned success, a required field is now
populated, an iteration counter, a done-flag the step sets. Guard on progress you can
name, not on a self-affected signal.

---

## 9. A regression after a refactor that didn't touch the suspect = the *structure* tripped a latent bug

**Diptychon moment.** `WindowMinWidth`'s code was byte-identical between `main` (fine)
and the slice-1 branch (runaway). Slice 1 only **moved where it was attached** — from
the inner `HStack` to a new outer `VStack` wrapping an `HSplitView`. The fragility (a
brake that relied on a settling measurement) was always there; the new structure
changed the relayout timing enough to expose it.

**Principle.** When a regression appears after a change that *didn't modify the
suspected code*, stop staring at the code — the cause is the **surrounding structure /
wiring** exposing a pre-existing latent fragility. Diff how the thing is composed and
fed, not just what it does.

**Where it transfers.** A prompt, tool, or chain step that worked suddenly misbehaves
after you reorder the pipeline, add a pane/agent, or change the context budget — the
component is usually fine; its *inputs, ordering, or timing* changed. Diff the
composition (what's upstream, in what order, with what context), not the unit alone.

---

## 10. Match the observation window to the failure's timescale — and build the kill-switch before you reproduce

**Diptychon moment.** Two receipts, one good and one a mistake. The mistake: I called
the fix verified after watching memory stay flat for ~16 seconds — but the real
runaway was *automation-triggered* and I hadn't actually reproduced it, so the flat
sample proved nothing. The good move: before any repro attempt on a bug that had
already crashed the machine once, I gave the app a self-quit **watchdog** (force-quit
at 1.5 GB) plus an external memory **kill-switch**, so reproducing it couldn't take
the machine down again.

**Principle.** (a) A clean *short* observation does not prove absence of a *slow or
conditional* failure — size the watch to the failure's actual timescale and trigger
before you trust it. (b) For any failure that can damage the environment, **build the
safety net before you reproduce**, not after.

**Where it transfers.** Evals and agent safety. A model that passes 16 quick prompts
can still fail on long-context, rare, or adversarial inputs — size the eval to the
failure mode you fear, not to convenience. And before the first real run of an agent
that can spend, send, delete, or deploy, wrap it in a hard budget / dry-run /
kill-switch. The net is cheap; reproducing destructively isn't.

---

## How to use this doc
- **When starting a new product** (especially AI): read §1 and §5 *before* you
  design the second pane or give an agent write-access. They're the expensive
  lessons to learn late.
- **When a surface feels noisy or unreadable:** §2 and §3.
- **When scope is creeping:** §4.
- **When debugging a runaway / freeze / non-terminating loop** (code *or* agent):
  §7–§10, in order — find the feedback writer → fix the termination on logical state →
  suspect the structure, not the suspect → reproduce safely with a kill-switch.
- **Pairs with:** `dashboard-research.md` (§2 in depth), `competitor-benchmark.md`
  §3 (§4 in depth), and the issue spine — `18` (reversibility surfaced), `19`
  (discoverability surfaced).
