# 90 — Terminal-Session wirklich beenden: Tab mit ✕

Status: **CLOSED (2026-08-29)** — gebaut, von Till am laufenden Build getestet
und abgenommen, committet als `e68bf0b` auf `main`. Nicht gepusht.
Volle Unit-Suite: **249 Tests, 0 Fehler**.
Category: enhancement / terminal

## Entscheidung (Till, 2026-08-27)

**Variante B: keine Rückfrage.** Das ✕ beendet, immer — auch mitten im Befehl.

## Was gebaut wurde

- `TerminalSession.endSession()`: Shell per SIGTERM beenden, Terminal-View
  wegwerfen, gemerkten Ordner und „(exited)" zurücksetzen. Danach ist die
  Session leer, kein Rest zum Wiederanknüpfen.
- `WorkspaceModel.closeTerminalSession()`: `endSession()` **plus** Panel
  einklappen. Das Einklappen ist nicht Kosmetik — es erzwingt den Neuaufbau des
  Panels, und genau dadurch startet das nächste ⌘J eine frische Shell im dann
  aktiven Ordner.
- ✕ am rechten Rand der Namensleiste. Kein Chip, kein Rahmen — die Bandkanten
  tragen es, wie überall sonst in der App.
- 5 neue Tests in `TerminalSessionCloseTests`: ⌘J lässt die Session in Ruhe,
  ✕ klappt ein, ✕ räumt alles weg, ✕ auf nie geöffneter Session ist harmlos,
  zweimal ✕ ist harmlos.

Fallstrick beim Testen notiert: ein frisches `WorkspaceModel` stellt den
**echten** letzten Zustand aus den UserDefaults wieder her (#41). Tests müssen
`terminalVisible` explizit setzen, statt „aus" anzunehmen — drei Tests sind
genau daran erst rot gewesen.

## Parent

`.scratch/diptychon-mvp/PRD.md` — Folge von #65 (eingebettetes Terminal).

## Problem

Till, 2026-08-27, am laufenden Build:

> „command j schliesst das terminal aber nicht den inhalt des terminals, also
> wenn ich eine claude session in dem terminal habe und dann com j drücke
> schliesst terminal, dann drücke ich wieder com j und das terminal öffnet sich
> und die alte claude session ist immer noch am laufen"

Und davor:

> „es braucht nen terminal tab mit nem x button"

⌘J **versteckt** das Panel, es beendet nichts. Das ist die Entscheidung aus #65
und sie ist bewusst so: eine laufende Build- oder Agenten-Sitzung soll ein
eingeklapptes Panel überleben. Der Fehler ist nicht diese Regel, sondern dass es
**keinen zweiten Griff** gibt: es fehlt die Geste „diese Sitzung ist fertig,
weg damit". Wer aufräumen will, hat nur `exit` von Hand oder App-Neustart.

Nebenbefund: es gibt auch **kein Leeren** des Terminals (kein ⌘K). Getrennt
behandeln — siehe „Abgrenzung".

## Lösung

Die Namensleiste wird zum **Tab**: derselbe Text wie heute, plus ein ✕ am
rechten Rand. Das ✕ beendet die Shell und wirft den Inhalt weg. Das nächste
Öffnen startet eine frische Shell im Ordner des dann aktiven Panels.

Zwei Griffe mit klar getrennter Bedeutung:

| Geste | Wirkung |
|---|---|
| **⌘J / Umschalter unten** | Panel ein-/ausblenden. Shell läuft weiter. |
| **✕ im Tab** | Shell beenden, Inhalt weg. Nächstes Öffnen = neue Shell. |

Damit bleibt die #65-Regel („ein laufender Build überlebt das Einklappen")
unangetastet und bekommt ihr fehlendes Gegenstück.

## Design-Frage (entschieden: B, siehe oben)

**Braucht das ✕ eine Rückfrage, wenn ein Befehl läuft?**

- **A (Vorschlag): Ja, aber nur dann.** Läuft nichts, schließt das ✕ sofort.
  Läuft etwas, kurze Rückfrage „Läuft noch — trotzdem beenden?". Begründung:
  eine Claude-Session wegzuklicken, die gerade arbeitet, ist teuer und nicht
  rückholbar; ein leerer Prompt ist es nicht.
- **B: Nie fragen.** Ein ✕ beendet, immer. Weniger Reibung, aber ein Fehlklick
  kostet eine laufende Sitzung.

Technisch heißt „läuft etwas": die Shell hat ein Kindprozess. Das ist prüfbar,
aber nicht gratis — deshalb ist es eine Entscheidung und keine Selbstverständ-
lichkeit.

## Abgrenzung

- **Terminal leeren (⌘K)** ist ein eigener Wunsch und ein eigenes Ticket wert:
  Inhalt löschen, Shell behalten. Gehört nicht in dieses.
- **Mehrere Tabs** nebeneinander bleiben offen (bewusst zurückgestellt in #65).
  Dieses Ticket macht aus der Namensleiste einen Tab, aber es bleibt genau
  einer. Ob je ein zweiter dazukommt, entscheidet Till aus der Praxis.
- Auto-`cd`, „Shell folgt dem aktiven Panel" — in #65 verworfen, bleibt
  verworfen.

## Weiteres

- Die Namensleiste zeigt heute schon „(exited)", wenn die Shell tot ist. Nach
  diesem Ticket ist dieser Zustand fast nie sichtbar — das ✕ räumt ihn weg.
  Der Fall bleibt trotzdem: eine Shell kann von selbst sterben.
- Formsprache: Diptychon ist rechteckig/box-aligned, keine Pillen. Der Tab darf
  kein Chip werden — Kante und Trennlinie tragen ihn, wie bei den anderen
  Bändern.
