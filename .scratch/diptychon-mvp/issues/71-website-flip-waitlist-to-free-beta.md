# 71 — Website-Flip: Waitlist → „free while in beta"-Download

Status: **CLOSED** (2026-08-11) — Flip live, Stichprobe über alle 13 URLs grün
Category: gtm / landing-page

## Parent

Strategiewechsel 2026-08-03 (#66). **Hart blockiert von #68 und #69** — erst
darf der Download echt und der Erstkontakt tragfähig sein, dann darf die Seite
ihn versprechen. Nie umgekehrt.

Beim Umbau mit erledigen: **#78** — die Copy widerspricht sich heute selbst
(1,4 gegen 1,5 MB, 5 gegen 6 MB installiert) und behauptet an zwei Stellen
einen Einmalkauf, obwohl der Preis in #66 offen ist. Dieselben Dateien, gleiche
Durchsicht.

## Was sich ändert — und warum es größer ist als zwei Zeilen

Die Seite hat heute den Job „überzeuge einen Fremden, dass Warten sich lohnt".
Output ist eine Zahl (Signups), die als Validierungs-Proxy gedacht war. Weil
Till ohnehin baut und ausliefert, misst diese Zahl nichts, worüber noch
entschieden wird. Neuer Job: **„gib es Leuten in die Hand und lerne, was als
nächstes gebaut werden soll."** Output ist Text und Downloads, nicht Zahlen.

„pre-launch" steckt an mehr Stellen als der sichtbaren Zeile:

- die Tabellenzeile `Available today: Diptychon: No — pre-launch` auf allen
  vier A2-Seiten
- die Preiszelle `one-time (price not set)` — die wird beim Flip zu einer
  **Preisaussage** und berührt damit #66
- JSON-LD `offers` steht auf `PreOrder`
- `llms.txt` / `llms-full.txt` werden **aus den gerenderten Seiten generiert**,
  tragen also alles mit

Wenn die sichtbare Seite „free download" sagt und das Markup weiter `PreOrder`,
ist das eine Seite, die sich selbst widerspricht — genau das Spam-Signal, vor
dem #67 warnt. **Copy-Flip und Maschinen-Layer sind ein Ticket und ein Deploy.**

## Copy-Entscheidungen (Till)

- **Label ist Pflicht: „Free while in beta", nicht „Free."** Ohne Label ist
  Gratis-Ausliefern die schwerste Preisänderung, die es gibt — später Geld
  verlangen liest sich für frühe Nutzer als Wortbruch. Mit Label ist es normal.
  Kostet einen halben Satz und hält #66 offen
- Hero-CTA von „Email me at launch" auf Download umstellen. Die E-Mail bleibt
  als zweite Option, aber ihr Job ändert sich: vom Zähler zur Rückrufnummer
- Wedge-Zeile („Update-Fenster" / „Buy once, updates included. No expiry date.")
  hängt weiter am ForkLift-Recheck aus #67 — nicht mit rausschieben

## Entscheidungsgrundlage

**`docs/adr/0008-landing-page-is-distribution-not-fake-door.md`** — dort steht
die Begründung, die Alternativen und was ausdrücklich *nicht* entschieden wurde.
Dieses Ticket führt nur aus.

Wichtig daraus: die gewählte Option ist **nicht** „Copy tauschen". Ein
Job-Wechsel ist ein Struktur-Wechsel. Die Startseite wird um Download und
Feedback herum neu geordnet; `/vs` und die vier Vergleichsseiten behalten ihre
Struktur und brauchen nur Textkorrekturen — sie sind bereits answer-first
gebaut und funktionieren unverändert als Einstiege.

## Aus #42 hierher gebündelt (Platzierungsentscheid 2026-08-07)

Die Doku geht mit dem Flip live, nicht vorher — eine Doku-Seite zu einer App,
die man nicht laden kann, wäre dieselbe Halbheit, die dieses Ticket beseitigt.
Vier Punkte, die vier Augen sonst verlieren:

1. `docs/user-guide.md`, `docs/keyboard-reference.md`, `docs/gadgets.md` als
   HTML unter **`/docs`** im Stil von `/vs` (gleiches `page.css`)
2. Die Web-Referenz wird **aus der Markdown-Quelle generiert**, nie daneben
   gepflegt — `DocsKeyboardReferenceTests` bewacht nur die Repo-Fassung, eine
   Hand-Kopie driftet unbewacht
3. Menüeintrag **„User Guide"** in der App neben „Keyboard Shortcuts…" — #74
   hat ihn bewusst weggelassen, solange die Seite fehlt (kein Menüeintrag, der
   ins Leere führt). Kommt also erst mit diesem Deploy
4. `sitemap.xml` und `llms-full.txt` nehmen die `/docs`-Seiten mit auf — ein
   User Guide ist die zitierfähige Primärquelle, auf die der #67-Befund zeigt

## Umfang

1. `index.html` — **Neuordnung, nicht nur Textersatz.** Der Artefakt nach oben,
   der Überzeugungs-Mittelteil schrumpft (er rechtfertigte ein Warten, das es
   nicht mehr gibt), `#notify` hört auf, ein Capture-Formular zu sein, und wird
   zum Feedback-Weg (#72). Hero, CTA, `#notify`-Block
2. Die vier A2-Seiten: `Available today`-Zeile, Preiszelle, sichtbare
   „no download"-Sätze
3. Maschinen-Layer neu generieren: JSON-LD `offers` von `PreOrder` auf
   `https://schema.org/InStock` + `price: "0"`, `llms.txt` / `llms-full.txt`
   neu ziehen
4. **Download-CTAs mit `?src=` anlegen.** Heute hat *keine* Seite einen
   `/download`-Link (`grep 'href="/download'` findet nichts). Der Worker zählt
   seit #70 pro Kanal (`downloads:src:<x>`), bekommt aber nichts zu zählen,
   solange die Links fehlen. Werte wie bei den Signup-Links: `tcmac`, `marta`,
   `forklift`, `pathfinder`
5. `dist/` spiegeln, Parität prüfen
6. Ein `wrangler deploy` für alles

## Done heißt

Keine Seite und kein Markup behauptet mehr „pre-launch". Sichtbare Aussage und
JSON-LD stimmen überein. Stichprobe: `curl` auf alle sechs Seiten plus
`llms-full.txt`, kein Treffer für `pre-launch` oder `PreOrder`.

## Outcome (2026-08-11)

Live als Worker-Version `324c32a1`, ein Deploy für alles. Vorher
`a2-seo-pages` nach `main` gemerged (`4a1eeec`) — damit gingen die vier
A2-Seiten und der Maschinen-Layer erstmals überhaupt live.

- **index**: Hero-CTA „Download for macOS" + Label „Free while in beta ·
  notarized by Apple", Nav/Final-CTA auf `/download` mit src-Kanälen,
  Notify-Block vom Zähler zur Rückrufnummer + Feedback-Weg (#72)
  umgeschrieben und aus dem Hero in eine eigene Sektion verschoben
- **vs + 4 A2-Seiten**: Available-today „Yes — free beta", Preiszellen
  „free while in beta (pricing not set)" — kein Preis-Claim, #66 bleibt
  offen; alle CTAs auf `/download?src=vs/marta/forklift/pathfinder/tcmac`,
  der #70-Zähler bekommt erstmals Futter
- **`/docs` neu**: user-guide, keyboard-reference, gadgets — generiert via
  `scripts/generate-docs.mjs` aus den test-bewachten Markdown-Quellen
  (#42-Punkte 1+2); Hilfe ▸ **User Guide** in der App zeigt darauf
  (#42-Punkt 3, Suite grün `e15f903`); sitemap + llms nehmen die Seiten
  auf (#42-Punkt 4)
- **Maschinen-Layer**: JSON-LD `offers` `InStock`/`price 0` (PreOrder
  existierte entgegen Ticket-Annahme nirgends), llms.txt/llms-full.txt
  ohne pre-launch, mit Docs-Volltext

Verifikation nach Deploy (Cache-Propagation ~2 min abgewartet): alle 13
URLs 200, **null Treffer** für pre-launch/PreOrder/launch day/1.4/1.5 MB,
Beta-Label überall vorhanden.

Damit ist die Folge #68→#69→#71 komplett. Nächster Hebel: Downloads und
Freitext lesen (#70/#72/#73).
