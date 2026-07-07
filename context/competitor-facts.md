# Competitor Facts — dual-pane Mac file managers

> Snapshot: 2026-07-07. Verification pass for the `/vs` page (`channel-plan.md` A1) and
> positioning. **Sourcing caveat:** these are from review sites + vendor/store pages, not
> hands-on testing. Pricing especially drifts — **confirm on each vendor's own pricing page
> before publishing a specific number publicly.** Pairs with `positioning-note.md` +
> `netnography/`.

## Summary table (verified 2026-07-07, directional)

| | **Diptychon** | Marta | ForkLift 4 | Nimble Commander | Path Finder |
|---|---|---|---|---|---|
| **Price model** | one-time (planned) | **free** (not OSS) | **one-time $19.95** (single; $29.95 family) | **free** tier (sandboxed/limited) + **$29.99 one-time** Pro | **subscription** $29.95/yr or $2.95/mo (license-key option exists) |
| **Native / stack** | Swift, ~1.4 MB | Swift, native | Swift (rebuilt), native | C++, native, **open-source** | native |
| **Dual-pane** | yes | yes | yes | yes | yes |
| **Remote (SFTP/WebDAV/…)** | **no — by design** | no | **yes** (SFTP/FTP/WebDAV/S3/B2/Drive/OneDrive/Dropbox/SMB/AFP/NFS) | yes (mounts) | limited |
| **Notable** | keyboard, undo-anything, Finder tags, no telemetry | keyboard-cult; single-dev continuity worry | remote powerhouse, multi-rename, 20× sync | 100+ hotkeys, fast; features paywalled in free tier | actively maintained (v11, Feb 2026) but **went subscription** |

## Per competitor

**Marta** — free (not open-source), written in Swift, dual-pane, plugin support, keyboard-first
(cult following). The recurring worry in the community is **single-dev continuity**, not
capability. → *Diptychon's angle:* undo-anything + real Finder tags + an actively-shipped roadmap.

**ForkLift 4** — **one-time $19.95** single / $29.95 family / $69.95 business (NOT subscription).
Rebuilt in Swift, Apple-Silicon-native; the remote powerhouse (SFTP/FTP/WebDAV/S3/B2/cloud/SMB/
AFP/NFS), folder sync (20× faster), multi-rename, archive handling, Quick Look, Spotlight. → *Angle:*
if you only need **local**, it's a lot of app for a fraction of Diptychon's footprint; keyboard is
"partial" vs ForkLift's mouse-forward workflow.

**Nimble Commander** — **free + open-source** (GitHub `mikekazakov/nimble-commander`); the free
Mac App Store build is **sandboxed and feature-limited**, and **$29.99 one-time Pro** (from the
magnumbytes store) unlocks admin/root mode, UNIX/BSD flags, ownership editing, etc. C++ = blazing +
low memory, 100+ hotkeys, remote mounts, archive-as-folder; **steep learning curve, no plugins**.
→ *Angle:* gentler to learn, one-time with no feature paywall once priced, undo, native tags.

**Path Finder (Cocoatech)** — **actively maintained** (v11 out Feb 2026; some sources cite other
version strings — verify) despite older "discontinued" claims. **Now subscription: $29.95/yr or
$2.95/mo**, with a license-key one-time activation option. Kitchen-sink power features, heavier
footprint. → *Angle:* Path Finder going **subscription** is a gift for the anti-abo segment
(netnography **T-A**) — Diptychon's one-time + tiny footprint is the clean contrast.

## Corrections to apply to the `/vs` draft

- **Path Finder:** draft said "one-time ~$36" → **wrong. It's subscription ($29.95/yr; license-key
  option).** Fix the table AND add the anti-abo contrast in prose — this is a real wedge.
- **ForkLift:** make price specific → **one-time $19.95** (not just "one-time").
- **Nimble Commander:** nuance "paid/paywalled" → **free (limited) + $29.99 one-time Pro; open-source.**
- **Telemetry column:** left "verify" for competitors — **do not assert** competitor telemetry
  without a source; either drop the row or keep only Diptychon's "none" as a stated fact.
- General: before publishing, re-confirm each price on the **vendor's own page** (review sites lag).

## Sources
- Marta — [marta.sh](https://marta.sh/), [MacUpdate](https://marta.macupdate.com/), [Mac Treasure](https://mactreasure.com/marta/)
- ForkLift 4 — [binarynights.com](https://binarynights.com/), [techrevue review](https://techrevue.com/software/forklift-4-mac-review-alternatives/), [mqdir price note](https://mqdir.com/blog/file-management/finder-vs-forklift)
- Nimble Commander — [magnumbytes.com](https://magnumbytes.com/), [Mac App Store](https://apps.apple.com/us/app/nimble-commander/id905202937?mt=12), [GitHub](https://github.com/mikekazakov/nimble-commander)
- Path Finder — [cocoatech.io](https://cocoatech.io/product/path-finder/), [store/updates](https://store.cocoatech.io/updates), [mqdir 2026](https://mqdir.com/blog/file-management/best-finder-alternatives-2026)
