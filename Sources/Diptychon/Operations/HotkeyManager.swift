import AppKit

/// A user's change to one action's binding (issue 44). Absence of an override means
/// "use the default"; `.unbound` means the user explicitly cleared it (or it was
/// stolen); `.rebind` is a user-chosen chord. `Codable` for `UserDefaults` storage.
enum HotkeyOverride: Equatable, Codable {
    case rebind(KeyChord)
    case unbound
}

extension Keymap {
    /// The effective action→key table = `Keymap.default` with per-action overrides
    /// layered on top. An overridden action's default entries are dropped; a `.rebind`
    /// re-adds it with the chosen chord, `.unbound` leaves it with none. Multi-chord
    /// defaults (e.g. the ⌥⌘←/→ pair) collapse to the single chosen chord on rebind.
    static func resolve(overrides: [AppAction: HotkeyOverride]) -> [(chord: KeyChord, action: AppAction)] {
        var result = `default`.filter { overrides[$0.action] == nil }
        for (action, override) in overrides {
            if case .rebind(let chord) = override { result.append((chord, action)) }
        }
        return result
    }
}

/// App-global, observable owner of the effective keymap (issue 44). A single shared
/// instance so every scene agrees: the main window's key dispatch, the command
/// palette's shortcut hints, and the Settings recorder all read/write the same state.
/// Overrides persist to `UserDefaults` as one JSON blob; unknown/corrupt data falls
/// back to defaults silently (a bad blob must never brick the keyboard).
@Observable final class HotkeyManager {
    static let shared = HotkeyManager()
    static let storeKey = "hotkeyOverrides"

    private(set) var overrides: [AppAction: HotkeyOverride]
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.overrides = Self.load(from: defaults)
    }

    /// `Keymap.default` with overrides applied — what dispatch and hints read.
    var effectiveMap: [(chord: KeyChord, action: AppAction)] {
        Keymap.resolve(overrides: overrides)
    }

    /// Resolve an `NSEvent` against the effective map (drop-in for `Keymap.action`).
    func action(for event: NSEvent) -> AppAction? {
        Keymap.action(for: event, in: effectiveMap)
    }

    /// The effective chord bound to `action` (the first, keeping one-chord-per-action
    /// in the UI), or nil if unbound.
    func chord(for action: AppAction) -> KeyChord? {
        effectiveMap.first { $0.action == action }?.chord
    }

    /// `action`'s effective chord as glyphs (e.g. "⇧⌘R"), or nil if unbound.
    func glyphs(for action: AppAction) -> String? { chord(for: action).map(\.glyphs) }

    /// True when the user has changed `action` from its default (rebound or cleared).
    func isOverridden(_ action: AppAction) -> Bool { overrides[action] != nil }

    // MARK: Mutations (steal-and-unbind — issue 44 decision)

    /// A locked action currently bound to `chord`, if any — such a chord can't be stolen
    /// (rebinding onto it must be refused, or dispatch would be ambiguous). Issue 44.
    func reservedOwner(of chord: KeyChord) -> AppAction? {
        AppAction.allCases.first { !$0.isRebindable && self.chord(for: $0) == chord }
    }

    /// Bind `action` to `chord`, stealing it from any other *rebindable* action that
    /// owns it (the previous owner is left unbound). No-op if `action` is locked or the
    /// chord belongs to a locked action (caller should have refused via `reservedOwner`).
    func rebind(_ action: AppAction, to newChord: KeyChord) {
        guard action.isRebindable, reservedOwner(of: newChord) == nil else { return }
        for other in AppAction.allCases
        where other != action && other.isRebindable && chord(for: other) == newChord {
            overrides[other] = .unbound
        }
        overrides[action] = .rebind(newChord)
        save()
    }

    /// Clear `action`'s binding (leaves it unbound). No-op for locked actions.
    func clear(_ action: AppAction) {
        guard action.isRebindable else { return }
        overrides[action] = .unbound
        save()
    }

    /// Restore every binding to `Keymap.default`.
    func reset() {
        overrides = [:]
        save()
    }

    // MARK: Persistence

    private func save() {
        let byName = Dictionary(uniqueKeysWithValues: overrides.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(byName) {
            defaults.set(data, forKey: Self.storeKey)
        }
    }

    private static func load(from defaults: UserDefaults) -> [AppAction: HotkeyOverride] {
        guard let data = defaults.data(forKey: storeKey),
              let byName = try? JSONDecoder().decode([String: HotkeyOverride].self, from: data)
        else { return [:] }
        var result: [AppAction: HotkeyOverride] = [:]
        for (name, override) in byName {
            if let action = AppAction(rawValue: name) { result[action] = override } // ignore unknown keys
        }
        return result
    }
}
