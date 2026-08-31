import AppKit

/// Which app the system opens when another app says "Show in Finder" (issue 54).
///
/// macOS reads the global `NSFileViewer` default to decide who receives a reveal.
/// Diptychon already *answers* one (`public.folder` doc type → `openExternal`, merge
/// `24f9396`); what was missing was a way to become the receiver without typing
/// `defaults write -g NSFileViewer …` in a Terminal. This is that way.
///
/// **Reveal only.** Folder double-clicks, the Desktop and Open/Save dialogs stay with
/// Finder — macOS 26 blocks `public.folder` handlers at the content-type level. That
/// is a proven dead end, not a gap; see `context/finder-replacement-runbook.md`.
///
/// Writing the global domain needs no privileges here because the app is unsandboxed
/// (ADR 0001) — no helper tool, no admin prompt.
enum RevealHandler {
    /// The global default macOS consults for reveals.
    static let defaultsKey = "NSFileViewer"

    /// Us, as the system knows us.
    static var appBundleID: String {
        Bundle.main.bundleIdentifier ?? "com.diptychon.app"
    }

    /// Who currently receives reveals.
    ///
    /// Three cases, not two: the key can also point at *another* file manager. Folding
    /// that into "off" would be a lie the UI then tells — the user would read "Finder
    /// handles this" while ForkLift actually does.
    enum State: Equatable {
        /// Diptychon receives reveals.
        case diptychon
        /// No key set — Finder receives them, the macOS default.
        case systemDefault
        /// Another app claimed it. Carries the bundle id so the UI can name it.
        case otherApp(String)
    }

    /// Map a raw `NSFileViewer` value to what it means for us.
    ///
    /// Pure, and the only part worth testing: everything else is a preferences call.
    /// `ourBundleID` is a parameter rather than read from the bundle so a test can pin
    /// it — under XCTest the bundle identifier is the test runner's, not the app's.
    static func state(forRawValue raw: String?, ourBundleID: String) -> State {
        guard let raw, !raw.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .systemDefault
        }
        // Bundle ids are case-insensitive to Launch Services, so a hand-typed
        // "Com.Diptychon.App" must still read as us rather than as a stranger.
        return raw.caseInsensitiveCompare(ourBundleID) == .orderedSame
            ? .diptychon
            : .otherApp(raw)
    }

    /// The live state, read from the system every time.
    ///
    /// Never cached and never mirrored into our own defaults: the user can change this
    /// from a Terminal or another file manager, and a remembered flag would then show
    /// the wrong thing with full confidence.
    static var currentState: State {
        state(forRawValue: rawValue(), ourBundleID: appBundleID)
    }

    /// Become the reveal target.
    static func enable() {
        setRawValue(appBundleID)
    }

    /// Hand reveals back to Finder.
    ///
    /// Deletes the key rather than writing `com.apple.finder`. Restoring the *absence*
    /// of a setting is what "back to normal" means; an explicitly written Finder value
    /// would leave a second, stickier kind of default behind.
    static func disable() {
        setRawValue(nil)
    }

    // MARK: - The global preferences domain

    private static func rawValue() -> String? {
        CFPreferencesCopyValue(defaultsKey as CFString,
                               kCFPreferencesAnyApplication,
                               kCFPreferencesCurrentUser,
                               kCFPreferencesAnyHost) as? String
    }

    /// `kCFPreferencesAnyApplication` + `AnyHost` is the exact domain `defaults -g`
    /// writes (`~/Library/Preferences/.GlobalPreferences.plist`). A different host
    /// scope would write a file macOS never reads for this.
    private static func setRawValue(_ value: String?) {
        CFPreferencesSetValue(defaultsKey as CFString,
                              value as CFPropertyList?,
                              kCFPreferencesAnyApplication,
                              kCFPreferencesCurrentUser,
                              kCFPreferencesAnyHost)
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
    }
}
