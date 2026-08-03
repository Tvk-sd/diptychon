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

## Noch offen — Teil 2: der empirische Erstlauf

Die Aktenlage kann nur beantworten, was jemand schon aufgeschrieben hat. Drei
Fragen aus der Aufgabenstellung brauchen einen echten Start:

- allererster Start **ohne** gespeicherten `workspaceState` — was sieht man?
- an welcher Stelle kommen die macOS-Zugriffsdialoge, und wirkt die App davor
  kaputt?
- ist ohne Vorwissen erkennbar, dass es zwei Panels gibt und wie man wechselt?

Läuft über den Probe-Harnisch (`DIPTYCHON_DIR`-Seed, Fenster auf {60,60},
`poke`). Greift Tills Bildschirm ab, deshalb nicht nebenbei.

## Outcome — **Gate ist noch OFFEN**

Teil 1 (Aktenlage) fertig, 2026-08-04. Von drei vermuteten Blockern haben zwei
sich als Karteileichen erwiesen (#63, #53 längst gemergt). Übrig:

- **B1** → adressiert in **#74**: `.commands`-Block mit Hilfe ▸ Keyboard
  Shortcuts…, per UI-Test durch den echten Aufrufpfad belegt, volle Suite grün
  (216 Unit + 14 UI). Uncommitted.
- **B2** → **#42**: die Doku ist nicht nur ungeprüft, sondern falsch
  (dokumentiert `⌘[`/`⌘]`, seit #60 gilt ⌘←/⌘→; vier Features fehlen ganz).
  Generator neu laufen lassen, Platzierung entscheiden.

**Das Gate ist damit nicht durch.** Teil 2 — der empirische Erstlauf — hat nicht
stattgefunden. Solange er fehlt, sind drei Fragen unbeantwortet, die kein
Ticket beantworten kann: erster Start ohne `workspaceState`, Timing der
macOS-Zugriffsdialoge, und ob die Zwei-Panel-Anordnung ohne Vorwissen lesbar
ist. Zusätzlich offen aus #74: die übrigen SwiftUI-Standardmenüs
(Ablage/Bearbeiten/Darstellung/Fenster) sind nie daraufhin angesehen worden, ob
ein Eintrag ins Leere führt.

**#69 und #71 dürfen erst starten, wenn Teil 2 gelaufen ist** — sonst verspricht
die Website einen Download, dessen Erstkontakt nie jemand angesehen hat.
