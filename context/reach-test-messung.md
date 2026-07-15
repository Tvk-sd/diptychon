# Reach-Test — Messung: wo die Zahlen liegen und wie du sie liest

> Angelegt 2026-07-13. Das Nachschlage-Doc zu Issue #55: alle Datenquellen,
> alle Kommandos, alle Berechnungen. Quelle der Wahrheit für Signups ist
> **unser eigener KV-Speicher**, nicht Google, nicht Cloudflare-Analytics.
> (Technik dahinter: `.scratch/landing-page/src/worker.js`, ~85 Zeilen.)

## Die drei Datenquellen auf einen Blick

| Quelle | Wo | Beantwortet | Vertrauen |
|---|---|---|---|
| **KV-Zähler** (first-party) | Cloudflare KV, via `wrangler`-CLI | Signups gesamt + pro Kanal, Wünsche, Downloads | Hoch — zählt echte Eintragungen |
| **Google Ads Dashboard** | [ads.google.com](https://ads.google.com) → Kampagne | Klicks + Ausgaben (je Anzeigengruppe) | Hoch für Klicks/Kosten; sieht Signups NICHT |
| **Cloudflare Server-Statistik** | [dash.cloudflare.com](https://dash.cloudflare.com) → diptychon.com → **Analytics & Logs → Traffic** | grobe Besuchslage | Niedrig — nur Diagnose. Bots inflationieren („75 Visits" an Tag 1 waren ≈ Scanner-Bots). NICHT „Web Analytics" verwenden (deaktiviert, würde Datenschutz § 4 brechen) |

## 1 · KV-Zähler lesen (die Signup-Wahrheit)

Alle Kommandos **aus diesem Ordner** ausführen (dort liegt die Wrangler-Config):

```bash
cd "/Users/Till/Projects/untitled folder/.scratch/landing-page"
```

**Was existiert im KV:**

| Key | Inhalt |
|---|---|
| `signups:total` | Signups gesamt (Zahl) |
| `signups:src:<kanal>` | Signups pro Kanal (Zahl) — Kanal = `gads`, `vs`, `direct`, `xda`, `sweetbits`, `fileminutes`, `tokie`, `mqdir`, `empiric` |
| `signup:<email>` | Einzel-Datensatz: `{ts, wishes[], src}` (Zeitpunkt, Wünsche, Erst-Kanal) |
| `total`, `day:YYYY-MM-DD` | Download-Zähler (Issue #48, für den Reach-Test sekundär) |

Ohne `?src=` im Link zählt ein Signup als `direct`. Es gilt der **Erst-Kontakt**:
ein späterer Wishes-Klick überschreibt den Kanal nie. Roundup-Traffic landet oft
als `direct`, weil Autoren die nackte Domain verlinken — `direct`-Anstieg nach
einer Erwähnung gehört also gedanklich zum Outreach.

**Alle Zähler auf einmal ansehen:**

```bash
npx wrangler kv key list --binding DOWNLOADS --remote
```

**Einen bestimmten Zähler lesen** (Beispiel Google Ads):

```bash
npx wrangler kv key get "signups:src:gads" --binding DOWNLOADS --remote
```

**Alle Signup-Datensätze inkl. Wünschen dumpen** (für Wishes-Verteilung +
Remote-Anteil; Ausgabe enthält E-Mail-Adressen → lokal behalten):

```bash
for k in $(npx wrangler kv key list --binding DOWNLOADS --remote | grep -o '"signup:[^"]*"' | tr -d '"'); do
  echo "$k → $(npx wrangler kv key get "$k" --binding DOWNLOADS --remote)"
done
```

**Widerruf umsetzen** (Zusage aus Datenschutz § 3 — Eintrag löschen):

```bash
npx wrangler kv key delete "signup:<email>" --binding DOWNLOADS --remote
```

Ehrlichkeits-Fußnote: die `signups:*`-Zähler zählen Eintragungen und werden bei
einem Widerruf nicht zurückgerechnet — bei einzelnen Widerrufen egal, bei vielen
im Kopf behalten.

## 2 · Google Ads lesen

[ads.google.com](https://ads.google.com) → Kampagne → Anzeigengruppen-Ansicht:
**Klicks** und **Kosten**, getrennt für Competitor-Intent und Category-Intent.
Mehr braucht es nicht — Google sieht die Signups absichtlich nicht (kein
Conversion-Tag, Entscheidung siehe `google-ads-setup.md`).

## 3 · Die Berechnungen (wöchentlich, ~10 Minuten)

```
Capture-Rate(gads)   = signups:src:gads ÷ Ads-Klicks            → Ziel: ≥ 8 % (Competitor-Intent)
Cost-per-Signup      = Ads-Ausgaben ÷ signups:src:gads          → Ziel: ≤ €5
Capture organisch    = signups:src:<kanal> je Outreach/vs/direct → Vergleichswert ohne Klick-Nenner
Wishes-Verteilung    = Häufigkeit je Wunsch aus dem Signup-Dump  → validiert JTBD-Ranking
Out-of-Segment-Anteil= Anteil Datensätze mit Wunsch „remote"     → hoch = Traffic passt nicht zum Produkt
```

**GO-Bar (fixiert 2026-07-12, nicht rückwirkend ändern):** Competitor-Intent
≥ 8 % Capture bei ≤ €5 pro Signup, gelesen nach 2 Wochen →
GO / ITERATE / STOP. **Ergebnis + Zahlen gehören in Issue #55**
(`.scratch/diptychon-mvp/issues/55-reach-test-execution.md`, Abschnitt Outcome).

## 4 · Wochenritual (Checkliste)

1. `signups:src:*` lesen (Kommando oben) und notieren.
2. Ads-Dashboard: Klicks + Kosten je Anzeigengruppe notieren.
3. Capture-Rate + Cost-per-Signup ausrechnen (Formeln oben).
4. Signup-Dump: Wishes zählen, Remote-Anteil prüfen.
5. Zahlen als Zeile in #55 unter „Outcome" anhängen (Datum + Werte).

Abkürzung: Claude in diesem Ordner fragen — „lies die Reach-Test-Zahlen" reicht,
das Doc hier beschreibt alles Nötige.
