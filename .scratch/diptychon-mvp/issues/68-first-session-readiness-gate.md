# 68 — Readiness-Gate: was trifft ein Fremder in der ersten Session?

Status: **ready-for-agent**
Category: gtm / qa

## Parent

Strategiewechsel 2026-08-03 (siehe #66): die Website wird von Waitlist auf
öffentlichen Gratis-Download umgestellt. Dieses Ticket ist das Tor davor.

## Warum

Ein Download ist ein echter Commitment-Akt und damit ein viel stärkeres Signal
als eine E-Mail-Adresse. Er hat aber eine Eigenschaft, die ein Signup nicht hat:
**er ist einmalig.** Wer die App lädt, startet und in den ersten Minuten auf
etwas Kaputtes trifft, kommt nicht wieder — und weil Diptychon **bewusst keine
Telemetrie** hat (Datenschutz § 4, nie aufweichen), erfährst du nichts davon.
Kein Crash-Report, kein Absprungsignal, nichts.

Heißt: ein schlechter erster Kontakt ist ein starkes Signal, das du weder lesen
noch rückgängig machen kannst. Deshalb steht dieses Ticket **vor** der
Notarisierung, nicht danach.

## Konkreter Anlass

- **#63 — Tastatur-Selektion stirbt nach jeder ⏎-Navigation (bis zum Klick).**
  Für einen tastaturzentrierten Dual-Pane-Manager ist das ein
  Erste-30-Sekunden-Bug. Die Kernbewegung des Produkts ist „navigieren ohne
  Maus"; genau die bricht.

## Aufgabe

Alle offenen Issues einmal gegen eine einzige Frage triagieren:
**„Trifft das jemand, der die App zum ersten Mal öffnet, ohne zu wissen, wie sie
gedacht ist?"**

Drei Ausgänge pro Issue:
- **blocker** — muss vor dem öffentlichen Download weg
- **nach-launch** — echt, aber kein Erstkontakt
- **egal** — Randfall oder nur mit Testharness erreichbar (z. B. #64, das
  `DIPTYCHON_DIR` betrifft, nicht den echten Nutzer)

Bekannter Stand beim Anlegen: #39, #40, #57 sind `ready-for-agent`;
#58 `needs-triage`; #63 und #64 offen ohne Statuszeile.

## Was zusätzlich zu prüfen ist

Nicht nur Bugs — Erstkontakt-Lücken, die kein Issue haben:
- Was passiert beim allerersten Start ohne gespeicherten `workspaceState`?
- Gibt es irgendwo einen Hinweis auf die Tastaturbelegung, oder muss man sie
  raten? (Keymap existiert, aber ein Fremder kennt sie nicht.)
- Erste-Start-Dialoge von macOS (Ordnerzugriff / TCC) — an welcher Stelle
  kommen sie, und wirkt die App davor kaputt?

## Done heißt

Eine Blocker-Liste in diesem Issue, jedes Element mit Issue-Nummer oder neu
angelegt. Danach entscheidet Till, ob die Blocker gefixt werden oder ob der
Download-Plan wartet.

## Triage-Ergebnis 2026-08-04 (Teil 1: Aktenlage)

**Korrektur zum Anlass oben: #63 ist geschlossen und gefixt** (`fe2f3d1` auf
main, `viewDidMoveToWindow` claimt den Fokus selbst). Ebenso #64. Beide waren
beim Anlegen dieses Tickets fälschlich als offen gelistet — die Statuszeile
steht dort im Format `**Status:** closed`, das der erste Scan nicht erkannt hat.
Der ursprüngliche Hauptblocker existiert also nicht.

### Blocker — muss vor dem öffentlichen Download weg

**B1 — Die Tastaturbelegung ist in der App nicht auffindbar.**
`DiptychonApp.swift` hat **keinen `.commands { }`-Block**. Die App läuft mit der
SwiftUI-Standard-Menüleiste: kein Hilfe-Eintrag, kein „Keyboard Shortcuts…",
kein Verweis auf irgendeine Doku. `docs/keyboard-reference.md` (85 Zeilen,
aus `Keymap.default` generiert) liegt **im Repo, nicht im App-Bundle** — wer ein
Zip lädt, sieht es nie.

