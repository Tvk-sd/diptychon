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

## Reproduktion (nur bei Till)

Von hier aus **nicht messbar**: ein aus dem Terminal gestarteter Prozess erbt
die TCC-Zuordnung des Elternprozesses, und meine Shell darf Schreibtisch und
Dokumente bereits. Deshalb:

1. Debug-Build kopieren, `CFBundleIdentifier` der Kopie auf einen frischen Wert
   setzen, ad-hoc neu signieren (Ablauf in #68 › Methode)
2. `defaults read <neue-id>` muss „does not exist" melden
3. **Im Finder doppelklicken**, nicht per `open` aus einer Shell
4. Notieren: wie viele Dialoge, für welche Ordner, in welcher Reihenfolge, und
   wie die App zwischen den Dialogen aussieht

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
