# Diptychon is MIT-licensed

Decided 2026-09-26 by Till. Closes the open question left by ADR 0010
("Open source" under *What this does not decide*).

## The decision

Diptychon's own source is published under the MIT licence. A `LICENSE` file at
the repository root carries the text; the copyright holder is Till von Krueger.

Separately, the licences of bundled third-party code are reproduced in
`Resources/THIRD-PARTY-NOTICES.txt`, which ships inside the app bundle at
`Diptychon.app/Contents/Resources/`.

## Why

- The repository at `github.com/Tvk-sd/diptychon` has been public all along,
  with no `LICENSE` file. The effective state was "readable by everyone, usable
  by nobody" — publication without a permission grant, which was not intended.
- The PRD has promised "MIT license" since the start; nothing since has argued
  against it. ADR 0010 made the app free, which removes the commercial reason
  to withhold reuse rights.
- Copyleft was the alternative considered (recorded in issue 66). It protects
  against closed forks, but Diptychon competes on being small and native, not
  on owning the idea. MIT costs nothing here and keeps the project easy to
  cite, learn from and fork.

## The third-party obligation

The terminal panel uses SwiftTerm 1.11.2 (MIT). MIT requires the copyright and
permission notice to travel with every distributed copy. The shipped
`Diptychon.zip` carried no notice at all, and `scripts/release.sh` copied none
— the notices file is registered in `project.yml` so Xcode copies it into the
bundle on every build, with no release-script step to forget.

## Consequences

- Anyone may fork, modify and redistribute Diptychon, including commercially,
  as long as the copyright notice travels with it.
- Every new third-party dependency has to add its notice to
  `Resources/THIRD-PARTY-NOTICES.txt`. Adding a dependency without one now
  breaks the same rule SwiftTerm did.
- The website is unaffected: it says "free" and makes no claim about the
  licence. Saying "open source" there is now true but remains a separate
  decision about the page.
- "Free forever" stays unpromised. MIT makes existing copies irrevocable, not
  future releases.
