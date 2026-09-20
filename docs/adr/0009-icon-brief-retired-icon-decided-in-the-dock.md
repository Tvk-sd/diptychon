# The icon brief is retired; the icon is decided in the Dock

Decided 2026-09-19/20, during the icon redesign on branch `curvy-otter`.
Supersedes `design/icon/BRIEF.md` (draft, 2026-07-08), which is deleted in the
same commit.

## What changed

The July brief fixed the icon's *appearance* before anything had been drawn:
two flat tones (`#282828` / `#D9D9D9`), and gradients, gloss and glass listed
under "anti-goals (auto-reject)". It also prescribed a preferred solution — the
fragmented mosaic resolving into "DT" on second look.

Working against real references showed the rule set was taste frozen too early,
not a constraint the product needs. Every concept that read well at Dock size
used exactly what the brief forbade: translucency to show one panel through
another, and a tonal gradient to separate a panel from its ground. The flat
two-tone reduction survives, but as a small-size fallback, not as the law.

## The decision

1. **The brief is deleted, not amended.** A document whose every clause is now
   optional stops being a constraint and starts being noise for the next
   session. Its history stays in git.
2. **Gradients, translucency and soft shadows are allowed.** So is a coloured
   ground. Nothing about the icon's surface is prescribed in advance.
3. **What survives is the product reading, not the taste:** two panels with a
   seam, one block that reads as crossing it, legible at 16 px, holding its
   edge on a light *and* a dark Dock. These are claims about what the app does,
   so they outrank any style rule.
4. **The test is the Dock, not the page.** A concept counts as working only
   when it has been rendered to real icon sizes and seen next to Finder,
   Safari, Zed and Terminal. Concept 02 failed that test on its first render
   (the frosted pane collapsed into a grey blob at 92 px) and was fixed because
   of it — a judgement no amount of looking at the 1024 px artwork would have
   produced.

## Consequences

- `design/icon/alternatives/` holds finished, standalone SVGs plus a gallery;
  `design/icon/concepts/` holds the exploration board. Neither ships.
- The mark is `alt-02-frosted-bw.svg`, accepted by Till on 2026-09-20 at the
  real Dock test. It ships as `Resources/AppIcon.icns` via `CFBundleIconFile`,
  **not** through the asset catalogue: on macOS 26 a catalogue app icon is
  treated as legacy and seated on a grey plate, whatever the artwork does.
  `AppIcon.appiconset` is deleted, because an `AppIcon` set re-adds
  `CFBundleIconName` on its own. The artwork keeps the classic inset squircle —
  the deployment target is macOS 14, and 14/15 do not mask the corners.
- At 16 px the frosted version still muddies. A simplified small-size artwork
  is outstanding for whichever concept wins.
- The wordmark question from the old brief (set "diptychon" in a real mono
  face, do not illustrate the name) is unaddressed and unrecorded elsewhere.
  It is the one piece of the brief worth rebuilding when the mark is settled.
