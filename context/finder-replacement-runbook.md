# Runbook: Diptychon als Standard-Ordner-Viewer (Finder-Ersatz)

Selbständig ausführbar oder als Auftrag an Claude übergebbar. Stand: 2026-07-11.

## Kontext

Diptychon kann seit dem (noch ungecommitteten) Change vom 2026-07-09 externe
„Ordner öffnen"-Events annehmen: `public.folder`-Dokumenttyp in
`Resources/Info.plist` + `onOpenURL`-Hook in `WorkspaceView` →
`WorkspaceModel.openExternal` (Ordner → rein navigieren, Datei →
Eltern-Ordner öffnen + Datei highlighten).

macOS hat kein offizielles „Standard-Dateimanager"-Setting. Der Mechanismus
unten ist derselbe undokumentierte, den Path Finder und ForkLift nutzen.
**Nicht ersetzbar bleiben:** Desktop-Icons, Open/Save-Dialoge, Dock-Stacks —
die gehören weiterhin Finder.

## Schritt 1 — Installation (am 2026-07-11 bereits ausgeführt)

Nur nötig, wenn ein neuer Build installiert werden soll. Voraussetzung: der
Debug-Build liegt unter `build/DerivedData/Build/Products/Debug/Diptychon.app`
(sonst erst `xcodegen generate && xcodebuild … build`).

```bash
cd "/Users/Till/Projects/untitled folder"
osascript -e 'tell application "Diptychon" to quit'
rm -rf /Applications/Diptychon.app
ditto build/DerivedData/Build/Products/Debug/Diptychon.app /Applications/Diptychon.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Diptychon.app
```

Verifikation — muss den Folder-Viewer-Eintrag ausgeben:

```bash
plutil -extract CFBundleDocumentTypes json -o - /Applications/Diptychon.app/Contents/Info.plist
# erwartet: [{"CFBundleTypeName":"Folder","CFBundleTypeRole":"Viewer",...}]
```

## Schritt 2 — Als Standard-Ordner-Viewer setzen (am 2026-07-11 bereits ausgeführt)

```bash
defaults write -g NSFileViewer -string com.diptychon.app
defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers \
  -array-add '{LSHandlerContentType="public.folder";LSHandlerRoleAll="com.diptychon.app";}'
```

**Achtung Duplikate:** `-array-add` hängt blind an. Vor erneutem Ausführen
prüfen, ob der Eintrag schon existiert:

```bash
defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -c "public.folder"
# 0 = noch nicht gesetzt, 1 = bereits gesetzt (dann NICHT nochmal -array-add)
```

Danach **abmelden und wieder anmelden** (oder Neustart). Launch Services
übernimmt die `LSHandlers`-Präferenz erst beim Login in seine Datenbank —
ein `killall lsd` reicht nachweislich nicht (am 2026-07-11 getestet).

## Test (nach dem Login)

```bash
open ~/Downloads
```

- **Erwartet:** Diptychon öffnet sich / kommt nach vorn, das aktive Panel
  zeigt `~/Downloads`.
- Zusatztest Datei-Reveal: in Safari/Chrome bei einem Download
  „Im Finder anzeigen" klicken → Diptychon soll den Ordner öffnen und die
  Datei grau markieren.
- **Bleibt Finder (kein Fehler):** Doppelklick auf Desktop-Icons,
  Open/Save-Dialoge in Apps, Dock-Stacks.

Wenn `open ~/Downloads` weiterhin Finder öffnet: Mechanismus greift auf
dieser macOS-Version nicht wie dokumentiert → Rollback ausführen oder
tiefer debuggen (das Setup ist Apple-seitig undokumentiert, keine Garantie).

## Rollback

```bash
# 1. Reveal-Routing zurück auf Finder
defaults delete -g NSFileViewer

# 2. Ordner-Handler entfernen — GROB: löscht ALLE benutzerdefinierten
#    Datei-Zuordnungen ("Immer öffnen mit …"), nicht nur den Folder-Eintrag
defaults delete com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers
```

Danach wieder abmelden/anmelden. Wer die übrigen Handler behalten will,
löscht statt Schritt 2 nur den `public.folder`-Eintrag aus dem Array
(z. B. via PlistBuddy oder von Hand in
`~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist`).

Die App selbst ist vom Rollback unabhängig — `/Applications/Diptychon.app`
kann bleiben; ohne die defaults verhält sie sich wie vorher.

## Ergebnis (2026-07-12): Teilerfolg — Ordner-Handler auf macOS 26 tot

- [x] Test nach Login: `open ~/Downloads` öffnet weiterhin **Finder**.
- **Ursache (bewiesen):** macOS 26 blockt den `public.folder`-Handler auf
  Typ-Ebene. Beim Login wurde der `LSHandlers`-Eintrag von Launch Services
  verworfen (Plist um 01:14 neu geschrieben, Eintrag weg). API-Beweis:
  `LSSetDefaultRoleHandlerForContentType("public.folder", …)` und
  `NSWorkspace.setDefaultApplication(toOpen: .folder)` liefern beide
  `paramErr (-50)` — **auch beim Setzen auf Finder selbst**, während die
  API für andere Typen (public.plain-text) normal funktioniert. Kein
  App-Problem, kein Rank-Problem, keine Chance über Rebuild.
- **Was funktioniert (verifiziert):** `NSFileViewer`-Reveal-Routing.
  `activateFileViewerSelecting` → Diptychon kommt nach vorn und highlightet
  die Datei. „Im Finder anzeigen" aus Browsern/Apps landet in Diptychon.
- **Weiter nutzbar trotz Block:** Ordner auf Dock-Icon ziehen,
  Rechtsklick → „Öffnen mit" → Diptychon, `open -a Diptychon <ordner>`
  (Shell-Alias möglich). Alles via dem onOpenURL-Code.
- `killall lsd` löscht den Eintrag übrigens NICHT (getestet) — nur der
  Login-Import verwirft ihn.

## Offene Punkte

- [ ] Till entscheidet: +21 Zeilen committen (Reveal + Open-With + Dock-Drop
      funktionieren und rechtfertigen den Code) oder Rollback
- [ ] Bei Behalten: `defaults delete -g NSFileViewer` NICHT ausführen —
      das trägt das Reveal-Routing. Der tote LSHandlers-Eintrag räumt sich
      beim nächsten Login von selbst weg.
- [ ] Onboarding-Follow-up-Issue nur noch für NSFileViewer sinnvoll,
      nicht mehr für den Ordner-Handler
