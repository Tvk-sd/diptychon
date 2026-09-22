# 98 — Homepage: Zustandswechsel in den Kapiteln (Paseo-Muster, Screenshots bleiben echt)

Status: **ready-for-agent** — Schritt 1 abgenommen („looks very good“, 2026-09-22) und deployt; Schritt 2 (Move) ist dran
Category: gtm / landing-page

## Herkunft

Till hat am 2026-09-21 paseo.sh analysieren lassen. Kern des Paseo-Heros: ein
App-Rahmen, vier Tabs (Build / Review / Ship / Extend), pro Klick wechselt nur
die Fläche, die sich im Produkt wirklich ändert. Sidebar und Titelleiste bleiben
stehen, das Auge landet auf dem Unterschied. Paseo baut die Screens als HTML;
Diptychon bleibt bei echten Screenshots (Tills Entscheidung, Option A).

Zweite Entscheidung (Option 1, 2026-09-21): **kein Tab-Hero.** Der Hero wäre
mit Move / Stage / View eine Kopie der Kapitel 1–3 darunter. Paseo kann Hero-Tabs,
weil seine unteren Sektionen keine Screenshots haben; Diptychon hat in jedem
Kapitel einen. Die Interaktion wandert deshalb in die Kapitel.

## Was gebaut wird

Ein wiederverwendbarer Block „Zustandswechsel": Knopfleiste + ein Bildrahmen,
pro Zustand ein Light- und ein Dark-Screenshot wie heute. Vier Einsatzorte,
in dieser Reihenfolge:

| Schritt | Sektion | Zustände (= Knöpfe) | Neue Shots |
|---|---|---|---|
| 1 | 3.0 View | Table `default` · Brief `⌘1` · Columns `⌘2` · Terminal `⌘J` | Terminal neu (heute 640×200-Crop, braucht das volle Fenster) |
| 2 | 1.0 Move | Vorher · `⌥⌘→` (Kopie liegt rechts) · `⌥⇧⌘→` (Datei ist links weg) | 2 |
| 3 | 2.0 Stage | `⌘⇧S` in Shoots · `⌘⇧S` in Clients · `⌘⇧B` zeigt das Set | 3 |
| 4 | „Why", Kachel 3 | Diptychon · Finder — gleiche Dateien, gleiche Tag-Punkte | 1 (Finder) |

Nicht gebaut, bewusst: Hero-Tabs (siehe oben), Statement-Band (nur Text),
Kachel 2 (hat noch kein Bild, offen bei Till in PLAN.md), 4.0 Extend
(Palette/Gadgets-Wechsel wäre denkbar, braucht erst einen Gadget-Shot — eigenes
Ticket, falls gewollt), Filterfeld über der Shortcut-Liste (Idee notiert, nicht
Teil dieses Tickets).

## Annahmen

- Harter Schnitt, keine Überblendung. Die Seite hat die Regel „no entrance
  animation" (Kommentar im `<style>` von `index.html`), `prefers-reduced-motion`
  ist schon abgedeckt.
- Knöpfe rechteckig im Stil der `.key`-Chips, keine Pillen (Diptychon-Formsprache).
- Das Skript ist dasselbe Muster wie der Theme-Switch im Footer: Buttons mit
  `aria-pressed`, eine Handvoll Zeilen, per `data-`-Attribut auf jeden Block
  anwendbar. Kein Framework, kein Build.
- Versteckte Zustände laden `loading="lazy"`; der erste Zustand ist der heutige
  Screenshot, damit ohne Klick nichts schlechter wird.
- In Schritt 1 fällt das 2×2-Raster weg: ein Bild in voller Spaltenbreite statt
  vier halbbreiter. Verlust: der Vergleich aller vier Ansichten auf einen Blick.
  Gewinn: Brief und Columns werden lesbar. Falls Till den Blick-Vergleich
  vermisst, bleibt das Raster mobil (unter 760 px) ohnehin gestapelt — dort
  ändert sich nichts.
- Bei Schritt 2 wird der heutige Chord-Badge (`.chord`, dekorativ) selbst zum
  Knopf. Das ist der eigentliche Gewinn: die Taste des Produkts schaltet das Bild.
- Shots kommen aus `.scratch/demo-video/harness/shoot_landing.sh` (gestagter
  Klon, eigene Bundle-ID, geseedeter `workspaceState`). Fenstergröße stellt Till
  von Hand ein — das ist sein Schritt, nicht meiner.

## Schritte

1. **View-Block bauen** (Shots liegen bis auf Terminal vor): Markup + CSS + Skript
   in `index.html`, Terminal-Reshoot, `dist/` neu, lokal zeigen (Main-Checkout,
   Port 8799). Till nimmt ab.
2. **Move-Block**: zwei Shots (nach `⌥⌘→`, nach `⌥⇧⌘→`), Chord-Badge wird Knopf.
3. **Stage-Block**: drei Shots der Sequenz.
4. **Tag-Kachel**: ein Finder-Shot derselben Dateien, Umschalter in der Kachel.
5. Nach jedem Schritt: zeigen, dann committen, dann `npx wrangler deploy` aus
   `.scratch/landing-page` (nackt, ohne CLI-Flags — sonst fällt die www-Domain).

