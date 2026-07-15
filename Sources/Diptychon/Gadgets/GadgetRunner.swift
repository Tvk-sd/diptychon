import AppKit

/// Launches a gadget (issue 36). Application gadgets go through `NSWorkspace`
/// — the same call as Open With. Executable gadgets spawn a `Process` with an
/// argv **array**, never a shell string, so a hostile filename can't inject
/// anything. Fire-and-forget: output is not captured (issue non-goal). The app
/// is not sandboxed (ADR 0001), so spawning needs no entitlement.
@MainActor
enum GadgetRunner {
    static func run(_ gadget: Gadget, context: GadgetContext) {
        do {
            switch gadget.type {
            case .application: try openApplication(gadget, context: context)
            case .executable: try launchExecutable(gadget, context: context)
            }
        } catch let error as GadgetSubstitutionError {
            presentError(gadget, error.message)
        } catch {
            presentError(gadget, error.localizedDescription)
        }
    }

    /// The expanded command line, shown in the first-run confirm (decision B:
    /// the user sees exactly what will run before anything runs). Best effort —
    /// an expansion error shows as itself, the run path re-throws it properly.
    static func commandPreview(_ gadget: Gadget, context: GadgetContext) -> String {
        do {
            let target = try GadgetSubstitution.expandSingle(gadget.target, location: "target", context: context)
            let argv = try GadgetSubstitution.expandArgs(gadget.args ?? [], context: context)
            return ([target] + argv).joined(separator: "\n  ")
        } catch let error as GadgetSubstitutionError {
            return error.message
        } catch {
            return error.localizedDescription
        }
    }

    /// First-run confirm for an executable gadget. Returns whether to proceed.
    static func confirmFirstRun(_ gadget: Gadget, context: GadgetContext) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Run \"\(gadget.name)\" for the first time?"
        alert.informativeText = """
        This gadget runs an external command with your user privileges:

        \(commandPreview(gadget, context: context))

        You won't be asked again for this gadget.
        """
        alert.addButton(withTitle: "Run")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    // MARK: - Launch paths

    private static func openApplication(_ gadget: Gadget, context: GadgetContext) throws {
        let appPath = try GadgetSubstitution.expandSingle(gadget.target, location: "target", context: context)
        let urls = context.activeSelectionPaths.map { URL(fileURLWithPath: $0) }
        guard !urls.isEmpty else {
            throw GadgetSubstitutionError.selectionRequired(variable: GadgetVariable.activeSelectionPaths.rawValue)
        }
        NSWorkspace.shared.open(urls, withApplicationAt: URL(fileURLWithPath: appPath),
                                configuration: NSWorkspace.OpenConfiguration()) { _, error in
            guard let error else { return }
            Task { @MainActor in presentError(gadget, error.localizedDescription) }
        }
    }

    private static func launchExecutable(_ gadget: Gadget, context: GadgetContext) throws {
        let target = try GadgetSubstitution.expandSingle(gadget.target, location: "target", context: context)
        let argv = try GadgetSubstitution.expandArgs(gadget.args ?? [], context: context)
        let cwd = try gadget.workingDirectory.map {
            try GadgetSubstitution.expandSingle($0, location: "workingDirectory", context: context)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: (target as NSString).expandingTildeInPath)
        process.arguments = argv
        if let cwd { process.currentDirectoryURL = URL(fileURLWithPath: cwd) }

        // Off the main thread — the spawn touches disk; failures hop back for the alert.
        Task.detached {
            do { try process.run() }
            catch { await MainActor.run { presentError(gadget, error.localizedDescription) } }
        }
    }

    private static func presentError(_ gadget: Gadget, _ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Gadget \"\(gadget.name)\" failed"
        alert.informativeText = message
        alert.runModal()
    }
}
