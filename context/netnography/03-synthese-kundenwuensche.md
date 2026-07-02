# 03 — Synthese: Kundenwünsche, Trends & Nutzerverhalten

Verdichtung der Befunde (02) zu handlungsleitenden Aussagen. Bindung an Evidenz über
Code-Verweise (`P#`/`W#`/`V#`, definiert in 02 §1; Belege in 01).

---

## 1. Executive Summary (BLUF)

Das laute, öffentlich schreibende macOS-Power-Segment ist **chronisch unzufrieden**
(„the hunt for a finder alternative continues") — es gibt **keinen klaren
Kategoriesieger**. Entscheidungen fallen weniger an Feature-Listen als an **Vertrauen &
Verlässlichkeit**: Merkt sich das Tool meinen Zustand? Ist es nativ und leicht? Fair
bepreist (Einmalkauf, keine Telemetrie)? Kann ich mich auf Tastatur & Transfers
verlassen? Ist die Doku brauchbar? Wer diese „Hygiene" erfüllt, gewinnt Glaubwürdigkeit
*vor* dem Feature-Duell.

Die **größte strategische Spannung** für Diptychon: Für ein lautes Sub-Segment ist der
eigentliche Job **Remote-Zugriff** (SFTP/WebDAV) — genau das, was Diptychon bewusst
ausschließt. Das ist verkraftbar (klare Zielsegment-Wahl), muss aber bewusst getroffen
und kommuniziert werden.

---

## 2. Kundenwünsche als Jobs-to-be-Done

> Format: *Wenn ich …, will ich …, damit …* — mit Evidenz-Code.

1. **JTBD-1 (Persistenz).** *Wenn ich meinen Mac neu starte oder ein Laufwerk aushänge,
   will ich, dass Sortierung, Spaltenbreiten, Tabs und Ansicht erhalten bleiben, damit
   ich nicht jedes Mal alles neu einrichte.* → P1/W2. **Hoch, unterbedient.**
2. **JTBD-2 (Vertrauen/Tastatur).** *Wenn ich eine Taste drücke, will ich sofortiges,
   verlässliches Feedback, damit ich nicht rätsle, ob die Eingabe ankam.* → P4/W11.
3. **JTBD-3 (Transfers).** *Wenn ich viele/große Dateien kopiere, will ich eine sichtbare
   Queue mit Fortschritt, Pause/Abbruch und Merge, damit ich Kontrolle behalte.* → P5/W9.
4. **JTBD-4 (Preview).** *Wenn ich eine Datei markiere, will ich sofort eine echte
   Vorschau (doc/pdf/jpeg/xml…), damit ich ohne Öffnen entscheiden kann.* → P8/W1.
5. **JTBD-5 (Remote).** *Wenn meine Dateien auf einem Server liegen, will ich sie so
   schnell wie lokale bedienen, damit ich nicht in Finder/Terminal wechseln muss.* →
   P12/W8. **Hoch — aber außerhalb Diptychons Scope.**
6. **JTBD-6 (Suche).** *Wenn ich in großen/vernetzten Ordnern suche, will ich lokale,
   sofortige Suche (nicht Spotlight), damit ich auch im Netz etwas finde.* → P9/W7.
7. **JTBD-7 (Rename).** *Wenn ich viele Dateien umbenenne, will ich Regex-/EXIF-basiertes
   Batch-Rename mit Vorschau, damit Serien konsistent werden.* → W3.
8. **JTBD-8 (Onboarding).** *Wenn ich ein neues Tool teste, will ich lesbare Text-Doku
   und ein verständliches Onboarding, damit ich den Nutzen schnell sehe.* → P3/W15.
9. **JTBD-9 (Werte).** *Wenn ich ein Tool kaufe, will ich Einmalkauf, keine Telemetrie
   und eine native, leichte App, damit es meinen Werten entspricht.* → V1/V2/V3/W12.
10. **JTBD-10 (Muscle Memory).** *Wenn ich von Total Commander komme, will ich vertraute
    Gesten (Dual-Pane, F-Keys, Copy-to-other), damit mein Workflow sofort greift.* → V4.

---

## 3. Trends

- **T-A · Anti-Abo / „Ownership".** Deutliche, moralisch aufgeladene Ablehnung von
  Subscriptions („renting software", „monetization optimization stuff"); Einmalkauf +
  freie Updates werden aktiv **belohnt** (S7). Verstärkt durch die breitere „Adobe/
  Creative-Cloud-Fatigue" im selben Umfeld. → V2/W12.
- **T-B · „Native & lightweight" als Qualitätssiegel.** „No Electron bloat", „100%
  local, no telemetry" werden zu **Verkaufsargumenten**, die aktiv beworben werden. →
  V1/V3. Deckt sich direkt mit Diptychons ~3-MB-These.
- **T-C · Privacy-Aktivismus.** Nutzer prüfen Privacy-Policies, mailen Entwickler:innen,
  posten Screenshots, nutzen Little Snitch. Privacy ist von „egal" zu **Deal-Breaker**
  gewandert. → V3/P2.
- **T-D · Neue native Entrants.** Mehrere frische, SwiftUI/AppKit-native Finder-Ersätze
  in Beta (Trove, Bloom, Fileside, „Captain's Deck", Folders …) → der Markt ist **in
  Bewegung**, kein erstarrtes Oligopol. Chance und Wettbewerbsdruck zugleich.
- **T-E · KI (noch) kein Thema.** Auffällig: In diesem Korpus **keine** starke Nachfrage
  nach „KI im Dateimanager". Der Bedarf ist klassisch (Verlässlichkeit, Remote, Rename).
  → Kein Hype-Feature nötig; Fundament schlägt Buzzword.

---

## 4. Nutzerverhalten

- **Tool-Hopping & serielles Testen.** Nutzer probieren 5–10 Tools durch und führen
  Mini-Reviews („I looked at a ton of them…"). Entscheidung fällt oft an **einem**
  K.-o.-Kriterium (Doku broken → raus; Telemetrie → raus; vergisst Settings → raus).
- **Community als Kaufberater.** r/macapps-Vergleichs-Threads & HN prägen die Wahl stark;
  ein überzeugter Fürsprecher („Forklift wins every day", „Marta by light years") wiegt
  schwer. → Advocacy/WOM ist der Haupt-Distributionskanal in diesem Segment.
- **Workarounds statt Kompromiss.** Lieber TC in einer Windows-VM/Wine oder
  `brew install midnight-commander` als ein unpassendes natives Tool. Zeigt die **Tiefe
  der Muscle-Memory-Bindung** (V4) und die Zahlungs-/Aufwandsbereitschaft.
- **„Beweis-Kultur".** Belege (Screenshots von Datendialogen, Policy-Zitate) werden
  geteilt; Behauptungen ohne Beleg zählen wenig. → Für GTM: mit **nachprüfbaren**
  Claims arbeiten (gemessene App-Größe, offene Privacy-Policy).

---

## 5. Priorisierte Opportunities (segment-fokussiert)

Bewertung für Diptychons Zielsegment (Personas B + C, siehe 02 §5), nicht den
Gesamtmarkt.

| Prio | Opportunity | Warum (Evidenz) | Diptychon-Fit |
|---|---|---|---|
| **1** | **Verlässliche Zustands-Persistenz** (Sortierung, Spaltenbreite, Tabs, View, Mounts) | T1/JTBD-1; unterbedient, delegitimiert Tools sofort | Hoch — Differenzierung durch „boring reliability" |
| **2** | **Sichtbare Operation-Queue + Merge** | JTBD-3/P5; Nimble-Schwäche, baut auf Diptychons Undo-Spine | Hoch (Issue 34) |
| **3** | **Werte-Hygiene sichtbar machen** (nativ/~3 MB, Einmalkauf, keine Telemetrie) als GTM-Kern | T-A/T-B/T-C; aktiv beworbenes Kaufargument | Sehr hoch (schon wahr) |
| **4** | **Echter Preview-Pane** (viele Formate) | JTBD-4; wiederkehrende Erwartung | Vorhanden (Issue 14) — als Stärke betonen |
| **5** | **Brauchbare Text-Doku & Onboarding** | T4/JTBD-8; K.-o.-Kriterium bei Marta/Path Finder | Hoch, günstig — echter Moat vs. Marta |
| **6** | **Regex-/EXIF-Batch-Rename** | JTBD-7; „stand out" (S7) | Teilvorhanden (Issue 07) — ausbauen |
| **7** | **Lokale, sofortige (nicht-Spotlight) Suche** | JTBD-6/P9; harter Produktivitäts-Schmerz | Mittel — prüfen |
| — | **Remote-Mounts (SFTP/WebDAV/NFS)** | JTBD-5; **stärkster** unerfüllter Job im Gesamtkorpus | **Bewusst außerhalb Scope** — siehe §6 |

---

## 6. Strategische Spannung: Remote-Zugriff

Der **im Gesamtkorpus stärkste** unerfüllte Job (JTBD-5, P12/W8) ist genau das, was
Diptychon per Positionierung ausschließt (local-only, „lightweight"; siehe
`../competitor-benchmark.md` §3). Ehrliche Konsequenzen:

- Diptychon adressiert damit **Persona B/C** (TC-Heimkehrer, werteorientierte
  Pragmatiker), **nicht** Persona A (Remote-Operator). Das ist legitim — aber es ist
  eine **Segment-Entscheidung**, kein „wir holen das später nach".
- Wer Remote braucht, wird ForkLift/QSpace vorziehen. Diptychon sollte **nicht** so
  tun, als konkurriere es dort. Klarheit schützt die Positionierung.
- **Option (nicht Empfehlung):** Der `PanelSource`-Seam (ADR 0003) hält die Tür offen.
  Falls die Remote-Nachfrage im *eigenen* Zielsegment (nicht nur im lauten Gesamtmarkt)
  auftaucht, wäre ein schlanker read-only-SFTP-Mount die kleinste sinnvolle Wette —
  aber erst nach eigener Nachfrage-Validierung, nicht auf Basis dieser Fremd-Tool-Daten.

---

## 7. Was NICHT gebaut werden sollte (Anti-Empfehlungen aus den Daten)

- **Quad-Pane als Pflicht.** Umstritten; 2-Pane ist Default (02 §4). Kein Kern-Job.
- **Schwere Plugin-Plattform (Lua o. ä.).** Begeistert nur die kleine Tinkerer-Nische
  (Persona D) und widerspricht „lightweight/Finder-nativ". Gadgets-lite als Brücke reicht.
- **KI-Features als Zugpferd.** Keine Nachfrage im Korpus (T-E). Ressourcen ins
  Fundament.
- **Abo-Monetarisierung.** Aktiv bestraft (T-A). Einmalkauf ist Teil des Produkts.

---

## 8. Weiter
Konkretes Mapping dieser Opportunities auf bestehende/neue Diptychon-Issues und die
Positionierung → `04-diptychon-mapping.md`.
