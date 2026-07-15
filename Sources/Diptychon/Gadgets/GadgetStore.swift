import Foundation
import Observation

/// Owns the user's gadgets (issue 36): loads `gadgets.json` from Application
/// Support (decision A — a hand-editable file, since v1 has no GUI) and tracks
/// which executable gadgets have had their first run confirmed (decision B).
/// Load problems are collected, not thrown — the palette keeps working with
/// whatever parsed.
@MainActor @Observable
final class GadgetStore {
    private(set) var gadgets: [Gadget] = []
    private(set) var loadErrors: [String] = []
    let configURL: URL

    /// ids of executable gadgets the user has confirmed once (decision B).
    /// Persisted so the dialog is first-run-only, not every-run.
    private var confirmedRuns: Set<String>
    private let defaults: UserDefaults
    private static let confirmedKey = "gadgetConfirmedRuns"

    nonisolated static var defaultConfigURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Diptychon/gadgets.json")
    }

    init(configURL: URL = GadgetStore.defaultConfigURL, defaults: UserDefaults = .standard) {
        self.configURL = configURL
        self.defaults = defaults
        self.confirmedRuns = Set(defaults.stringArray(forKey: Self.confirmedKey) ?? [])
        reload()
    }

    func reload() {
        let result = GadgetConfig.load(from: configURL)
        gadgets = result.gadgets
        loadErrors = result.errors
    }

    // MARK: - First-run confirmation (decision B)

    func needsFirstRunConfirmation(_ gadget: Gadget) -> Bool {
        gadget.type == .executable && !confirmedRuns.contains(gadget.id)
    }

    func markConfirmed(_ gadget: Gadget) {
        confirmedRuns.insert(gadget.id)
        defaults.set(Array(confirmedRuns).sorted(), forKey: Self.confirmedKey)
    }

    // MARK: - Config bootstrap

    /// Create the config with a documented starter if it doesn't exist yet —
    /// backs the palette's "Gadgets: Edit Config" so the user never has to hunt
    /// for the right path or invent the schema.
    func ensureConfigExists() throws {
        guard !FileManager.default.fileExists(atPath: configURL.path) else { return }
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Self.starterConfig.data(using: .utf8)!.write(to: configURL)
    }

    /// Starter content: one harmless example per gadget type. The "//" keys are
    /// ignored by the decoder — JSON has no comments, this is the workaround.
    nonisolated static let starterConfig = """
    {
      "//": "Diptychon gadgets — external-tool actions for the ⌘K palette. Full format: docs/gadgets.md",
      "// variables": "${active.selection.paths} ${active.selection.names} ${current.file.path} ${active.folder.path} ${inactive.folder.path} ${user.home}",
      "gadgets": [
        {
          "id": "open-in-textedit",
          "name": "Open in TextEdit",
          "type": "application",
          "target": "/System/Applications/TextEdit.app"
        },
        {
          "id": "example-list-selection",
          "name": "Example: touch selection",
          "type": "executable",
          "target": "/usr/bin/touch",
          "args": ["${active.selection.paths}"],
          "workingDirectory": "${active.folder.path}"
        }
      ]
    }
    """
}
