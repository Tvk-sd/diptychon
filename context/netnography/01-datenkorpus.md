# 01 — Datenkorpus (Evidenz-Log)

Anonymisierter Archival-Data-Korpus + Feldnotizen. Verbatim-Zitate im **englischen
Original** (Authentizität); Teilnehmende pseudonymisiert (`P#`); Verlinkung auf
Thread-/Artikelebene (siehe Ethik in `00-methodik-und-ethik.md` §5). Erhoben 2026-07-02.

---

## Quellenverzeichnis

| ID | Quelle | Typ | Jahr | Link |
|---|---|---|---|---|
| S1 | Hacker News — „What to use on macOS instead of Finder?" | Forum-Thread | 2022 | https://news.ycombinator.com/item?id=32334373 |
| S2 | Hacker News — „Show HN: Marta – A fast and minimalistic file manager for macOS" | Show-HN-Thread | 2017 | https://news.ycombinator.com/item?id=13921364 |
| S3 | Applefritter — „Comparing macOS file managers for remote server access (QSpace, Nimble Commander, Forklift)" | Fachartikel + Kommentare | 2023 | https://www.applefritter.com/content/comparing-macos-file-managers-remote-server-access |
| S4 | r/macapps — „Mac App Comparisons – 2025 Update" | Reddit-Thread | 2025 | https://old.reddit.com/r/macapps/comments/1j56vvb/mac_app_comparisons_2025_update/ |
| S5 | r/macapps — „Forklift vs QSpace (long)" | Reddit-Thread | 2023 | https://old.reddit.com/r/macapps/comments/15wqdhx/forklift_vs_qspace_long/ |
| S6 | r/macapps — „Looking for proper Total Commander alternative" | Reddit-Thread | 2021 | https://old.reddit.com/r/macapps/comments/vl2k7k/looking_for_proper_total_commander_alternative/ |
| S7 | r/macapps — Suchergebnisse „file manager" (u. a. „Bloom"-Wunschliste, PCP-Posts) | Reddit-Suche/Posts | 2024–2026 | https://old.reddit.com/r/macapps/search/?q=file+manager&restrict_sr=1 |
| S8 | Marta — offizielle Dokumentation | Herstellerdoku (Referenz) | laufend | https://marta.sh/docs/ |

---

## A. Finder als Auslöser — warum Nutzer:innen wechseln

> **[S3 · P (Autor:in)]** „I've been using Dolphin on KDE Plasma a lot and it's made
> me realize just how much the shortcomings in Finder limit how I work. Finder
> doesn't have good support for remote volumes …"

> **[S3 · P]** „What I want is to be able to connect to my Nextcloud server via WebDAV
> and access those files with the speed and convenience of a local file system. I also
> want to be able to access my Debian servers via SFTP."

> **[S7]** Kontext: Ein Konkurrenz-Tool bewirbt sich explizit über Finder-Defizite und
> ergänzt Finder um: *„Cut & Paste, Copy Path, Copy To…, Move To…, Toggle Hidden
> Files, Show File Size, Show Image Dimensions, Invert Finder selection"* — d. h. genau
> diese fehlen vielen an Finder.

**Feldnotiz:** Finder-Schmerz ist selten „Finder ist langsam", sondern konkret:
Remote-Volumes, echtes Cut&Paste-Move, Pfad-Eingabe, Ordnergrößen, Hidden-Files-
Toggle, Batch-Rename. Diese sind die „Einstiegsdrogen" in Commander-Tools.

---

## B. Total Commander / Norton / Far — Nostalgie & Muscle Memory

> **[S1 · P1]** „By far the best file manager for MacOS is Marta. It is the only app
> that is close to great old **Far Manager**, which sadly only works properly on
> Windows …"

> **[S5 · P (Kommentar)]** „I have been searching **Total Commander replacement** in
> MacOS for a long time and IMO **Nimble Commander is only app that comes close**."

> **[S6 · P]** Nutzer installieren teils **Total Commander via Wine/VM** auf dem Mac:
> „Fully working TC on MacOS. Local file system is available thru Z: drive." — bzw.
> weichen auf `brew install midnight-commander` / `far2l` aus.

**Feldnotiz:** Starke Tribal-Identität rund um die Commander-Linie. „Close to Total
Commander / Far" ist das höchste Lob; der Referenzrahmen ist Windows/DOS-Erbe. Die
Bereitschaft, TC in einer VM zu betreiben, zeigt die Wechselkosten der Muscle Memory.

---

## C. Marta — Lob & Schmerz

> **[S1 · P]** „Marta's **config DSL syntax is the closest to The Correct Answer™**
> I've seen so far." · „Seamless **archive support** FTW."

