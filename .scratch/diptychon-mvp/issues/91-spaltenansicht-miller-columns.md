# 91 — Spaltenansicht (Miller Columns) + sichtbarer Ansichts-Umschalter

Status: **CLOSED (2026-09-01)** — gebaut, in vier Runden mit Till am laufenden
Build nachgeschärft, von ihm abgenommen („it looks amazing"). Gemergt auf `main`
als `41f1b9d`. Volle Unit-Suite: **290 Tests, 0 Fehler**.

## Parent

`.scratch/diptychon-mvp/PRD.md` — dritte Anzeigeart neben Tabelle (#01/#17) und
Kurzansicht (#37).

## Problem Statement

Ich stehe in einem tiefen Baum und will ihn ablaufen, ohne den Weg zu verlieren.
Heute geht das nur eine Ebene nach der anderen: Ordner öffnen, Liste wird
ersetzt, die Herkunft steht nur noch als Text im Breadcrumb. Wo ich herkomme und
was daneben lag, ist weg.

Till, 2026-08-31, beim Testen von #37:

> „wenn ich einen ordner öffne sehe ich in der nächsten spalte nicht die dateien
> die da drinnen liegen"

Das war keine Fehlfunktion von #37 — die Kurzansicht bricht *einen* Ordner auf
mehrere Spalten um. Es war die Erwartung einer anderen Ansicht, die es noch nicht
gibt.

Zweites, kleineres Problem: die Anzeigearten sind **unsichtbar**. Die Kurzansicht
erreicht man nur über ⌘1 oder das Ansicht-Menü. Wer nicht weiß, dass es sie gibt,
findet sie nie — dasselbe Muster wie bei #54 (Feature vorhanden, Schalter fehlte).

## Solution

**Zwei Dinge, ein Ticket**, weil das zweite ohne das erste keinen Sinn hat: mit
drei Anzeigearten braucht es einen Umschalter, der alle drei zeigt.

### 1. Spaltenansicht

Jede Spalte ist eine Ebene. Auswahl eines Ordners in Spalte *n* zeigt seinen
Inhalt in Spalte *n+1*. Auswahl einer Datei zeigt in der nächsten Spalte nichts
(oder, später, eine Vorschau — siehe „Out of Scope"). Wächst der Pfad über die
Panelbreite hinaus, scrollt die Ansicht waagerecht und hält die **letzte** Spalte
sichtbar.

Der wesentliche Unterschied zur Kurzansicht in einem Satz: die Kurzansicht zeigt
**einen Ordner in mehreren Spalten**, die Spaltenansicht zeigt **mehrere Ordner,
einen je Spalte**.

### 2. Ansichts-Umschalter mit Symbolen

Drei Symbole, eine Gruppe, in der Kopfzeile des Panels — pro Pane, weil die
Anzeigeart pro Pane gilt. Das aktive Symbol trägt die Akzentfarbe, wie die
übrigen Umschalter der App.

## User Stories

1. Als Nutzer will ich in der Spaltenansicht einen Ordner auswählen und seinen
   Inhalt sofort rechts daneben sehen, damit ich einen Baum ablaufen kann, ohne
   die Herkunft zu verlieren.
2. Als Nutzer will ich beim Ablaufen alle Ebenen des Weges nebeneinander sehen,
   damit ich verstehe, wo ich bin, ohne den Breadcrumb zu lesen.
3. Als Nutzer will ich mit ← und → zwischen den Spalten wechseln, mit ↑ und ↓
   innerhalb einer Spalte, damit die Tastaturführung dem entspricht, was das Auge
   sieht.
4. Als Nutzer will ich, dass → auf einem Ordner in die nächste Spalte springt und
   dort die erste Zeile wählt, damit ich mit einer Hand durch den Baum komme.
5. Als Nutzer will ich, dass ← zurück in die vorherige Spalte springt, ohne die
   Auswahl der verlassenen Spalte zu vergessen.
6. Als Nutzer will ich, dass die Ansicht waagerecht mitscrollt und die aktive
   Spalte sichtbar hält, damit ich nie ins Leere navigiere.
7. Als Nutzer will ich, dass eine ausgewählte **Datei** die Spalten rechts davon
   leert, damit keine tote Spalte aus der vorigen Auswahl stehen bleibt.
8. Als Nutzer will ich, dass eine Datei per Doppelklick oder Return geöffnet
   wird, genau wie in der Tabelle.
9. Als Nutzer will ich, dass der Breadcrumb der Top-Leiste dem aktiven Ordner der
   Spaltenansicht folgt, damit die beiden nicht auseinanderlaufen.
10. Als Nutzer will ich, dass Zurück/Vorwärts (⌘←/⌘→, #60) sinnvoll bleiben,
    damit die vorhandene History nicht kaputtgeht.
11. Als Nutzer will ich, dass die Spaltenansicht **pro Pane** gilt, damit links
    ein Baum und rechts eine Tabelle stehen kann.
12. Als Nutzer will ich, dass die Anzeigeart Beenden und Neustart übersteht, wie
    bei #37 — inklusive des Ordners, in dem ich stand.
13. Als Nutzer will ich, dass Kopieren, Verschieben, Löschen, Umbenennen und
    Tags auf die Auswahl in der Spaltenansicht wirken, genau wie in der Tabelle.
14. Als Nutzer will ich in der Spaltenansicht ziehen und ablegen können, wie in
    der Tabelle.
15. Als Nutzer will ich das Kontextmenü mit Rechtsklick bekommen, wie in der
    Tabelle.
16. Als Nutzer will ich QuickLook (Leertaste) benutzen können.
17. Als Nutzer will ich, dass die Spaltenansicht bei einem großen Ordner nicht
    einbricht — auch eine einzelne Spalte kann 50k Einträge haben (#22).
18. Als Nutzer will ich, dass ein Ordner, den ich nicht lesen darf, in seiner
    Spalte eine Meldung zeigt statt leer zu bleiben.
19. Als Nutzer will ich, dass eine Spalte mit leerem Ordner sichtbar leer ist und
    nicht wie ein Ladefehler aussieht.
20. Als Nutzer will ich, dass Änderungen im Dateisystem in den offenen Spalten
    ankommen, wie in der Tabelle (`DirectoryWatcher`).
21. Als Nutzer will ich, dass die Trennlinien zwischen Spalten dieselben sind wie
    in der Kurzansicht, damit die App nicht zwei Raster-Sprachen hat.
22. Als Nutzer will ich drei Symbole sehen — Tabelle, Kurzansicht,
    Spaltenansicht — damit ich weiß, dass es die Ansichten überhaupt gibt.
23. Als Nutzer will ich, dass das Symbol der aktiven Ansicht hervorgehoben ist,
    damit ich ohne Ausprobieren weiß, worin ich gerade bin.
24. Als Nutzer will ich, dass der Umschalter die Ansicht **der Pane** wechselt,
    in deren Kopfzeile er sitzt, nicht die der aktiven Pane — sonst ändert ein
    Klick etwas anderes, als er anfasst.
25. Als Nutzer will ich für die Spaltenansicht auch eine Tastenkombination,
    passend zu ⌘1 für die Kurzansicht.
26. Als Nutzer will ich die Ansichten weiterhin über das Ansicht-Menü und die
    Befehlspalette erreichen.

## Entwurfs-Entscheidungen (2026-08-31, vor dem Bauen)

**Die Kette wird abgeleitet, nicht getrennt gehalten.** Zwei Wege standen zur
Wahl: die Spaltenkette als eigenen Zustand führen, oder sie aus dem einen
`PanelModel.directory` ableiten. Gewählt: **ableiten.**

    spalten(fuer: directory) = [vorfahren von directory ...] + [directory]

Damit ist die letzte Spalte immer der Inhalt von `directory`, und das ist genau
die Spalte, die das Panel ohnehin schon zeigt. Breadcrumb, Kopierziel,
Terminal-Startordner und ⌘←/⌘→ lesen weiterhin denselben einen Wert und
brauchen **keinen Sonderfall**. Die Alternative hätte `directory` mit Spalte 0
in einen Kreis gebracht und Flickwerk an vielen Aufrufstellen erzwungen.

**Die Auswahlregel, ausgedrückt über `directory`:**

    ordner F in Spalte i gewaehlt  ->  directory = F        (Kette waechst)
    datei  X in Spalte i gewaehlt  ->  directory = Ordner(i) (Kette schneidet ab)
                                       selection = {X}

Ein Ordner-Klick zeigt seinen Inhalt rechts daneben, weil `directory` auf ihn
zeigt und die Kette daraus folgt. Ein Datei-Klick in einer mittleren Spalte wirft
die rechten weg, weil die Kette bei dem Ordner endet, in dem die Datei liegt.

**Spalten-Modelle sind ein Cache, kein Neubau je Bild.** Die *Identität* der
Kette ist abgeleitet, die Zeilen darin nicht: jede Spalte braucht ein
`PanelModel` für Inhalt, Sortierung und `DirectoryWatcher`. Diese Modelle werden
nach URL zwischengespeichert. Bei jedem Bild neu zu bauen hieße: jeder Klick
listet jede Spalte neu und meldet jeden Watcher neu an — ein Fehler, der bei 4
Einträgen unsichtbar ist und bei 400 wehtut.

**Spaltenauswahl schreibt KEINE History.** Sonst hinterlässt fünf Ebenen tief
klicken fünf Zurück-Einträge, und ⌘← wird unbrauchbar. Der Finder verhält sich
auch nicht so. Benutzt wird `PanelModel.relocate(to:)` — der vorhandene Weg,
`directory` ohne History-Eintrag zu setzen (bisher für verschwundene Laufwerke,
#41). ⌘← führt damit weiterhin zum vorigen **Ort**, nicht zur vorigen Spalte.

**Persistenz: neues Feld gewinnt, altes trägt weiter.** `PaneState` bekommt
`displayMode: String?` zusätzlich zu `briefColumns: Int?`. Beim Wiederherstellen
wird **zuerst** `displayMode` gelesen und nur bei dessen Fehlen auf
`briefColumns` zurückgefallen. Andersherum wäre still tödlich: eine
Spaltenansicht persistiert mit `briefColumns: nil`, und die alte Regel
`from(briefColumns: nil)` liefert `.table` — jede Spaltenansicht würde beim
Neustart heimlich zur Tabelle. Der #37-Persistenztest fängt das nicht, weil er
den dritten Fall nicht kennt.

**Vorfahren-Kette:** `TopBarView.trail(of:)` rechnet diese Kette bereits für das
Breadcrumb aus. Wiederverwenden statt einen zweiten Weg zu schreiben. Das
Breadcrumb kappt auf die letzten fünf; die Spaltenansicht kappt **nicht**,
sondern scrollt waagerecht und hält die letzte Spalte im Bild (Story 6).

## Implementation Decisions

**Anzeigeart wird zu drei Fällen.** `DisplayMode` (aus #37, heute
`table` / `brief(columns:)`) bekommt `columns` dazu. Die persistierte Form in
`PaneState` ist heute `briefColumns: Int?` — das reicht für drei Fälle nicht mehr.
Ein **zusätzliches** optionales Feld für die Anzeigeart aufnehmen und
`briefColumns` als Parameter der Kurzansicht behalten; altes Blob ohne das neue
Feld liest wie bisher (nil = Tabelle, 1–3 = Kurzansicht). Additiv bleiben,
Regel aus #41.

**Ein Modell je Spalte, kein neues Lademodell.** Jede Spalte ist ein Ordner mit
Zeilen, Auswahl, Sortierung, Watcher — also genau das, was `PanelModel` schon
ist. Die Spaltenansicht hält eine **Kette von Spalten-Modellen** statt ein
eigenes Ladesystem zu erfinden. Das erbt ADR 0003 (`PanelSource`),
`DirectoryWatcher`, Fehler- und Rechte-Behandlung und die Filter-Logik, ohne sie
zu duplizieren.

**Die Kette ist der Zustand.** Auswahl in Spalte *n* schneidet alles ab *n+1* ab
und hängt eine neue Spalte an, falls ein Ordner gewählt wurde. Als Regel:

    waehle(ordner, in: n)  ->  spalten = spalten[0...n] + [neu(ordner)]
    waehle(datei,  in: n)  ->  spalten = spalten[0...n]

Diese eine Regel deckt Vorwärtsgehen, Zurückspringen und Datei-Auswahl ab.

**Das Panel hat weiter genau ein `directory`.** Der Rest der App — Breadcrumb,
Zielordner für Kopieren, Terminal-Startordner, Persistenz — liest diesen einen
Wert. In der Spaltenansicht ist er der Ordner der **aktiven Spalte**. Nicht als
Sonderfall an vielen Stellen, sondern indem die Spaltenansicht das `directory`
des Panels mitzieht.

**Waagerechtes Scrollen hält die aktive Spalte im Bild.** Wie im Finder: die
Ansicht folgt der Navigation, sie wartet nicht auf den Nutzer.

**Der Umschalter sitzt in der Panel-Kopfzeile**, nicht in der Bodenleiste. Die
Bodenleiste trägt Fenster-Umschalter (Sidebar, Preview, Terminal); die
Anzeigeart gehört der einzelnen Pane, und die Kopfzeile ist der einzige Ort, der
schon pro Pane existiert. Damit gilt auch Story 24 von selbst.

**Achtung Bodenleiste (#89):** Klicks in der Kopfzeile lösen keinen Panel-Wechsel
aus — das Kopfband ist bereits ausgenommen. Der Umschalter erbt das, ohne dass
`PanelClickRouter` angefasst werden muss. Nachprüfen, nicht annehmen.

**Symbole:** SF Symbols, dieselbe Sprache wie die vorhandenen Umschalter,
rechteckig, keine Pillen. Naheliegend: `list.bullet` (Tabelle),
`rectangle.split.3x1` (Kurzansicht), `rectangle.split.3x1.fill` oder
`sidebar.squares.right` (Spaltenansicht) — beim Bauen am laufenden Build
ansehen und das Paar wählen, das sich auf einen Blick unterscheidet.

## Testing Decisions

Gute Tests hier greifen die **Kettenregel** ab, nicht das Zeichnen. Die Regel ist
der ganze Verhaltenskern der Ansicht und lässt sich ohne Fenster prüfen.

- **Neue Unit-Tests auf der Spaltenkette:** Ordner in der letzten Spalte wählen
  hängt eine an; Ordner in einer **mittleren** Spalte wählen wirft die rechten
  weg und hängt eine an; Datei wählen wirft die rechten weg und hängt nichts an;
  Auswahl aufheben; leerer Ordner erzeugt eine leere, aber vorhandene Spalte;
  das `directory` des Panels folgt der aktiven Spalte. Vorbild:
  `PanelFocusSelectionTests` (injizierte `PanelSource`, kein Dateisystem) und
  `NavigationHistoryTests` für die Zustands-Übergänge.
- **Persistenz-Tests** in `WorkspaceStateTests` / `PanelModelRestoreTests`:
  Round-Trip der drei Anzeigearten, ein Blob von vor #91 liest als das, was er
  vorher war, ein unbekannter Wert fällt auf Tabelle zurück. Das ist die
  Toleranz-Regel aus #41 und sie hat in #37 schon einmal getragen.
- **Kein UI-Test.** Die UI-Suite ist auf dieser Maschine anfällig (#61).
- **Von Hand am laufenden Build, mit Blick aufs Bild** — der Schritt, dessen
  Auslassen #37 den ersten Anlauf gekostet hat: Baum ablaufen, waagerechtes
  Scrollen, Pfeiltasten, Umschalter-Symbole, ein Ordner ohne Leserecht, ein
  Ordner mit sehr vielen Einträgen. Aufnahme über die CGWindowID, damit die
  Sonde Till nicht den Fokus stiehlt.
- Vor dem Merge die **volle Suite**, nicht nur die neuen Dateien.

## Out of Scope

- **Vorschau in der letzten Spalte** (Finder zeigt dort eine Dateivorschau).
  Diptychon hat dafür die Vorschau-Pane (#14). Später entscheidbar, nicht jetzt.
- **Spaltenbreiten ziehen und merken.** Erst feste Breite; ob das stört, zeigt
  der Gebrauch.
- **Kurzansicht ersetzen.** Beide bleiben, ausdrücklich (Till, 2026-08-31).
- Tabs pro Pane (#38), Auto-Anpassung der Spaltenzahl an die Fensterbreite (#37,
  bewusst offen gelassen).

## Further Notes

- #37 hat den teuren Teil schon bezahlt: `DisplayMode`, die Persistenz-Erweiterung,
  das Menü und die Palette-Einträge stehen. Dieses Ticket hängt eine dritte
  Anzeigeart daneben und macht alle drei sichtbar.
- **Fallstrick aus #37, nicht wiederholen:** ein Layout darf nie
  `collectionView.bounds` lesen, um seine eigene Geometrie zu bestimmen — die
  Größe wird aus `collectionViewContentSize` gesetzt, das ergibt eine
  Rückkopplung. Immer den Viewport (die Clip View) fragen.
- Trennlinien und Zeilenbänder aus #37 wiederverwenden, nicht neu erfinden.
