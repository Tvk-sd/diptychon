# 72 — Feedback-Kanal: der einzige Weg, überhaupt etwas zu erfahren

Status: **needs-triage**
Category: gtm / app

## Parent

Strategiewechsel 2026-08-03 (#66).

## Warum

Diptychon hat **bewusst keine Telemetrie** (Datenschutz § 4, Cloudflare Web
Analytics wurde 2026-07-13 deaktiviert und darf nie zurück). Das ist eine
Positionierungsentscheidung und bleibt.

Die Konsequenz ist aber selten ausgesprochen: wenn die App bei einem Fremden
abstürzt, sich merkwürdig verhält oder er nach zwei Minuten aufgibt, **erfährst
du das nie** — außer er schreibt dir aktiv. Der Feedback-Kanal ist damit kein
Nice-to-have, er ist das gesamte Messsystem.

Und er muss dort sitzen, wo der Nutzer ist: **in der App**, nicht nur auf der
Website. Wer die App geladen hat, kommt nicht auf die Landing Page zurück, um
sich zu beschweren.

## Zwei Teile

**1. In der App** (der wichtigere)
- Ein sichtbarer, kurzer Weg: Menü-Eintrag oder Panel-Fußzeile, der eine
  vorbereitete Mail an `feedback@diptychon.com` öffnet (Email Routing steht
  bereits)
- Vorausgefüllt: App-Version, macOS-Version. **Nichts über Dateien, Pfade oder
  Ordnerinhalte** — das wäre genau die Datensammlung, die wir nicht wollen
- Der Text der Frage entscheidet über die Antwortqualität. Nicht „Feedback",
  sondern eine konkrete Frage: *„Was fehlt dir hier am meisten?"*

**2. Auf der Website** (das, was ursprünglich als „Freitextfeld" geplant war)
- Der bestehende `#notify`-Flow hat zwei Schritte: E-Mail, dann Checkbox-Liste
  (`persistence`, `keyboard`, `transfers`, …). Die Checkboxen sind **unsere
  Hypothesen, nicht ihre Worte** — sie halten den Antwortenden in unserem Rahmen
- Dritter Schritt: zwei Freitextfelder, „What do you use today?" / „What annoys
  you most about it?", optional, `skip` bleibt
- `worker.js` braucht dafür ein **neues Feld**: `wishes` ist auf 40 Zeichen und
  12 Einträge gedeckelt (`String(w).slice(0, 40)`, `.slice(0, 12)`), Freitext
  passt da nicht rein. Neues Feld `answers: {today, pain}`, eigenes Limit
  (~500 Zeichen), nachreichbar wie `wishes`. `src` bleibt first-touch

## Offene Frage an Till

Nach dem Flip (#71) ist die Website-Variante deutlich weniger wert als die
In-App-Variante — die Leute haben dann die App. Lohnt Teil 2 überhaupt noch,
oder reicht Teil 1 plus die E-Mail-Adresse als Rückrufnummer?

## Metrik

Nicht Signup-Rate. **Verwertbare Freitextantworten**, absolut. Tills eigene
Schwelle aus der Ads-Planung: 30+ verwertbare Antworten = Erkenntnis erreicht.

## Outcome

_(offen)_
