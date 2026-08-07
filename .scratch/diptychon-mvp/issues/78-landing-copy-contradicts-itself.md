# 78 — Die Landing-Copy widerspricht sich selbst (Größe und Preis)

Status: **needs-triage**
Category: gtm / landing-page

## Parent

Nebenbefund aus **#69** (Notarisierung). Beim Zusammenstellen der Checkliste
„Größenangabe nachziehen" kam heraus: es gibt nicht eine Zahl zum Nachziehen,
sondern mehrere, die sich schon heute widersprechen. Hängt zusammen mit
**#71** (Website-Flip), **#67** (Long-tail-Vergleichsseiten) und **#66**
(Preisfrage).

## Problem

Die Seiten nennen drei Fakten über das Produkt, die sich gegenseitig
widersprechen. Ein Besucher, der zwei Seiten liest, sieht zwei Antworten.

### Downloadgröße: 1,4 MB gegen 1,5 MB

| Datei | Zeile | Behauptung |
|---|---|---|
| `index.html` | 7 (meta description) | 1.4 MB |
| `index.html` | 627 | 1.5 MB download |
| `index.html` | 703 | 1.5 MB to download |
| `index.html` | 805 (footer) | ~1.4 MB |
| `vs.html` | 193, 207, 236, 278 | 1.5 MB |
| `dir-a.html` | 253 | 1.4 MB |
| `dir-b.html` | 412, 515, 528 | 1.4 MB |
| `dir-c.html` | 263 | 1.4 MB |
| `index-prev-dark.html` | 7, 164, 261 | 1.4 MB |
| `datenschutz.html` | 110 | 1.4 MB |
| `impressum.html` | 93 | 1.4 MB |

`index.html` widerspricht sich **innerhalb einer Datei**: Meta-Description und
Footer sagen 1,4 MB, der Hero-Block und der Werte-Absatz sagen 1,5 MB.

### Installierte Größe: 5 MB gegen 6 MB

- `index.html:627` — „6 MB installed"
- `dir-a.html:253`, `dir-b.html:412`, `dir-b.html:515` — „5 MB installed"

### Preismodell: „one-time purchase" gegen unentschieden

- `vs.html:193` — „one-time purchase"
- `index.html:703` — „the plan is a fair one-time…"

Das ist die schwerere Widersprüchlichkeit. Die Preisfrage ist in **#66**
ausdrücklich **offen**, und **#71** stellt die Seite auf „free while in beta"
um. Die Seite behauptet also heute ein Geschäftsmodell, das nicht beschlossen
ist, und wird es in #71 anders behaupten. `vs.html` nennt den Einmalkauf sogar
in der direkten Konkurrenzgegenüberstellung, wo er als Kaufargument gegen
Abo-Wettbewerber gelesen wird.

## Warum die Zahlen ohnehin fallen — gemessen, nicht geschätzt

Beide Größenangaben sind gegen alte Builds gemessen. Der aktuell
ausgelieferte Zip stammt vom 2026-07-17 (1.560.529 B = 1,56 MB — daher 1,5).
Woher die 1,4 MB stammen, ist nicht dokumentiert, vermutlich ein früherer
Build.

**Messung 2026-08-05** (Release-Lauf aus #69, signiert, vor dem Stapeln):

| | Bytes | gerundet |
|---|---|---|
| altes Zip (2026-07-17) | 1.560.529 | 1,56 MB |
| neues Zip, signiert (2026-08-05) | 2.655.945 | 2,66 MB |
| neues Zip, gestapelt (2026-08-07) | 2.657.584 | 2,66 MB |

Installiert (`du -sh` auf dem entpackten `.app`): **9,0 MB**. Die Seite sagt
5 beziehungsweise 6 MB — daneben um Faktor 1,5 bis 1,8, also derselbe
Größenordnungsfehler wie bei der Downloadzahl.

Faktor **1,7**. Der Sprung kommt vom eingebetteten Terminal (#65, SwiftTerm)
plus Signatur; das Notarisierungs-Ticket kommt beim Stapeln noch dazu, ist
aber klein. Die endgültige Zahl steht erst nach dem Stapeln fest und muss
gegen `build/release/Diptychon.zip` nachgemessen werden, nicht gegen die
Einreichungsdatei oben.

Damit ist keine der Zahlen auf der Seite knapp daneben, sondern grob falsch.
Besonders relevant in `vs.html:207`: dort steht die 1,5 MB in der
Vergleichstabelle gegen ForkLift (16,3), Path Finder (19,4), Marta (10,7) und
Nimble Commander (15,0). Mit 2,7 MB bleibt Diptychon dort deutlich vorne — das
Argument trägt weiter, die Zahl trägt nicht.

Vorbehalt: gemessen am verworfenen Branch-Build aus #69. Die Größenordnung
stimmt, die exakte Zahl muss aus dem sauberen main-Lauf kommen.

## Was zu tun ist

1. Nach dem #69-Release **einmal messen**, nicht schätzen: Zip-Bytes und
   `du -sh` des entpackten `.app`
2. Eine einzige Zahl je Fakt über alle Seiten ziehen (Download, installiert)
3. Entscheiden, wie die Zahl geschrieben wird — exakt („1,7 MB") oder gerundet
   mit Tilde („~2 MB"). Exakt altert schneller, jeder Build verschiebt sie
4. Preis-Claims aus der Copy nehmen, bis #66 entschieden ist. Bis dahin gilt
   die Formulierung aus #71, immer mit Label

## Offene Frage an Till

Sollen die Größen überhaupt so prominent bleiben? Sie sind ein echtes
Differenzierungsmerkmal (die Konkurrenz liegt bei 10 bis 19 MB), aber sie
erzeugen bei jedem Release Pflegeaufwand an zwölf Stellen. Alternative: die
Zahl lebt nur noch in der Vergleichstabelle in `vs.html`, überall sonst steht
eine qualitative Aussage.

## Achtung beim Umsetzen

`dir-a.html`, `dir-b.html`, `dir-c.html` gehören zu **#67** und werden im
Worktree `/Users/Till/Projects/diptychon-a2-seo` (Branch `a2-seo-pages`)
bearbeitet. Änderungen an diesen Dateien in `main` kollidieren. Entweder dort
mitziehen oder dieses Ticket auf `index.html` plus `vs.html` beschränken und
den Rest an #67 hängen.

## Done heißt

Kein Fakt über Diptychon steht auf zwei Seiten mit zwei verschiedenen Werten,
und kein Preis-Claim steht auf der Seite, der nicht in einem Ticket
entschieden ist.

## Outcome

_(offen)_
