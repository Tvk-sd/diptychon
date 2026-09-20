# 93 — Icon: eigene Kleinstgrößen-Zeichnung und Wortmarke

Status: **OPEN** — `ready-for-agent`. Entstanden am 2026-09-20 beim Abnehmen des
neuen Icons (Konzept 02, „frosted transfer"), siehe `docs/adr/0009-icon-brief-retired-icon-decided-in-the-dock.md`.

## Parent

`docs/adr/0009-icon-brief-retired-icon-decided-in-the-dock.md` — die Entscheidung
selbst ist dort festgehalten. Dieses Ticket trägt nur, was danach offen blieb.

## Problem Statement

Das gewählte Zeichen lebt von Transluzenz: eine Milchglas-Fläche, durch die die
zweite Fläche durchscheint, plus ein solider Block, der halb über die Kante
hinausragt. Das trägt groß und in der Dock-Größe — geprüft neben Finder, Safari,
Zed und Terminal, nachdem die erste Fassung bei 92 px zu einem grauen Klumpen
zusammenfiel und Frost und Kante nachgezogen werden mussten.

Bei 16 und 32 px trägt es **nicht**. Der Weichzeichner ist dort breiter als die
Formen, die er trennen soll; übrig bleibt ein dunkles Kästchen mit einem hellen
Fleck. Genau diese Größen sind die Finder-Liste und die Seitenleiste, also der
Ort, an dem Till das Icon am häufigsten sieht.

Heute liegen in `Resources/Assets.xcassets/AppIcon.appiconset/` für alle sieben
Slots Verkleinerungen derselben 1024er Zeichnung. Für 16/32 ist das der falsche
Weg: Kleinstgrößen brauchen eine eigene, vereinfachte Zeichnung, kein
heruntergerechnetes Bild.

## Umfang

1. **Kleinstgrößen-Zeichnung (der eigentliche Auftrag).** Eine flache Fassung
   ohne Weichzeichner für die Slots 16 und 32 px: zwei Flächen, eine Fuge, ein
   Block auf der Kante — in genau zwei Tonwerten. `alt-02-frosted-bw.svg` ist
   die Vorlage, die flache Reduktion aus `design/icon/concepts/index.html`
   (Konzept C) zeigt die Richtung. Prüfen heißt: in einer echten Finder-Liste
   ansehen, nicht in der Galerie.
2. **Wortmarke.** Steht seit dem gelöschten Juli-Briefing ohne Zuhause: „diptychon"
   in einer echten Mono-Schrift gesetzt, gesperrt, kleingeschrieben, höchstens
   ein gebautes Detail (etwa eine Lücke, die die Fuge aufnimmt). Den Namen nicht
   illustrieren, keine Pixel-Buchstaben. Das ist eine eigene Runde mit Till, kein
   Nebenprodukt dieses Tickets — hier steht es, damit es nicht wieder verloren geht.

## Nicht in diesem Ticket

- Die Wahl des Zeichens. Die ist gefallen: Konzept 02.
- `design/icon/AppIcon-master.png` — ist am 2026-09-20 auf das neue Zeichen
  gezogen worden.
- Die Landingpage — `icon.png` (Quelle und `dist/`) ist auf dem Branch
  `feat/diptychon-homepage` als `4439950` bereits nachgezogen.

## Hinweise für die Umsetzung

- Bauen braucht XcodeGen: `xcodegen generate`, dann
  `xcodebuild build -scheme Diptychon`. Die `.xcodeproj` ist generiert und
  gitignored, nie von Hand anfassen.
- Rendern der SVGs: headless Chrome mit
  `--headless=new --default-background-color=00000000`, Kunstwerk auf 824 px
  innerhalb einer 1024er Fläche für das App-Icon, randabfallend fürs Web.
- Das Asset-Set lässt sich ohne vollen Build prüfen:
  `xcrun actool Resources/Assets.xcassets --compile <out> --platform macosx --app-icon AppIcon`.