> **[S5 · P (OP)]** „Marta — Their **documentation is severely broken**. Just browsing
> on their web site, you can click and get … [broken]. … such **pathetic docs binned
> it**." *(→ Tool wegen schlechter Doku aussortiert, trotz Interesse.)*

**Feldnotiz:** Marta polarisiert. Die Config-DSL und der Archiv-Support begeistern
Hardcore-Power-User; gleichzeitig ist die **Doku/Onboarding-Hürde** ein realer
Ausschlussgrund. Beta-Status & unstete Entwicklungskadenz schwingen mit.

---

## D. Nimble Commander — UI-Latenz, Transfer-Feedback, Lernkurve

> **[S3 · P]** „My biggest complaint about Nimble Commander is that it seems to **load
> content from remote volumes before making any update to the view**. … the way it
> pauses for just a moment before opening a folder makes you **question whether your
> key press was recognized** … it throws me off focus every time."

> **[S3 · P]** „Nimble Commander's other big shortcoming is that it **doesn't show
> file transfers clearly**. There's no file transfer pane showing number of files or
> time remaining, just a progress bar in the app icon. It also **doesn't offer
> merge**."

> **[S3 · P]** „The **learning curve is steep** compared to QSpace and Forklift, and
> **not intuitive** (unless you used Norton Commander …), but fantastic once you've
> learned it."

**Feldnotiz:** Wahrgenommene Latenz ≠ echte Latenz — die *Reihenfolge* (erst laden,
dann Ansicht wechseln) zerstört das Vertrauen in die Eingabe. Klares, sichtbares
Transfer-Feedback und „Merge" sind Erwartung, kein Luxus.

---

## E. ForkLift — der „nächste an zufrieden"

> **[S3 · P]** „I have **no real complaints about Forklift 4**. The interface is
> intuitive, but still **highly customizable and can be keyboard driven**."

> **[S3 · P]** „Thanks to its FTP roots, Forklift has the **best management of file
> transfers**. It **organizes them in the sidebar and keeps a log**."

> **[S3 · P]** „when you start typing a file name to select it, **Forklift lets you
> type a space** as part of the name" *(Detail-Lob für Type-ahead-Qualität).*

> **[S5 · P]** „Apart from that, **Forklift wins every day**." *(im Vergleich zu QSpace,
> dem aber die 4-Pane-Workspaces besser gefielen).*

> **[S3 · P (OP, ältere Version)]** „I tried **Forklift 3** … but rejected it as being
> **too sluggish**." *(Versionsabhängig — F4 behob das.)*

**Feldnotiz:** ForkLift ist im Korpus der De-facto-Referenz-„Gewinner" — dank
Transfer-Log, Remote-Story, Anpassbarkeit + Keyboard. Sein Schwachpunkt in Diskussionen:
nur 2 Panes + Tabs (statt Quad), Preis/Update-Modell.

---

## F. Commander One — Persistenz & fehlende Basics

> **[S6 · P (OP)]** „Tried Commander One, but it doesn't even come close. Main
> annoyances: **Doesn't remember view settings**, changes the sorting and column
> widths to default after restarting mac. **No way to change column width** for simple
> list view. **Doesn't remember tabs**, go to default after restarting mac. **Inactive
> tabs change to mac HD after dismounting external drives.** Is there any TC
> alternative for mac that can **at least remember its UI settings?**"

> **[S5 · P (OP)]** „Commander One — the big dawg didn't hunt. **No view pane**, or I
> couldn't get it to work. **No multi-file rename**. And the **navigation to folders I
> know the name of annoyed me**."

> **[S7/S6 · P (Sammel-Review)]** „commander one (power user oriented while somehow
> **lacking basic functions like a sidebar**, also **difficult to navigate, and
> expensive**)".

**Feldnotiz:** Zustands-Persistenz (Sortierung, Spaltenbreite, Tabs, Mount-Status)
ist ein **eigenständiger, unterschätzter Schmerzpunkt**. „At least remember its UI
settings" ist ein Hilferuf, kein Feature-Wunsch der Extraklasse.

---

## G. Path Finder — Doku & Reife-/Abandonment-Zweifel

> **[S5 · P (OP)]** „Path Finder — **couldn't find any evidence of a Preview Pane** —
> but the **docs are almost entirely YouTube videos, which I despise. I read faster
> than you talk; give me text.**"

> **[S3 · P]** „Path Finder uses the Finder for mounting WebDAV volumes, which is
> **painfully slow**, and it **doesn't support SFTP at all**."

**Feldnotiz:** Video-only-Doku ist ein aktiver Frust-Trigger bei Power-Usern
(„give me text"). Path Finder gilt vielen als schwer, reif-bis-stagnierend, remote-schwach.

---

## H. QSpace — Privacy-Misstrauen vs. 4-Pane-Stärke

> **[S5 · P]** „**Qspace will collect your personal data.**" *(mit Screenshot des
> Datensammel-Dialogs als Beleg-Artefakt.)*

