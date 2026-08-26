# 89 — Klick auf die Bodenleiste macht das rechte Panel aktiv

Status: **CLOSED (2026-08-26)** — gebaut, von Till am laufenden Build getestet,
committet als `550dc29` auf `main`. Nicht gepusht.
Category: bug / panel

## Ergebnis

Behoben. Die Klick-Zuordnung liegt jetzt als reine Funktion
`PanelClickRouter.target(...)` neben den Panels; der `NSEvent`-Monitor in
`WorkspaceView` übersetzt nur noch Ereignis → Funktion → Model-Zustand.

- **Bodenleiste als eigenes Ausnahme-Band** (32pt + 1pt Trennlinie), gespiegelt
  zur vorhandenen Kopfleisten-Ausnahme. Damit wechselt kein Umschalter unten
  mehr den aktiven Panel — Terminal, Preview, Staging, Activity, Sidebar.
- **Terminal-Trefferprüfung deckt das ganze Panel**: `TerminalSession` hält eine
  schwache Referenz auf eine Hintergrund-View, die die Panel-Fläche misst, also
  Namensleiste und 9pt-Einzugsstreifen mit. `onDisappear` setzt sie auf nil,
  damit eine liegengebliebene View nach dem Einklappen keine Klicks über den
  Dateilisten abfängt.
- **Volle Unit-Suite: 244 Tests, 0 Fehler** (vorher 226; 18 neue in
  `PanelClickRouterTests`, darunter der Regressionstest für genau diesen Fehler
  und je ein Kantentest für beide Bänder).

Von Till von Hand bestätigt: Terminal öffnet im linken Ordner; nach ⌘J-Schließen
schalten Klicks links/rechts weiterhin normal um; Klick auf die rechte Hälfte der
Terminal-Namensleiste lässt den aktiven Panel stehen.

Die unverifizierte Vermutung oben (Aux-Spalte verschiebt die rechte Kante) wurde
**nicht** nachgemessen und ist es auch nicht mehr wert: die Bodenleiste antwortet
jetzt in beiden Fällen `.none`, abgesichert durch Test.

Nächster Schritt: **#88** (Ordner ins Terminal ziehen) ist damit entsperrt.

## Parent

`.scratch/diptychon-mvp/PRD.md` — betrifft #65 (Terminal) sichtbar, Ursache
liegt in der Panel-Aktivierung aus #13/#21.

## Problem Statement

Ich arbeite im **linken** Panel, beide Panes sind offen. Ich klicke unten rechts
auf das Terminal-Symbol. Das Terminal geht auf — aber im Ordner des **rechten**
Panels. Ich habe rechts nichts angefasst.

Aus #65: „Die Shell ist auf den Ordner festgenagelt, in dem sie geöffnet wurde."
Der cwd wird **einmal** gesetzt. Wird er falsch gesetzt, ist er dauerhaft
falsch — ich muss die Shell selbst per `cd` wieder einfangen oder die App neu
starten. Ein einmaliger Fehlgriff mit dauerhafter Folge.

## Solution

Ein Klick auf die Bodenleiste wechselt den aktiven Panel nicht. Die Bodenleiste
ist Fenster-Chrome, kein Panel. Nur ein Klick **in** eine Dateiliste macht deren
Panel aktiv.

Das Terminal öffnet danach im Ordner des Panels, das vorher aktiv war.

## Ist-Zustand und Ursache (verifiziert durch Lesen des Codes)

