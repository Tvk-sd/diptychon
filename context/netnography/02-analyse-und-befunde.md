# 02 — Analyse & Befunde

Iterative Kodierung, qualitative Themen, quantitative (korpus-interne) Häufigkeiten,
Sentiment, Personas. Datengrundlage: `01-datenkorpus.md` (Quellen S1–S8). Methodik &
Limitationen: `00-methodik-und-ethik.md`.

> **Lesehinweis zu Zahlen:** „Quellen-Häufigkeit" = Anzahl der Quellen (max. 8), in
> denen ein Code mindestens einmal vorkommt. **Indikativ, nicht repräsentativ**
> (Power-User-Selbstselektion, Single-Rater). Zahlen ranken Themen *innerhalb* dieses
> Korpus — sie schätzen keine Marktanteile.

---

## 1. Kodier-Framework (induktiv)

### Schmerzpunkte (`P`)
| Code | Schmerzpunkt | Kernbeleg (Quelle) |
|---|---|---|
| P1 | **Zustand nicht persistent** (Sortierung, Spaltenbreite, Tabs, Mount-Status gehen verloren) | Commander One (S6) |
| P2 | **Privacy/Telemetrie-Misstrauen** | QSpace (S3, S5) |
| P3 | **Schlechte/undurchdachte Doku & Onboarding** (broken docs, video-only) | Marta (S5), Path Finder (S5) |
| P4 | **Wahrgenommene UI-Latenz / Eingabe-Unsicherheit** | Nimble (S3) |
| P5 | **Schwaches/opakes Transfer-Feedback; kein Merge** | Nimble (S3) |
| P6 | **Steile, un-intuitive Lernkurve** | Nimble (S3) |
| P7 | **Fehlende „Basics" trotz Power-User-Anspruch** (kein Sidebar, kein Multi-Rename, kein View-Pane) | Commander One (S5, S6) |
| P8 | **Schwacher/fehlender Preview-Pane** | Commander One, Path Finder (S5) |
| P9 | **Netzwerk-/Remote-Suche unbrauchbar** (Spotlight findet nichts im Netz) | QSpace (S5) |
| P10 | **Preis-/Monetarisierungs-Friktion** (teuer, Subscription-Aversion) | Commander One (S6/S7), allg. (S6) |
| P11 | **Nicht-nativer Look/„fühlt sich nicht wie Mac an" / Electron** | Fileside (S5), allg. (S6) |
| P12 | **Remote-Zugriff langsam/fehlend** (WebDAV via Finder, kein SFTP) | Path Finder (S3), ForkLift 3 sluggish (S3) |
| P13 | **Reife-/Abandonment-Zweifel** (Beta, stagnierend, „early development") | Marta, div. (S5/S6) |
| P14 | **SIP muss deaktiviert werden** (Sicherheits-Tradeoff) | TotalFinder/XtraFinder (S5) |

### Wünsche (`W`)
| Code | Wunsch | Kernbeleg |
|---|---|---|
| W1 | **Dual-Pane + echter Preview** (repräsentiert doc/jpeg/pdf/xml …) | S5, S7 |
| W2 | **Echte Persistenz + benannte Workspaces/Sessions** | S6, S7 |
| W3 | **Mächtiges Batch-Rename (Regex + EXIF)** | S5, S7 |
| W4 | **Konfigurierbares Kontextmenü / eigene Befehle** | S7 |
| W5 | **Automation: Shortcuts / AppleScript / Service Menu / Plugin-API** | S7 |
| W6 | **Erweitertes Tab-Management** (pinned, farbig, Gruppen, Shortcuts) | S7 |
| W7 | **Schnelle lokale + Netzwerk-Suche** (nicht Spotlight-abhängig) | S5 |
| W8 | **Remote-Mounts (SFTP/WebDAV/NFS) + Remote-Favoriten, Auto-Mount** | S3, S5, S7 |
| W9 | **Merge / smarte Konflikt-Auflösung beim Kopieren** | S3, S7 |
| W10 | **Ordnergrößen / Disk-Usage sichtbar** | S3/S7, S8 |
| W11 | **Keyboard-first inkl. freier Pfad-Eingabe (Go-to)** | S5 |
| W12 | **Einmalkauf statt Abo · keine Telemetrie · nativ/leicht** | S6, S7 |
| W13 | **Optionaler Finder-Kompatibilitätsmodus** (breitere Adoption) | S7 |
| W14 | **>2 Panes / Quad-View & Workspaces** (umstritten: manche wollen es, manche „fumble with tabs") | S5 |
| W15 | **Gute, textbasierte Doku** | S5 |

### Werte / Kultur (`V`, Querschnitt)
| Code | Wert |
|---|---|
| V1 | **Nativ > Electron** (Identitäts-/Statussignal) |
| V2 | **Anti-Subscription / Einmalkauf** (moralisch aufgeladen) |
| V3 | **Privacy & Vertrauen** (Little Snitch, Open-Source-Präferenz) |
| V4 | **Commander-Nostalgie** (Norton/Far/TC als Referenz & Tribal-Identität) |
| V5 | **Chronische Unzufriedenheit** („the hunt continues" — kein Kategoriesieger) |

---

## 2. Quantitative Verdichtung (korpus-intern, indikativ)

Ranking der Themen nach Anzahl Quellen (max. 8), in denen sie auftreten:

| Rang | Thema (Code) | Quellen | Häufigkeit | Sentiment |
|---|---|---|---|---|
| 1 | Remote-Zugriff/-Mounts als Kern-Job (P12/W8) | S3,S5,S7 (+S6) | ●●●●○○○○ | stark, unerfüllt |
| 1 | Preis-/Modell-Friktion & Anti-Abo (P10/W12/V2) | S3,S6,S7 (+S4) | ●●●●○○○○ | wertend, emotional |
| 3 | Keyboard-first + freie Pfad-Eingabe (W11/V4) | S1,S3,S5,S6 | ●●●●○○○○ | positiv-fordernd |
| 4 | Zustands-Persistenz / Workspaces (P1/W2) | S5,S6,S7 | ●●●○○○○○ | frustriert |
| 4 | Privacy/Telemetrie (P2/V3) | S3,S5 (+S4/S7) | ●●●○○○○○ | Deal-Breaker |
| 4 | Echter Preview-Pane (P8/W1) | S3,S5,S7 | ●●●○○○○○ | Erwartung |
| 7 | Native/kein Electron (P11/V1) | S5,S6,S7 | ●●●○○○○○ | Identität |
| 7 | Transfer-Feedback/Queue + Merge (P5/W9) | S3,S7 | ●●○○○○○○ | Vertrauen |
| 7 | Batch-Rename (Regex/EXIF) (W3) | S5,S7 | ●●○○○○○○ | „nice differentiator" |
| 7 | Doku/Onboarding-Qualität (P3/W15) | S5 (+S2) | ●●○○○○○○ | Ausschlussgrund |
| 11 | Automation/Plugin/AppleScript (W5/W4) | S1,S7 | ●●○○○○○○ | Power-Nische |
| 11 | Lokale+Netzwerk-Suche (P9/W7) | S5 | ●○○○○○○○ | spitz, aber hart |
| 11 | UI-Latenz-Wahrnehmung (P4) | S3 | ●○○○○○○○ | subtil, wichtig |
| 11 | Tab-Management erweitert (W6) | S7 | ●○○○○○○○ | Komfort |
| 11 | >2 Panes / Quad (W14) | S5 | ●○○○○○○○ | **umstritten** |

**Beobachtung:** Die Spitzenplätze sind *nicht* exotische Power-Features, sondern
**Vertrauens- und Verlässlichkeits-Themen** (Remote als Kern-Job, faires Preismodell,
Keyboard-Verlässlichkeit, „merkt sich meine Einstellungen", Privacy). Die klassischen
„Feature-Listen"-Punkte (Quad-Pane, Plugins) ranken tiefer — und sind teils umstritten.

---

## 3. Qualitative Kernthemen (5 Muster)

### T1 — „Es merkt sich nichts" ist ein eigener Schmerz (P1/W2)
Persistenz wird als *Grundvertrauen* behandelt, nicht als Feature. Der O-Ton „Is there
any TC alternative for mac that can **at least remember its UI settings?**" (S6) zeigt:
Zustandsverlust (Sortierung, Spaltenbreite, Tabs, Mount-Status) delegitimiert ein Tool
sofort. **Unterschätzt**, weil kein Hersteller damit wirbt.

### T2 — Vertrauen schlägt Feature-Fülle (P2/P4/V3)
Privacy-Misstrauen (QSpace) und wahrgenommene Eingabe-Latenz (Nimble) sind *Vertrauens-*
brüche. Beide killen die Nutzung trotz starker Feature-Sets. Little-Snitch-Nutzung und
Screenshot-„Beweise" zeigen aktives Misstrauens-Verhalten.

### T3 — Remote ist für ein lautes Segment der eigentliche Job (P12/W8)
Für einen erheblichen Teil des Korpus ist der Auslöser „weg von Finder" **remote
volumes** (SFTP/WebDAV/NFS), nicht Dual-Pane. ForkLifts Stärke hier = sein Ruf als
„Gewinner". → **Direkter Konflikt mit Diptychons „local-only"-These** (siehe 03/04).

### T4 — Onboarding & Doku entscheiden über Adoption (P3/P6/W15)
Zwei Tools (Marta, Path Finder) wurden trotz Interesse **wegen Doku aussortiert**
(„pathetic docs binned it"; „give me text"). Lernkurve (Nimble) ist akzeptiert *wenn*
der Payoff sichtbar ist — aber schlechte Doku killt den Payoff.

### T5 — Identität & Kultur steuern die Wahl (V1–V5)
„Nativ statt Electron", „Einmalkauf statt Abo", „close to Total Commander/Far" und
„the hunt continues" sind kulturelle Codes. Die Kaufentscheidung ist teils Werte-
bekenntnis. Wer diese Codes bedient (nativ, leicht, fair bepreist, keine Telemetrie),
gewinnt Glaubwürdigkeit *vor* dem ersten Feature-Vergleich.

---

## 4. Widersprüche & Spannungen (bewusst nicht geglättet)

- **Quad-Pane: Ja vs. Nein.** „I prefer the 4 panes layout … instead of fumbling with
  tabs" (S5) **vs.** „I very seldom am coordinating four directories … two is the norm"
  (S5). → Kein Konsens; 2-Pane ist Default, >2 ist Nische.
- **Keyboard-Menü vs. Sidebar.** Manche vermissen zuerst eine Favoriten-Sidebar,
  bevorzugen nach Eingewöhnung aber das **keyboard-driven favorites menu** (S3). →
  Sidebar ist Erwartung, nicht Notwendigkeit.
- **Einfachheit vs. Konfigurierbarkeit.** Marta-DSL/Plugins begeistern eine Elite (S1),
  während andere schon an Doku/Onboarding scheitern (S5). → Zwei Sub-Segmente
  („Tinkerer" vs. „Pragmatiker").

---

## 5. Personas (aus den Mustern abgeleitet)

**A · „Der Remote-Operator"** — Admin/Dev, arbeitet gegen Server (SFTP/WebDAV/NFS).
Kern-Job: entfernte Dateien so schnell wie lokale. Nutzt ForkLift/QSpace. Diptychon-Fit
heute: **niedrig** (local-only). *(Quellen: S3, S5)*

**B · „Der TC-Heimkehrer"** — Windows-/DOS-Sozialisation, sucht Total-Commander-Muscle-
Memory auf dem Mac. Keyboard-first, F-Keys, freie Pfad-Eingabe. Toleriert Lernkurve,
hasst schlechte Doku. Nutzt Marta/Nimble. Diptychon-Fit: **hoch**. *(S1, S5, S6)*

**C · „Der werteorientierte Pragmatiker"** — will „einfach ein besseres Finder", nativ,
leicht, Einmalkauf, keine Telemetrie, merkt sich alles. Kein Tinkerer. Ausschlussgründe:
Electron, Abo, Persistenz-Bugs, schlechte Doku. Diptychon-Fit: **sehr hoch**. *(S6, S7)*

**D · „Der Tinkerer"** — liebt Config-DSL, Plugins, AppleScript, Gadgets. Klein, aber
laut/einflussreich (schreibt die Vergleiche). Diptychon-Fit: **mittel** (Positionierung
gegen schwere Extensibilität — Gadgets-lite als Brücke). *(S1, S7)*

---

## 6. Übergang
Kundenwünsche, Jobs-to-be-Done, Trends & Verhaltensmuster → `03-synthese-kundenwuensche.md`.
Produkt-Mapping auf Diptychon-Issues → `04-diptychon-mapping.md`.
