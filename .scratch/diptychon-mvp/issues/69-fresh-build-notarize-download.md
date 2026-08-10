# 69 — Frischen Build notarisieren und den Download echt machen

Status: **ready-for-human** (hängt an Tills Apple-Developer-Lizenz)
Category: release

## Parent

Strategiewechsel 2026-08-03 (#66). Blockiert von **#68** (Readiness-Gate).

## Warum

Der Download auf `diptychon.com/download` ist heute ein gebrochenes Versprechen:
das Zip ist nicht notarisiert, macOS Gatekeeper lehnt es ab und legt es in den
Papierkorb. Solange das so ist, darf auf der Seite nichts von „free download"
stehen — der Besucher merkt es in 30 Sekunden und ist weg.

Till hat entschieden, die Developer-Lizenz (~$99/Jahr) ohnehin zu kaufen,
unabhängig von jedem Reichweitensignal. Damit ist sie **Voraussetzung, kein
Gate** — die alte Roadmap-Reihenfolge („erst Reichweite messen, dann $99") ist
hinfällig.

## Wichtig: frisch bauen, nicht das vorhandene Zip notarisieren

`.scratch/landing-page/dist/Diptychon.zip` ist vom **2026-07-17** (1.560.529 B).
Seitdem sind unter anderem das eingebettete Terminal (#65, `4043372`) und
weitere Arbeit auf main gelandet. Das Zip ist veraltet.

## Schritte

1. Apple-Developer-Lizenz kaufen (Till)
2. Developer-ID-Zertifikat einrichten, Signing in den Build hängen
3. **Frisch von main bauen** — nicht das vorhandene Zip anfassen
4. `codesign` mit Hardened Runtime, dann `notarytool submit --wait`, dann
   `stapler staple`
5. Neu zippen, in `dist/` legen, Größe in der Copy nachziehen (die Seiten nennen
   1,5 MB — die Zahl stimmt nach einem neuen Build vermutlich nicht mehr)
6. **Verifizieren wie ein Fremder:** Zip über `https://diptychon.com/download`
   herunterladen (nicht lokal kopieren — Quarantäne-Flag entsteht nur beim
   echten Download), dann `spctl -a -vv /Applications/Diptychon.app` und einmal
   per Doppelklick starten. Erst wenn das ohne Warndialog durchläuft, ist das
   Ticket fertig

## Plan 2026-08-04 (Lizenz ist da)

Lizenz bestätigt (Apple-Developer-Account zeigt „Programmressourcen" mit App
Store Connect und Zertifikaten — das sieht ein Free-Account nicht).

**Harter Blocker bleibt:** `security find-identity -v -p codesigning` sagt
`0 valid identities found`. Ohne Developer-ID-Zertifikat im Schlüsselbund kann
nichts signiert werden. Zertifikat und Notary-Key sind interaktive
Till-Schritte, kein Agent kann sie ausführen.

### Annahmen

- Artefakt bleibt **Zip**, kein DMG. `src/worker.js` liefert `/Diptychon.zip`,
  die Copy nennt eine Zip-Größe. DMG plus Homebrew Cask (in
  `docs/distribution.md` als „Target" skizziert) ist ein späteres Ticket.
- Notary-Credentials über **App-Store-Connect-API-Key** (`.p8`) plus
  `xcrun notarytool store-credentials`, so wie in `PLAN.md` festgelegt — nicht
  über app-specific password.
- Keychain-Profil heißt `diptychon-notary`.
- `project.yml` bleibt unangetastet: ad-hoc-Signing für lokale Builds, das
  Release-Signing passiert nach dem Build im Skript. Sonst bricht jeder
  Entwickler-Build ohne Zertifikat.
- Kein `--deep`. Apple hat es für Distributions-Signing abgekündigt; das Skript
  signiert vorhandenen verschachtelten Code zuerst, dann das App-Bundle.
  (Der aktuelle Release-Build hat kein `Contents/Frameworks`, SwiftTerm linkt
  statisch — die Schleife ist eine Absicherung, kein Muss.)

### Was ich jetzt liefere (ohne Zertifikat lauffähig, aber verweigert sauber)

1. `scripts/release.sh` — ein Durchlauf von main zum notarisierten Zip:
   - `xcodebuild build -scheme Diptychon -configuration Release -derivedDataPath .build-dd`
   - Team-ID aus `security find-identity -v -p codesigning` ziehen (die Klammer
     hinter „Developer ID Application"), nicht hart kodieren. Fehlt die
     Identity: mit lesbarer Meldung abbrechen
   - verschachtelten Code signieren, falls vorhanden, dann das Bundle:
     `codesign --force --options runtime --timestamp --entitlements Resources/Diptychon.entitlements`
     (`--options runtime` und `--timestamp` sind die zwei häufigsten stillen
     Notarisierungs-Ablehnungen)
   - `ditto -c -k --keepParent` zum Zip — `notarytool` nimmt kein nacktes `.app`
   - `xcrun notarytool submit --wait --keychain-profile diptychon-notary`
   - `xcrun stapler staple` auf das **`.app`**, nicht auf das Zip
   - **neu zippen** nach dem Stapeln. Wird der Schritt vergessen, geht ein
     ungestapeltes Zip raus: online läuft es über Ticket-Lookup durch, offline
     nicht — der schlimmste Fehlerfall
   - `codesign -dv --verbose=4` und `spctl -a -vv` als lokale Endkontrolle
   - Keine Keys, keine Passwörter, keine Issuer-IDs im Repo — nur der Profilname
2. `docs/distribution.md` bekommt den echten Runbook-Pfad. **Die Anleitung für
   den Gatekeeper-Bypass bleibt vorerst drin** und fliegt erst in dem Commit
   raus, der die grüne `spctl`-Ausgabe dokumentiert. Sonst verspricht die Doku
   dasselbe, was dieses Ticket am Download kritisiert. Die Umschreibung ist
   über 30 % der Datei, geht also vorher als Review in den Chat.
3. Zeiger in `project.yml` korrigieren: der Kommentar verweist auf „issue 10",
   das ist aber Full Disk Access. Distribution ist dieses Ticket.

### Was Till machen muss (blockiert alles ab Schritt 2)

1. Enrollment-Status prüfen — kann bis zu 48 h „pending" stehen
2. **Developer ID Application**-Zertifikat erzeugen (Xcode ▸ Settings ▸
   Accounts ▸ Manage Certificates ▸ +, oder über das Portal mit einer CSR aus
   der Schlüsselbundverwaltung). Der private Schlüssel entsteht dabei lokal und
   muss im Schlüsselbund landen
3. Notary-API-Key in App Store Connect holen (Users and Access ▸ Integrations ▸
   App Store Connect API). **Die `.p8` lädt genau einmal.** Key ID und Issuer ID
   mitschreiben
4. `xcrun notarytool store-credentials diptychon-notary --key <p8> --key-id <id> --issuer <uuid>`
5. Ausgabe von `security find-identity -v -p codesigning` durchgeben

### Danach (ein Durchlauf, größtenteils automatisiert)

`scripts/release.sh` laufen lassen, gestapeltes Zip nach
`.scratch/landing-page/dist/Diptychon.zip`, bare `npx wrangler deploy` aus
`.scratch/landing-page` (CLI-Flag-Deploys killen die www-Domain), dann die
Größenangaben nachziehen: `vs.html` nennt 1,5 MB an vier Stellen, gemessen am
alten Zip vom 2026-07-17 (1.560.529 B). Neue Zahl neu messen, nicht schätzen.

**Vorher fragen:** die Verifikation in Schritt 6 prüft
`/Applications/Diptychon.app` — das überschreibt Tills installierte Kopie.

#71 wird erst frei, wenn `spctl -a -vv` grün ist.

## Done heißt

Ein von diptychon.com heruntergeladenes Zip startet auf einem Mac ohne
Entwicklerwerkzeuge per Doppelklick, ohne Gatekeeper-Dialog. Mit Ausgabe von
`spctl -a -vv` in diesem Issue dokumentiert.

## Stand 2026-08-04

- Mitgliedschaft aktiv, **Developer-ID-Application-Zertifikat angelegt**:
  `Developer ID Application: Till von Krueger (XDCAAWJ75G)`, Team `XDCAAWJ75G`.
- `scripts/release.sh` gebaut: Preflight, frischer Release-Build, Signing mit
  Hardened Runtime und Timestamp, Notarisierung, Stapeln, Neu-Zippen, lokale
  `spctl`-Kontrolle. Ausgabe nach `build/release/Diptychon.zip` (gitignored).
  Platzierung in `dist/` und Deploy macht das Skript bewusst nicht — es druckt
  die Schritte nur aus.
- Preflight gegengeprüft: Identity und Team-ID werden korrekt geparst, ohne
  Notary-Credentials bricht das Skript vor dem Build ab, mit lesbarer Meldung.
- **Offen, Till:** API-Key in App Store Connect ▸ Users and Access ▸
  Integrations, dann
  `xcrun notarytool store-credentials diptychon-notary --key <p8> --key-id <id> --issuer <uuid>`.
  Bis dahin ist nichts notarisiert und die Copy darf nichts anderes behaupten.
- `docs/distribution.md` bleibt vorerst unverändert: die Bypass-Anleitung ist
  heute noch wahr und fliegt erst raus, wenn `spctl` auf einem echten Download
  grün ist.
- **Runbook:** `context/notarization-runbook.md` ist ab jetzt das
  Standarddokument für Notarisierung. `docs/distribution.md` zeigt darauf und
  behält bis zur Abnahme den Ad-hoc-Weg.
- Nebenbefund ausgelagert nach **#78**: die Größenangabe ist nicht eine Zahl,
  die nachgezogen wird, sondern zwölf Stellen mit zwei widersprüchlichen Werten
  plus zwei Preis-Claims, die #66 vorgreifen. Gehört zum Website-Umbau (#71),
  nicht in dieses Ticket.

## Stand 2026-08-10 — notarisiertes Artefakt liegt vor

Sauberer Volllauf von `main` (`31f2fe6`):

- Einreichung `e8b1859e-2880-4dc6-b7fe-715740f81b53`, `status: Accepted` nach
  rund einer Minute
- gestapelt, `stapler validate` grün, `spctl` lokal
  `source=Notarized Developer ID`
- Artefakt: `build/release/Diptychon.zip`, **2.657.585 Bytes**, installiert
  **9,0 MB**

Damit sind Schritte 1 bis 4 der Liste oben erledigt. Offen: Zip nach `dist/`,
deployen, Größen nachziehen (#78), **Abnahme über einen echten Download**.
Bis dahin liefert `diptychon.com/download` unverändert das alte, nicht
notarisierte Zip vom 2026-07-17.

Skript inzwischen dreimal gehärtet, siehe `context/notarization-runbook.md`:
Branch- und Sauberkeitszwang auf Build-Inputs, Statusauswertung statt
Exit-Code, `--resume` nach Netzabbruch.

## Stand 2026-08-07

Erster Volllauf am 2026-08-05 gemacht. Ergebnis gemischt:

- **Pipeline funktioniert.** Einreichung `3ff520fe-506a-4c23-b852-d527315464d9`
  kam mit `status: Accepted` zurück. Signatur, Hardened Runtime und Zeitstempel
  akzeptiert Apple.
- **Kein auslieferbares Artefakt.** Der Lauf baute aus dem Arbeitsverzeichnis,
  in dem eine parallele Session gerade `feat/42-docs-regenerated` mit
  schmutzigem Arbeitsbaum liegen hatte. Das Binary entspricht keinem Commit und
  wurde nie gestapelt. Verworfen.
- Der Poller starb zusätzlich an einem Netzabbruch (`Code=-1009`), nachdem der
  Upload schon durch war. Die Einreichung lief bei Apple weiter — sie brauchte
  rund 40 Minuten statt der üblichen 1 bis 5.
- `diptychon.com/download` liefert unverändert das alte Zip vom 2026-07-17.

**Nächster Schritt:** eigener Worktree auf `main`, dort bauen. Vier bekannte
Lücken im Skript stehen im Runbook unter „Bekannte Grenzen" — Branch- und
Sauberkeitszwang zuerst, sonst wiederholt sich genau dieser Lauf.

## Outcome

_(offen)_
