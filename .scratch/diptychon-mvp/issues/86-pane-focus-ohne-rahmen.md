# 86 — Aktives Panel ohne blauen Rahmen erkennbar machen

Status: **needs-triage**
Category: ux / panel

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
