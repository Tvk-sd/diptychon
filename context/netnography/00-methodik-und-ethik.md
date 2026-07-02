# 00 — Methodik, Reflexivität & Ethik

Netnographie zu macOS-Dateimanager-Nutzer:innen · erhoben 2026-07-02 · Methodik nach
Kozinets (2020) + Best-Practice-Checkliste der Auftraggeber:in.

---

## 1. Forschungsfrage

> **Wogegen richten sich starke negative Gefühle von Nutzer:innen bei
> Commander-artigen Dateimanagern (Marta, Total/Nimble Commander, ForkLift, Path
> Finder, QSpace …) und bei Finder selbst — und was wünschen sie sich stattdessen?**

Unterfragen:
- Welche **Schmerzpunkte** treiben den Wechsel weg von Finder / zwischen Tools?
- Welche **Wünsche** artikulieren Power-User explizit?
- Welche **Werte** (Privacy, Preismodell, „nativ") prägen die Kaufentscheidung?
- Welche **Verhaltensmuster** (Tool-Hopping, Nostalgie, Community-Empfehlung) zeigen sich?

Die Ableitung dient der Produkt-Discovery für **Diptychon** (leichter, nativer
Dual-Panel-Finder-Ersatz „im Geiste von Nimble Commander").

---

## 2. Introspektion & Reflexivität (Schritt 1 der Best Practice)

> *Best Practice: „Before observing others, critically reflect on your own biases,
> background, and relationship to the research topic."*

Wichtig, weil diese Studie **nicht neutral** ist — sie wird für ein konkurrierendes
Produkt erhoben. Offengelegte Verzerrungsrisiken:

- **Confirmation Bias / Advocacy Bias.** Auftraggeber:in baut Diptychon und hat eine
  vorhandene Positionierung („lightweight", „Finder-nativ", „kein Remote/Archiv").
  Es besteht die Versuchung, nur Belege zu sammeln, die diese These stützen. → Gegen-
  maßnahme: Befunde, die *gegen* die Positionierung sprechen (z. B. massive Nachfrage
  nach Remote-Mounts), werden explizit als solche markiert (siehe 03 §Spannungen).
- **Sampling Bias.** Wer öffentlich in r/macapps und Hacker News schreibt, ist ein
  technik-affiner Power-User — **nicht** die Mehrheit der Mac-Nutzer:innen. Die
  „normale" Finder-Zufriedene ist im Korpus systematisch unterrepräsentiert. Befunde
  gelten für das **Power-User-Segment**, das ohnehin Diptychons Zielgruppe ist.
- **Recency/Platform Bias.** Reddit + HN überrepräsentieren englischsprachige,
  westliche, oft entwickler-nahe Nutzer. Deutsch-/asiatischsprachige Communities
  fehlen in v1.
- **Eigene Nähe.** Analyst:in kennt die Commander-Tradition (Norton/Total Commander)
  und teilt tendenziell die „nativ statt Electron"-Haltung — Gefahr, diese Wertung
  als Konsens zu überzeichnen.

Diese Reflexivität ist im gesamten Dokument mitzudenken; die quantitativen Zahlen in
02 sind deshalb bewusst als *indikativ* und nicht als repräsentativ ausgewiesen.

---

## 3. Planning & Entrée — Site Selection

> *Best Practice: „Select online communities that directly align with your research
> question. Prioritize active, recently updated sites over dormant ones."*

Auswahlkriterien: (a) thematische Passung (Dateimanager/macOS-Power-Tools), (b)
Aktivität/Aktualität, (c) Zugänglichkeit für strukturierte Erhebung, (d) Dichte an
wertenden, begründeten Aussagen (nicht nur „App X ist gut").

| Plattform | Warum ausgewählt | Aktivität | Rolle im Sample |
|---|---|---|---|
| **r/macapps** (Reddit) | Zentrale Community für Mac-App-Diskussion & -Vergleiche | Sehr aktiv (2021–2026 Threads) | Primärquelle (archival) |
| **Hacker News** | Technik-Power-User, hohe Begründungstiefe, Show-HN-Feedback | Aktiv (2017–2024 Threads) | Primärquelle (archival) |
| **Applefritter** (Fachartikel + Kommentare) | Tiefer, methodischer 1:1-Vergleich inkl. Privacy-Audit | Artikel 2023, laufend | Sekundär-/Expertenquelle |
| **Herstellerdocs** (marta.sh) | Referenz für Feature-Ist-Stand (nicht Sentiment) | Laufend | Kontext/Referenz |

**Bewusst (noch) nicht erhoben** (v2-Kandidaten, siehe §7 Limitationen): Discord/
TikTok/YouTube-Kommentare, Mac App Store-Reviews (Marta/TC nicht im MAS; ForkLift/
Commander One wären erhebbar), deutschsprachige Foren, GitHub-Issue-Tracker der Tools.
Reddit war über den regulären Such-Crawler gesperrt; Zugriff erfolgte über
`old.reddit.com`.

---

## 4. Data Collection — Kozinets' drei Datenpfeiler

> *Best Practice: „Ensure your dataset includes archival data, elicited data, and
> field notes. Prioritize richness over big data."*

| Pfeiler | In dieser Studie | Ort |
|---|---|---|
| **Archival data** (bestehende Posts) | Verbatim-Zitate aus Threads & Artikeln, unverändert | Korpus (01) |
| **Elicited data** (ko-kreiert durch Interaktion) | **Nicht erhoben** in v1 — keine aktive Teilnahme/Befragung (rein observatorisch, „lurking"). Bewusste Grenze, siehe Ethik §5. | — |
| **Field notes** (eigene Reflexion) | Analyst:innen-Notizen zu Mustern, Widersprüchen, kulturellen Signalen | 01 §Feldnotizen + 02 |

**Richness over Big Data:** Es wurde bewusst *tief* statt *breit* erhoben — ~11
dichte Quellen mit begründeten, oft mehrsätzigen Aussagen, statt Massen-Scraping
tausender „App X 👍"-Kommentare. Erhebung lief bis zur **thematischen Sättigung**
(neue Quellen brachten überwiegend Wiederholungen bekannter Codes).

**Diverse Datentypen:** Neben Text wurden auch *Artefakte* der Community erfasst,
soweit relevant — z. B. Screenshots von Privacy-Dialogen (QSpace-Datensammlung),
„Norton-Blau"-Themes als nostalgisches Status-Signal, und die wiederkehrende Rhetorik
(„electron trash", „the hunt continues") als kulturelle Marker.

---

## 5. Ethik

> *Best Practice: „Respect privacy & consent. Anonymize data. Audit AI usage."*

- **Rein observatorisch.** Es wurde ausschließlich öffentlich zugänglicher Content
  ausgewertet; **keine** verdeckte oder offene Interaktion mit Community-Mitgliedern,
  daher entfällt die Offenlegungspflicht aus der aktiven Teilnahme. (Sollte v2
  elicited data erheben, ist die Forscher:innenrolle offenzulegen.)
- **Anonymisierung / PII.** Usernames werden **nicht** genannt. Teilnehmende erhalten
  Pseudonym-Codes (`P1`, `P2` …). Verlinkt wird auf **Thread-/Artikelebene**, nicht
  auf Nutzerprofile. Zitate werden verbatim wiedergegeben (Authentizität), aber ohne
  identifizierende Zusatzinfos.
- **Öffentliche Autoren.** Wo eine Quelle ein publizierter, namentlicher Fachartikel
  ist (Applefritter), wird auf Quellenebene zitiert; auch hier keine Nutzernamen aus
  den Kommentaren.
- **AI-Audit / Narrative Equity.** Erhebung, Kodierung und Verdichtung erfolgten
  KI-gestützt. Zur Wahrung der authentischen Community-Stimme gilt: (a) Kernbefunde
  sind an **Verbatim-Zitate** rückgebunden (01), nicht nur an paraphrasierte
  KI-Zusammenfassungen; (b) Zahlen sind nachvollziehbar aus dem Korpus ableitbar;
  (c) menschliche Triangulation/Review vor jeder Produktentscheidung ist vorgesehen.
  Die KI-Nutzung ist hiermit offengelegt.

---

## 6. Data Analysis — Kodier-Ansatz

> *Best Practice: „Iterative coding … multiple raters … qualitative tools (NVivo)."*

- **Iterative, offene Kodierung.** Codes wurden induktiv aus dem Material gebildet,
  nicht vorab festgelegt; Mehrdeutigkeit ist erlaubt — eine Aussage kann mehrere Codes
  tragen (z. B. „Commander One … expensive … lacking a sidebar" = Preis-**und**
  Feature-Lücke). Framework in 02 §1.
- **Zwei Code-Familien:** `P` = Pain/Schmerzpunkte, `W` = Wishes/Wünsche; plus eine
  Querschnitts-Ebene `V` = Werte/Kultur.
- **Werkzeuge (Transparenz statt NVivo):** Für diese v1 wurde kein NVivo genutzt;
  Kodierung erfolgte manuell im Markdown-Korpus. NVivo/ATLAS.ti + ein zweiter Rater
  (Inter-Rater-Reliabilität) sind die empfohlene Härtung für v2 — hier explizit als
  methodische Limitation ausgewiesen (Single-Rater).
- **Quantifizierung.** Häufigkeit je Code = Anzahl **Quellen**, in denen der Code
  mindestens einmal auftritt (nicht Anzahl Einzel-Erwähnungen), um lautstarke
  Einzelstimmen nicht zu überzeichnen.

---

## 7. Limitationen (ehrlich)

1. **Nicht repräsentativ.** Power-User-Selbstselektion; keine Populationsaussage.
   Zahlen in 02 sind korpus-intern und indikativ.
2. **Single-Rater.** Keine Inter-Rater-Reliabilität in v1 → Kodierung ist
   interpretativ. Gegenmittel: Verbatim-Rückbindung.
3. **Plattform-Schmalheit.** Nur Reddit/HN/ein Fachartikel; kein Discord/TikTok/
   YouTube/MAS-Reviews/DE-Foren. Visuelle Kultur (Memes/Video) nur am Rande erfasst.
4. **Recency-Spanne.** Quellen 2017–2026; einige Tool-Kritiken (z. B. ForkLift 3,
   Path Finder) beziehen sich auf ältere Versionen — Tools ändern sich. Vor Zitat
   nach außen: Versionsstand prüfen.
5. **Keine elicited data.** Rein passiv; keine gezielten Rückfragen an Nutzer:innen.
6. **Sprachbias.** Englischsprachig dominiert.

---

## 8. Weiterverwendung
- Rohbefunde & Zitate: `01-datenkorpus.md`
- Kodierung, Themen, Zahlen: `02-analyse-und-befunde.md`
- Kundenwünsche & Trends: `03-synthese-kundenwuensche.md`
- Produkt-Mapping Diptychon: `04-diptychon-mapping.md`
- Verwandt: `../competitor-benchmark.md` (Feature-Sicht), `../positioning-note.md`.
