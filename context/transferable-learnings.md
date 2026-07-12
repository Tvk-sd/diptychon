# Transferable Learnings — what Diptychon taught that outlives it

The other research docs (`dashboard-research.md`, `sidebar-research.md`,
`competitor-benchmark.md`) serve *Diptychon*. **This one serves future-you** — the
patterns from building a dual-panel native app that carry into the next product.

**Lens.** Entries are captured first through a **product-management lens** — scope,
positioning, metrics, decision-making, risk — with **AI product-building as a light
lookout**, not the main frame. So "where it transfers" leads with the PM move; the
AI angle gets a secondary glance where it genuinely applies (AI products are
converging on the same multi-panel, left-to-right work surfaces, which is why the
lookout is worth keeping — but it's a lookout, not the lens).

**Anchor rule for every entry:** name the concrete Diptychon moment that taught it,
the generalizable principle, and where it transfers (PM-first, AI-light). No
platitudes without a receipt. Transfers are tagged *Classical PM* (the lens) and
*AI lookout* (the glance) so the balance stays honest and PM leads by volume. Each
entry carries its *Captured* date so a claim's age is visible — re-check anything old
before you rely on it (§19).

> **The AI lookout, in one claim** (a taste of the secondary glance, not the lens).
> It's tempting to say "all AI products are multi-panel." That's false — most are
> still single-column chat. The credible claim is that **multi-panel is the
> *maturity direction***: as a product moves
> from "give an answer" to "be a place you do work," it grows a second pane —
> Claude's artifacts panel, ChatGPT canvas, Cursor, v0. Diptychon is a small,
> honest lab for the problems that *every* product hits when it crosses that line.

---

## 1. The hard part of multi-pane isn't layout — it's "where does this action go?"

*Captured 2026-06-24.*

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

**Where it transfers.**
*Classical PM.* Any system where an action can originate from more than one place
needs an explicit *authority + destination* rule — this is ownership/RACI wearing a
UI costume. A cross-functional workflow where three teams can all "act" on a deal:
which one is authoritative for a given decision, and where does its output land?
Leave it implicit and the work happens in the wrong place — the org-scale version of
"it did the thing in the wrong pane." Same for any multi-surface product (web +
mobile + email + API): decide which surface owns the state and where a result
surfaces *before* you ship the second entry point, not after the support tickets.
*AI lookout.* Every AI product that grows a second pane inherits this — chat +
canvas, "make it blue" edits the selection or appends to chat? Build the
**Active / Destination** model before the second pane; it's the load-bearing
abstraction.

---

## 2. Let the data drive the form — readability is a rendering decision

*Captured 2026-06-24.*

**Diptychon moment.** From `dashboard-research.md`, applied in the file list:
**right-align numeric sizes** (digits line up by place value), **tags as colored
dots/chips** not text, **truncate long names**. Each treatment is chosen from the
data *type*, not applied uniformly.

**Principle.** A usable surface matches presentation to the *meaning and structure*
of the data, instead of dumping everything as flat text. Categorical → chips;
numeric → right-aligned; time-ordered → timeline; urgency → meaningful color.

**Where it transfers.**
*Classical PM.* This is the discipline of every dashboard, report, and status deck
you'll ever ship: match the presentation to the *decision the data serves* instead
of dumping rows of text at a stakeholder. Categorical → chips; numeric →
right-aligned; time-ordered → timeline/sparkline; urgency → meaningful color. A KPI
table an exec reads in ten seconds lives or dies on this — the same treatment that
makes a file list scannable makes a board deck legible. (See `dashboard-research.md`
for the depth.)
*AI lookout.* Acute for AI products, which mostly render output as a wall of
markdown: a list of statuses should be chips, a table of numbers should right-align.
**Don't render the model's text — render the data the text describes.**

---

## 3. Discoverability is the tax on every keyboard / power UI — pay it with progressive disclosure

*Captured 2026-06-24.*

**Diptychon moment.** Keyboard-first is fast but the chords are *invisible* — the
exact gap that drove issue 19 (a ⌘K command palette listing every command with its
chord). The same instinct shows up smaller everywhere: tooltips on icon-only
controls, hover-reveal for secondary row actions, sheets for focused tasks instead
of permanent chrome.

**Principle.** Power and discoverability trade off, and the resolution is
**progressive disclosure**: surface the primary action, tuck the rest behind
hover / palette / menu, and give people a single place to *find* capability
(the palette) without cluttering the default view.

**Where it transfers.**
*Classical PM.* Discoverability is the hidden tax on adoption: a shipped feature
nobody can find is unshipped in the metrics (ties to §17 — capability isn't
outcome). Every complex product fights the same power-vs-approachability tension
Diptychon's chords do — Excel, Figma, Notion — and resolves it the same way: surface
the primary action, tuck depth behind menus / onboarding / empty-states, and give
one place to *discover* capability. When a launched feature underperforms, "can
users find it?" is the first question, before "do they want it?"
*AI lookout.* AI products have the worst version of this — the input is a blank box
and the user has no idea what's possible. Same primitives fix it: command palette,
suggested actions, slash-commands, example chips. The blank prompt is a keyboard UI
with no key legend; treat it like one.

---

## 4. Restraint is a feature — define the deliberate "don'ts"

*Captured 2026-06-24.*

**Diptychon moment.** The sidebar spec (issue 16) *explicitly excludes* Recents,
Tags, and iCloud/Locations from v1 — "less than Finder" is the goal, not a
compromise. The benchmark's §3 lists remote mounts, archive browsing, and
folder-sync as deliberate ➖, not gaps. The product's one durable differentiator —
**lightweight** — is defended entirely by saying no.

**Second receipt (issue 29).** An "add email to Diptychon" itch (born from wanting a
Notion-style one-stop tool) got scoped *down* to its smallest honest version —
`.eml` metadata in the inspector — and **prototyped specifically to earn the right
to decide.** A functional parser (9/9), a spec-by-example, and a visual HTML mock
later, the rendered surface made the answer obvious: email is *its own app*, not a
feature — showing a message invites a verb set (reply/forward/compose/thread) a file
manager can't honestly carry. We shelved it as a deliberate non-scope (`wontfix`),
keeping only what's already free (the OS previews `.eml` bodies). The prototype's job
wasn't to build the feature — it was to make the "no" concrete and defensible (ties
to §14: aim the cheap probe at the real question).

