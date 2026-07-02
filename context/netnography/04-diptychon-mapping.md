# 04 — Mapping: Befunde → Diptychon

Übersetzt die Netnographie-Befunde (03) in Diptychon-Entscheidungen: Was bestätigt
bestehende Issues, was rechtfertigt **neue** Issues, was ist GTM/Positionierung.
Bindung an Evidenz über `JTBD-#`/`P#`/`W#` (siehe 02/03).

---

## 1. BLUF für Diptychon

Die Daten **bestätigen den Kern der Positionierung** (nativ, leicht, Einmalkauf, keine
Telemetrie, Finder-nah, Keyboard-first) als echtes, wertgeladenes Kaufargument — nicht
als Slogan. Sie decken zugleich eine **unterbediente Lücke** auf, die keine Feature-
Liste betont: **verlässliche Zustands-Persistenz**. Und sie schärfen die
**Segment-Grenze**: Remote-Zugriff ist der stärkste Gesamtmarkt-Job, aber bewusst
nicht Diptychons — das ist zu *entscheiden und zu kommunizieren*, nicht zu erschleichen.

---

## 2. Bestehende Issues — durch Evidenz gestützt

| Issue | Netnographie-Stütze | Bewertung |
|---|---|---|
| **34 — Operation Queue (Progress/Pause/Cancel)** | JTBD-3, P5 (Nimble: „no file transfer pane"; ForkLift-Lob fürs Transfer-Log) | **Bestätigt, hochprior.** Ergänzen: **Merge/Konflikt-Auflösung** (W9) explizit mitdenken. |
| **07 — Batch-Rename** | JTBD-7, W3 („regex and EXIF awareness would go a long way") | **Bestätigt.** Erweiterungs-Kandidat: Regex + EXIF-Token. |
| **14 — Inline Preview-Pane** | JTBD-4, P8/W1 („Preview really should preview … doc/jpeg/xml/pdf") | **Bestätigt als Stärke.** Format-Breite betonen. |
| **15 — Path Bar + Go-to-Folder** | JTBD-2, W11 („easy ability to enter arbitrary address") | **Bestätigt.** Persona B Kern. |
| **16 — Sidebar (Favoriten/Places)** | S3 (Favoriten erwartet, aber keyboard-menü ok) | **Bestätigt „less than Finder"-Ansatz** — Sidebar ist Erwartung, nicht Muss. |
| **38 — Per-Pane Tabs** | JTBD-1 (Teil), W2/W6 | **Bestätigt** — aber Persistenz muss über Tabs hinausgehen (siehe §3, N1). |
| **37 — Multi-Column Brief View** | W1 (Ansichts-Flexibilität) | Schwach gestützt; niedrigere Prio als Persistenz/Queue. |
| **04/05 — Undo-Spine, Kollisionsdialog** | JTBD-3/W9 | **Bestätigt** als Vertrauens-Fundament (T2). Merge ist die Lücke. |

**Prioritäts-Signal aus den Daten:** 34 (Queue+Merge) und die Persistenz-Lücke (N1)
ranken **über** 37 (Multi-Column) und 36 (Gadgets-lite). Vertrauen/Verlässlichkeit
schlägt Feature-Breite.

---

## 3. Neue Issue-Kandidaten (durch Netnographie gerechtfertigt)

> Noch **nicht** als Files angelegt — hier als begründete Vorschläge. Auf Wunsch lege
> ich sie als `40+`-Issues im Tracker an.

> **Status-Update (2026-07-02):** N1 → **Issue 41** angelegt (state persistence).
> N2 (Merge/W9) → in **Issue 34** gefaltet. N3 → **Issue 42** (docs/onboarding).
> N5 → **Issue 43** (local instant search). N4 bleibt Ausbau von Issue 07.

### N1 — Zustands-Persistenz („merkt sich alles") · **→ Issue 41 (angelegt)**
- **Evidenz:** JTBD-1, P1/W2. O-Ton: *„Is there any TC alternative for mac that can at
  least remember its UI settings?"* (S6). Sortierung, Spaltenbreiten, Tabs, Ansicht,
  Mount-/Ordner-Zustand über Neustart & Laufwerks-Aushängen hinweg.
- **Warum stark:** Unterbedient (kein Wettbewerber wirbt damit), delegitimiert
  Konkurrenz sofort, passt perfekt zu „boring reliability" als Diptychon-Tugend.
- **Abgrenzung zu 38:** 38 macht Zustand *pro Tab*; N1 ist die **Persistenz-Garantie
  über Sessions** (was überlebt Neustart/Remount?) — querschnittlich, eigenes Issue.

### N2 — Merge / smarte Konflikt-Auflösung · **→ in Issue 34 gefaltet**
- **Evidenz:** W9; Nimble „doesn't offer merge" (S3); „smart conflict resolution" (S7).
- **Warum:** Erwartungs-Feature bei Transfers; ergänzt Issue 34 & den Kollisionsdialog
  (05). Ggf. als Erweiterung von 34/05 statt eigenständig.

### N3 — Doku- & Onboarding-Qualität als Produkt-Feature · **→ Issue 42 (angelegt)**
- **Evidenz:** T4, P3/W15. Zwei Tools wurden **wegen Doku aussortiert** („pathetic docs
  binned it"; „give me text" statt Video). 
- **Warum:** Billigster echter Moat gegen Marta/Path Finder. Text-first Doku, „First 5
  Minutes"-Onboarding, Keyboard-Cheat-Sheet. Kein Code-Feature, aber Adoptions-kritisch.

### N4 — Regex-/EXIF-Batch-Rename (Ausbau von 07)
- **Evidenz:** W3. Als „differentiator" genannt.

### N5 — Lokale, sofortige (nicht-Spotlight) Suche · **→ Issue 43 (angelegt)**
- **Evidenz:** JTBD-6/P9 („Spotlight doesn't find anything on the network"). 
- **Warum:** Harter Produktivitäts-Schmerz; für local-only-Diptychon technisch gut
  machbar (lokaler Ordner-Index statt Spotlight). Prio mittel — Nachfrage im *eigenen*
  Segment vor Bau validieren.

---

## 4. Positionierung & GTM (aus Trends/Verhalten)

- **Werte-Hygiene sichtbar an die Front.** Nativ/~3 MB, Einmalkauf, **keine
  Telemetrie**, 100% lokal — laut T-A/T-B/T-C aktiv beworbene Kaufargumente. Diptychon
  erfüllt sie bereits → auf Website/README **prominent & nachprüfbar** machen (gemessene
  Größe, offene Privacy-Policy). Vgl. `../competitor-benchmark.md` §4 (Footprint).
- **„Beweis-Kultur" bedienen.** Claims mit Belegen (gemessene Zahlen aus
  `../performance.md`, App-Größe) — dieses Segment misstraut unbelegten Aussagen.
- **Advocacy/WOM ist der Kanal.** r/macapps- & HN-Fürsprecher entscheiden. GTM =
  glaubwürdige Präsenz in genau diesen Threads (ehrlich, nicht als Astroturf — vgl.
  Ethik-Prinzipien in 00).
- **Klare Segment-Kommunikation.** Nicht als Remote-Tool auftreten (siehe §5). „Der
  leichte, verlässliche, native Dual-Pane für lokale Arbeit" — Persona B/C.

---

## 5. Die eine strategische Entscheidung: Remote

Stärkster unerfüllter Job im **Gesamtkorpus** (JTBD-5, P12/W8) = SFTP/WebDAV-Remote —
**bewusst außerhalb** Diptychons Scope (`../competitor-benchmark.md` §3).

- **Empfehlung:** Bei der Segment-Entscheidung bleiben (Persona B/C bedienen, A nicht).
  Diese Netnographie liefert **keinen** Beleg für Remote-Nachfrage im *eigenen*
  Zielsegment — nur im lauten Gesamtmarkt. Positionierung nicht verwässern.
- **Offene Tür (nicht Empfehlung):** `PanelSource`-Seam (ADR 0003) erlaubt später eine
  schlanke read-only-SFTP-Wette — **erst nach eigener Nachfrage-Validierung**.
- **Fitness-Funktion für den Reversal:** „Flippen wir Remote nur, wenn ≥ X validierte
  Anfragen aus dem *eigenen* Nutzerstamm kommen — nicht auf Basis von Fremd-Tool-Foren."

---

## 6. Empfohlene nächste Schritte

1. ✅ **N1 (Persistenz)** → Issue **41** angelegt (+ Filter-nicht-persistieren &
   Staging-Set-Entscheidung ergänzt).
2. ✅ **34** um **Merge (N2/W9)** erweitert + Bottom-Left-Toggle-Panel + Abgrenzung zu 18.
3. ✅ **N3 (Doku/Onboarding)** → Issue **42**; **N5 (lokale Suche)** → Issue **43**.
4. ✅ GTM-Notiz in `../positioning-note.md` §GTM ergänzt: Werte-Hygiene + Beweis-Kultur
   + klare Nicht-Remote-Kommunikation.
5. ✅ Prio-Reihung im `PROJECT-TRACKER.md` → *Backlog priority (netnography-informed)*
   angelegt: Persistenz/Queue vor Multi-Column/Gadgets.

---

## 7. Verweise
- Rohdaten/Zitate: `01-datenkorpus.md` · Analyse: `02-analyse-und-befunde.md` ·
  Synthese: `03-synthese-kundenwuensche.md` · Methodik/Ethik: `00-methodik-und-ethik.md`
- Produktseitig: `../competitor-benchmark.md` (§3 Scope, §4 Footprint, §5 Marta),
  `../positioning-note.md`, `.scratch/diptychon-mvp/issues/34–39`.
