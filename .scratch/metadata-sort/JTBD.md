# Metadata Sort — JTBD + Value Proposition

_Feature #3 from the AI-agent-tasks research: sort/organize an imported folder by metadata (capture date, source, sequence, filename patterns). No vision model — the metadata is already on the files._

## The job executor

The Diptychon user: an artist / photographer / archivist who composes diptychs from a large personal image collection — often a folder dumped from cameras, scanners, or multiple sources, named with machine defaults (`IMG_2048.jpg`, `DSC_0001`, `scan_047.tif`).

## Core job (JTBD statement)

> **When** I open a folder of imported images to start composing diptychs, and the files are named by machine defaults and dumped in no order,
> **I want to** turn that pile into a navigable structure using the metadata already on the files — capture date, source, sequence, existing name patterns —
> **so I can** reach the images I need while composing, instead of scrolling a wall of meaningless names.

## Job dimensions

- **Functional:** chaos → navigable order; rename to human-meaningful; group by date / shoot / source; reach any image fast.
- **Emotional:** relief from overwhelm; confidence nothing is lost or misfiled; in control of my archive rather than buried by it.
- **Social (weaker):** hand off / export a tidy archive; not embarrassed by `IMG_2048.jpg` in a finished piece.

## Desired outcomes (what "better" means, measurably)

- ↓ time to locate a known image
- ↓ number of manual rename/move actions before composing can start
- ↑ confidence the operation is safe & reversible ← the make-or-break outcome
- ↓ cognitive load of reading filenames

## Four forces

- **Push** (away from today): unnavigable dump; scrolling thousands of cryptic names; "I know I have that image but I can't find it."
- **Pull** (toward the feature): one action turns the pile into date/source-grouped, human-named files, right inside the tool.
- **Anxiety** (blocks adoption): "Will it move or rename my originals destructively? Will it mis-sort? Can I undo?" — acute for irreplaceable creative work.
- **Habit** (holds them back): Finder + manual dragging — slow, but trusted not to wreck files.

→ The anxiety force is **stronger here than in ordinary file-sorting** because these are art originals. Preview-first, non-destructive, fully reversible is not a nice-to-have — it is the price of entry. (Every credible tool in the space — NameQuick, hyperfield/ai-file-sorter — leads with preview + undo for exactly this reason.)

## Value proposition

**For** diptych-makers drowning in machine-named image dumps,
**Diptychon's metadata sort** turns a chaotic import into a navigable, human-named archive in one reviewable pass — using the date/source/sequence data already on your files, entirely on-device —
**so you spend your time composing pairs, not filing photos.**
**Unlike** Finder (all manual) or generic AI sorters (a separate app that touches your files without you watching), it happens inside the tool you're already composing in, previews every change, and never moves an original you didn't approve.

## Sharpening risks (resolve before the code spike)

1. **Metadata may be too thin to produce a _useful_ sort.** A single shoot or a batch of scans can share one capture date and sequential names — sorting by metadata then just re-creates the pile in a new order. Value depends on the collection actually _having_ varied metadata.
2. **Why Diptychon and not NameQuick?** If this is generic metadata sorting, a dedicated sorter does it better. The defensible version is sorting _for composition_ — grouping the way a diptych-maker thinks (by session / series / source), reachable without leaving the tool. Untie it from the composing job and it belongs in someone else's app.

## Recommended next step

Before any code spike, run a **10-minute data spike**: point at one real import folder and dump what metadata actually exists — EXIF date spread, filename patterns, source variance. That confirms whether #3 is a real job or a mirage, far cheaper than building it.

---

## Data spike results (2026-07-06) — folder tested: `~/Desktop`

**Status: PARKED — commodity, off-job.**

81 image files scanned:

| Signal | Finding | Read |
|---|---|---|
| Filename pattern | 79/81 screenshots (`Bildschirmfoto…`), 2 stray jpg | Not diptych source material |
| EXIF capture data | 0/40 sampled have camera/acquisition model | The "rich metadata" path is empty for screenshots |
| Date in filename | 79/81 parseable, 34 distinct days, 2021→2026 | The only real sort signal — in the name, not EXIF |
| Date distribution | busiest day 7 files; 34 days total | Date-grouping distributes the pile, not reshuffles |

**Risk #1 (metadata too thin) — confirmed _and_ refuted.** EXIF is dead on arrival (0 hits); an EXIF-based sorter produces nothing here. But the filename timestamp is rich (79/81 across 34 days). So the sort is feasible — off a *different* signal than assumed. That reframes the build as a **filename-date parser**, not an EXIF engine: lighter to build, but commodity (Hazel, Finder smart folders, a 10-line shell script already do it).

**Risk #2 (why Diptychon, not NameQuick) — confirmed. This is the real finding.** The nearest real folder is 97% screenshots — desktop junk, not diptych material. The metadata-sort itch, in the actual environment, is **generic Desktop cleanup**, which is not Diptychon's job. Exactly the "belongs in someone else's app" case.

### Decision

Do **not** spike code. #3, tested where it actually lives, drifts off Diptychon's job.
- If the screenshot mess is genuinely felt → it's a **separate tiny utility** (Hazel/NameQuick territory), not a diptych-tool feature.
- To fairly re-test #3 for Diptychon → re-run the spike against a real **photo-import folder** (camera/scan originals with EXIF). If that folder _also_ leans on filename dates with dead EXIF, #3 is commodity everywhere → kill it.