Die Belegung *ist* einsehbar: Command-Palette (⌘K, #19) und der
Shortcut-Editor in den Einstellungen (⌘, #44). Beides setzt aber voraus, dass
man ⌘K oder ⌘, schon kennt. Für ein Produkt, dessen ganzes Versprechen
„Keyboard-first" ist, ist das der teuerste denkbare Erstkontakt: der Nutzer
findet die eine Sache nicht, die ihn überzeugen würde.

Kleinster Fix: `.commands`-Block mit einem Hilfe-Eintrag, der die
Keyboard-Referenz zeigt (Fenster oder Link). Nicht die ganze #42-Doku.

**B2 — #42 Docs & Onboarding hängt seit 2026-07-03 im Review.**
Tier-2-Entwurf liegt fertig da: `README.md` (149 Z.), `docs/user-guide.md`
(149 Z.), `docs/keyboard-reference.md` (85 Z.) — nie durchgesehen. Das Issue
zitiert die Netnographie: zwei Konkurrenzprodukte wurden **explizit wegen der
Doku** verworfen („*such pathetic docs binned it*", S3/S5), trotz echtem
Interesse. Das ist genau die Zielgruppe, die den Gratis-Download zieht.
Braucht keine Entwicklung, nur Tills Durchsicht.

**~~B3 — #53: Löschen bricht die Tastatur-Schleife.~~ ENTFÄLLT.**
Ebenfalls erledigt und gemergt (`70cb7a2`, `pendingReselect` in
`PanelModel.swift:131`). Die Statuszeile stand noch auf `ready-for-human`,
während der Outcome-Block im selben File den Merge dokumentierte.

### Methodischer Befund (wichtiger als die Einzelbefunde)

Drei von vier Kandidaten — #63, #64, #53 — waren **bereits gefixt und gemergt**,
standen aber offen. In allen drei Fällen sagte der **Outcome-Block** die
Wahrheit und die **Statuszeile** war alt. Zusätzlich waren #43 und #57 faktisch
geliefert bzw. abgelöst, ohne geschlossen zu sein.

Heißt für jede künftige Triage: **Outcome-Block schlägt Statuszeile.** Und die
End-of-Task-Regel („Triage-Label setzen + Outcome-Notiz") wird offenbar zur
Hälfte befolgt — die Notiz kommt, das Label nicht. Wer das automatisieren will:
ein Check, der Issues mit gefülltem Outcome, aber offenem Status meldet.

Nach der Korrektur bleibt von den Blockern **nur B1** übrig. Das Produkt ist
deutlich näher an erstkontakt-tauglich, als die offene Ticketliste aussehen
ließ.

### Nach-Launch — echt, aber kein Erstkontakt

#34 (Slice 2+, Evaluations-Gate läuft ohnehin noch) · #35 Disk Usage ·
#37 Brief-Modus · #38 Tabs · #39 Recent Locations · #47 PTP/MTP ·
#49 URL-Schema · #50 Archive · #54 Reveal-Default · #56 globaler Hotkey ·
#58 Rename via Breadcrumb.

**#40 (Ladepfad, 50k)** bewusst hier und nicht bei den Blockern: gemessen
~4,6 s bis Liste / ~6,5 s interaktiv bei 50.000 Einträgen. Ordner dieser Größe
sind im Erstkontakt selten; blockiert nie die UI. Wird zum Blocker, sobald die
Copy irgendwo „instant" behauptet — genau der Grund, aus dem die Behauptung in
#22 zurückgezogen wurde.

### Egal / erledigt

- **#48 Usage-Insight-Instrumentation** — widerspricht der Keine-Telemetrie-
  Position (Datenschutz § 4) und ist durch **#72** abgelöst. Sollte geschlossen
  werden, sonst liest es sich wie ein offener Plan, Nutzung zu messen.
- **#64** — betrifft nur `DIPTYCHON_DIR`, also den Testharnisch, nicht den
  echten Nutzer. Ohnehin geschlossen.

### Tracker-Hygiene (fällt nebenbei an)

Zwei Issues stehen offen, sind aber faktisch geliefert:
- **#43 Local instant search** (`needs-triage`) — `RecursiveSearch.swift` +
  `FuzzyMatch.swift` sind auf main.
- **#57 Open in Terminal** (`ready-for-agent`) — durch das eingebettete
  Terminal (#65, `4043372`) abgelöst; auf dem verwaisten Branch
  `claude/open-tickets-triage-r8tzl1` liegt eine zweite, nie gemergte Lösung.

## Ablauf für Teil 2 (terminiert 2026-08-04, 17:00)

Vorbereitet, damit der Lauf nicht an einem Gesprächskontext hängt.

**Vorher**
1. Tills laufende Instanz beenden — **pid am Start merken und nur die killen**.
   Kein `pkill -f`, kein `killall`: das Muster trifft Tills eigenes Diptychon
   und hat es schon einmal erwischt.
2. Frischen Build von main nehmen. Gleiche Bundle-ID heißt: läuft noch eine
   Instanz, holt `open` nur die alte nach vorn und der Lauf misst nichts.
3. Seed-Ordner anlegen und `DIPTYCHON_DIR` setzen — das schaltet zugleich die
   Persistenz ab (`WorkspaceModel.swift:246`), man bekommt also verlässlich
   einen Erstlauf-Zustand, ohne Tills echten `workspaceState` anzufassen.
4. Fenster auf {60,60} schieben; auf einem Zweitmonitor greifen die
   Klick-Koordinaten daneben. Werkzeug: `.scratch/demo-video/harness/poke`.

**Zu beobachten — die vier offenen Fragen**
- **Allererster Start ohne gespeicherten Zustand:** was steht da? Wirkt es
  leer, kaputt oder absichtlich?
- **macOS-Zugriffsdialoge:** an welcher Stelle kommen sie, und sieht die App
  davor so aus, als würde sie nichts können? Der Full-Disk-Access-Pfad aus #10
  ist gebaut — die Frage ist das Timing, nicht die Existenz.
- **Zwei-Panel-Anordnung ohne Vorwissen:** ist erkennbar, dass es zwei Seiten
  gibt, welche aktiv ist und wie man wechselt?
- **Restliche Standardmenüs** (Ablage/Bearbeiten/Darstellung/Fenster): führt
  ein Eintrag ins Leere? Nur das Hilfe-Menü ist bisher angesehen (#74).

**Nachher**
Ergebnis als Blocker-Liste unten anhängen, jeder Punkt mit Issue-Nummer oder
neu angelegt. Erst dann ist das Gate durch.

## Teil 2 — Ergebnis (2026-08-04, vorgezogen)

**Methode.** Tills laufende Instanz wurde *nicht* angefasst. Stattdessen der
Debug-Build kopiert, `CFBundleIdentifier` der Kopie auf `com.diptychon.probe1`
gesetzt und ad-hoc neu signiert. Eigene Bundle-ID heißt eigene
UserDefaults-Domain (`defaults read` bestätigte: „does not exist") — also ein
**echter** Erstlauf ohne gespeicherten `workspaceState`, ohne Tills Zustand zu
berühren und ohne Bundle-ID-Kollision. Fensterbilder gezielt per CG-Window-ID,
nie der ganze Bildschirm. Menüs über System Events ausgelesen statt geklickt.

### T1 — Blocker: beide Panels zeigen beim Erstlauf denselben Ordner

Der allererste Start öffnet **links und rechts das Home-Verzeichnis**. Zwei
identische Listen nebeneinander. Genau in dem Moment, in dem das Produktkonzept
landen müsste, sieht es aus wie ein Darstellungsfehler oder eine sinnlose
Verdopplung — nicht wie zwei unabhängige Arbeitsflächen.

Sobald man in einem Panel navigiert, wird die Sache sofort klar (links Desktop,
rechts Home, aktives Panel blau umrandet). Das Konzept ist also gut gebaut und
schlecht eingeführt. Kleinster Fix: unterschiedliche Startordner, etwa links
Home und rechts Dokumente.

### T2 — Blocker: das Bearbeiten-Menü behauptet, die App könne nichts

Ausgelesener Zustand: **Undo, Redo, Cut, Copy, Paste, Delete sind alle
dauerhaft `enabled: false`**, also grau. Nur „Select All" ist aktiv.

Die App kann all das — über ⌘Z, ⌘C, ⌘V, ⌘⌫. Das Menü sagt das Gegenteil, und
zwar über genau die Eigenschaft, die ADR 0004 zur Kernidee erklärt
(umkehrbare Operationen). Wer als Erstnutzer ins Menü schaut, liest dort:
dieses Programm kann nicht kopieren und nichts rückgängig machen.

Gleiche Wurzel wie B1: der `NSEvent`-Monitor besitzt die Tastatur, an die
Responder-Chain ist nichts angeschlossen. Der Fix in #74 hat die Tür zur
Tastaturbelegung gebaut, aber die Menüs selbst stimmen weiter nicht.

### T3 — Fenster-Tabbing in einer App ohne Tabs

„Show Tab Bar" und „Show All Tabs" (Darstellung) sowie „Show Previous Tab",
„Merge All Windows", „Remove Window from Set" (Fenster) sind aktiv. Das ist
AppKits automatisches Fenster-Tabbing. Diptychon hat kein Tab-Konzept
(#38 steht auf `needs-triage`), und wer das anklickt, bekommt eine
Systemfunktion, die zur Zwei-Panel-Anordnung quer steht.

### T4 — das Produkt kommt in der Menüleiste nicht vor

Vollständige Menüs: Diptychon (Standard), Ablage (New Window/Close/Close All),
Bearbeiten (grau, siehe T2), Darstellung (Tabs/Vollbild), Fenster (Standard),
Hilfe (**„Keyboard Shortcuts…"** — der #74-Fix, hier unabhängig von XCUITest
bestätigt).

Nirgends: Navigation (zurück/vorwärts/aufwärts), Neuer Ordner, Umbenennen,
Vorschau, Ausgeblendetes zeigen, Terminal, Staging, Gadgets. Wer die App über
die Menüleiste erkundet — der klassische Mac-Reflex — findet das Produkt nicht.

### T5 — **beantwortet 2026-08-04 durch Till: die Dialoge kommen.**

Till hat eine Kopie mit frischer Bundle-ID per Doppelklick im Finder gestartet
— verantwortlicher Prozess also Finder, nicht mein Terminal — und **es kamen
Berechtigungsdialoge**.

Damit ist der Befund unten widerlegt: die Probe hatte den Zugriff geerbt. Für
einen Fremden gilt das Gegenteil dessen, was meine Messung zeigte. Ebenfalls
von Till im selben Lauf bestätigt: **beide Panels starteten auf demselben
Ordner** (T1), unabhängig von meiner Messung.

Noch offen und für #75 entscheidend: **an welcher Stelle** die Dialoge kommen —
schon beim Auflisten von Home, oder erst beim Betreten von Desktop/Dokumente/
Downloads. Davon hängt ab, ob ein Startordner überhaupt frei wählbar ist.

### T5 — die ursprüngliche, widerlegte Messung

Die Probe hat Desktop und Dokumente **ohne jeden Dialog** gelistet. Das ist
aber kein Ergebnis: die Probe wurde aus meiner Shell gestartet, und die darf
Desktop und Dokumente bereits (nachgeprüft; Full Disk Access hat sie nicht,
aber die Ordner-Dienste sind eigene TCC-Einträge). macOS rechnet den Zugriff
teils dem verantwortlichen Elternprozess zu, die Probe hat also vermutlich
geerbt.

**Wie es sauber geht:** Till startet
`…/scratchpad/probe/DiptychonProbe.app` einmal per Doppelklick im Finder —
dann ist der verantwortliche Prozess nicht mein Terminal. Dreißig Sekunden,
und die Frage ist beantwortet.

### T6 — Nachtrag 2026-08-04: der Kaltstart braucht länger als gedacht

Beim Bauen von #75 aufgefallen und mit einer Gegenprobe abgesichert: im
Erstlauf steht das Home-Panel nach **4 und nach 8 Sekunden** noch auf
„Loading…" und ist erst zwischen 8 und 16 Sekunden fertig. Der Kontrolllauf mit
dem alten Verhalten (beide Panels auf Home) zeigt dasselbe — es liegt nicht an
#75.

Einordnung mit Vorsicht: der allererste Probelauf am selben Tag hatte Home nach
4 Sekunden vollständig gelistet. Zwischen den Läufen liegen viele App-Kopien
und Signaturen auf derselben Maschine, das kann Spotlight oder Gatekeeper
beschäftigt haben. **Vor einer Bewertung auf einer ruhigen Maschine
nachmessen.**

Falls es sich bestätigt, ist es ein Erstkontakt-Blocker eigener Güte: acht
Sekunden Spinner statt des eigenen Home-Ordners ist das erste, was ein Fremder
sieht. Gehört dann zu #40 (Ladepfad), das bisher nur den 50k-Fall betrachtet.

### Positiv, ohne Fund

- Aktives Panel ist mit blauem Rahmen klar markiert
- Der leere Zustand ist ehrlich beschriftet („PINNED — No pinned folders")
- Die Liste steht sofort da, kein Ladehänger, kein Leerbild

## Werkzeuge aus Teil 2 (wiederverwendbar)

Im Scratchpad gebaut, weil `poke` andere Argumente erwartet:

- `winid <pid>` — CG-Window-IDs und Rahmen eines Prozesses; Grundlage für
  `screencapture -l<id>`, damit nie der ganze Bildschirm im Bild landet
- `rclick <pid> <dx> <dy> [klicks]` — Klick **relativ zum Fenster**, gemessen
  **nach** dem Aktivieren. Der erste Anlauf hat vorher gemessen und danach
  aktiviert; das Fenster wandert beim Aktivieren, und der Klick landete zwei
  Zeilen daneben (öffnete `Public` statt `Desktop`). Reihenfolge ist der Fix
- `key <pid> <keycode>` — CGEvent-Taste; erreicht den `NSEvent`-Monitor

Die Bundle-ID-Kopie ist der eigentliche Trick: eigene Defaults-Domain =
echter Erstlauf, kein Anfassen des laufenden Diptychon.

## Outcome — **Gate ist noch OFFEN**

Teil 1 (Aktenlage) fertig, 2026-08-04. Von drei vermuteten Blockern haben zwei
sich als Karteileichen erwiesen (#63, #53 längst gemergt). Übrig:

- **B1** → adressiert in **#74**: `.commands`-Block mit Hilfe ▸ Keyboard
  Shortcuts…, per UI-Test durch den echten Aufrufpfad belegt, volle Suite grün
  (216 Unit + 14 UI). Uncommitted.
- **B2** → **#42**: die Doku ist nicht nur ungeprüft, sondern falsch
  (dokumentiert `⌘[`/`⌘]`, seit #60 gilt ⌘←/⌘→; vier Features fehlen ganz).
  Generator neu laufen lassen, Platzierung entscheiden.

Teil 2 (empirischer Erstlauf) ebenfalls am 2026-08-04 gelaufen, vorgezogen.
Er hat zwei Blocker gefunden, die in keinem Ticket standen:

- **T1** — Erstlauf zeigt links und rechts denselben Ordner; das Zwei-Panel-
  Konzept ist genau im ersten Moment unsichtbar
- **T2** — Bearbeiten-Menü hat Undo/Redo/Cut/Copy/Paste/Delete dauerhaft grau,
  obwohl die App all das kann. Das Menü behauptet das Gegenteil des Produkts

Dazu zwei Warzen ohne Blocker-Rang (**T3** natives Fenster-Tabbing in einer App
ohne Tabs, **T4** kein einziger Produkt-Befehl in der Menüleiste) und eine
**offene Frage**: **T5**, das TCC-Timing, ist nicht belastbar geprüft — die
Probe lief aus einer Shell, die Desktop und Dokumente schon darf, und hat den
Zugriff vermutlich geerbt.

### Offene Blocker-Liste (das Gate)

| | | |
|---|---|---|
| **B1** | Tastaturbelegung nicht auffindbar | ✅ #74, gemergt |
| **B2** | Doku falsch und nicht platziert | offen, #42 |
| **T1** | Erstlauf zeigt zweimal denselben Ordner | offen, **#75** |
| **T2** | Bearbeiten-Menü widerspricht dem Produkt | offen, **#76** (mit T3/T4) |
| **T5** | TCC-Timing ungeprüft | offen, 30 s bei Till |

**#69 und #71 dürfen erst starten, wenn diese Liste leer ist** — sonst
verspricht die Website einen Download, dessen erste dreißig Sekunden gegen das
Produkt arbeiten.
