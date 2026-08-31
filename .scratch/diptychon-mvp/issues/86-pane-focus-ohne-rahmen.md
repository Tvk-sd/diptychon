# 86 — Aktives Panel ohne blauen Rahmen erkennbar machen

Status: **CLOSED (2026-08-31)** — gebaut, von Till am laufenden Build
abgenommen. Volle Unit-Suite: **261 Tests, 0 Fehler**.
Category: ux / panel

## Ergebnis

Rahmen-Overlay in `PanelView` entfernt. Das aktive Panel erkennt man jetzt an
der **Selektionsfarbe** — AppKit zeichnet die Auswahl des First Responders in
Accent, die des inaktiven Panels grau. Kein eigenes Zeichnen.

Zweiter Cue war schon da und trägt jetzt mit: der Panel-Titel steht im aktiven
Panel auf `.primary`, im inaktiven auf `.secondary` (`PanelView`, Zeilen um
49/56). Deshalb ist auch ein Panel ganz ohne Auswahl noch unterscheidbar.

### Tills Entscheidungen (2026-08-31)

- **Auto-Selektion nur bei Tastatur-Wechsel** (die „Abschwächen"-Variante des
  Trade-offs oben). `PanelModel.selectFirstRowIfEmpty()` läuft ausschließlich
  in `perform(.switchPanel)`, nie bei einem Klick ins Leere. Grund: die
  Selektion ist zugleich Ziel von Return, Leertaste und ⌘⌫ — wer nur klickt,
  wollte oft bloß das Panel aktivieren und darf keine Löschkandidatin
  untergeschoben bekommen.
- **Kein dritter Cue.** Keine getönte Pfadzeile. Wenn es im Gebrauch zu leise
  wirkt, ist das ein eigenes kleines Ticket.

### Akzeptanzkriterien

- [x] AC1 — kein Rahmen mehr; aktives Panel über Accent-vs-Grau erkennbar.
- [~] AC2 — **bewusst abgeschwächt**: nicht nach jedem Load/Navigation, sondern
  nur beim Tab-Wechsel. Siehe Entscheidung oben; das ursprüngliche AC2 hätte
  genau den Trade-off ausgelöst, den Till vermeiden wollte.
- [x] AC3 — Panelwechsel färbt um, die Selektion des inaktiven Panels bleibt
  erhalten (`selectFirstRowIfEmpty` ist ein No-op bei vorhandener Auswahl —
  eigener Test).
- [x] AC4 — Trade-off aufgelöst und hier notiert.

### Tests

5 neue in `PanelFocusSelectionTests` (injizierte `PanelSource`, kein
Dateisystem): leere Auswahl nimmt Zeile 1; vorhandene Auswahl bleibt; Mehrfach-
auswahl bleibt; leerer Ordner erfindet nichts; Filter aktiv → erste **sichtbare**
Zeile, nicht die erste des Ordners.

### Bekannter, akzeptierter Rest

Haben beide Panels keine Auswahl, trägt nur der Titel-Kontrast. Leiser als der
alte Rahmen. Bewusst so abgenommen.

## Parent

Tills Idee (2026-08-11): Fokus-Anzeige ohne den blauen Rahmen lösen — z. B.
immer die erste Zeile selektieren, oder Glow/Atmen. Diskussion in Session,
Empfehlung unten.

## Ist-Zustand

Aktives Panel bekommt einen 2px-Accent-Rahmen als Overlay
(`Sources/Diptychon/Panel/PanelView.swift:142`). Funktioniert, ist aber laut
und markiert die Fläche statt des Ortes, an dem die Tastatur wirkt.

## Wie andere Multi-Pane-Apps das lösen

- **Finder / Mail / Xcode (macOS-nativ):** kein Rahmen. Die Selektionsfarbe
  trägt den Fokus — aktives Panel zeigt die Auswahl in Accent-Farbe, inaktives
  in Grau (`unemphasizedSelectedContentBackground`). AppKit macht das
  automatisch über den First Responder.
- **Marta / ForkLift / Commander One:** Header/Pfadzeile des aktiven Panels
  getönt, inaktives Panel leicht gedimmt.
- **Midnight Commander / Far / Total Commander:** jedes Panel hat immer eine
  Cursor-Zeile; im aktiven Panel farbig, im inaktiven grau. Die Cursor-Zeile
  IST der Fokusindikator — exakt Tills „erste Zeile selektieren"-Idee.
- **tmux / iTerm2:** inaktives Panel wird gedimmt.
- **Vim / VS Code / Zed:** Cursorzeile + dezente Chrome-Tönung nur im aktiven
  Split.

## Empfehlung

Native Konvention nutzen, null Custom-Drawing:

1. Rahmen-Overlay entfernen (`PanelView.swift:142`).
2. Jedes Panel hält immer eine Selektion (nach Load/Navigation Zeile 0, falls
   keine vorhanden).
3. Aktives Panel = First Responder der Table. AppKit rendert dessen Auswahl
   in Accent, die des inaktiven Panels grau. Fertig.
4. Optionaler Zweitcue: Header/Pfadtext aktiv primär, inaktiv sekundär
   (Marta-Stil).

Bonus: die graue Selektion im inaktiven Panel dient als „da war ich"-Marker
beim Zurückwechseln.

**Glow/Atmen: verworfen.** Animation zieht den Blick dauerhaft; ein Fokus-Cue
soll einen Blick beantworten, nicht Aufmerksamkeit fordern. Weicher Glow
widerspricht außerdem der rechteckigen Formsprache (kein Pillen-/Soft-Look).

## Offener Trade-off (vor Umsetzung entscheiden)

Selektion = Aktionsziel. Eine automatisch selektierte Zeile 0 heißt: Enter,
Space oder ⌘⌫ wirken auf eine Datei, die der Nutzer nie angefasst hat.
Midnight Commander trennt Cursor und Markierung; NSTableView kennt nur
Selektion. Optionen:

- **Akzeptieren** — Diptychon ist tastaturgetrieben, persistenter Cursor passt
  zur Lineage; Risiko v. a. bei destruktiven Aktionen.
- **Abschwächen** — Auto-Selektion nur, wenn das Panel per Tastatur aktiviert
  wird (nicht bei Maus-Klick ins Leere).

## Akzeptanzkriterien

- AC1: Kein Rahmen-Overlay mehr; aktives Panel ist über die Selektionsfarbe
  (Accent vs. Grau) eindeutig erkennbar.
- AC2: Jedes Panel zeigt nach Load/Navigation immer eine selektierte Zeile.
- AC3: Panelwechsel (Tab/Klick) wechselt Accent/Grau korrekt, ohne die
  Selektion des inaktiven Panels zu verlieren.
- AC4: Destruktive Aktionen auf Auto-Selektion sind bewusst entschieden
  (Trade-off oben aufgelöst und im Issue notiert).
