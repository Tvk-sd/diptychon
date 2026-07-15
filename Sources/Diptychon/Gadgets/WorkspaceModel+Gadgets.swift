import AppKit

// Gadgets (issue 36): the model glue — pane state → `GadgetContext`, gadgets →
// palette commands, and the run path with the first-run confirm.
extension WorkspaceModel {
    /// Snapshot of pane state the gadget templates resolve against. Selection in
    /// visible order, so argv order matches what the user sees.
    var gadgetContext: GadgetContext {
        let selected = activeModel.selectedItems
        return GadgetContext(
            activeSelectionPaths: selected.map(\.url.path),
            activeSelectionNames: selected.map(\.url.lastPathComponent),
            activeFolderPath: activeModel.directory.path,
            inactiveFolderPath: inactiveModel.directory.path
        )
    }

    /// The user's gadgets as palette commands (category "Gadgets"), plus the two
    /// built-ins that make a hand-edited config livable: edit and reload. Merged
    /// into the palette by `CommandPaletteSheet` — they can't live in the static
    /// `CommandCatalog.commands`.
    var gadgetPaletteCommands: [PaletteCommand] {
        let userCommands = gadgetStore.gadgets.map { gadget in
            // A gadget that resolves selection variables greys out without a
            // selection (application gadgets always act on the selection).
            let needsSelection = gadget.type == .application || GadgetSubstitution.referencesSelection(gadget)
            return PaletteCommand(
                id: "gadget:\(gadget.id)", title: gadget.name, category: "Gadgets",
                shortcut: { nil },
                isEnabled: { needsSelection ? !$0.activeModel.selection.isEmpty : true },
                run: { $0.runGadget(gadget) }
            )
        }
        let editConfig = PaletteCommand(
            id: "gadget-edit-config", title: "Gadgets: Edit Config…", category: "Gadgets",
            shortcut: { nil }, isEnabled: { _ in true },
            run: { $0.editGadgetConfig() }
        )
        let reload = PaletteCommand(
            id: "gadget-reload", title: "Gadgets: Reload", category: "Gadgets",
            shortcut: { nil }, isEnabled: { _ in true },
            run: { $0.reloadGadgets() }
        )
        return userCommands + [editConfig, reload]
    }

    func runGadget(_ gadget: Gadget) {
        let context = gadgetContext
        if gadgetStore.needsFirstRunConfirmation(gadget) {
            guard GadgetRunner.confirmFirstRun(gadget, context: context) else { return }
            gadgetStore.markConfirmed(gadget)
        }
        GadgetRunner.run(gadget, context: context)
    }

    /// Open `gadgets.json` in the default editor, creating a documented starter
    /// on first use — the user never hunts for the path or invents the schema.
    private func editGadgetConfig() {
        do {
            try gadgetStore.ensureConfigExists()
            NSWorkspace.shared.open(gadgetStore.configURL)
        } catch {
            reportGadgetProblems(["Could not create \(gadgetStore.configURL.path): \(error.localizedDescription)"])
        }
    }

    /// Re-read the config and tell the user what happened — the feedback loop
    /// for hand-editing (errors would otherwise vanish silently).
    private func reloadGadgets() {
        gadgetStore.reload()
        if gadgetStore.loadErrors.isEmpty {
            let count = gadgetStore.gadgets.count
            reportGadgetProblems(["\(count) gadget\(count == 1 ? "" : "s") loaded."], title: "Gadgets reloaded")
        } else {
            reportGadgetProblems(gadgetStore.loadErrors)
        }
    }

    private func reportGadgetProblems(_ messages: [String], title: String = "Gadget config problems") {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = messages.joined(separator: "\n")
        alert.runModal()
    }
}
