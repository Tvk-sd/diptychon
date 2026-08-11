# 80 — KV-Auswertung: Downloads und Freitext lesen

Status: **ready-for-human** (Skript steht, Lesen und Deuten ist Tills Job)
Category: gtm / measurement

## Parent

Folge von **#71** (Flip live seit 2026-08-11) — setzt um, was **#70** (Zähler
pro Kanal), **#72** (Feedback-Weg) und **#73** (Downloads statt Signups als
Messgröße) angelegt haben. ADR 0008: die Website verteilt und lernt.

## Was es ist

`scripts/read-funnel.sh` — liest den KV-Store der Landing Page, nur lesend:

- Downloads gesamt (`total`), pro Tag (`day:*`), pro Kanal (`downloads:src:*`)
- Signups (`signups:*`) — Alt-Zähler plus neue Rückrufnummer
- **Freitext/Wishes** (`signup:*` JSON) — der eigentliche Lernstoff (#72),
  entscheidet laut PLAN über das Auftauen von #39/#40
- Abzugsposten-Block: bekannte Test-Treffer, damit niemand meine
  Verifikations-Downloads als Nutzer liest

Aufruf: `./scripts/read-funnel.sh` (wrangler-Login vorausgesetzt). Ausgabe
ist als kopierbares Snippet für dieses Ticket gebaut.

## Erster Snapshot (2026-08-11, ~1 h nach dem Flip)

```
total: 31 · signups:total: 1 (tillnic@web.de, Testeintrag)
Tag         Downloads
2026-08-10  7    (davon ~4 Verifikation/Abnahme #69)
2026-08-11  16   (davon ~2 Verifikation; Rest siehe Vorbehalt)
Kanäle: home-hero 4 · home-final 4 · home-nav 3 · direct 5 ·
        forklift 2 · pathfinder 2 · tcmac 1 · vs 1 · acceptance 1
```

## Vorbehalte — vor jedem Schluss lesen

1. **Kein Bot-Filter, kein Dedupe** (#48-Bauentscheid: raw GETs). Die
   CTA-Kanäle sind seit heute Nacht live; Crawler folgen frisch deployten
   Links. 16 „Downloads" in der ersten Stunde nach Mitternacht sind mit
   hoher Wahrscheinlichkeit überwiegend Maschinen. Erst Tages-Muster über
   eine Woche lesen, nicht Einzelstunden
2. **Test-Treffer abziehen** — Liste steht im Skript-Output und in #69.
   Kuriosum dokumentiert: der `src=release-check`-Download vom 2026-08-10
   wurde nie gezählt (Key existiert nicht; vermutlich Edge-Cache-Antwort,
   bevor der Worker-Zähler lief). Zähler sind Näherungen, keine Buchhaltung
3. **Ein Download ist ein Commitment-Signal, kein Nutzer.** Ob jemand die
   App startet und behält, sieht niemand — bewusst, kein Telemetry (ADR
   0006). Das stärkste Signal bleibt Freitext (#72)

## Was Till entscheidet

- **Rhythmus:** Vorschlag wöchentlich einmal laufen lassen, Snapshot hier
  anhängen. Täglich schauen lohnt erst bei echtem Traffic-Ereignis (Post,
  Outreach)
- **Schwellen:** ADR 0008 hat bewusst keine GO/STOP-Zahl mehr — was hier
  herauskommt, steuert Reihenfolge (#39/#40-Auftauen, #66-Preisfrage),
  nicht Existenzentscheidungen
- Ob die Bot-Frage ein eigenes Ticket wird (User-Agent-Filter im Worker
  wäre ~10 Zeilen, kostet aber die #48-Einfachheit)

## Done heißt

Es gibt einen wiederholbaren, dokumentierten Lesebefehl; der erste echte
Wochen-Snapshot steht in diesem Ticket; und mindestens eine Entscheidung
(auftauen, Preis, Bot-Filter) hat sich auf diese Daten gestützt.

## Outcome

_(offen)_
