# 75 — Erstlauf zeigt links und rechts denselben Ordner

Status: **CLOSED** (2026-08-11) — gebaut, auf main (`930f5d1`), am echten Erstlauf verifiziert
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

1. **Unterschiedliche Startordner.** Ein Default-Wert, kein neues Konzept,
   keine UI. Die Zwei-Flächen-Idee steht damit im ersten Bild. **Empfohlen.**

   ⚠️ **Der zweite Ordner darf nicht Dokumente, Downloads oder Schreibtisch
   sein.** Till hat am 2026-08-04 bestätigt (#68 › T5): beim Doppelklick einer
   frisch signierten Kopie **kommen Berechtigungsdialoge**. Alle drei
   naheliegenden Kandidaten sind TCC-geschützt — ein Erstlauf, der direkt in
   einem Systemdialog endet, ist schlechter als zwei gleiche Panels.

   Nicht geschützt und damit brauchbar: **`/Applications`** (existiert immer,
   ist ein echter Ort zum Stöbern und zeigt sofort zwei verschiedene Flächen).
   `~/Public` wäre ebenfalls frei, ist aber ein toter Ordner.

   Vorschlag: links Home, rechts `/Applications`.
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
- **T5 ist geklärt: die Dialoge kommen.** Der Zweitordner muss deshalb außerhalb
  von Dokumente/Downloads/Schreibtisch liegen — siehe oben.
- **Offen und vor dem Fix zu klären:** kommt der Dialog schon beim Auflisten von
  **Home**, oder erst beim Betreten eines geschützten Unterordners? Wenn schon
  Home ihn auslöst, hilft kein anderer Startordner und das eigentliche Thema
  ist die Reihenfolge von Onboarding und erstem Listing (#10 baute den
  Full-Disk-Access-Pfad, aber nicht dessen Timing). Till per Doppelklick
  prüfbar; von hier aus nicht messbar, weil ein aus dem Terminal gestarteter
  Prozess den Zugriff erbt.

## ⚠️ Unerklärter Nebenbefund (2026-08-04, beim Bauen von #76)

Eine dritte Probe-Kopie (`com.diptychon.probe3`, **frische** Bundle-ID, Domain
vor dem Start nachweislich leer) startete **nicht** auf Home, sondern tief in
`~/Desktop/Archiv 2020-21/PM Frameworks` — mit selektierter Zeile.

Geprüft und ausgeschlossen: kein Eintrag unter
`~/Library/Saved Application State/com.diptychon.probe3`, und
`~/Library/Application Support/Diptychon/` enthält nur `gadgets.json`.
`WorkspaceState.key` ist `"workspaceState"` in `UserDefaults`, also
domänengebunden. Woher der Pfad kam, ist damit offen.

Das berührt dieses Ticket direkt: wenn eine leere Domain trotzdem irgendwo
Zustand findet, ist „Erstlauf" nicht das, wofür wir es halten, und ein neuer
Default könnte davon überschrieben werden. **Vor dem Fix reproduzieren** — Kopie
mit neuer Bundle-ID anlegen, `defaults read` als leer bestätigen, starten,
Pfad notieren.

Der Befund T1 selbst bleibt gültig: er wurde an `probe1` erhoben, deren Domain
vor dem Start ebenfalls leer war und die **beide Panels auf Home** zeigte.

## Acceptance criteria

- [ ] Erster Start ohne gespeicherten `workspaceState` zeigt in den beiden
      Panels **verschiedene** Ordner
- [ ] Zweiter Start übernimmt weiterhin den gespeicherten Zustand (#41 bleibt
      unberührt)
- [ ] `DIPTYCHON_DIR` setzt weiterhin beide Panels auf denselben Ordner
- [ ] Fehlt der Zweitordner, fällt das rechte Panel still auf Home zurück
- [ ] Volle Suite grün vor dem Merge

## Outcome (2026-08-04) — gebaut, Suite grün

`URL.secondPaneStartDirectory` (`WorkspaceView.swift`) liefert `/Applications`,
fällt auf Home zurück, wenn der Ordner fehlt, und gibt bei gesetztem
`DIPTYCHON_DIR` beide Panels wieder auf denselben Ordner — der Override heißt
„öffne hier, deterministisch", und die UI-Tests hängen daran.

In `WorkspaceModel` ist `plan(...)` um einen `firstRun`-Parameter erweitert,
getrennt vom `home`-Parameter. Der Unterschied ist der Punkt: `home` bleibt der
Notnagel für einen **gespeicherten** Ordner, der nicht mehr auflösbar ist —
dort wäre `/Applications` eine Überraschung. `firstRun` greift nur, wenn gar
nichts gespeichert ist.

Drei Unit-Tests in `StartDirectoryTests.swift`; sie überspringen sich selbst,
wenn `DIPTYCHON_DIR` gesetzt ist. Volle Suite **219 Unit + 16 UI** grün.

Am echten Erstlauf verifiziert (frische Bundle-ID, leere Domain): links Home,
rechts Applications.

### Fehlalarm, der sich gelohnt hat

Im Erstlauf-Bild stand das linke Panel nach 4 und nach 8 Sekunden auf
„Loading…" und war erst zwischen 8 und 16 Sekunden fertig. Verdacht war, dass
`/Applications` — viele App-Bundles, teure Typauflösung — das andere Panel
aushungert.

**Zwei Gegenproben widerlegen das:**
1. zweites Panel auf `/` (vier Einträge, sofort geladen) — Home hängt trotzdem
2. Kontrolllauf mit dem alten Verhalten, **beide Panels auf Home** — beide
   hängen bei „Loading…"

Die Verzögerung ist also unabhängig von diesem Ticket. Sie ist aber real und
gehört beobachtet: siehe Nachtrag in #68, Kandidat für #40.

## Nachtrag (2026-08-11) — geschlossen

Committed als `930f5d1` (auf main); #68-Gate wurde darauf geschlossen
(2026-08-10). Der unerklärte probe3-Nebenbefund oben bleibt unreproduzieren —
falls „Erstlauf zeigt fremden Ordner" je wieder auftaucht, hier ansetzen.
