# 77 — Drei Berechtigungsdialoge direkt beim Start

Status: **ready-for-human** (Reproduktion und Beobachtung nur bei Till möglich)
Category: bug / onboarding / trust

## Parent

`#68` Readiness-Gate, Befund **T5**, präzisiert durch Tills Beobachtung
2026-08-04: die Dialoge kommen **direkt beim Start**, nicht erst beim Betreten
eines geschützten Ordners.

## Warum das mehr ist als eine Warze

Ein frisch heruntergeladenes Programm fragt, **bevor der Nutzer irgendetwas
getan hat**, nach Zugriff auf Schreibtisch, Dokumente und Downloads. Das ist
nicht nur Reibung im Erstkontakt — es widerspricht der Positionierung. Diptychon
wirbt mit „keine Telemetrie" und Datensparsamkeit (ADR 0006, Datenschutz § 4);
drei ungefragte Zugriffsanfragen in der ersten Sekunde lesen sich als das
Gegenteil, und zwar bei genau der Zielgruppe, die darauf achtet.

Dazu kommt: der Nutzer kann die Frage in dem Moment nicht beantworten. Er weiß
noch nicht, was das Programm tut. Ein „Nicht erlauben" ist die sichere Antwort,
und danach wirkt die App kaputt.

## Was der geplante Weg war

ADR 0001 sieht **Full Disk Access** vor, einmal in den Systemeinstellungen
erteilt — der Weg prompt**et** nie. #10 hat den Onboarding-Pfad dafür gebaut
(Erkennung, Menüeintrag, Wiederaufnahme nach Erteilung). Die Einzelordner-
Dialoge sind der Fallback des Systems, den wir gar nicht wollten, und sie
kommen **vor** dem Onboarding statt danach.

Das eigentliche Thema ist also nicht „welcher Startordner", sondern das
**Timing**: irgendetwas fasst geschützte Ordner an, bevor das Onboarding
erklärt hat, worum es geht.

## Was zu untersuchen ist

Ausgeschlossen: `SidebarPlace.standard` (`SidebarView.swift:14-30`) löst über
`FileManager.url(for:in:appropriateFor:create:)` nur Pfade auf und liest keine
Inhalte — das allein löst keinen Dialog aus.

Verdächtige, in dieser Reihenfolge zu prüfen:

1. **Zeilen-Metadaten beim Auflisten von Home.** Die Home-Liste enthält die
   Zeilen Desktop, Dokumente, Downloads. Werden dafür Icons oder
   `URLResourceValues` geholt, greift das *in* den Ordner (ein eigenes
   Ordner-Icon liegt als Datei darin) — und genau das promptet.
2. **`FullDiskAccess`-Probe** (`FullDiskAccess.swift:17`) liest
   `~/Library/Application Support/com.apple.TCC/TCC.db`. Sollte still
   fehlschlagen, ist aber zeitlich am Start und gehört verifiziert.
3. **Geräte-/Volume-Enumeration** beim Start (#46/#59).
4. **Wiederherstellung des `workspaceState`** — zeigte ein Panel zuletzt auf
   einen geschützten Ordner, wird er beim Start gelesen. Erklärt allerdings
   nicht den Erstlauf mit leerer Domain.

## Code-Untersuchung 2026-08-10 — alle vier Verdächtigen entlastet

| Verdacht | Befund |
|---|---|
| 1 Zeilen-Metadaten | `LocalDirectorySource.load()` holt `resourceValues` + FinderTags nur auf den Kind-**Einträgen** von Home (stat/xattr auf dem Ordner-Knoten), nicht in ihnen. Zeilen-Icons kommen aus `FileIconProvider` — **typ-basiert** (`NSWorkspace.icon(for: UTType)`), nie pfad-basiert; `icon(forFile:)` existiert nur im Open-With-Menü (Nutzeraktion) |
| 2 FDA-Probe | `FullDiskAccess` liest ~/Library/Safari, läuft aber erst bei `windowDidBecomeActive`, nicht beim Start — und ~/Library ist nicht Desktop/Documents/Downloads |
| 3 Volume-Enumeration | `mountedDeviceVolumes()` läuft im `init`, fasst aber nur `/Volumes/*` an |
| 4 State-Restore | reiner UserDefaults-Read; Erstlauf hat ohnehin leere Domain |

Sidebar zusätzlich geprüft: `url(for:in:appropriateFor:create: false)` — reine
Pfadauflösung, kein Zugriff. `DirectoryWatcher` öffnet nur die zwei gelisteten
Ordner (Home, /Applications).

**Folgerung:** kein expliziter Griff in die drei Ordner im eigenen Code. Der
Auslöser sitzt in Framework-Internals (AppKit/SwiftUI-Prefetch oder ein
TCC-gated Syscall auf den Ordner-Knoten selbst) und ist nur empirisch zu
fassen. Deshalb ist die Reproduktion jetzt vorbereitet:

## Reproduktion (vorbereitet 2026-08-10, Beobachtung bei Till)

Von hier aus **nicht messbar**: ein aus dem Terminal gestarteter Prozess erbt
die TCC-Zuordnung des Elternprozesses, und meine Shell darf Schreibtisch und
Dokumente bereits. Deshalb:

Steht bereit: **`/Applications/Diptychon77.app`** — Release-Build von main mit
frischer Bundle-ID (`com.diptychon.probe77.…`, leere Defaults-Domain, ad-hoc
signiert). Skripte im Session-Scratchpad (`probe77-setup.sh` zum Neubauen,
`probe77-capture.sh` für den TCC-Log-Mitschnitt).

Ablauf (2 Minuten):

1. Capture-Skript starten (nimmt 90 s `log stream` auf `com.apple.TCC` auf)
2. **Diptychon77 im Finder doppelklicken** — nicht per `open`/Terminal, sonst
   erbt der Prozess die TCC-Rechte der Shell
3. Notieren: wie viele Dialoge, welche Ordner, welche Reihenfolge, wie die App
   dazwischen aussieht
4. Der Mitschnitt (`/tmp/probe77-tcc.log`) liefert die `kTCCService…`-Namen und
   das Timing — daraus lässt sich der Auslöser dem Startpfad zuordnen

## Lösungsrichtungen (noch nicht entschieden)

- **Nichts Geschütztes beim Start anfassen.** Der erste Dialog kommt dann, wenn
  der Nutzer selbst auf „Schreibtisch" klickt — ein Moment, in dem die Frage
  offensichtlich zu seiner Handlung gehört. Wahrscheinlich die richtige Antwort,
  wenn Verdacht 1 zutrifft.
- **Onboarding zuerst.** Der #10-Pfad erklärt Full Disk Access, bevor
  irgendetwas Geschütztes berührt wird. Teurer, und ein Erklärschirm beim
  allerersten Start ist selbst Reibung.
- **Beides:** nichts anfassen, und im leeren Zustand einen ruhigen Hinweis
  zeigen, statt zu fragen.

## Verhältnis zu #75

#75 (verschiedene Startordner) bleibt gültig und wird **nicht** von diesem
Ticket blockiert — links Home, rechts `/Applications`, beide ungeschützt. Es
löst dieses Problem aber auch nicht: der Dialog kommt beim Auflisten von Home,
nicht wegen des zweiten Panels.

## Outcome

_(offen)_
