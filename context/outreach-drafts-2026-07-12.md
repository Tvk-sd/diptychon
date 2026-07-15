# Roundup-Outreach — personalisierte Drafts (2026-07-12)

> Ausführung von `roundup-outreach.md` (Soft-Pitch, pre-launch). Recherche-Stand
> 2026-07-12: alle 7 Ziel-Artikel gelesen, Autoren + Kontaktwege verifiziert.
> **Jede Behauptung unten ist produkt- oder vendor-verifiziert** (Return öffnet
> Ordner: `WorkspaceModel.openSelection`; ~1.4 MB, ForkLift ~16 MB, Subscription-
> Preise: `competitor-facts.md`).

## Re-Priorisierung nach der Recherche (wich vom Playbook ab)

Die SERP-Liste aus dem Playbook hielt der Prüfung nur teilweise stand:

| Prio | Ziel | Realität | Kontakt |
|---|---|---|---|
| **1** | XDA | echtes Editorial, Autor testete ~15 Apps selbst | Bluesky `@indospot.bsky.social` (João Carrasqueira; X ist er nicht mehr aktiv) |
| **1** | TheSweetBits | echtes Outlet, lädt explizit App-Stories ein | `contact@thesweetbits.com` |
| **2** | FileMinutes | Vendor-Blog (Sujeevan, baut FileMinutes), aber echte Fremd-Empfehlungen + one-time-Framing | `support@fileminutes.com` |
| **3** | Tokie | Vendor-Blog, anonym, SEO-Templates; Dev = Dabo Chen | GitHub `dabochen/tokieapp` (Issues) |
| **3** | mqdir | KONKURRENT (Vendor-Blog, rankt sich selbst #1) | X `@H5nam` |
| **3** | Empiric Apps | KONKURRENT (Vendor-SEO-Seite) | `contact@empiricapps.com` |
| **skip** | SimplyMac | Content-Farm, Artikel von 2024, KEIN E-Mail-Kontakt auffindbar | – |

**Empfehlung:** Welle 1 = XDA + TheSweetBits + FileMinutes (beste Odds).
Welle 2 (optional, niedrige Odds, ehrlich als Konkurrenz-Anfrage gerahmt) =
Tokie, mqdir, Empiric. SimplyMac streichen.

## Tracking

| Outlet | Kontakt | Gesendet | Reply | Gelistet? | Link |
|---|---|---|---|---|---|
| XDA | Bluesky @indospot.bsky.social | | | | `?src=xda` |
| TheSweetBits | contact@thesweetbits.com | | | | `?src=sweetbits` |
| FileMinutes | support@fileminutes.com | | | | `?src=fileminutes` |
| Tokie | GitHub issue | | | | `?src=tokie` |
| mqdir | X @H5nam | | | | `?src=mqdir` |
| Empiric | contact@empiricapps.com | | | | `?src=empiric` |

---

## 1 · XDA — João Carrasqueira (Bluesky-DM, kurz)

**Hook:** Sein Artikel-Aufhänger ist, dass Enter in Finder umbenennt statt zu
öffnen; er lobt Commander One genau dafür. Und er zögert, bezahlte Apps zu
empfehlen. Beides adressieren.

**Bluesky-DM (kurzform):**

> Hi João, read your Finder-alternatives piece on XDA. Your Enter-key peeve is
> the exact class of friction I am building against: in Diptychon, Return opens
> the folder. It is a keyboard-first dual-pane manager, native Swift, ~1.4 MB
> (ForkLift's build is ~16 MB), one-time purchase, no telemetry. I know you are
> wary of recommending paid apps, so no pitch to rank it. It launches soon and
> I would love to send you an early build to judge first-hand. Comparison table:
> diptychon.com/vs?src=xda

**Fallback (falls DM nicht geht): öffentlicher Reply/Post mit derselben ersten
Hälfte + Link.**

## 2 · TheSweetBits — Redaktion (E-Mail)

**Hook:** Ihre Contact-Seite lädt explizit "a story about your app" ein. Ihre
Haupt-Kritik an ForkLift/Path Finder: brauchen viel Bildschirmplatz, komplexe UI.

**Subject:** `A native ~1.4 MB dual-pane file manager for your Finder-alternatives guide`

> Hi TheSweetBits team,
>
> I read your Finder-replacement guide. The point that stuck with me: ForkLift
> practically needs full-screen before dual-pane plus preview becomes usable,
> and Path Finder buries everyday users in features. That gap is exactly where
> I am building.
>
> Diptychon is a keyboard-first dual-panel file manager for macOS:
>
> - Native Swift, ~1.4 MB. For context, ForkLift's build is ~16 MB. No Electron.
> - One-time purchase, no telemetry, while the category drifts to subscriptions.
> - Move files between panels with one keystroke, undo anything, real Finder tags.
>
> It launches soon. Happy to send an early build to try, or specs and
> screenshots, so you can judge it first-hand. A plain comparison is here:
> diptychon.com/vs?src=sweetbits
>
> Either way, thanks for keeping these guides honest.
>
> Till
> diptychon.com

## 3 · FileMinutes — Sujeevan (E-Mail)

**Hook:** Er führt "one-time purchases with no subscriptions" explizit als
Kaufargument und kürt Marta zum besten Keyboard-Manager. Ehrlich erwähnen,
dass er selbst Indie-Dev ist (Peer-Ansprache).

**Subject:** `One for your Finder-alternatives list: keyboard-first, one-time, ~1.4 MB`

> Hi Sujeevan,
>
> I read your 2026 Finder-alternatives roundup. Two things stood out: you are
> one of the few who calls out one-time pricing as a real criterion, and you
> gave Marta the keyboard crown. Fellow indie Mac dev here, so I know what
> that list costs to maintain.
>
> I am building Diptychon, a keyboard-first dual-panel file manager, and I
> think it can compete for that keyboard crown:
>
> - Return opens the folder, one keystroke moves files between panels, undo anything.
> - Native Swift, ~1.4 MB. One-time purchase, no telemetry.
> - Real Finder tags, not a parallel tagging system.
>
> It launches soon. Happy to send an early build so you can judge it against
> Marta first-hand. Comparison: diptychon.com/vs?src=fileminutes
>
> Thanks for the honest criteria in that piece.
>
> Till
> diptychon.com

## 4 · Tokie — Dabo Chen (GitHub, kurz + Peer-Ton) — Welle 2

> Hi Dabo, saw your Finder-alternatives comparison on tokie.is. Different
> angle than yours (you go folder-as-database, I go keyboard-first dual-pane),
> but your table values completeness: Diptychon is native Swift, ~1.4 MB,
> one-time purchase, no telemetry, launching soon. If you update the list and
> want verified specs: diptychon.com/vs?src=tokie. Happy to reciprocate with
> a fair look at Tokie.

## 5 · mqdir — @H5nam (X-DM, kurz) — Welle 2, niedrige Odds

**Achtung:** Direkter Konkurrent mit überlappendem Persistence-Angle. Kein
Feature-Battle im Pitch; nur Fakten + Completeness-Ask.

> Hi, read your 2026 Finder-alternatives post on mqdir.com. Fair point about
> shallow state persistence in the incumbents. I build Diptychon, a native
> keyboard-first dual-pane manager (~1.4 MB, one-time, no telemetry), launching
> soon. If your comparison aims for completeness, verified specs are at
> diptychon.com/vs?src=mqdir.

## 6 · Empiric Apps — contact@ (E-Mail, kurz) — Welle 2, niedrige Odds

**Subject:** `Verified specs for your dual-pane comparison page`

> Hi Empiric team,
>
> Your dual-pane comparison page lists the major managers side by side, and
> you clearly value one-time pricing, so a data point for your next update:
> Diptychon, a native Swift keyboard-first dual-pane manager, ~1.4 MB,
> one-time purchase, no telemetry. Launching soon. Verified specs:
> diptychon.com/vs?src=empiric
>
> Till, diptychon.com

---

## Nächste Schritte

- [ ] Till: Welle-1-Drafts reviewen (XDA, TheSweetBits, FileMinutes)
- [ ] Entscheiden: Welle 2 (Konkurrenten) mitsenden oder weglassen
- [ ] Versand: E-Mails von Tills Adresse; Bluesky/X-DMs von Tills Accounts
- [ ] Nach Versand: Tracking-Tabelle oben pflegen; 1 Follow-up nach ~7 Tagen
      (Vorlage: `roundup-outreach.md` Email 2)
