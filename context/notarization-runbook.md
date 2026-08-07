# Runbook: Diptychon signieren, notarisieren, ausliefern

Selbständig ausführbar oder als Auftrag an Claude übergebbar. Stand: 2026-08-07.

Dies ist das Standarddokument für Notarisierung. Das Skript dazu ist
`scripts/release.sh`. `docs/distribution.md` beschreibt weiterhin den alten
Ad-hoc-Weg für Einzeltester — der gilt, bis der erste notarisierte Download
verifiziert ist (Issue **#69**).

---

## Status

| | Stand |
|---|---|
| Apple-Developer-Mitgliedschaft | aktiv |
| Developer-ID-Zertifikat | vorhanden, Team `XDCAAWJ75G` |
| Notary-Credentials | im Schlüsselbund, Profil `diptychon-notary` |
| `scripts/release.sh` | vorhanden, einmal komplett durchgelaufen |
| Notarisierung technisch bewiesen | **ja** — Einreichung `3ff520fe-…5464d9` vom 2026-08-05 kam mit `status: Accepted` zurück |
| Stapeln bewiesen | **ja** — am 2026-08-07 von Hand nachgeholt, `stapler validate` grün, `spctl` meldet `source=Notarized Developer ID` |
| Auslieferbares Artefakt | **nein** — siehe unten |
| `diptychon.com/download` | liefert weiterhin das alte, nicht notarisierte Zip vom 2026-07-17 |

**Warum es trotz `Accepted` kein Release gibt:** der Lauf vom 2026-08-05 baute
aus dem Arbeitsverzeichnis, in dem gerade der Branch `feat/42-docs-regenerated`
mit schmutzigem Arbeitsbaum lag — eine parallele Session hatte umgeschaltet.
Das Artefakt entspricht keinem Commit, also weiß niemand, was drin ist. Es
wurde nicht gestapelt und darf nicht ausgeliefert werden. Der Lauf zählt als
Rauchtest der Pipeline: Build, Signatur mit Hardened Runtime, Zeitstempel,
Upload und Apples Prüfung funktionieren nachweislich.

**Nächster Schritt:** einen sauberen Worktree auf `main` anlegen, dort bauen.
Siehe „Bekannte Grenzen" unten.

---

## Kontext

macOS blockt seit Catalina jede App aus dem Netz, die nicht von Apple
notarisiert ist. Gatekeeper prüft dabei drei Dinge:

1. **Signatur** mit einem Developer-ID-Application-Zertifikat
2. **Hardened Runtime** plus sicherer Zeitstempel
3. **Notarisierungs-Ticket** — Apple hat das Binary auf Malware geprüft

Das Ticket liegt zunächst nur auf Apples Servern. `stapler staple` klebt eine
Kopie ins `.app`, damit die Prüfung auch offline gelingt.

Ausgelöst wird die Prüfung vom Attribut `com.apple.quarantine`, das der
**Browser** beim Download setzt. Eine lokal kopierte App trägt es nicht.
Deshalb beweist kein lokaler Test etwas — die Abnahme läuft immer über einen
echten Download.

---

## Einmalige Einrichtung (erledigt am 2026-08-04/05)

Nur zur Dokumentation. Muss nur wiederholt werden, wenn Zertifikat oder Key
ablaufen oder widerrufen werden.

### 1. Zertifikat

Xcode ▸ Settings ▸ Accounts ▸ Manage Certificates ▸ `+` ▸ **Developer ID
Application**.

Nicht „Apple Development" (nur lokale Geräte) und nicht „Apple Distribution"
(nur App Store). Für ein Zip auch nicht „Developer ID Installer", das ist für
`.pkg`.

Prüfen:

```bash
security find-identity -v -p codesigning
# erwartet: "Developer ID Application: Till von Krueger (XDCAAWJ75G)"
```

Die Klammer ist die Team-ID. Das Skript liest sie von hier, sie steht nirgends
fest verdrahtet.

### 2. Notary-Credentials

App Store Connect ▸ Users and Access ▸ Integrations ▸ App Store Connect API ▸
Team Keys ▸ `+`. Rolle **Developer** wurde am 2026-08-05 verwendet und
funktioniert für Notarisierung. Ob eine niedrigere Rolle reichen würde, ist
ungeprüft.

Die `.p8` lädt genau einmal. Zusammen mit Key ID und Issuer ID gehört sie in
den Passwort-Manager, **nicht ins Repository** — sie erlaubt, in Tills Namen zu
notarisieren, und eine einmal committete Datei steht dauerhaft in der
Git-History.

```bash
xcrun notarytool store-credentials diptychon-notary \
  --key ~/pfad/AuthKey_XXXXXXXX.p8 --key-id <KEY_ID> --issuer <ISSUER_UUID>
```

Alles in **einer** Zeile. Ein Zeilenumbruch nach `store-credentials` lässt zsh
den Rest als eigenen Befehl lesen — daran ist es am 2026-08-05 zweimal
gescheitert.

Danach liegen die Zugangsdaten im Schlüsselbund. Das Skript kennt nur den
Profilnamen; die `.p8` wird nie wieder gelesen.

Prüfen:

```bash
xcrun notarytool history --keychain-profile diptychon-notary
```

---

## Der Release-Lauf

```bash
cd "/Users/Till/Projects/untitled folder"
./scripts/release.sh
```

Dauer: 2 bis 10 Minuten, davon der Löwenanteil Wartezeit bei Apple.

| Schritt | Was passiert | Warum |
|---|---|---|
| Preflight | Zertifikat und Notary-Profil prüfen, Team-ID auslesen, Branch und Arbeitsbaum melden | scheitert in Sekunden statt nach Minuten |
| Build | `.build-dd` löschen, Release neu bauen | #69: nie das alte Zip notarisieren, es kennt das Terminal (#65) nicht |
| Signieren | `xattr -cr`, dann `codesign --options runtime --timestamp --entitlements` | Hardened Runtime und Zeitstempel sind Pflicht; die Entitlements müssen beim Neusignieren erneut mit, sonst verliert die App den Dateizugriff |
| Einreichen | `ditto` zum Zip, `notarytool submit --wait` | `notarytool` nimmt kein nacktes `.app` |
| Stapeln | `stapler staple` aufs `.app` | holt das Ticket ins Bundle |
| Neu zippen | zweites `ditto` | **der Schritt, den man vergisst** |
| Sanity-Check | `codesign --verify`, `stapler validate` | bewusst kein `spctl` |

Ergebnis: `build/release/Diptychon.zip` (gitignored) plus eine ausgedruckte
Checkliste.

### Warum zweimal gezippt wird

Das erste Zip geht nur zu Apple. Das Ticket landet im `.app`, nicht im Zip.
Wer das Einreichungs-Zip ausliefert, liefert eine ungestapelte App: online
läuft sie, weil macOS das Ticket nachfragt, **offline verweigert sie**. Ein
Fehler, der beim Entwickler nie auftritt.

### Warum der Sanity-Check kein `spctl` ist

Das frisch gebaute Bundle hat kein Quarantäne-Attribut — das Skript hat es
sogar aktiv entfernt. Gatekeeper bewertet es milder als einen echten Download.
Ein grünes lokales `spctl` sieht aus wie ein Beweis und ist keiner.

---

## Was Apple antwortet

`notarytool submit --wait` gibt zuerst eine **Submission ID** aus, pollt dann
und endet mit einem Statusblock:

| Status | Bedeutung | Reaktion |
|---|---|---|
| `Accepted` | durch, Ticket liegt bereit | Skript stapelt weiter |
| `Invalid` | verarbeitet, durchgefallen | Log lesen, Ursache fixen, neu einreichen |
| `Rejected` | Policy-Verstoß, selten | Log lesen |
| `In Progress` | rechnet noch | warten |

Das ist keine App-Review, kein Mensch schaut drauf. Normal 1 bis 5 Minuten;
die erste Einreichung eines neuen Teams dauerte hier **rund 40 Minuten**.

```bash
# Status einer Einreichung
xcrun notarytool info <submission-id> --keychain-profile diptychon-notary

# Ablehnungsgrund im Klartext
xcrun notarytool log <submission-id> --keychain-profile diptychon-notary

# alle bisherigen Einreichungen
xcrun notarytool history --keychain-profile diptychon-notary
```

---

## Wenn etwas schiefgeht

| Symptom | Ursache | Behebung |
|---|---|---|
| `no 'Developer ID Application' identity` | Zertifikat fehlt oder abgelaufen | Einrichtung Schritt 1 |
| `No Keychain password item found for profile` | `store-credentials` nie gelaufen oder anderer Profilname | Einrichtung Schritt 2 |
| `command not found: diptychon-notary` | Zeilenumbruch im `store-credentials`-Befehl | einzeilig eingeben |
| `Error … Code=-1009 … offline` beim Pollen | Netz weg, **nur der Poller stirbt** | Einreichung läuft bei Apple weiter: `notarytool info <id>` fragen, bei `Accepted` von Hand stapeln und neu zippen |
| `status: Invalid` | fehlendes Hardened Runtime, fehlender Zeitstempel, unsignierte verschachtelte Binaries | `notarytool log <id>` |
| `does not have a ticket stapled to it` | Lauf brach vor dem Stapeln ab | siehe Netz-Zeile |
| App startet lokal, meckert nach Download | ungestapeltes Zip ausgeliefert | zweites `ditto` nach dem Stapeln |

### Von Hand stapeln, wenn nur der Poller starb

```bash
APP=.build-dd/Build/Products/Release/Diptychon.app
xcrun notarytool info <submission-id> --keychain-profile diptychon-notary   # Accepted?
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
ditto -c -k --keepParent "$APP" build/release/Diptychon.zip
```

Nur gültig, solange `.build-dd` unangetastet ist. Ein neuer Build erzeugt ein
anderes Binary, dessen Hash nicht zum Ticket passt.

**Achtung:** `scripts/release.sh` beginnt mit `rm -rf .build-dd`. Ein neuer
Lauf zerstört also stillschweigend den Rettungsweg für eine noch offene
Einreichung. Wer nach einem Netzabbruch das Skript neu startet, statt von Hand
zu stapeln, verliert das Ticket und darf neu einreichen. Der `--resume`-Pfad
aus Grenze 4 muss deshalb beides festhalten: die Submission ID **und** genau
dieses `.app`.

Am 2026-08-07 auf diesem Weg nachgeholt und bewiesen — der Stapel- und
Zip-Teil des Skripts war bis dahin nie gelaufen.

---

## Nach dem Lauf — bis zur Abnahme

1. Zip nach `.scratch/landing-page/dist/Diptychon.zip`
2. Aus `.scratch/landing-page`: `npx wrangler deploy` — **bar, ohne
   CLI-Flags**, sonst fällt die www-Domain weg
3. Größenangaben nachziehen, siehe Issue **#78**. Gemessen am 2026-08-07 am
   gestapelten Bundle: Zip **2.657.584 Bytes (~2,66 MB)** gegen 1.560.529 vorher,
   installiert **9,0 MB** (`du -sh`). Die Seite nennt an zwölf Stellen 1,4 oder
   1,5 MB und 5 beziehungsweise 6 MB installiert. Zahlen aus dem sauberen Lauf
   neu messen, die hier stammen vom verworfenen Branch-Build
4. **Die Abnahme:** im Browser über `https://diptychon.com/download` laden,
   dann auf die heruntergeladene Kopie

   ```bash
   spctl -a -vv /pfad/zur/Diptychon.app
   ```

   Erwartet: `accepted` und `source=Notarized Developer ID`. Ausgabe in #69
   dokumentieren. Erst danach ist #69 zu und **#71** frei.

Schritt 4 überschreibt typischerweise `/Applications/Diptychon.app` — Tills
installierte Kopie. Vorher fragen.

---

## Bekannte Grenzen des Skripts

Offen, in dieser Reihenfolge zu beheben:

1. **Kein Branch- und Sauberkeitszwang.** Bei fremdem Branch oder schmutzigem
   Arbeitsbaum warnt das Skript nur und baut weiter. Genau so entstand am
   2026-08-05 ein notarisiertes Artefakt ohne zugehörigen Commit. Soll
   abbrechen, mit `RELEASE_ALLOW_DIRTY=1` als bewusstem Übersteuerer.
2. **Kein Worktree.** Solange eine zweite Claude-Session im selben
   Arbeitsverzeichnis arbeitet, ist jeder Release-Build ein Glücksspiel.
   Release gehört in einen eigenen Worktree auf `main`.
3. **Status wird nicht ausgewertet.** Das Skript verlässt sich auf den
   Exit-Code von `notarytool`. Ob der bei `Invalid` ungleich 0 ist, ist
   ungeprüft. Wenn nicht, läuft es weiter und scheitert erst beim Stapeln —
   mit einer schlechteren Meldung als dem Notarisierungs-Log.
4. **Kein Wiederaufsetzen.** Ein Netzabbruch beim Pollen wirft den ganzen Lauf
   weg, obwohl die Einreichung bei Apple weiterläuft. Submission ID
   persistieren, `--resume` nachrüsten, das dann nur noch wartet und stapelt.

### Falle beim Beobachten

`./scripts/release.sh | tail -40` puffert bis zum Ende — es gibt keine
Zwischenausgabe, und der gemeldete Exit-Code ist der von `tail`, nicht der des
Skripts. Am 2026-08-05 meldete ein abgestürzter Lauf so „exit code 0". Ohne
Pipe laufen lassen, oder in eine Datei mit `tee`.

---

## Historie

| Datum | Ereignis |
|---|---|
| 2026-08-04 | Mitgliedschaft aktiv, Developer-ID-Zertifikat erzeugt, `scripts/release.sh` gebaut |
| 2026-08-05 | Notary-Key erzeugt, Credentials im Schlüsselbund; erster Volllauf: Build und Signatur sauber, Einreichung `Accepted` nach ~40 min, Poller starb vorher am Netz; Build kam vom falschen Branch, Artefakt verworfen |

## Siehe auch

- `scripts/release.sh` — die ausführbare Fassung dieses Dokuments
- Issue **#69** — Download echt machen, hier liegt die Abnahme
- Issue **#78** — die Größen- und Preisangaben auf der Seite
- `docs/distribution.md` — der Ad-hoc-Weg für Einzeltester, gilt bis #69 zu ist
- `docs/adr/0001-non-sandboxed-direct-distribution.md` — warum kein App Store
