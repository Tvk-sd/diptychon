# 88 — Ordner in das eingebettete Terminal ziehen

Status: **wontfix (2026-08-29)** — gebaut, dreimal am laufenden Build
getestet, dreimal gescheitert, wieder ausgebaut. Kein Code davon ist auf `main`.
Category: enhancement / terminal

## Ergebnis: zurückgebaut

Till, 2026-08-29, nach dem dritten Versuch:

> „ok this does not work and i can not describe how it is not working - can we
> reverse this development and put the ticket of pullable path ad acta"

Das ist der Abbruch, und er ist richtig: „ich kann nicht beschreiben, wie es
nicht geht" heißt, die Geste ist nicht nur kaputt, sie ist **unlesbar** geworden.
Eine Interaktion, deren Fehlverhalten der Nutzer nicht mehr benennen kann,
repariert man nicht per weiterem Versuch.

Ausgebaut wurden: `ShellQuoting` samt Tests, `TerminalSession.insert(_:)` und
`claimKeyFocus()`, `TerminalDropView`, der `onDrag` am Breadcrumb und der
`WindowDragBlocker`. Suite danach: **249 Tests, 0 Fehler**.

**Nicht ausgebaut** (gehört zu #89 bzw. #90 und bleibt): die erweiterte
Klick-Trefferprüfung des Terminal-Panels und das ✕ in der Namensleiste.

## Warum es gescheitert ist — drei Hürden, zwei davon nachgewiesen

1. **`onDrag` startet auf einem SwiftUI-`Button` nie.** Die eigene Druck-Geste
   des Buttons frisst sie. Nachgewiesen: nach dem Umbau auf `Text` +
   `onTapGesture` hob das Segment ab.
2. **Das Kopfband liegt in der Fenster-Zieh-Zone.** Mit `.hiddenTitleBar` steigt
   der Inhalt bis unter die Titelleiste; Fenster-Ziehen schlägt View-Ziehen.
   Tills Beobachtung: „der pfad bewegt sich kurz mit, dann bewegt er sich
   selbstständig und dann das fenster". Ein `mouseDownCanMoveWindow = false`
   im Hintergrund hat das nicht sauber gelöst.
3. **Unbekannter Rest.** Nach Hürde 2 war das Verhalten so diffus, dass es nicht
   mehr beschreibbar war. Ob die Abwurfstelle im Terminal überhaupt je erreicht
   wurde, ist **nie verifiziert** worden — der Zug kam nie sauber dort an.

## Übertragbar

- **`onDrag` + `Button` vertragen sich in SwiftUI nicht.** Wer eine Zeile
  klickbar *und* ziehbar braucht, nimmt `Text` + `contentShape` +
  `onTapGesture`.
- **Ein Fenster mit versteckter Titelleiste ist kein guter Ort für eine
  Zieh-Quelle.** Die Fenster-Zieh-Zone gewinnt, und sie ist unsichtbar.
- **Abbruchsignal:** wenn der Tester das Fehlverhalten nicht mehr benennen kann,
  ist das ein Befund über die Interaktion, kein Mangel an Beschreibung.

## Falls es je zurückkommt

Nicht am Breadcrumb ansetzen. Zwei Wege, die die beiden Hürden umgehen:

- **Aus der Dateiliste ziehen.** Die Zeilen sind schon Zieh-Quellen (`onDrag`
  ist dort erprobt) und liegen weit unter der Titelleiste. Nur die Abwurfstelle
  im Terminal wäre neu — genau ein Baustein statt vier.
- **Ganz ohne Ziehen.** Eine Tastenkombination „Pfad des aktiven Panels ins
  Terminal einfügen". Kein Drag-System, keine Titelleiste, testbar als reine
  Funktion.

Der teure Teil war nie das Quoting — der war in einer Stunde fertig und grün.
Teuer war die Geste.

## Parent

`.scratch/diptychon-mvp/PRD.md` — Folge von #65 (eingebettetes Terminal).

## Problem Statement

Ich stehe in einem Repo, das Terminal-Panel ist offen, und ich will den Pfad
dieses Ordners in einem Befehl benutzen (`cd`, `code`, `git -C`, `open`). Heute
muss ich ihn abtippen oder über einen Umweg kopieren. Der Pfad steht sichtbar
zwei Zentimeter über der Shell — im Breadcrumb der Top-Leiste — aber ich komme
nicht an ihn heran.

Aus #65 ist bewusst entschieden: **die Shell folgt dem aktiven Panel nicht.**
Kein Auto-`cd`. Das bleibt. Der fehlende Baustein ist nicht Automatik, sondern
eine Übergabe, die ich selbst auslöse: ich ziehe den Ordner dorthin, wo ich ihn
brauche, und tippe den Befehl drumherum selbst.

## Solution

Breadcrumb-Segmente in der Top-Leiste werden **Drag-Quellen**. Das Terminal wird
**Drop-Ziel**. Ziehe ich ein Segment in die Shell, wird der vollständige,
shell-taugliche Pfad an der Cursor-Position eingefügt — als Text, gefolgt von
einem Leerzeichen. Kein Return. Nichts wird ausgeführt.

Das Drop-Ziel akzeptiert jede Datei-URL, nicht nur Breadcrumb-Segmente. Damit
funktioniert derselbe Griff aus der Dateiliste, aus der Sidebar und aus dem
Finder — ein Ziel statt vier Sonderfällen.

## User Stories

1. Als Nutzer will ich ein Breadcrumb-Segment anfassen und ziehen können, damit
   der sichtbare Pfad auch ein greifbarer Pfad ist.
2. Als Nutzer will ich ein gezogenes Segment im Terminal fallen lassen, damit
   der Pfad an der Cursor-Position erscheint.
3. Als Nutzer will ich den **vollständigen** Pfad eingefügt bekommen (nicht nur
   den Ordnernamen), damit der Befehl unabhängig vom cwd der Shell funktioniert.
4. Als Nutzer will ich, dass ein Pfad mit Leerzeichen korrekt gequotet wird,
   damit `cd ` auf `/Users/Till/Projects/untitled folder` nicht zerbricht.
5. Als Nutzer will ich, dass Pfade mit Anführungszeichen, `$`, Backslash oder
   Zeilenumbruch sicher gequotet werden, damit ein Ordnername nie zu einem
   ungewollten Befehl wird.
6. Als Nutzer will ich nach dem eingefügten Pfad ein Leerzeichen, damit ich
   sofort weitertippen kann.
7. Als Nutzer will ich, dass **nie** ein Return mitgeschickt wird, damit ein
   Drop niemals von selbst etwas ausführt.
8. Als Nutzer will ich den Pfad an der Cursor-Position eingefügt bekommen,
   damit ich `cd ` vorher tippen kann und `git -C ` genauso funktioniert.
9. Als Nutzer will ich ein Segment aus der Mitte des Breadcrumbs ziehen können,
   nicht nur das letzte, damit ich auch den Repo-Root oder den Elternordner
   übergeben kann.
10. Als Nutzer will ich, dass ein einfacher **Klick** auf ein Segment weiterhin
    dorthin navigiert, damit die vorhandene Breadcrumb-Navigation aus #21 durch
    das Ziehen nicht kaputtgeht.
11. Als Nutzer will ich beim Ziehen die macOS-übliche Drag-Rückmeldung sehen,
    damit ich erkenne, dass etwas am Cursor hängt.
12. Als Nutzer will ich ein sichtbares Drop-Feedback im Terminal, damit ich vor
    dem Loslassen weiß, dass die Shell den Drop annimmt.
13. Als Nutzer will ich eine Datei aus der Dateiliste ins Terminal ziehen
    können, damit `cat `, `rm ` und `mv ` denselben Griff haben.
14. Als Nutzer will ich mehrere ausgewählte Dateien in einem Zug ziehen können
    und alle Pfade — einzeln gequotet, durch Leerzeichen getrennt — eingefügt
    bekommen, damit ein Batch-Befehl in einem Schritt entsteht.
15. Als Nutzer will ich einen Ordner aus dem Finder ins Terminal ziehen können,
    damit ich nicht erst in Diptychon dorthin navigieren muss.
16. Als Nutzer will ich einen gepinnten Ordner aus der Sidebar ziehen können,
    aus demselben Grund.
17. Als Nutzer will ich, dass ein Drop das Terminal **nicht** zwingend in den
    Fokus zieht, ohne dass mir der Fokus verloren geht — das Verhalten muss
    eindeutig sein und nach dem Drop darf die Tastatur nicht ins Leere gehen.
18. Als Nutzer will ich, dass ein Drop **kein** `cd` auslöst, damit die
    Entscheidung aus #65 („nichts folgt dem aktiven Panel") gilt.
19. Als Nutzer will ich, dass ein Drop den aktiven Panel nicht wechselt, damit
    die Übergabe nichts anderes im Fenster verschiebt (siehe #89).
20. Als Nutzer will ich, dass ein Drop während eines laufenden Befehls den Text
    genauso an die Shell schickt wie Tippen — kein Sonderpfad, keine
    Pufferung.
21. Als Nutzer will ich ein Breadcrumb-Segment auch auf das **andere Panel**
    ziehen können, damit „diesen Ordner dorthin kopieren" ohne Umweg über die
    Dateiliste geht.
22. Als Nutzer will ich, dass ein solcher Drop auf ein Panel dieselbe
    Copy/Move-Bestätigung durchläuft wie jeder andere Panel-Drop, damit nichts
    unbemerkt kopiert wird.
23. Als Nutzer will ich ein Breadcrumb-Segment in **andere Apps** ziehen können
    (Finder, Editor, Terminal.app), weil die Pasteboard-Repräsentation eine
    Standard-Datei-URL ist.
24. Als Nutzer will ich, dass bei geschlossenem Terminal-Panel nichts an dieser
    Stelle passiert und der Drag einfach ins Leere läuft.

## Implementation Decisions

**Volle Pfade, nicht Namen.** Der Nutzer sagte „den Namen des Ordners"; eingefügt
wird trotzdem der absolute Pfad. Begründung: der Ordnername allein ist nur dann
brauchbar, wenn die Shell schon im Elternordner steht — und die Shell folgt dem
Panel gerade *nicht*. Der absolute Pfad ist außerdem das, was jedes andere
Terminal beim Datei-Drop einfügt. **Annahme, nicht Rückfrage** — wenn Till den
Kurznamen will, ist das ein Einzeiler in derselben Funktion.

**Drei Bausteine, ein neuer prüfbarer Saum:**

1. **Quoting (rein, der Saum).** Eine reine Funktion `path -> shell-sicherer
   String`. Aus #65 wurde `shellQuoted` samt Tests gelöscht, als die
   „cd hierher"-Affordanz zurückgebaut wurde — hier lebt sie wieder auf, weil
   der Bedarf zurück ist. Regel: einfache Anführungszeichen, jedes enthaltene
   `'` als `'\''` maskiert. Das macht jedes Sonderzeichen inert.
   Mehrfachauswahl: einzeln quoten, mit Leerzeichen fügen, ein Leerzeichen
   anhängen.
2. **Einfügen (dünn).** Die Terminal-Session bekommt eine Methode „diesen Text
   an die Shell schicken", die intern SwiftTerms `send(txt:)` benutzt — exakt
   der Pfad, den Tippen nimmt. Keine Zwischenablage, kein Bracketed-Paste-
   Sonderfall, kein Newline. Ist die Shell beendet, ist der Aufruf ein No-op.
3. **Drop-Ziel (AppKit).** Die Terminal-View registriert `.fileURL` als
   akzeptierten Drag-Typ, liest die URLs, ruft (1) und dann (2). Wird an der
   `NSViewRepresentable`-Grenze aufgesetzt, die es schon gibt — kein neuer
   View-Typ.

**Drag-Quelle.** Die Breadcrumb-Segmente bekommen einen Drag-Modifier, der eine
Datei-URL als Item-Provider liefert. Vorbild ist der bestehende Zeilen-Drag der
Dateiliste — bewusst der „nur ziehen"-Modifier und nicht `draggable`, damit der
einfache Klick weiter navigiert.

**Bewusst akzeptierte Nebenwirkung.** Eine Standard-Datei-URL auf dem Pasteboard
macht Breadcrumb-Segmente automatisch auch für die Panels und für fremde Apps zu
gültigen Drag-Quellen. Das wird **angenommen, nicht eingeschränkt**: „der
Ordner, den ich sehe, ist der Ordner, den ich ziehe" ist die einfachere Regel,
und der Panel-Drop läuft ohnehin durch die vorhandene Copy/Move-Behandlung.

**Kein Auto-`cd`, keine Ausführung.** Ein Drop schreibt Text und mehr nicht. Die
Entscheidung aus #65 bleibt unangetastet.

**Fokus.** Ein Drop, der Text in die Shell schreibt, gibt der Shell auch die
Tastatur — sonst schreibt der nächste Tastendruck woanders hin. Das ist die eine
Fokus-Bewegung, die ein Drop machen darf; den aktiven Panel wechselt er nicht.

## Testing Decisions

Gute Tests hier prüfen beobachtbares Verhalten an einer schmalen Grenze und
nicht, wie AppKit intern zieht. Drag-and-Drop selbst ist per Unit-Test nicht
sinnvoll fahrbar (`NSDraggingInfo` müsste gefälscht werden) — deshalb wird der
prüfbare Kern aus der Interaktion herausgezogen.

- **Neue Unit-Tests auf der Quoting-Funktion** (der einzige neue Saum):
  Pfad ohne Sonderzeichen, Pfad mit Leerzeichen (`/Users/Till/Projects/untitled
  folder` — Tills echter Arbeitspfad), Pfad mit `'`, mit `"`, mit `$`, mit
  Backslash, mit Umlaut, leere Eingabe, mehrere Pfade auf einmal, angehängtes
  Leerzeichen. Vorbild: `PathInputTests`, `FuzzyMatchTests` — reine Funktion,
  Tabelle aus Ein-/Ausgabe.
- **Kein Test auf `send(txt:)`** — das ist ein Ein-Zeilen-Durchreicher zu
  SwiftTerm; ein Test darauf prüfte das Framework, nicht uns.
- **Von Hand verifiziert (im Ticket abhaken):** Ziehen eines mittleren
  Segments; Klick navigiert weiterhin; Drop während laufendem Befehl; Drop aus
  dem Finder; Mehrfachauswahl aus der Dateiliste; Drop bei beendeter Shell.
- Vor dem Merge die **volle Suite** laufen lassen, nicht nur die neue Datei.

## Out of Scope

- Auto-`cd`, „Shell folgt dem aktiven Panel", eine „cd hierher"-Schaltfläche —
  in #65 explizit verworfen.
- Ausführen des Befehls nach dem Drop (kein Return).
- Tabs im Terminal-Panel (offener Punkt aus #65).
- Drop von Text aus anderen Apps in die Shell.
- Drag **aus** dem Terminal heraus.
- Eine Tastenkombination „Pfad einfügen" ohne Maus — sinnvoll, aber eigenes
  Ticket, wenn der Bedarf im Gebrauch auftaucht.

## Further Notes

- Terminal-Kernwissen liegt in `Sources/Diptychon/Terminal/`, das Breadcrumb in
  der Top-Leiste (Nav-Zeile des aktiven Panels).
- Hängt lose an **#89**: solange ein Klick auf die Bodenleiste den aktiven Panel
  umschaltet, zeigt das Breadcrumb nach dem Öffnen des Terminals unter Umständen
  den falschen Ordner — dann zieht man den falschen Pfad. #89 zuerst.
