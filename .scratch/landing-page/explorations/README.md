# Landing-page explorations

Alternative visual directions for diptychon.com. **Nothing here is deployed.**
The shipped page stays `.scratch/landing-page/index.html`; its system is `DESIGN.md`.

## machine-hall.html

A landing page whose visual identity was derived from a random alphanumeric seed
rather than from `DESIGN.md` — deliberately *not* the hairline-lattice /
Apple-blue system, so the two can be compared side by side.

Product facts, voice and the key table are unchanged and come from `PRODUCT.md`,
`CONTEXT.md` and the shipped page, so only the design varies.

### Direction: "machine hall daylight"

| Seed sub-pattern | Design consequence |
|---|---|
| Length 96 = 12 x 8 | 12-column grid on an 8px baseline |
| Digits read `1909` in sequence | Werkbund / AEG Turbinenhalle year: industrial-modernist *Typisierung* |
| Digit sum 57 | Hue 57 deg -> raw brass/olive-gold accent; complement 237 deg -> steel-blue neutrals |
| Only two doubled pairs (`99`, `GG`) | Doubling as structural law: the page is itself a diptych |
| Joint-most-frequent chars `x` and `W` (5x each) | Crossing/pairing motif -> the seam between panels |
| Digit positions cluster, gap of 21+19, re-cluster | Page rhythm: dense hero -> quiet middle -> re-densified key table |

Light theme is primary (zinc/concrete ground, brass accent, oxide red spent once
on the honest-limits section). Type is one family across both its axes: Archivo
at wdth 118 / wght 800 for signage headlines and wdth 100 / wght 400 for body,
with Martian Mono on keycaps and labels.

### What differs from the shipped page

- Structure is **material plates split by a seam**, not a hairline lattice.
- The hero is a **live, keyboard-operable dual-panel demo** (Tab switches panels,
  arrows select, left/right sends across, Cmd-Z undoes) instead of a static
  screenshot — the claim is demonstrated rather than asserted.
- No signup form. The single action is the beta download, per ADR 0008.

Open the file directly in a browser; it has no build step and no dependencies
beyond Google Fonts.