Definition of done pro Block: Klick wechselt nur das Bild, Light/Dark stimmen
in beiden Zuständen, Tastaturbedienung über die Knöpfe geht (Tab + Enter),
Mobil unter 760 px bricht nichts, Lighthouse-LCP des Heros unverändert.

## Offene Fragen an Till

- Schritt 1: Raster-Vergleich gegen Vollbreite — Annahme oben ok?
- Schritt 4: erledigt sich — die Tags liegen schon auf der Platte (`~/Studio/Inbox`,
  die Punkte im Table-Shot sind echte Finder-Tags). Finder-Fenster auf den Ordner,
  Capture per Window-ID; kein Handgriff von Till nötig.

## Comments

**2026-09-21, Schritt 1 gebaut (nicht committet, Branch `feat/98-view-switch`):**
- `index.html`: `.views`-Raster raus, `[data-switch]`-Block rein (Knopfleiste
  `role=group` + vier `.sw-state`-Panes, `aria-pressed`, `hidden`); CSS-Block
  „chapter 3" ersetzt; ein zweites Skript neben dem Theme-Switch. Versteckte
  Panes werden nach `load` für die aktive Appearance vorgeladen, sonst wäre der
  erste Klick ein leerer Rahmen.
- Volle Fenster-Shots (1668×933) lagen noch in `/tmp/dipt-shots/out` vom
  2026-09-20 — kein Reshoot nötig. Als `shots/{table,brief,columns,terminal}-{light,dark}.png`
  übernommen; die alten `shots/view-*.png`-Crops (8 Dateien) sind jetzt unbenutzt,
  Löschen mit dem Commit, wenn Till einverstanden.
- **Terminal-Shots waren nicht shipbar:** in beiden Varianten war ein Tastendruck
  ins Suchfeld gerutscht („s"), die linke Pane zeigte 1.000 Treffer aus Tills
  echtem Home (Projektnamen, Diptychon-Quellen). Der alte 640×200-Crop hatte das
  verdeckt. Fix ohne Reshoot: `harness/patch.swift` (neu) kopiert die saubere
  Inbox-Pane aus dem Table-Shot in den Terminal-Shot (gleiche Fenstergröße,
  gleiche Zeilenhöhe). Beide Varianten per Sichtprüfung sauber.
- Geprüft: 1440 px light/dark, alle vier Zustände, 390 px (Chips ausgeblendet,
  Knöpfe passen ohne Overflow), kein Layout-Sprung (alle Shots gleich groß).
- Port 8799 gehört dem Wrangler-Dev-Server der anderen Session
  (Worktree `scrawny-blowfish`, Branch `finalize/landing-legal-docs`), nicht dem
  Main-Checkout. Eigener Server: `python3 -m http.server 8798` in
  `.scratch/landing-page`.
- Columns-Shot: zweite Spalte leer, Till wollte den Reshoot (siehe unten).

**2026-09-22, Columns-Reshoot + Abnahme:**
- Ursache der leeren zweiten Spalte: der gestagte Klon `Shots.app` war 17 Minuten
  vor dem #94-Merge gebaut (13:30 vs. 13:47). Klon neu aus `/Applications/Diptychon.app`
  (Build 2026-09-20 16:10, enthält #94), Bundle-ID umgesetzt, ad-hoc signiert.
- Der Arrow-Walk im Harness war nicht reproduzierbar: welche Pane beim Start den
  Fokus hat, ist nicht persistiert — im Light-Lauf gingen die Tasten in die rechte
  Pane oder ins Leere, im Dark-Lauf in die linke. Den Kind-Ordner direkt als
  `directory` zu seeden zeichnet die Elternkette nicht. Lösung: **ein Klick auf
  die erste Ordnerzeile** (`poke click`), seit #94 öffnet das die nächste Spalte
  sofort. Harness entsprechend umgebaut, dazu `ONLY=<szene>` zum Einzelschuss.
- `/Applications`-Build kennt `DIPTYCHON_NO_DEVICES` nicht (String nicht im
  Binary; der Build stammt nicht von main nach `512ae55`), also standen Tills
  echte Volumes („Paseo 0.7.2-arm64“, „TILL 2024“) im Sidebar. Per `patch.swift`
  mit dem leeren Sidebar-Bereich der alten Shots überdeckt (`0 300 199 90`).
- Kleiner Rest: die Demo-Daten sind gealtert, Columns zeigt „Sep 19/20“, die
  anderen Shots „Today/Yesterday“. Fällt nur im direkten Vergleich auf; ein
  Komplett-Reshoot nach `make_demo_data.py` würde es glätten.
- Alte `shots/view-*.png` + `dist/shots/view-*.png` (16 Dateien) gelöscht,
  nichts referenziert sie mehr.
