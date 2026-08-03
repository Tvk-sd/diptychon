# 48 — Usage insight instrumentation (local-first, understand real user needs)

Status: **wontfix — geschlossen 2026-08-04 bei der Readiness-Triage (#68).**
Zwei Gründe. Erstens kollidiert es mit der Positionierung: Diptychon wirbt mit
„keine Telemetrie", Cloudflare Web Analytics wurde 2026-07-13 bewusst abgeschaltet
und Datenschutz § 4 sagt es zu. Ein offenes Ticket, das Nutzungsmessung plant,
liest sich wie ein Widerspruch dazu — auch wenn es local-first gemeint war.
Zweitens ist die Frage dahinter („woher erfahre ich, was Nutzer brauchen") von
**#72** übernommen, und zwar über den einzigen Weg, der zur Position passt:
Menschen schreiben es einem selbst.

Falls das je wiederkommt, muss es als ADR entschieden werden, nicht als Ticket.

Ursprünglicher Stand: needs-triage (2026-07-06) — drafted to answer a recurring PM gap: nearly every
recent issue (43, 40, 35, 38, …) carries a "validate demand in our own segment before
heavy build" note, but we have **no instrument** to observe what users actually do. This
issue proposes one — built to fit Diptychon's privacy-first positioning, not fight it.

## Parent

`.scratch/diptychon-mvp/PRD.md`

## The job to be done

As the PM/builder, I need to **learn which capabilities users actually reach for**, so I
can prioritise the backlog and confirm (or kill) demand before expensive builds — the
exact judgement call deferred in issues 43 (local search), 40 (load-path), 35 (disk
usage), 47 (camera import). Today those calls rest on a single netnography voice plus
intuition. Instrumentation replaces guesswork with our own segment's behaviour.

## The core tension (decide this first)

Diptychon's GTM is **values-hygiene / local-first** (`context/netnography/`, landing-page
`SCOPE.md`): the target segment actively distrusts tools that phone home. Standard
product analytics (background event streams to a vendor) is **the thing they are running
from**. Shipping naive telemetry would contradict the pitch and burn trust with exactly
the users we want.

So the design constraint is not "how do we track users" but **"how does the app learn
from itself without betraying the local-first promise."** Recommended posture:

- **Local-only by default.** Counters/events are written to a plain, human-readable file
  on the user's own disk (`~/Library/Application Support/Diptychon/insights.json` or
  similar). Nothing is transmitted, ever, by default.
- **User-owned + inspectable.** A menu item opens the file / a readable summary. No
  hidden collection — the user can see exactly what was recorded. This is itself
  on-brand: transparency as a feature.
- **Opt-in to share, never opt-out.** The only way data reaches us is an explicit
  **"Share usage with the developer"** action that exports the readable file for the
  user to send (email/attach). Consent is per-export, informed, revocable.
- **No PII, no content, no paths.** Record *that* a capability was used and rough
  frequency — never filenames, folder paths, image content, or tags. Aggregate counts
  and coarse buckets only (see below).

This keeps us honest: if we wouldn't show the user the recorded line, we don't record it.

## What to build (v1)

A small **local usage-insight recorder** wired to the command/action spine, plus a
surface to view and (optionally) export it.

- **Event model — coarse and anonymous.** Increment named counters on meaningful
  actions, e.g. `dualPane.focusSwitch`, `stage.add`, `operation.copy`, `search.run`,
  `hotkey.customised`, `preview.open`. Store counts + first/last-seen day (day
  granularity, not timestamps). Reuse the existing `AppAction` spine (issue 04 / 28 /
  44) as the single tap point so instrumentation is centralised, not sprinkled.
- **Coarse context buckets, not raw values.** Where a magnitude matters, bucket it:
  folder size as `<100 / 100–1k / 1k–10k / 10k+` (ties to issue 22/40 perf work),
  session length as coarse ranges. Never the actual number, never the path.
- **Local viewer.** A menu item (Help ▸ "Usage insights…") that opens the readable file
  or a simple summary sheet — so the user always sees what exists.
- **Explicit share/export.** "Share usage with the developer" → writes/reveals the
  export file with a one-screen plain-language explanation of what it contains and what
  it omits. No silent upload.
- **Off, or on-with-notice — decide in plan.** Either recording is opt-in on first run
  via a one-line consent ("Diptychon keeps anonymous usage counts *on this Mac* to
  improve the app — view or clear them anytime"), or on-by-default-but-local with a
  prominent off switch. Given the segment, lean toward **on-locally, transparent,
  trivially clearable** rather than a nagging opt-in wall — but this is a judgement call
  for the plan.

## Why this shape (PM note)

- **It answers the "validate first" notes cheaply.** Once shipped, issues like 43/40/35
  gain a real signal source: are people even hitting the shallow feature the deeper one
  would extend?
- **It turns a liability into a differentiator.** "Your usage never leaves your Mac —
  and you can read every line we keep" is a *values-hygiene* selling point, consistent
  with the landing-page positioning, not a footnote in a privacy policy.
- **Qualitative still matters.** Counters tell us *what*, not *why*. Pair with a
  lightweight in-app "Send feedback" affordance (out of scope here, note as follow-up)
  so we get the narrative behind the numbers.

## Acceptance criteria

- [ ] Meaningful actions increment named, anonymous counters recorded to a local,
      human-readable file — no network transmission by default.
- [ ] Recorded data contains **no** filenames, paths, tag names, image content, or
      precise timestamps; magnitudes are bucketed.
- [ ] Instrumentation is centralised on the existing action spine (one tap point), not
      scattered per-view.
- [ ] The user can view the recorded data and clear it from within the app.
- [ ] Sharing with the developer is an explicit, per-export action with a plain-language
      disclosure of contents — never automatic.
- [ ] No measurable UI/perf regression vs issue 22 baselines (recording is cheap and
      off-main where needed).

## Out of scope

- Any background / automatic transmission of data to a server or third party.
- Session replay, heatmaps, screen recording, keystroke logging — invasive, off-brand.
- Third-party analytics SDKs (contradicts local-first; also a supply-chain/trust cost).
- Per-user identity, cohorts, funnels, remote dashboards. (If we ever want aggregate
  cross-user stats, that is a *separate, explicitly-consented* future issue with its own
  privacy review — not this one.)
- In-app qualitative feedback UI (worthy follow-up; note below).

## Open decisions for the plan

- On-locally-by-default vs opt-in-on-first-run (recommended: on-locally + transparent +
  clearable).
- Storage format/location and whether the viewer is the raw file or a formatted sheet.
- Exact v1 event list — start minimal (the actions above), expand only when a specific
  backlog decision needs a specific signal.

## Related

- `context/netnography/` — values-hygiene GTM; the segment's distrust of phone-home
  tooling is the whole reason for the local-first constraint.
- `.scratch/landing-page/SCOPE.md` — positioning this must stay consistent with.
- `22-performance-baseline-measurements` — existing measurement posture + perf baselines
  to not regress; bucket boundaries can align with its size classes.
- `43 / 40 / 35 / 47` — issues carrying explicit "validate demand first" notes that this
  instrument is meant to serve.
- `04 / 28 / 44` — the `AppAction` command spine this taps into.

## Follow-ups (not this issue)

- In-app "Send feedback" for qualitative *why* behind the counters.
- If cross-user aggregate insight is ever wanted: a separate, consent-first, privacy-
  reviewed issue.
