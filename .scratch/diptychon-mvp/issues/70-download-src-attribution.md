# 70 — `?src=` an `/download` durchreichen (Commitment pro Kanal)

Status: **ready-for-agent**
Category: gtm / landing-page

## Parent

Strategiewechsel 2026-08-03 (#66). Unabhängig von #68/#69 baubar, aber erst
sinnvoll live, wenn der Download echt ist.

## Problem

`src/worker.js:35` zählt Downloads nur global:

```js
async function recordDownload(env) {
  const day = new Date().toISOString().slice(0, 10);
  for (const key of ["total", `day:${day}`]) { … }
}
```

Damit weiß man **wie viele** geladen haben, aber nicht **woher sie kamen**.
Genau das ist die Frage, die der Reichweitentest beantworten soll.

Die Signup-Route kann es bereits: `handleNotify` normalisiert `src` und
schreibt ihn **first-touch** (`const src = existing?.src ?? …`) — wird nie
überschrieben. Die Download-Route hat nichts davon.

## Aufgabe

1. `recordDownload(env, src)` — zusätzlich `src:<kanal>` und optional
   `src:<kanal>:day:<datum>` hochzählen
2. `src` aus `url.searchParams` lesen, mit derselben Normalisierung wie in
   `handleNotify` (lowercase, `[^a-z0-9._-]` raus, 40 Zeichen, Fallback
   `"direct"`) — nicht duplizieren, in eine Hilfsfunktion ziehen
3. Alle Download-CTAs auf den Seiten bekommen ihren `?src=` mit — die vier
   A2-Seiten nutzen schon `tcmac`, `marta`, `forklift`, `pathfinder` für die
   Signup-Links, gleiche Werte verwenden
4. Kein Cookie, kein Fingerprint, keine IP-Speicherung. Nur ein Zähler pro
   Kanal. Datenschutz § 4 bleibt wie er ist

## Achtung

Kein Redirect einbauen. Der Worker serviert das Zip absichtlich direkt
(`worker.js:17-19`), damit ein Access-Login-Umweg trotzdem im Download endet.

## Done heißt

`GET /download?src=marta` erhöht `total`, `day:<heute>` **und** `src:marta`.
Verifiziert gegen die Live-KV, danach Zähler zurücksetzen wie beim
Signup-Smoke-Test 2026-07-12.

## Outcome (2026-08-04) — Worker fertig, Deploy offen

Gebaut in `.scratch/landing-page/src/worker.js`, uncommitted:

- `normalizeSrc(raw)` als eine Funktion für beide Routen — lowercase,
  `[^a-z0-9._-]` raus, 40 Zeichen, Fallback `"direct"`. `handleNotify` nutzt sie
  jetzt statt der inline-Kette; First-Touch-Logik (`existing?.src ?? …`)
  unverändert
- `recordDownload(env, src)` zählt zusätzlich **`downloads:src:<kanal>`**.
  Die bestehenden Schlüssel `total` und `day:<datum>` bleiben unangetastet, damit
  laufende Zählerstände nicht brechen. Namespace bewusst gesetzt, damit ein
  KV-Listing neben `signups:src:*` lesbar bleibt
- Die Zählschleife nutzt jetzt `bump()` statt einer eigenen Kopie derselben drei
  Zeilen
- Kein Redirect eingebaut, das Zip wird weiter direkt serviert

Geprüft: `node --check` sauber; Normalizer gegen `null`, `""`, Großschreibung,
Pfad-Tricks (`ma rta/../x` → `marta..x`), Umlaute (`päth-finder` → `pth-finder`),
60 Zeichen und reine Sonderzeichen (→ `direct`) durchgespielt.

**Nicht gemacht, gehört zu #71:** die Seiten haben aktuell **keinen einzigen**
`/download`-Link (`grep 'href="/download'` findet nichts). Die CTAs mit `?src=`
entstehen erst beim Flip. Bis dahin zählt die Route nur Direktaufrufe als
`downloads:src:direct`.

**Offen:** Deploy (`npx wrangler deploy`, bare, aus `.scratch/landing-page/`) und
danach die Live-Verifikation gegen KV plus Rücksetzen der Testzähler — wie beim
Signup-Smoke-Test 2026-07-12.
