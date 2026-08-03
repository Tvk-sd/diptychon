# 74 — Menüleiste: die Tastaturbelegung auffindbar machen

Status: **ready-for-agent**
Category: bug / onboarding

## Parent

`#68` Readiness-Gate, Blocker **B1**. Der einzige Blocker, der die Triage
überlebt hat.

## Problem

`Sources/Diptychon/App/DiptychonApp.swift` hat **keinen `.commands { }`-Block**.
Die App läuft mit der unveränderten SwiftUI-Standardmenüleiste: kein einziger
eigener Menüeintrag, kein Hinweis auf die Tastaturbelegung, kein Verweis auf
Doku.

Das ist ausgerechnet bei diesem Produkt teuer. Das ganze Versprechen ist
„keyboard-first"; der Erstnutzer findet aber genau die Sache nicht, die ihn
überzeugen würde. Er sieht zwei Panels und weiß nicht, dass Tab umschaltet,
⌘⌥→ kopiert, ⌘⇧G springt.

**Die Referenz existiert bereits** — Einstellungen (⌘,) → Tab „Shortcuts" listet
alle `AppAction`s mit Glyphen (`HotkeyEditorView`, `manager.glyphs(for:)`).
Ebenso die Command-Palette (⌘K, #19). Beide Wege setzen voraus, dass man ⌘, oder
⌘K **schon kennt**. Das ist die ganze Lücke: nicht fehlende Information,
fehlender Weg dorthin.

Zweitens: `docs/keyboard-reference.md` (aus `Keymap.default` generiert) liegt im
Repo, **nicht im App-Bundle**. Wer ein Zip lädt, sieht es nie.

## Was zu bauen ist

Ein `.commands`-Block in `DiptychonApp.swift`, minimal gehalten:

- **Hilfe-Menü**: Eintrag, der die Einstellungen auf dem Shortcuts-Tab öffnet
  (`SettingsLink` bzw. `@Environment(\.openSettings)`). Beschriftung sagt, was
  man bekommt — „Keyboard Shortcuts", nicht „Hilfe"
- **Command-Palette** als Menüeintrag mit sichtbarem ⌘K, damit der zweite
  Discovery-Weg selbst auffindbar wird
- Kein eigenes Hilfe-Fenster, keine neue Doku-Oberfläche. Die Referenz gibt es,
  sie braucht nur eine Tür

## Zu prüfen beim Bauen

SwiftUI setzt ohne Zutun einen Eintrag „Diptychon Help" ins Hilfe-Menü. Ohne
`CFBundleHelpBookName` im Info.plist läuft der ins Leere („Help isn't available
for Diptychon"). Falls das so ist: ersetzen statt danebenstellen — ein
Menüeintrag, der eine Fehlermeldung öffnet, ist im Erstkontakt schlimmer als
keiner.

## Nicht in diesem Ticket

- `#42` Docs & Onboarding — der fertige Tier-2-Entwurf braucht Tills Durchsicht,
  nicht Code
- Ein Onboarding-Overlay oder Tutorial. Ungefragt und teurer als das Problem

## Acceptance criteria

- [ ] Ein Erstnutzer, der nur die Menüleiste ansieht, findet die vollständige
      Tastaturbelegung in höchstens zwei Klicks
- [ ] ⌘K ist als Menüeintrag mit Kürzel sichtbar
- [ ] Kein Menüeintrag führt in eine Fehlermeldung
- [ ] Volle Suite grün vor dem Merge

## Outcome (2026-08-04) — gebaut, Suite grün, Live-Check offen

`Sources/Diptychon/App/DiptychonApp.swift`, uncommitted:

```swift
.commands {
    CommandGroup(replacing: .help) {
        SettingsLink { Text("Keyboard Shortcuts…") }
    }
}
```

Drei Entscheidungen dahinter:

- **`replacing: .help`, nicht `after:`** — ohne `CFBundleHelpBookName` öffnet der
  Standard-Eintrag „Diptychon Help" eine Fehlermeldung. Im Erstkontakt ist ein
  Menüeintrag, der in einen Fehler läuft, schlimmer als keiner
- **Kein `.keyboardShortcut`** am Eintrag. Der `NSEvent`-Monitor ist die
  Tastatur-Autorität (`Keymap`/`AppAction`); ein SwiftUI-Kürzel wäre ein zweiter
  Pfad, den der Shortcut-Editor nicht umbelegen kann und der nach einem Rebind
  falsch beschriftet wäre
- **Kein eigenes Hilfefenster.** Die vollständige Referenz existiert schon als
  `HotkeyEditorView` (Einstellungen → Shortcuts, `manager.glyphs(for:)`) und
  bleibt automatisch korrekt, auch nach Umbelegungen. Der Eintrag ist nur die Tür

`SettingsLink` ist macOS 14+, Deployment-Target ist 14.0 — passt.

**Verifiziert:** `xcodegen generate` + Build grün; volle Suite **216 Unit +
13 UI, 0 Fehler**.

**Echter Aufrufpfad verifiziert** — per UI-Test statt per Hand, weil Tills
Instanz lief (pid 10175) und ein `open` bei gleicher Bundle-ID nur die alte
Instanz aktiviert hätte. XCUITest startet eine eigene Instanz, kollidiert also
nicht: `testHelpMenuOffersKeyboardShortcutsAndNotTheBrokenDefault` klickt Hilfe,
klickt den Eintrag und prüft, dass ein Fenster mit Titel **„Shortcuts"**
erscheint. Ein macOS-Settings-Fenster übernimmt den Tab-Namen als Fenstertitel —
damit belegt eine Assertion beides: Settings offen **und** auf dem Keymap-Tab.

Zwischenbefund beim Schreiben des Tests: `app.windows.element(boundBy: 1)` ist
das Arbeitsfenster (steht auf `Disabled`, während Settings davor liegt), nicht
das Settings-Fenster — Abfrage über den Titel ist hier der stabile Weg.

**Nachziehen, sobald `#42` die Doku unter `diptychon.com/docs` stellt:** ein
zweiter Eintrag „User Guide" daneben. Jetzt noch nicht — der Link ginge ins
Leere, und das verletzt die eigene Akzeptanzbedingung „kein Menüeintrag führt in
eine Fehlermeldung".

### Acceptance criteria

- [x] Tastaturbelegung in höchstens zwei Klicks aus der Menüleiste — **im
      Erstlauf**, per UI-Test durch den echten Aufrufpfad belegt: Hilfe klicken,
      Eintrag klicken, Fenster mit Titel „Shortcuts" erscheint.
      **Bekannte Grenze:** ein macOS-`TabView` stellt die zuletzt gewählte
      Auswahl wieder her. Wer zuletzt auf „Full Disk Access" war, landet dort.
      Für #68 (Erstkontakt) unerheblich, weil ein frischer Nutzer keine
      gespeicherte Auswahl hat. Wenn das stören soll: Tab explizit binden
- [ ] ~~⌘K als Menüeintrag mit Kürzel sichtbar~~ — **verworfen.** Wäre ein
      zweiter Tastaturpfad neben dem `NSEvent`-Monitor und würde nach einem
      Rebind ein falsches Kürzel anzeigen. `openPalette` steht ohnehin mit
      aktueller Belegung in der Shortcuts-Liste
- [x] Kein Menüeintrag führt in eine Fehlermeldung — **im Hilfe-Menü**, per
      UI-Test: „Diptychon Help" ist nachweislich weg, nicht danebengestellt.
      Die übrigen SwiftUI-Standardmenüs (Ablage/Bearbeiten/Darstellung/Fenster)
      sind **nicht** durchgesehen; das gehört in Teil 2 von #68
- [x] Volle Suite grün vor dem Merge _(216 Unit + **14** UI, 2026-08-04 — der
      neue Test ist der vierzehnte)_