**Principle.** Positioning lives in what you refuse to build. A feature list with no
explicit non-scope has no identity; the deliberate-don'ts *are* the shape. And a
*no* is sometimes worth a cheap prototype: building the smallest version is often the
fastest way to *see* that it doesn't belong — and to record why, so it isn't
re-litigated.

**Where it transfers.** AI products bloat fastest of all — every capability feels
free to bolt on. The discipline of a written "deliberately out of scope" list (and
a bar to flip an item: "does this break the one thing we're actually differentiated
on?") is what keeps an AI product from becoming an everything-drawer that's good at
nothing.

---

## 5. Reversibility is the trust layer — and it matters more when an AI acts

*Captured 2026-06-24.*

**Diptychon moment.** ADR 0004: a reversible `Operation` spine where every action
(copy/move/trash/rename) records its own inverse, powering multi-level undo. We
built it *before* most operations existed, so every later op inherited undo for
free. Overwrites are the one explicitly non-undoable case — and we surface that
honestly rather than pretending.

**Principle.** When software takes consequential actions on a user's behalf,
**recording the inverse is what makes the action safe to offer.** "You can't mess
this up" lets users move faster than "are you sure?" ever will.

**Where it transfers.**
*Classical PM.* Reversibility is a trust primitive in any product that takes
consequential action — Gmail's undo-send, soft-delete + trash, draft/publish, a
staged rollout with a rollback plan. "You can't mess this up" lets users (and orgs)
move faster than any confirmation dialog. The PM move is to build the reversibility
spine *before* the risky actions so each new one inherits safety for free, and to
flag the genuinely irreversible ones loudly rather than pretend. It scales up to
change management: a pilot you can roll back is a change people will actually try.
*AI lookout.* The most important version of the pattern for **agentic AI** — an
agent that edits files or sends messages is a file manager with a non-deterministic
operator at the wheel. Every agent action carries its undo, the few irreversible
ones flagged loudly; that's the line between an agent trusted with real work and a
demo you babysit.

---

## 6. When the framework fights you, drop to the layer that owns the problem

*Captured 2026-06-24.*

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

**Where it transfers.**
*Classical PM.* This is the build-vs-buy and platform-dependency call in miniature.
A high-level framework (or SaaS vendor, or platform) optimizes the common case —
great until your differentiator *is* the uncommon case, at which point you're
fighting the tool instead of the market. The PM hedge is one well-placed seam at the
boundary so you can drop a layer (or swap a vendor) without rewriting the product —
but *only* the seams you'll actually cash in. Abstracting every dependency "just in
case" is speculative flexibility you pay for and never use.
*AI lookout.* Directly to AI engineering: high-level agent frameworks are SwiftUI
`Table` — wonderful until your use case isn't theirs. Keep a seam so you can drop to
the **raw model API** when you need control; resist abstracting every provider behind
config you'll never vary.

---

## 7. An infinite loop needs a "feedback writer" — find the one thing that writes back

*Captured 2026-06-25.*

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

**Where it transfers.**
*Classical PM.* Runaway *processes* work the same way — a reinforcing loop needs one
step that feeds its own input. A support queue that generates more tickets than it
closes, a status meeting that spawns more status meetings, a scope that grows every
time you "finish" a piece: the runaway isn't everywhere, it's one reinforcing edge.
Don't pile on symptoms (more agents, more meetings); inventory the loop and cut the
single step that writes back into its own input.
*AI lookout.* Agent loops that never terminate: find the step feeding its own input —
a tool whose output re-triggers planning, a scratchpad the planner both reads and
appends to. Fix the one step that closes the cycle, not the symptom.

---

## 8. Terminate on a logical state change, not on a measurement the loop perturbs

*Captured 2026-06-25.*

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

**Where it transfers.**
*Classical PM.* "Done when it feels ready" or "ship when the demo looks good" are
perturbable brakes — the act of building distorts the very signal you're braking on.
Define exit criteria on a discrete state you control and record it *before* the work:
acceptance criteria met, a checklist flag flipped, a metric past a pre-registered
threshold. A launch gate keyed on a vibe slips forever; one keyed on a nameable state
actually closes.
*AI lookout.* Agent stop conditions: "stop when the output looks complete" is a
perturbable measurement. Prefer explicit logical state — a tool returned success, a
required field is populated, a done-flag the step sets.

---

## 9. A regression after a refactor that didn't touch the suspect = the *structure* tripped a latent bug

*Captured 2026-06-25.*

**Diptychon moment.** `WindowMinWidth`'s code was byte-identical between `main` (fine)
and the slice-1 branch (runaway). Slice 1 only **moved where it was attached** — from
the inner `HStack` to a new outer `VStack` wrapping an `HSplitView`. The fragility (a
brake that relied on a settling measurement) was always there; the new structure
changed the relayout timing enough to expose it.

**Principle.** When a regression appears after a change that *didn't modify the
suspected code*, stop staring at the code — the cause is the **surrounding structure /
wiring** exposing a pre-existing latent fragility. Diff how the thing is composed and
fed, not just what it does.

**Where it transfers.**
*Classical PM.* A team or workflow that ran fine suddenly degrades after a reorg, a
new dependency, or a cadence change — and the unit itself never changed. The fragility
was always latent; the new *wiring* exposed it. Don't audit the team; diff the
composition — what's upstream now, in what order, with what handoffs and timing. The
cause is the structure you changed, not the part that looks broken.
*AI lookout.* A prompt or chain step that worked misbehaves after you reorder the
pipeline, add an agent, or change the context budget — the component is usually fine;
its inputs, ordering, or timing changed. Diff the composition, not the unit.

---

## 10. Match the observation window to the failure's timescale — and build the kill-switch before you reproduce

*Captured 2026-06-25.*

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

**Where it transfers.**
*Classical PM.* Two launch disciplines. (a) A rollout that looks clean in week 1 can
still fail on slow, seasonal, or edge cohorts — size the measurement window to the
*failure mode you fear*, not to when the dashboard looks good; a short clean sample
doesn't disprove a slow or conditional failure. (b) Before exposing a risky change,
build the safety net first — staged rollout, feature flag, rollback plan — so the
blast radius is bounded *before* the first real run, not patched after.
*AI lookout.* Evals and agent safety: a model passing 16 quick prompts can still fail
on long-context or adversarial inputs — size the eval to the failure you fear. Before
an agent that can spend, send, or delete runs for real, wrap it in a hard budget /
dry-run / kill-switch.

---

## 11. Routing by geometry is content-blind — and a coordinate-space mismatch is a silent gap

*Captured 2026-06-25.*

**Diptychon moment.** Moving the Filter into the unified top bar made clicking it
*steal the active panel to the right*. The cause was a global `NSEvent` `leftMouseDown`
monitor that picks the active panel purely from the click's **x**. Two compounding
bugs: (a) it measured the top-bar guard band from `contentView.bounds.maxY`, but
SwiftUI uses a **full-size content view** that extends behind the title bar — so
`bounds.maxY` is ~28pt *above* where content actually renders, and the band sat over
the title bar and missed the real bar. My first fix used that wrong anchor and *failed
silently* — no error, the Filter just kept stealing. The right anchor was
`window.contentLayoutRect.maxY` (the usable area *below* the title bar). And (b) the
monitor has no idea the Filter exists — it routes by position, so *any* interactive
control later dropped into the panels' x-range inherits "click here = activate this
panel."

**Principle.** (a) Whenever you correlate two coordinate systems (event space vs view
space, content vs window), an off-by-a-constant offset throws **no error** — it just
opens a dead zone where behaviour quietly differs. Anchor to the *semantically correct*
rect, not the convenient one, and verify against the running surface, not the math in
your head. (b) A dispatcher keyed on **geometry is blind to identity** — it can't tell
a file row from a text field at the same x. Every element you add inside its zone
silently inherits its rule; adding a case means re-checking the ones that "worked."

**Where it transfers.**
*Classical PM.* Any router or attribution keyed on a *proxy* rather than declared
identity inherits two failures. It's content-blind — a lead-routing rule or analytics
that attributes by screen region can't tell one thing from another at the same
coordinates, so every new case dropped into its zone silently inherits the rule. And
correlating two systems by a convenient anchor (a constant offset, a heuristic
mapping) throws *no error* when it's wrong — it just opens a dead zone where behaviour
quietly differs. Anchor on declared identity, and verify against the live system, not
the mapping in your head.
*AI lookout.* An LLM router that classifies by keywords instead of declared intent, or
any hit-testing / coordinate-mapping code: works until you add something new inside the
zone, then an old path breaks with no error to point at it.

---

## 12. A green test or a relaunch is a *proxy* for "verified" — not the thing itself

*Captured 2026-06-26.*

**Diptychon moment.** Fixing the self-overwrite data-loss bug (paste a file into its
own folder + Overwrite → file destroyed), I twice told the user it was "fixed and
verified" while it was still broken. First: the unit test passed because it
*constructed* the source URL directly — the real paste round-trips the URL through
`NSPasteboard`, which hands back a different representation, and that's where the bug
lived. Second: the manual re-test ran on a **stale process** — macOS had reactivated
the old binary, so the user retested pre-fix code. Two different proxies, same false
"verified." (Echoes §9: the bug hid in *how the operation was called*, not in the
operation.)

**Principle.** "It passes a test" and "I relaunched it" are proxies for verification,
not verification. A regression test only verifies if it exercises the **real call
path** (the real pasteboard/URL representation, the real input), and a manual check
only verifies on the **freshly built artifact** (force-kill, confirm a new pid).
Until both hold, the honest status is "fixed, not yet verified" — don't round up.

**Where it transfers.** Acute for AI products: an eval that hand-builds inputs instead
of running the real prompt/tool path will pass while production fails; "I tested the
fix" on a cached bundle or a stale deploy is the same stale-process trap. Verify
through the path the user (or the agent) actually travels, on the build they'll
actually run.

---

## 13. Refactors are steered by fitness functions, not a north-star metric

*Captured 2026-06-26.*

**Diptychon moment.** Before deepening the operation/refresh seam, the user (a PM)
asked for a "north-star metric" and floated an over-cautious ADR's 50k-file
performance worry as the candidate. Reframing it unlocked a clean decision: a
north-star is the wrong instrument for a maintainability refactor, and that perf
number is a *threshold/tripwire*, not a star. We scored the options on **fitness
functions** instead — footguns (forgettable steps with no compile check),
hops-to-comprehension (files to open to trace one action), testable-in-isolation —
and the A-vs-B interface fork settled itself.

**Principle.** Product value gets a north-star (a leading indicator of the value
created); internal-quality work gets **fitness functions** (cheap, checkable bars
that say "is the codebase getting healthier"). Don't anchor a correctness/
maintainability change to a performance number — measure the property you're actually
changing. And separate a *steering metric* from a *threshold* that only settles one
local choice.

**Where it transfers.** Any internal-quality effort — an AI agent's tool/codebase
refactor, an eval-harness cleanup, a prompt-library consolidation. Pick 2–3 fitness
functions that name the property under change, score before→after, and keep
performance tripwires as tripwires, not steering wheels.

---

## 14. Prototype your riskiest assumption, not the part that looks most like the product

*Captured 2026-06-30.*

**Diptychon moment.** Scoping the `.eml` preview (issue 29), we weighed three
prototype fidelities for the *same* feature: an **md spec-by-example** (ASCII
mockups of the inspector + parse traces), an **HTML mockup**, and a **~20-line
inline functional parser** run against a real `.eml`. The feature had two unknowns
with *opposite* risk. Layout was near-zero risk — the email metadata strip reuses
the existing `MetadataView` row component, just different labels — and the body
preview turned out **free** (macOS Quick Look already renders the
`com.apple.mail.email` UTI). The entire risk lived in the header parser: folded
continuation lines, `Subject: Re: Re:` colons-in-value, body lines that *look*
like headers. The functional snippet proved all three breakable cases in a single
run; an HTML mockup would have cost more and validated only the safe layout with
hardcoded fake data.

**Principle.** Fidelity isn't a scalar you turn up. Rank prototype media by **how
much each de-risks your riskiest assumption per unit of effort**, not by how much
the artifact resembles the finished product. A polished mockup of a low-risk
surface is motion, not progress — and the prettier the artifact, the more it tempts
you to validate the part that was never going to break. For a *known-UI-over-risky-
logic* feature, the cheapest *meaningful* prototype is running code on a real input,
not a rendered screen. Bonus move: match each medium to the axis it actually tests —
the cheap md locked the UX + became the unit-test cases (low-risk axis), the
functional snippet proved the parse (high-risk axis), and the middle option (HTML)
did neither well, so it was skipped.

**Where it transfers.** Any product / PM decision about how to test a bet *before*
building it. The instinct is to make the prototype resemble the product — a
clickable Figma flow, a styled landing page, a pixel-perfect mockup — when the real
question is usually *"will the core mechanic actually work?"* or *"will users
actually do the hard step?"* Spend the prototype budget on whichever axis is
genuinely uncertain: a fake-door / concierge test for **demand** risk, a throwaway
working spike for **feasibility** risk, a paper sketch when only the **layout** is
in doubt. The fidelity that looks impressive in a review is rarely the fidelity that
answers the question. Same family as §10 (size the test to the failure you fear) and
§12 (test the real path): aim the cheap probe at the assumption that can actually
sink the feature, and refuse to polish the safe part first.

---

## 15. JTBD is a *framing* instrument — it moves the question from feature to job, and scope + value + the right test all fall out

*Captured 2026-06-30.*

**Diptychon moment.** Issue 18 (operation history) was triaged and half-planned as a
full scrubbable timeline — until the PM stopped it cold: *"is this git with extra
steps, just for files? who's the user?"* Re-stating the **job** — *the bulk
reorganiser in the "wait, did I just break my folder structure?" moment* — did three
things at once. (a) It separated the part already solved (the reversible spine, blind
⌘Z) from the part actually being added (*legibility* + jump-to-a-point). (b) It exposed
that the triggering moment is *occasional* — so the risk was **demand** ("will anyone
reach for this?"), not feasibility. (c) It handed us the smallest evidence test for
*that* risk: ship **Tier 1**, a one-file undo *toast* ("Undone — Moved 12 items"), and
watch whether people start wishing they could see further back. We explicitly refused
the git-graph — heavy, and *wrong*, since the undo is linear (LIFO), not branching.

**Principle.** JTBD isn't documentation you write after — it's a **framing lens that
moves the unit of analysis from the *artifact* (the feature) to the *motivation* (the
job)**. It sits *upstream* of both scoping and value, which is why naming it a "scoping
instrument" or a "value instrument" undersells it — those are *effects*, not the thing.
Once you measure against the job, three things become decidable that weren't: **scope**
(cut whatever the job doesn't need), **value** (it lives in the job, not the feature —
so "does this serve the job?" replaces "is this cool?"), and **the right test** (the job
says whether the risk is *wanting it* or *building it*). Concretely, saying the job out
loud (i) splits "already solved" from "what I'm really adding," (ii) classifies the risk
as *demand* vs *feasibility*, and (iii) yields the cheapest probe that retires it. For
demand risk, ship the **thinnest real thing that makes the job legible** and let appetite
pull the heavy version. (It also decouples *problem* from *solution* — the stable job
from the disposable feature — which is what lets you see an oversized solution for what
it is. §14 generalised from feasibility to **value/demand** risk; pairs with §4.)

**Where it transfers.** This is the single most efficient way to **steer an AI builder**.
An AI will happily build whatever you point it at — so "what's cool to build" quietly
wins unless something forces "what job earns the build." A one-sentence JTBD is that
forcing function: it keeps the agent scoped to value, and AI features are *demand-risk
machines* — every capability feels valuable, demos beautifully, and sits unused. Before
building the agent / panel / automation, write the job, ask *"is the hard part wanting
it or building it?"*, and aim the probe at that axis: a fake-door or a legibility toast
for demand, a working spike for feasibility. The "value check / Eignungscheck" before
the build is what separates a product from a pile of capabilities.

---

## 16. A thin *real* slice is the cheapest way to discover the design is wrong — if the core is separable from the surface

*Captured 2026-06-30.*

**Diptychon moment.** The staging panel (#20). We deliberately chose **Option A** —
a file panel *swaps its source* to show the staging set — and built it as the #30/#31
slices, tests and all. Thirty seconds of using it live exposed what the plan couldn't:
swapping a panel *sacrifices a whole directory view*, but staging's job needs **source
panel + destination panel + the set visible at once**. We reversed to **Option A′**:
staging lives in the right auxiliary pane, both file panels stay directories. The
reversal was *cheap* — because #30 had split the **data layer** (`StagingStore` /
`StagingSource`, surfacing-agnostic) from the **surfacing**, the pivot threw away only
UI, never the model. The same separation then made the operate-on-set slice (#32) easy,
since the staging pane was already a real `PanelModel` with selection.

**Principle.** Some design errors are only visible *in the hand*, never in the plan. A
thin **working** slice — not a mockup — is the cheapest instrument to find them, **on
one condition**: you've separated the durable core from the disposable surface, so being
wrong about presentation costs only the presentation. Plan to be wrong about surfacing;
architect so that being wrong is cheap. (Distinct from §14: that's a *throwaway* probe
for feasibility; this is a *shippable* slice for UX/design discovery. Pairs with §6's
one-well-placed-seam.)

**Where it transfers.** AI products where the *interaction shape* is the real unknown —
chat vs canvas vs inline vs ambient/background. Build the capability behind a seam and
try the cheapest surfacing first, **expecting to move it**. The teams that re-shape an
AI interaction model cheaply are the ones who kept the model/tool layer independent of
how it's presented; the ones who fused capability to a chat transcript pay for it on
every pivot. Ship a real slice early — its job is to make the wrong surfacing *obvious
while it's still cheap to change*.

---

## 17. A capability is an *input* to value, not proof of it — "we built X" is not "users get the outcome X promised"

*Captured 2026-07-02.*

**Diptychon moment.** The app was architected for speed — off-main loads, a
virtualized `NSTableView`, prefetched resource keys — and a 50k folder was
spot-checked as "doesn't block." That *output* (the fast design shipped) hardened,
unmeasured, into an *outcome claim*: the benchmark's planned headline §4 *"instant
on huge folders."* Issue 22 finally measured it — ~4.6 s to load, ~6.5 s to fully
interactive. The design goal (never freeze the UI) was real and met; it had just
been quietly promoted into a different promise (fast) nobody had checked.
Non-blocking is *responsiveness*, not *speed*.

**Principle.** This is **the build trap** in miniature: shipping the capability
feels like delivering the value, so "we implemented the fast architecture" gets
logged as "it's fast." Keep the ledger honest — a feature is an *input* to an
outcome, and the outcome is real only when measured in the unit the user feels
(wall-clock seconds, not "we went off-main"). Corollary for **positioning**: a
superlative you can't put a number behind ("instant") is a liability, not an asset
— it breaks the first time a user counts. The specific, honest claim ("never
freezes; stays scrollable while it loads") is both defensible *and* more
differentiated than the superlative you can't defend.

**Where it transfers.** Any roadmap or OKR: police the line between **output
metrics** ("shipped the feature," "launched the model") and **outcome metrics**
("task completes faster," "user succeeds"). Celebrating the former as the latter is
product's most common self-deception. Before a claim reaches a landing page, a
sales deck, or a benchmark doc, ask *"what number defends this, and have we taken
it?"* — the same discipline whether the claim is load time or model accuracy.
(Pairs with §13: measure the property you're actually changing.)

---

## 18. A rolled-up "green" can be a watermelon — green on top, red inside; trust what *ran*, and run the counterfactual before you blame

*Captured 2026-07-02.*

**Diptychon moment.** One test double-`fulfill()`ed an expectation and crashed the
whole XCTest runner (exit 65); it restarted, re-ran the survivors, and the tracker
read *"100 tests green."* The suite had been compromised since the issue-18 merge
(PR #36) — a single crashing test masking the readout, and the summary line hid it.
The other 105 tests were fine. I only trusted the crash was pre-existing (not mine)
after reverting my own changes and reproducing it on a clean tree.

**Principle.** Two classic reporting traps, both here. (1) **Watermelon status**: an
aggregate "green" (a summary line, a rolled-up KPI, a RAG dashboard) can be green
while a component underneath is red — and it reports only on what *ran*, silently
dropping what never did. Trust the count of *ran-and-passed*, not the headline, and
ask *"what's excluded from this number?"* (2) **Attribution**: don't pin a
regression on the latest change because it's the obvious suspect — run the
counterfactual (revert, isolate, holdout) and reproduce. Cheaper and surer than
reasoning "it can't be mine."

**Where it transfers.** Every metric a PM reads is an aggregate that can hide its
exceptions: NPS computed on responders only, a funnel that drops errored sessions,
an OKR green because the measured segment is green. Watermelon reporting is how a
project sails green into a failed launch. And "the metric moved *because* of our
change" is product's most common causal error — the fix is the test-suite fix:
isolate and run the counterfactual, don't eyeball the timeline. (Pairs with §12:
a green readout is a proxy, not the thing.)

---

## 19. The map drifts from the territory, always toward flattering — reconcile records to ground truth or they rot

*Captured 2026-07-02.*

**Diptychon moment.** In a single session, four representations of the work were
wrong — each in the *optimistic* direction. Issue frontmatter said "ready-for-agent"
/ "needs-triage" on work merged weeks earlier. The tracker said "100 tests green"
over a crashing suite. The benchmark was about to claim "instant" over a 4.6 s load.
The footprint said "~1.5 MB," measured once (2026-06-24) and stale after ~10 more
shipped issues. Nothing was maliciously wrong — each record simply stopped being
reconciled with reality and drifted the pleasant way.

**Principle.** Any artifact that *describes* the work — status, dashboards,
benchmark claims, docs — decays toward optimism unless actively reconciled against
ground truth, because nobody re-checks a record that already says what they hope.
Two defenses: designate **one source of truth per fact** (here git + a green suite
are truth; the tracker is a derived view, and when they disagree the tracker is
wrong), and **date every measured claim** so staleness is visible — a number with
no date is an unearned assertion that it's still true. (Distinct from §17: that's a
*category error* at claim-time, an input mistaken for an outcome; this is *entropy*
over time, records rotting for want of reconciliation.)

**Where it transfers.** Status reporting and metrics hygiene — the daily PM job.
Two trackers with no reconciler diverge (roadmap vs. Jira vs. the deck); a "last
measured" date on every KPI tile is the cheapest guard against quoting a rotted
number; and the artifact that agrees with you is precisely the one to distrust.
Reconcile the map to the territory on a cadence, or it quietly becomes fiction.

---

## 20. Scout the solution space before naming the job and the tools become the lens — every "need" is a solution in disguise

*Captured 2026-07-06.*

**Diptychon moment.** A request to explore "AI file sorters + lightweight agent
tasks" started with web research into the *solution* space (local CLIP, Apple Vision
feature-prints, MobileCLIP). When I then listed candidate Jobs-to-be-Done for
Diptychon, **all of them were about image content** — semantic search, auto-pairing,
dedup — because I'd reverse-engineered jobs to fit the vision tech I'd just loaded.
The PM caught it in four words: *"why are they all just about images?"* The non-pixel
jobs (metadata rename, caption drafting, workspace automation) only surfaced *after*
that correction. Two more receipts compounded it: the whole "does this segment even
want AI?" question was **already answered in our own `netnography/`** — Trend T-E,
*"KI (noch) kein Thema,"* no AI demand in the corpus — and the one metadata feature
that survived (#3, sort-by-metadata) died in a **10-minute data spike on a real
folder** (Desktop: 97% screenshots, dead EXIF), cheaper than any argument.

**Principle.** Researching *how* before naming *what* quietly promotes the toolkit
into the lens: you stop asking "what job needs doing?" and start asking "what could
this tech do?", then dress each capability as a need. The **tell is homogeneity** —
when every candidate "need" shares the flavour of the thing you just researched,
they're solutions in job costumes, not jobs. Two guards: (a) **name the job cold,
before you scout solutions** — or scout, then deliberately re-derive the jobs from
the user with the tech menu shut; and (b) **before commissioning new evidence, check
whether the disqualifying answer is already in your own files** — prior research rots
into being un-re-read, and the cheapest test is often a real artifact you can grab in
ten minutes, not a build.

**Where it transfers.**
*Classical PM.* The classic "solution in search of a problem," sharpened to a
*sequencing* rule: the corruption enters the moment discovery of *how* precedes
definition of *what*. Any roadmap seeded by "we have this new capability / vendor /
model — where can we use it?" inherits it; every use case will smell like the
capability. Name the customer problem with the tool drawer shut, *then* open it. And
run the cheapest evidence first — a real record you already own beats a new study,
and the answer is often already written down in research nobody re-opened (here, T-E).
*AI lookout.* The dominant failure mode of AI product work right now — "we have an
LLM / agent, what should it do?" makes *every* feature look justified because the tech
is genuinely general. The homogeneity tell is loud: if every proposed feature is
"…but with a chatbot," the model has become the lens. Force the job first; let demand,
not capability, nominate the build. (Pairs with §15 — JTBD as the forcing function —
and §14/§10 — aim the cheap probe at the real risk.)

---

## 21. Depth is discovered by use, not specified up front — put the thin working slice in the hand and let it name the next layer

*Captured 2026-07-06.*

**Diptychon moment.** A request that started as "make search fuzzy" became nine
layers deep — and **none of them were foreseeable from the layer before**. Each one
only became legible once the previous one worked and got exercised on real files:
fuzzy match → *nothing found* (a >120k-entry `~/Library` ate the scan budget) →
*junk results* (needed relevance ranking) → *works in Home only* (scope: Search=global,
Filter=recursive-in-folder) → *path search* → *paste an absolute path* → *hidden
folders* → *noise* (a structural score floor) → *"where did I land?"* (a weak
highlight on the jump's target). The through-line: **"search" was never the job** —
"find and re-orient to my file" was, and each use-cycle peeled the proxy (matching)
back toward the real job (orientation). We only *touched* the real job at layer nine.

**Principle.** You cannot spec the depth of a feature before it exists, because each
layer's requirement is only visible once the layer beneath it works *in the hand*.
Planning the whole stack up front is a category error: it forecasts requirements that
only use can surface, so it predicts wrong at exactly the layers that matter. The
move is the opposite of a big spec — ship the **thinnest legible slice**, put it in a
real hand on real data, and let the friction name the next layer. Corollary: every
"it works, but…" is use doing its job, prying the feature name off the real job.

**Where it transfers.**
*Classical PM.* A roadmap that fully specifies a feature's depth is forecasting
requirements that don't exist yet; the honest unit is *thin slice + a usage loop*, not
the finished spec. Sequence by "what did using the last slice reveal?" not by a
pre-drawn feature list — and treat each "but…" as signal, not scope-creep. (Pairs with
§16 — the thin *working* slice finds the wrong surfacing in the hand — and §15 — JTBD
names the proxy-vs-real-job gap this rule keeps peeling.)
*AI lookout.* Agent-built features make this both cheap and dangerous: an agent can
ship a slice in minutes, so the use→reveal→next-slice loop can spin fast — *but only
if a human actually uses each slice against real data between turns.* Batch-speccing
"the whole search feature" to an agent up front buys a plausible artifact that is
wrong at layers 3–9, invisibly. Keep the human-in-the-hand loop; that's where the
depth lives, not in the prompt.

---

## 22. The faster the action, the louder its status must be — seamless actions incur an evaluation debt

*Captured 2026-07-06.*

**Diptychon moment.** The last search layer. Pasting an absolute path into Search now
*jumps* the pane straight to that file's folder — instant, no animation. It worked,
and it felt broken: the PM landed and couldn't tell *where*, because the jump erased
its own trace. The fix wasn't more speed — it was a **weak grey highlight** on the
landed-on file that scrolls into view and fades on the next interaction. The PM named
the underlying job: a search isn't done when results appear; it's done when the user
is *re-oriented*.

**Principle.** Every action has two gulfs (Norman): *execution* ("how do I do it?")
and *evaluation* ("did it work, and where am I now?"). Speed and seamlessness attack
the first gulf but **widen** the second — a slow action narrates itself; an instant
one deletes its own evidence, so the eye can't follow it. So feedback should scale
*inversely* with an action's visible duration: **the more magical the move, the more
deliberate the status cue.** But calibrate — feedback must be proportional to the
confusion it resolves; a cue that lingers, or fires where there's no disorientation,
becomes noise (status-illegibility by over-signaling). The shape we chose — weak,
transient, self-clearing — *is* that proportionality made concrete. And legibility is
**temporal**, not just static: not "can you read the screen," but "can you follow what
just happened."

**Where it transfers.**
*Classical PM.* When you make a flow faster or more automatic, budget for the
evaluation debt it creates — the delight of *instant* is a loan against orientation,
repaid with a status cue. "Visibility of system status" (Nielsen #1) isn't a
static-screen property; it's about rendering *causality* legible, especially for
actions too fast to witness. Define "done" by the user's orientation, not the
system's output: results on screen ≠ the job; the job is the user knowing where they
now stand. (Pairs with §2/§3 — presentation matched to the decision the data serves.)
*AI lookout.* Agentic systems are the extreme case — they act fast, invisibly, often
in bulk, maximally widening the gulf of evaluation. Every autonomous action needs a
legible trace proportional to its consequence: what changed, where, how to undo. Same
inverse law (the more seamless/autonomous, the louder the status), same caveat
(proportional, not blanket — or the trace log becomes its own fog). (Pairs with §1 —
consequential actions need a legible, reversible handoff to whoever evaluates them.)

---

## 23. In a mature category the MVP bar is table-stakes-high — but retire the *unknown* risk (reach), not the comfortable one (feasibility)

*Captured 2026-07-07.*

**Diptychon moment.** The product was built *far* — a near-complete keyboard-first file
manager (search, operations, staging, tags, undo, persistence) — before demand or reach
was ever tested. The PM named it honestly: slid into the build trap. But he half-defended
it: file managers compete with mature products, so a bare dual-pane wouldn't be a fair
test of a demanding segment. **Both true and a rationalization.** The netnography had
validated *latent interest*; but *reach + switching* stayed untested until a capture page
went up this week — a probe that never needed the finished product. The tell: effort went
into the risk that was already low (feasibility — a capable builder building) while the
genuinely unknown risk (will reachable users *switch*) sat untouched the whole time.

**Principle.** Two lessons that only *look* like they conflict:
1. **MVP scope is set by the category's table stakes, not your feature's novelty.** In a
   greenfield, one feature can be an MVP; in a crowded category the minimum viable is
   *"table stakes + your wedge."* A thinner build fails for reasons unrelated to your
   differentiator (here: missing persistence, keyboard reliability, undo — the segment's
   own JTBDs), so it isn't a clean test. Building to table stakes is defensible.
2. **But that is not a licence to defer the demand/reach probe.** The build trap is most
   expensive when you retire the risk you're *good* at (feasibility) while the genuinely
   unknown risk (desirability / reach / switching) stays untouched. Build-to-table-stakes
   and validate-reach are **parallel, not sequential** — the error is treating "the
   category needs a complete product" as permission to postpone the reach question until
   the product is done.

**The guard.** *Before the next big build push, name the single riskiest assumption and
the cheapest test of it. If the cheapest test doesn't require the product, run it in
parallel — never let the build itself be the test.*

**Where it transfers.**
*Classical PM.* This is feasibility-vs-desirability risk (Cagan): effort should retire the
biggest *unknown*, and for a capable team feasibility rarely is it — desirability/viability
usually is. "MVP = smallest feature" is category-blind; calibrate the MVP to the incumbent
bar, but run the desirability probe (landing + waitlist, interviews, a reach test) *along*
the build, paced by signal, not after it. The tell of the trap is the sentence "I need to
build more before I can test demand" — almost always false.
*AI lookout.* Acute for AI/agent products: building is now so cheap that retiring
feasibility ("can the model do X") is trivial and seductive, while the real risk (does
anyone want this, will they adopt/switch, does it hold on real inputs) goes untested. The
faster you *can* build, the more disciplined you must be about probing demand in parallel —
or you ship a technically-impressive thing nobody asked for, just faster. (Pairs with §15 —
JTBD as the forcing function; §20 — name the job, not the tool; §14/§10 — aim the cheap
probe at the real risk.)

---

## 24. A state doc is a bounded context — one reader, one question, one deletion moment

*Captured 2026-07-12.*

**Diptychon moment.** The PM couldn't reconstruct the project's open decisions and had to
ask an agent to grep for them. Post-mortem: PLAN.md was actually current, but
PROJECT-TRACKER had drifted into a 40-section append-only changelog, and the open
items lived as one-line "Open: …" sentences buried inside closed-work prose — plus in
chat, agent memory, and individual context docs. No surface answered "what's open, on
whom?" The fix was structural, not disciplinary: PLAN.md became Roadmap-lite → Offen
bei Till → Offen bei AI (pointer to the issue queue) → Aktiver Task; outcomes now close
in the issue file or an ADR; git history is the changelog; the tracker was retired to
`context/archive/`.

**Principle.** Domain-driven design's *bounded context* applies to project docs: every
state surface needs (1) **one reader**, (2) **one question it answers**, and (3) **one
deletion moment** — an owner-event where entries get *removed* (decision made → line
deleted; task done → section cleared; issue closed → leaves the queue). The diagnostic
is: *who deletes from this doc, and when?* A doc with no deletion moment can only grow,
turns into a changelog, and stops being read. Corollary: never hand-maintain what a
system already records — git is the changelog; a prose duplicate of it rots by default
(§19).

**The guard.** *Before creating or keeping any state doc, name its reader, its question,
and its deletion moment. Can't name all three, or two of them overlap another surface →
merge or kill it.*

**Where it transfers.**
*Classical PM.* This is why Jira boards and status pages rot and why status meetings
exist: no surface cleanly answers "what's blocked, on whom." Same test works for
dashboards, RAID logs, OKR check-ins — each needs an owner-moment of deletion or it
becomes archaeology.
*AI lookout.* With agents, docs aren't documentation *about* the collaboration — they
**are** the collaboration interface. Every session reads only what's written, so a doc
with two jobs actively misleads: the agent will faithfully append to the dead tracker
forever. Doc design is now interface design. (Pairs with §19 — records drift; §26 —
the rules that *point* at the docs rot the same way.)

---

## 25. Lead shared state with the roadmap — altitude before detail is the kickoff that every session re-attends

*Captured 2026-07-12.*

**Diptychon moment.** The restructured PLAN.md puts a one-line Roadmap-lite at the very
top (Reach-Test → Demand-Test → GO? → Notarisierung → Launch) above the open items and
the active task. The PM recognized his own old practice: kicking off feature meetings —
discovery through user stories and three-amigos — *with the roadmap*, to set the why
before anyone argued the what.

**Principle.** The first thing a reader ingests frames everything after it. For AI
collaboration this doubles in importance: **every session is a smart colleague with
amnesia**, and the top of the shared state file is the only kickoff meeting they get.
One line of "where we are in the sequence, and what the current bet is" is the cheapest
known defense against locally-sensible-but-globally-wrong work (an agent polishing a
feature while the roadmap says the demand test hasn't run). Roadmap-*lite*, deliberately:
3–5 lines of sequence; the detail lives in the issue queue, or it becomes bloat that
nobody re-reads (§24).

**The guard.** *Any doc that an agent or new teammate reads first: current bet + sequence
in the first five lines. If the reader has to scroll to learn the why, the doc starts at
the wrong altitude.*

**Where it transfers.**
*Classical PM.* Agenda-setting, the three-amigos context round, "strategy before
backlog" — the practice was always about shared framing, not the artifact.
*AI lookout.* Context files (CLAUDE.md, PLAN.md, system prompts) are read top-down under
attention and token budgets — put altitude first, mechanics later. Applies recursively:
the same rule that orders a meeting orders a prompt.

---

## 26. Maintain encoded rules like code — a convention change is a refactor across every place the old convention is written down

*Captured 2026-07-12.*

**Diptychon moment.** Retiring PROJECT-TRACKER took edits in **four** encodings: the
global CLAUDE.md (whose rule literally said "fold outcomes into PROJECT-TRACKER"), the
project CLAUDE.md (new end-of-task issue-close rule), the agent's persistent memory, and
— still open as a backlog item — the `project-setup` skill that scaffolds a tracker into
every *new* project. Miss any one and the old convention resurrects itself: the next
session dutifully appends to a dead file; the next project regenerates it from the
template.

**Principle.** Rules for AI collaborators are configuration-as-code, and they
**duplicate by design**: the same convention gets encoded in global rules, project
rules, skills/templates, and memories. Changing a convention is therefore a refactor —
grep for the old symbol ("PROJECT-TRACKER") the way you'd grep for a renamed function.
The dangerous property: **a stale rule doesn't error, and it isn't ignored — it is
executed.** An agent follows the outdated instruction literally and forever, which is
worse than a human's benign neglect of an old SOP.

**The guard.** *After changing any workflow convention, enumerate every artifact that
encodes the old one — global config, project config, skills, templates, memories — and
update or delete each, now. It never happens by itself later.*

**Where it transfers.**
*Classical PM.* Process changes die when the templates and checklists still embody the
old process (SOP drift): the org announces the new way while its artifacts keep teaching
the old one.
*AI lookout.* Treat CLAUDE.md, skills, and prompt templates with code-review discipline:
they have callers (agents), they go stale, and their bugs run silently at full speed.
When the project setup changes, the ruleset is *due for revisit* — put that revisit in
the backlog explicitly. (Pairs with §19 — the map drifts toward flattering; §24 — the
docs the rules point at rot the same way.)

---

## How to use this doc
- **When starting a new product:** read §1 and §5 *before* you design the second
  pane or hand consequential actions to any operator (a user or an agent). They're
  the expensive lessons to learn late.
- **When a surface feels noisy or unreadable:** §2 and §3.
- **When scope is creeping:** §4.
- **When debugging a runaway / freeze / non-terminating loop** (code *or* agent):
  §7–§10, in order — find the feedback writer → fix the termination on logical state →
  suspect the structure, not the suspect → reproduce safely with a kill-switch.
- **When a click / event / route goes to the wrong place** (especially after adding
  UI inside an existing zone): §11 — check the coordinate anchor and remember the
  router is blind to *what* it hit.
- **Before saying "fixed / verified":** §12 — confirm the *real* call path on the
  *fresh* build, or say "not yet verified."
- **When evaluating a refactor or any internal-quality work:** §13 — score fitness
  functions, not a north-star; keep perf numbers as tripwires.
- **When deciding how to prototype a feature:** §14 — aim the prototype at your
  riskiest assumption, not at product-likeness; run real code on real input over a
  pretty mockup of the safe part.
- **When scoping a new feature / bet (or steering an AI to build one):** §15 — state
  the JTBD first; it splits solved-from-new, names demand-vs-feasibility risk, and
  hands you the smallest test. Ship the thinnest legible version before the heavy one.
- **When a request starts from a technology ("we have X — where can we use it?") or
  right after you've researched the solution space:** §20 — name the job with the tool
  drawer shut, distrust candidate "needs" that all smell like the tech, and check
  whether the disqualifying evidence already sits in your own research before commissioning more.
- **When the interaction shape is the real unknown:** §16 — ship a thin *working*
  slice to find the wrong surfacing in the hand, with the core split from the surface
  so the pivot is cheap.
- **Before turning a capability into a claim (a landing page, deck, or benchmark):**
  §17 — a feature is an input to an outcome, not the outcome; measure it in the unit
  the user feels, and don't ship a superlative you can't put a number behind.
- **When reading any green dashboard / rolled-up status, or attributing a metric
  move:** §18 — trust what *ran-and-passed* (watch for watermelons), and run the
  counterfactual before you assign a cause.
- **When status / docs / benchmarks feel "probably still true":** §19 — records drift
  optimistic; pick one source of truth per fact and date every measured claim.
- **When scoping how deep to plan a feature (or handing one to an agent):** §21 —
  you can't spec depth up front; ship the thin working slice, use it on real data,
  and let each "it works, but…" name the next layer (and the real job under the name).
- **When you make an action faster / more automatic / more autonomous:** §22 — speed
  widens the gulf of evaluation; budget a status cue proportional to the confusion the
  now-invisible action creates. Done = the user is re-oriented, not "output shown."
- **Before a big build push (or when you catch yourself building toward validation):** §23 —
  set the MVP bar by the category's table stakes, but retire the *unknown* risk (demand/reach),
  not the comfortable one (feasibility); name the riskiest assumption + its cheapest test, and
  if that test doesn't need the product, run it in parallel — never let the build be the test.
- **When a "what's open / what did we decide" question needs an agent to answer, or a
  status doc feels dead:** §24 — give every state doc one reader, one question, one
  deletion moment; merge or kill docs that fail the test, and never hand-duplicate git.
- **When writing any doc an agent (or new teammate) reads first:** §25 — current bet +
  sequence in the first five lines; altitude before mechanics.
- **After changing a workflow convention (or when project setup changes):** §26 — grep
  every encoding of the old rule (global config, project config, skills, memories) and
  update each; a stale rule isn't ignored, it's executed.
- **Pairs with:** `dashboard-research.md` (§2 in depth), `competitor-benchmark.md`
  §3 (§4 in depth), and the issue spine — `18` (reversibility surfaced), `19`
  (discoverability surfaced).
