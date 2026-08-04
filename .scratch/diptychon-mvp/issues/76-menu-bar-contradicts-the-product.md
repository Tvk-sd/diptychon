# 76 — Die Menüleiste widerspricht dem Produkt

Status: **ready-for-agent**
Category: bug / onboarding

## Parent

`#68` Readiness-Gate, Befunde **T2** (Blocker), **T3** und **T4** aus dem
empirischen Erstlauf 2026-08-04. Fortsetzung von #74, das nur die Tür zur
Tastaturbelegung gebaut hat.

## T2 — Blocker: das Bearbeiten-Menü behauptet, die App könne nichts

Ausgelesener Zustand des laufenden Erstlaufs (System Events):

```
Undo : false      Cut : false       Paste : false
Redo : false      Copy : false      Delete : false
Select All : true
```

Alle dauerhaft grau. Die App kann jede dieser Operationen — über ⌘Z, ⌘C, ⌘V,
⌘⌫, alle über `Keymap`/`AppAction`. Das Menü sagt das Gegenteil, und zwar
ausgerechnet über **umkehrbare Operationen**, die ADR 0004 zur Kernidee des
Produkts erklärt.

Für den Erstnutzer ist ein graues Menü keine fehlende Funktion, sondern eine
Aussage: *dieses Programm kann nicht kopieren und nichts rückgängig machen.*
Das ist schlimmer als ein leeres Menü.

**Ursache** — dieselbe wie bei #74/B1: der `NSEvent`-Monitor ist die
Tastatur-Autorität, an der Responder-Chain hängt nichts. Die Standard-
Menüeinträge fragen die Chain nach `undo:`, `copy:`, `paste:` usw., finden
niemanden und deaktivieren sich.

### Zwei Wege, mit einem echten Risiko dazwischen

**A — Responder-Chain bedienen.** `undo:`, `redo:`, `copy:`, `paste:`,
`delete:` auf der Panel-`NSView` implementieren, die Standardeinträge werden
dadurch automatisch aktiv und zeigen ihre üblichen Kürzel.

> ⚠️ **Doppelauslösung prüfen.** Menü-Kürzel und der lokale `NSEvent`-Monitor
> greifen auf dasselbe ⌘Z. Lokale Monitore laufen **vor** der normalen
> Zustellung; solange der Monitor das Event schluckt (`return nil`), sieht das
> Menü es nie und es feuert einmal. Das muss für jede betroffene Taste
> nachgewiesen werden, nicht angenommen — ein doppeltes Undo ist genau die
> Sorte Fehler, die Vertrauen in „umkehrbar" zerstört.
>
> Zweiter Haken: **belegt der Nutzer Undo um** (#44), zeigt das Menü weiter ⌘Z
> und würde dann tatsächlich über das Menü feuern. Inkonsistent.

**B — Eigene Einträge, Kürzel aus dem `HotkeyManager` gelesen, ohne
`.keyboardShortcut`.** Klick führt die `AppAction` aus, die Beschriftung zeigt
die *aktuelle* Belegung. Immer korrekt, auch nach Umbelegung, und es entsteht
kein zweiter Tastaturpfad. Das ist die Linie, die #74 schon gewählt hat.

Empfehlung: **B**, aus Konsistenz mit #74 und weil es das Rebinding überlebt.
Braucht eine Brücke von der Szene zum `WorkspaceModel` — heute besitzt
`WorkspaceView` das Modell selbst. Die Brücke ist der eigentliche Aufwand
dieses Tickets.

## T3 — Fenster-Tabbing in einer App ohne Tabs

Aktiv im Menü: „Show Tab Bar", „Show All Tabs" (Darstellung), „Show Previous
Tab", „Show Next Tab", „Move Tab to New Window", „Merge All Windows", „Remove
Window from Set" (Fenster). Das ist AppKits automatisches Fenster-Tabbing.

Diptychon hat kein Tab-Konzept (#38 steht auf `needs-triage`), und wer das
anklickt, bekommt eine Systemfunktion, die zur Zwei-Panel-Anordnung quer steht.

Fix ist eine Zeile: `NSWindow.allowsAutomaticWindowTabbing = false`. Nimmt
beide Gruppen auf einmal aus dem Menü.

## T4 — das Produkt kommt in der Menüleiste nicht vor

Vollständiger Bestand: Diptychon (Standard), Ablage (New Window/Close/Close
All), Bearbeiten (grau, siehe T2), Darstellung (Tabs/Vollbild), Fenster
(Standard), Hilfe (Keyboard Shortcuts… — der #74-Fix).

Nirgends: Navigation zurück/vorwärts/aufwärts, Neuer Ordner, Umbenennen,
Vorschau, Ausgeblendetes zeigen, Terminal, Staging, Gadgets, Suche.

Die Menüleiste durchzugehen ist der klassische Mac-Reflex beim Kennenlernen
einer App. Wer ihn hier ausübt, findet das Produkt nicht.

**Nicht alles nachbauen.** Die Command-Palette (⌘K) ist die vollständige
Liste und bleibt es. Sinnvoll im Menü sind die Befehle, die ein Fremder
*sucht*, bevor er die Palette kennt: Navigation, Neuer Ordner, Umbenennen,
Ausgeblendetes zeigen, Terminal. Ein „Go"-Menü plus wenige Einträge unter
Ablage reichen; mehr wird Pflege ohne Gegenwert.

## Acceptance criteria

- [ ] Kein Menüeintrag behauptet etwas Falsches über das Produkt: was die App
      kann, ist entweder aktiv oder steht nicht im Menü
- [ ] Undo/Redo/Kopieren/Einfügen/Löschen sind aus dem Menü heraus ausführbar
      und feuern **genau einmal**, wenn zusätzlich die Taste gedrückt wird
      (nachgewiesen, nicht angenommen)
- [ ] Nach einer Umbelegung in den Einstellungen zeigt das Menü die neue
      Belegung
- [ ] Fenster-Tabbing kommt in keinem Menü mehr vor
- [ ] Ein Fremder findet Navigation, Neuer Ordner, Umbenennen, Ausgeblendetes
      und Terminal über die Menüleiste
- [ ] UI-Test deckt den Menübestand ab, analog zu
      `testHelpMenuOffersKeyboardShortcutsAndNotTheBrokenDefault`
- [ ] Volle Suite grün vor dem Merge

## Outcome

_(offen)_