> **[S3 · P (Autor:in, Privacy-Audit)]** „QSpace's privacy policy states 'in a case of
> an error … I collect data … IP address, operating system version, identifier of
> device.' … By contrast, the Mac App Store version of QSpace says **no information is
> collected**." … „I emailed the developer … he responded that the Mac App Store
> privacy info was **incorrect** … He did not answer my request for clarification …"

> **[S5 · P]** „QSpace has **better workspace support**: can easily have **4 panes**
> and manage them as workspaces … while with Forklift you would have 2 panes with
> perhaps additional tabs. I personally prefer the 4 panes layout … instead of having
> to **fumble with tabs**."

> **[S5 · P]** „My big problem with QSPACE is the **file search**. I have folders with
> a huge number of files and they are networked. Pathfinder and Forklift **search
> locally** in the folder once loaded. Qspace (like Finder) **uses Spotlight and
> Spotlight doesn't find anything on the network**, which limits my productivity a lot."

**Feldnotiz:** Privacy ist bei diesem Segment ein **Deal-Breaker**, kein Nice-to-have
(Little-Snitch-Nutzung, Screenshots als „Beweise", Verweis auf MAS-Version zum
Sandboxing). Gleichzeitig zeigt QSpace echte Nachfrage nach >2 Panes / Workspaces.
Lokale (nicht Spotlight-abhängige) Suche über Netzwerk ist ein Produktivitäts-Muss.

---

## I. Explizite Wunschliste (Power-User, „Bloom"-Review)

> **[S7 · P]** wörtliche Wunschliste an ein Dual-Pane-Tool:
> - „My top wish is for a **configurable context menu** where I can add and remove
>   commands. Qspace and PathFinder both have this."
> - „**Auto-mounting of WebDAV and NFS shares** … improve support for self-hosted
>   services and European services like Koofr and kDrive."
> - „improving its **renaming capabilities (with regex and EXIF awareness)** would go
>   a long way."
> - „Improvements in **dual-pane persistence** and the ability to **save named
>   workspaces**."
> - „**More powerful tab management** — pinned tabs, color-coded tabs, tab groups,
>   keyboard shortcuts for more tab operations."
> - „Integration with **Shortcuts, AppleScript, Service Menu**, and the addition of a
>   **plugin system** that other devs could hook into, like they do with Finder."
> - „a **Finder compatibility mode** that mimics Finder's keyboard shortcuts, viewing
>   modality, and folder opening behavior."
> - Preislob: „all future updates will be available to anyone who purchases the app —
>   **no subscriptions**, no paid updates after a year …"

**Feldnotiz:** Dies ist die dichteste Einzelquelle für Wünsche — deckt sich fast
1:1 mit den aus anderen Quellen induzierten Codes → hohe Konvergenz/Validität.

---

## J. Werte & Kultur (Querschnitt)

> **[S7 · P]** „Built with native Swift/SwiftUI/AppKit. **No Electron bloat here** 😄"

> **[S4/S7]** Konkurrenz-Verkaufsargument: „**Privacy: 100% Local. No telemetry. No
> data collection.**" — genutzt als Differenzierung → signalisiert Nachfrage.

> **[S6 · P (Notiz-Tools-Exkurs, gleiche Person, gleiche Werthaltung)]** „I don't like
> Electron Apps, so I don't use this …" · „all other apps are **electron trash** that
> is basically just the homepage. The **quick search is essential** for me, I don't
> know how people live without it."

> **[S6/S7 · P (Sammel-Review)]** „QSpace (security and privacy concerns) · commander
> one (… lacking basic functions … and expensive) · cosmil (**insufferable ui** …
> microscopic with no option to change any of it …). **The hunt for a finder
> alternative continues …**"

**Feldnotiz — kulturelle Marker:**
- **„nativ statt Electron"** ist Status-/Identitätssignal, nicht nur Technik.
- **Anti-Subscription** ist moralisch aufgeladen („renting software", „monetization
  optimization stuff").
- **Privacy** als Vertrauensgrundlage.
- **„The hunt continues"** ist ein wiederkehrendes Genre: chronische Unzufriedenheit,
  kein klarer Kategoriesieger → Marktlücke.

---

## K. Feature-Ist-Stand Marta (Referenz, kein Sentiment)

> **[S8]** Marta bietet u. a.: Operation Queue (pause/cancel), Analyze Disk Usage,
> Flatten, Multi-Column-View (1/2/3), Embedded Terminal, Gadgets, Lua-Plugin-API,
> Config-DSL, Themes, konfigurierbare Keybindings, Archive-Support. *(Details:
> `../competitor-benchmark.md` §5.)*