Der globale `leftMouseDown`-Monitor in `WorkspaceView` leitet den aktiven Panel
aus der **x-Position** des Klicks ab: links der Mitte → linkes Panel, rechts der
Mitte → rechtes Panel. Er nimmt drei Bereiche davon aus — die Top-Leiste (per
y-Band), die Sidebar und die Preview/Staging-Spalte (per x-Kanten) — und den
Terminal-Bereich (per Hit-Test aus #65).

**Die Bodenleiste ist in keiner dieser Ausnahmen.** Ihre Umschalter liegen am
rechten Fensterrand. Ein Klick dort erfüllt „nicht in der Top-Leiste" und „liegt
zwischen Sidebar- und Preview-Kante" und setzt deshalb `active = .right`, bevor
die Umschalt-Aktion überhaupt läuft.

Zwei Belege, dass das die richtige Spur ist:

- Die Zuweisung ist als einzige Stelle im Code an „rechtes Panel sichtbar"
  gekoppelt — genau die Bedingung aus Tills Beschreibung („wenn ich zwei Panes
  offen habe").
- Vermutung (**nicht nachgemessen**, erklärt aber, warum der Fehler nicht immer
  auftritt): ist eine Aux-Spalte (Preview/Staging) offen, rückt die rechte Kante
  um 300pt nach innen und die Umschalter könnten dann *außerhalb* liegen. Die
  genauen x-Positionen der einzelnen Symbole sind aus dem Code nicht ablesbar.
  Für die Reparatur ist das egal — nachher gilt `.nichts` in beiden Fällen.

**Der Fehler ist größer als das Terminal.** Dieselbe Zuweisung feuert bei
*jedem* Umschalter der Bodenleiste: Rechtes Panel, Preview, Terminal, Staging,
Activity, Sidebar. Das Terminal ist nur der Umschalter, bei dem es weh tut,
weil er einen dauerhaften Zustand festschreibt. Repariert wird die gemeinsame
Ursache, nicht das Symptom.

## User Stories

1. Als Nutzer will ich, dass ein Klick auf die Bodenleiste den aktiven Panel
   nicht wechselt, weil ich dort auf einen Umschalter geklickt habe und nicht
   in eine Dateiliste.
2. Als Nutzer will ich, dass das Terminal in dem Ordner öffnet, in dem ich
   gerade stand, damit der cwd stimmt.
3. Als Nutzer will ich dasselbe Verhalten per ⌘J wie per Klick, damit Maus und
   Tastatur dasselbe tun.
4. Als Nutzer will ich, dass ein Klick auf den Preview-Umschalter den aktiven
   Panel nicht wechselt, damit die Vorschau die Auswahl zeigt, die ich gerade
   ansehe.
5. Als Nutzer will ich, dass ein Klick auf den Staging-Umschalter den aktiven
   Panel nicht wechselt, damit das nächste „In Staging legen" die richtige
   Auswahl nimmt.
6. Als Nutzer will ich, dass ein Klick auf den Activity-Umschalter den aktiven
   Panel nicht wechselt.
7. Als Nutzer will ich, dass ein Klick auf den Sidebar-Umschalter den aktiven
   Panel nicht wechselt.
8. Als Nutzer will ich, dass ein Klick auf den „Rechtes Panel"-Umschalter den
   aktiven Panel nicht wechselt — außer die Regel aus #13 greift, dass beim
   Ausblenden des rechten Panels der linke aktiv wird.
9. Als Nutzer will ich, dass ein Klick auf leere Fläche der Bodenleiste
   (kein Umschalter) ebenfalls nichts wechselt.
10. Als Nutzer will ich, dass ein Klick in die **linke** Dateiliste weiterhin
    das linke Panel aktiviert.
11. Als Nutzer will ich, dass ein Klick in die **rechte** Dateiliste weiterhin
    das rechte Panel aktiviert.
12. Als Nutzer will ich, dass ein Klick in die linke Dateiliste weiterhin den
    Operations-Fokus von Staging zurückholt.
13. Als Nutzer will ich, dass ein Klick in die Staging-Spalte diese weiterhin
    zur Operations-Quelle macht.
14. Als Nutzer will ich, dass ein Klick in die Top-Leiste (Suche, Breadcrumb,
    Filter) weiterhin keinen Panel-Wechsel auslöst.
15. Als Nutzer will ich, dass ein Klick in die Sidebar weiterhin keinen
    Panel-Wechsel auslöst.
16. Als Nutzer will ich, dass ein Klick in das Terminal weiterhin keinen
    Panel-Wechsel auslöst (Regel aus #65).
17. Als Nutzer will ich, dass auch ein Klick auf die **Namensleiste** des
    Terminals keinen Panel-Wechsel auslöst — sie gehört sichtbar zum Terminal,
    ist aber kein Teil der Terminal-View und fällt heute durch den Hit-Test.
18. Als Nutzer will ich, dass ein Klick auf die 9pt breite Einzugs-Spalte links
    im Terminal aus demselben Grund nichts wechselt.
19. Als Nutzer will ich, dass bei ausgeblendetem rechtem Panel jeder Klick
    weiterhin beim linken Panel landet.
20. Als Nutzer will ich, dass das Terminal, wenn ich es schließe und wieder
    öffne, weiter im ursprünglichen Ordner steht — die Shell läuft ja weiter
    (Regel aus #65).
21. Als Nutzer will ich, dass die Namensleiste den Ordner nennt, in dem die
    Shell wirklich steht, damit ich einen falschen cwd sofort sehe.

## Implementation Decisions

**Ein Saum, und zwar eine reine Funktion.** Die Entscheidung „welcher Klick
aktiviert was" steckt heute als `if`-Kette in der Monitor-Closure in der View —
nicht prüfbar, ohne ein Fenster zu bauen. Sie wird als **eine reine Funktion**
herausgezogen: Geometrie und Sichtbarkeits-Flags rein, ein Ergebnis raus.

    Klickposition + Fenstermaße + (Sidebar sichtbar? Aux-Spalte offen?
    Rechtes Panel sichtbar? Höhe der Kopf-/Bodenleiste)
      -> .linkesPanel | .rechtesPanel | .staging | .nichts

Der Monitor wird zum Übersetzer: Ereignis auslesen, Funktion fragen, Ergebnis
auf den Model-Zustand anwenden. Der Terminal-Hit-Test bleibt im Monitor, weil er
echte View-Hierarchie braucht und keine Geometrie ist — er läuft weiterhin
*vor* der Funktion und liefert direkt `.nichts`.

Damit gibt es genau **einen** neuen prüfbaren Punkt statt eines pro Umschalter.

**Die Bodenleiste kommt als y-Band dazu**, gespiegelt zur vorhandenen
Top-Leisten-Ausnahme: eine Bandhöhe (Leistenhöhe + Trennlinie), gemessen von der
Unterkante des Inhaltsbereichs. Genau die Form, die die Top-Leiste schon nutzt —
kein zweites Muster.

**Die Namensleiste des Terminals** wird in dieselbe Ausnahme gezogen. Sie liegt
zwischen Panels und Terminal und ist heute weder vom Hit-Test noch von einem
Band gedeckt; ein Klick auf ihre rechte Hälfte schaltet den Panel um. Sauberste
Lösung: der Hit-Test prüft den **umschließenden Terminal-Container** statt nur
die SwiftTerm-View — deckt Namensleiste und Einzugs-Spalte in einem Zug ab.

**Die Bandhöhen sind gemessene Konstanten, keine hergeleiteten.** So ist es bei
der Top-Leiste schon (34 = 32pt Leiste + 1pt Trennlinie), mit einer Notiz im
Code, dass beim Ändern der Leistenhöhe nachgemessen werden muss. Gleiche Notiz
für die Bodenleiste.

**Kein Verhalten wird sonst angefasst.** Die x-Logik, die Sidebar- und
Aux-Kanten, die Staging-Regel und die Regel aus #13 („rechtes Panel aus →
linkes wird aktiv") bleiben, wie sie sind.

## Testing Decisions

Ein guter Test hier gibt eine Klickposition und einen Fensterzustand hinein und
prüft das Ergebnis — nicht, wie der Monitor registriert ist oder wie SwiftUI die
Leiste baut. Genau das erlaubt der neue reine Saum.

- **Neue Unit-Tests auf der Klick-Zuordnung.** Fälle: Klick in der Bodenleiste
  rechts (rechtes Panel sichtbar) → `.nichts` ← **der Regressionstest für
  diesen Fehler**; Bodenleiste rechts, Aux-Spalte offen → `.nichts`;
  Bodenleiste links → `.nichts`; Top-Leiste rechts → `.nichts`; Sidebar →
  `.nichts`; Preview-Spalte → `.nichts`; Staging-Spalte → `.staging`;
  Panelfläche links → `.linkesPanel`; Panelfläche rechts → `.rechtesPanel`;
  Panelfläche rechts bei ausgeblendetem rechtem Panel → `.linkesPanel`; ein
  Klick genau auf die Mittellinie (Kantenfall).
- **Vorbild:** `SplitPaneTests` und `VSplitPaneTests` — dort wird die
  Geometrie-Klemmung als reine Funktion geprüft, dieselbe Bauform. Für die
  Panel-Aktivierung ist `ActivateTests` die vorhandene Nachbarschaft.
- **Kein UI-Test.** Die UI-Suite ist auf dieser Maschine anfällig (siehe #61,
  testmanagerd-Klemme); der reine Saum deckt die Regression ohne sie ab.
- **Von Hand verifiziert (im Ticket abhaken):** links stehen, Terminal per
  Klick öffnen → Namensleiste zeigt den **linken** Ordner; dasselbe per ⌘J;
  Klick auf die Terminal-Namensleiste rechts → aktives Panel bleibt; alle
  übrigen Umschalter der Bodenleiste einmal durch.
- Vor dem Merge die **volle Suite**, nicht nur die neue Datei.

## Out of Scope

- Der cwd der laufenden Shell wird **nicht** nachträglich korrigiert oder
  umgezogen. #65 hat das entschieden: fest im Öffnungsordner.
- Kein Auto-`cd`, keine „cd hierher"-Schaltfläche.
- Wie das aktive Panel *angezeigt* wird (blauer Rahmen) — das ist **#86**.
- Ein Umbau der Panel-Aktivierung weg vom globalen Maus-Monitor hin zu echtem
  First-Responder-Tracking. Wäre die gründlichere Lösung, ist aber ein eigener
  Umbau mit eigenem Risiko und nicht das, was dieser Fehler verlangt.

## Further Notes

- Ursache steht in der Monitor-Closure in `WorkspaceView`; die Bodenleiste ist
  dort das `bottomBar`-Band. Der Terminal-Hit-Test lebt in
  `Sources/Diptychon/Terminal/`.
- **Vor #88 erledigen.** Solange der aktive Panel beim Öffnen des Terminals
  umspringt, zeigt das Breadcrumb den falschen Ordner — und #88 zieht dann
  genau diesen falschen Pfad in die Shell.
