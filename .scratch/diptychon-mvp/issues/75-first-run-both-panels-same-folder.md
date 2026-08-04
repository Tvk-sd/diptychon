# 75 — Erstlauf zeigt links und rechts denselben Ordner

Status: **ready-for-agent**
Category: bug / onboarding

## Parent

`#68` Readiness-Gate, Befund **T1** aus dem empirischen Erstlauf 2026-08-04.
Blockiert #69/#71 zusammen mit #42 und #76.

## Problem

Der allererste Start ohne gespeicherten `workspaceState` öffnet **in beiden
Panels das Home-Verzeichnis**. Der Nutzer sieht zwei identische Listen
nebeneinander.

Das ist der teuerste Moment, den man so verschenken kann. Der einzige Grund,
warum jemand einen Dual-Pane-Manager lädt, ist die Zwei-Flächen-Arbeit — und
genau die sieht im ersten Bild aus wie ein Darstellungsfehler oder eine
sinnlose Verdopplung. Nichts erklärt, dass die beiden Seiten unabhängig sind.

**Das Konzept ist gut gebaut, nur schlecht eingeführt.** Sobald man in einem
Panel navigiert, ist alles sofort klar: links Desktop, rechts Home, das aktive
Panel trägt einen blauen Rahmen. Es fehlt nur der Startzustand, der das zeigt.

Belegt per Fensterbild im Erstlauf-Probelauf (eigene Bundle-ID, leere
Defaults-Domain) — siehe Methode in #68.

## Lösungsraum

Absteigend nach Aufwand-Nutzen:

1. **Unterschiedliche Startordner.** Links Home, rechts Dokumente (oder
   Downloads). Ein Default-Wert, kein neues Konzept, keine UI. Die Zwei-Flächen-
   Idee steht damit im ersten Bild. **Empfohlen.**
2. **Rechts der zuletzt genutzte Ordner** — greift beim Erstlauf nicht, hilft
   also genau da nicht, wo das Problem sitzt. Verworfen.
3. **Onboarding-Overlay/Tour.** Ungefragt, teurer als das Problem, und es
   erklärt etwas, das eine gute Voreinstellung von selbst zeigt. Verworfen.

Fundstelle für den Default: `WorkspaceModel.swift:242 ff.` — dort wird der
`DIPTYCHON_DIR`-Override behandelt und entschieden, ob Persistenz greift
(`:246`). Der Erstlauf-Pfad ohne gespeicherten Zustand liegt daneben.

## Zu beachten

- **`DIPTYCHON_DIR` muss weiter beide Panels auf denselben Ordner setzen.** Der
  Override heißt „öffne hier, deterministisch" und trägt die UI-Tests; ein
  unterschiedlicher Default darf dort nicht durchschlagen. Sonst bricht unter
  anderem `testLaunchesWithTwoPanels`.
- Existiert der gewählte zweite Ordner nicht (kein `~/Documents`), muss der
  Fallback Home sein — kein leeres Panel, keine Fehlermeldung.
- Der Zweitordner ist potenziell TCC-geschützt. Falls #68 › T5 ergibt, dass
  ein Dialog kommt, darf der Default nicht so gewählt sein, dass der Erstlauf
  sofort in einem Berechtigungsdialog endet. Erst T5 klären, dann den Ordner
  festlegen.

## Acceptance criteria

- [ ] Erster Start ohne gespeicherten `workspaceState` zeigt in den beiden
      Panels **verschiedene** Ordner
- [ ] Zweiter Start übernimmt weiterhin den gespeicherten Zustand (#41 bleibt
      unberührt)
- [ ] `DIPTYCHON_DIR` setzt weiterhin beide Panels auf denselben Ordner
- [ ] Fehlt der Zweitordner, fällt das rechte Panel still auf Home zurück
- [ ] Volle Suite grün vor dem Merge

## Outcome

_(offen)_
