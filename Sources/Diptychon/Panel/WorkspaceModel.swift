import SwiftUI
import AppKit
import Quartz
import Observation

/// Owns both Panels, the active side, and the `OperationCoordinator`. Lives as a
/// reference type so the `NSEvent` key monitor can read live state (active side,
/// models) instead of a stale snapshot.
@MainActor
@Observable
final class WorkspaceModel {
    enum Side { case left, right }

    /// A copy-or-move write paused on the collision-resolution step.
    struct PendingWrite: Identifiable {
        enum Kind { case copy, move }
        let id = UUID()
        let kind: Kind
        let sources: [URL]
        let destinationDirectory: URL
        let collisionCount: Int
    }

    /// An open batch-rename sheet, operating on a snapshot of the selection.
    struct RenameRequest: Identifiable {
        let id = UUID()
        let items: [FileItem]
        let directory: URL
    }

    /// The one modal that can be presented at a time. Collision shows as a
    /// `confirmationDialog`; the rest as sheets.
    enum Sheet: Identifiable {
        case collision(PendingWrite)
        case rename(RenameRequest)
        case tags
        case goToFolder
        case palette
        var id: String {
            switch self {
            case .collision: "collision"
            case .rename: "rename"
            case .tags: "tags"
            case .goToFolder: "goToFolder"
            case .palette: "palette"
            }
        }
    }

    let left: PanelModel
    let right: PanelModel
    let coordinator = OperationCoordinator()
    private let quickLook = QuickLookController()
    private let openWith = OpenWithController()

    var active: Side = .left
    /// The single modal presented over the workspace, if any. One value ⇒ one modal
    /// at a time — the four independent flags this replaced gave no such guarantee.
    var presentedSheet: Sheet?

    /// Bumped by ⌘F to ask the Filter field to take focus (issue 28). `TopBarView`
    /// watches it and drives its `@FocusState` — the key monitor can't set SwiftUI
    /// focus directly.
    private(set) var filterFocusRequest = UUID()
    func focusFilter() { filterFocusRequest = UUID() }

    /// The collision dialog's data, when that's the presented modal (drives the
    /// `confirmationDialog`).
    var pendingCollision: PendingWrite? {
        if case .collision(let pending) = presentedSheet { pending } else { nil }
    }

    /// The presented sheet, excluding the collision case (which is a dialog). Lets
    /// one `.sheet(item:)` drive rename / tags / go-to-folder.
    var sheetItem: Sheet? {
        if case .collision = presentedSheet { nil } else { presentedSheet }
    }

    /// Whether the inline preview pane is shown (issue 14). Persisted across
    /// launches so it stays where the user left it.
    var previewVisible = UserDefaults.standard.bool(forKey: "previewVisible") {
        didSet { UserDefaults.standard.set(previewVisible, forKey: "previewVisible") }
    }

    /// Whether the left sidebar (places + pinned folders) is shown (issue 16).
    /// Defaults to true (a registered default in `DiptychonApp`). Persisted.
    var sidebarVisible = UserDefaults.standard.bool(forKey: "sidebarVisible") {
        didSet { UserDefaults.standard.set(sidebarVisible, forKey: "sidebarVisible") }
    }

    /// Folders the user pinned to the sidebar (issue 16, slice 2). Backed by a
    /// `[String]` of paths in `UserDefaults`; deduped on add via `PinnedFolders`.
    var pinnedFolders: [URL] = PinnedFolders.decode(
        UserDefaults.standard.stringArray(forKey: "pinnedFolders") ?? []
    ) {
        didSet { UserDefaults.standard.set(PinnedFolders.encode(pinnedFolders), forKey: "pinnedFolders") }
    }

    /// Apps the user pinned to the Open-With menu (⌘↩, issue 28). Backed by a
    /// `[String]` of app paths in `UserDefaults`; deduped on add via `FavoriteApps`.
    var favoriteApps: [URL] = FavoriteApps.decode(
        UserDefaults.standard.stringArray(forKey: "openWithFavorites") ?? []
    ) {
        didSet { UserDefaults.standard.set(FavoriteApps.encode(favoriteApps), forKey: "openWithFavorites") }
    }

    /// Whether the right file panel is shown (issue 13). Defaults to true (a
    /// registered default in `DiptychonApp`). Hiding it forces the Active Panel to
    /// the left so keyboard/clicks stay coherent.
    var rightPanelVisible = UserDefaults.standard.bool(forKey: "rightPanelVisible") {
        didSet {
            UserDefaults.standard.set(rightPanelVisible, forKey: "rightPanelVisible")
            if !rightPanelVisible { active = .left }
        }
    }

    init() {
        left = PanelModel(directory: .startDirectory)
        right = PanelModel(directory: .startDirectory)
        // One place decides when the UI re-lists: every Operation that settles
        // (run/undo/redo) refreshes both Panels. No per-call closure to forget.
        coordinator.onOperationSettled = { [weak self] in self?.refreshBoth() }
    }

    /// Full Disk Access onboarding (issue 10): called when the app reactivates
    /// (the user may have just granted access in System Settings). If a panel was
    /// blocked by a permission error and access is now available, re-list it so
    /// the folder fills in — no restart (AC3). No global banner: guidance is
    /// shown inline only when a protected folder is actually opened.
    func recheckFullDiskAccess() {
        guard left.accessDenied || right.accessDenied, FullDiskAccess.isGranted else { return }
        refreshBoth()
    }

    var activeModel: PanelModel { active == .left ? left : right }
    var inactiveModel: PanelModel { active == .left ? right : left }

    /// Handle a raw key event (from the local monitor). Returns true if consumed.
    func handleKeyDown(_ event: NSEvent) -> Bool {
        guard let action = Keymap.action(for: event) else { return false }
        // ⎋ clears the selection, but only when nothing modal is up — otherwise leave
        // Esc for the open sheet/dialog to consume (close on Esc). Don't swallow it.
        if case .selectNone = action, presentedSheet != nil { return false }
        perform(action)
        return true
    }

    func perform(_ action: AppAction) {
        switch action {
        case .copyToInactive:
            // No visible inactive target when the right panel is hidden.
            guard rightPanelVisible else { return }
            write(.copy, sources: activeModel.selectionURLs, into: inactiveModel.directory)
        case .undo: coordinator.undo()
        case .redo: coordinator.redo()
        case .goUp: activeModel.navigateUp()
        case .goBack: activeModel.goBack()
        case .goForward: activeModel.goForward()
        case .switchPanel:
            if !rightPanelVisible {
                rightPanelVisible = true   // Tab brings the right panel back…
                active = .right            // …and moves focus to it.
            } else {
                active = (active == .left) ? .right : .left
            }
        case .clipboardCopy: clipboardCopy()
        case .paste: write(.copy, sources: clipboardURLs(), into: activeModel.directory)
        case .pasteMove: write(.move, sources: clipboardURLs(), into: activeModel.directory)
        case .trash: trashSelection()
        case .duplicate: duplicateSelection()
        case .newFolder: create(.folder)
        case .newFile: create(.file)
        case .rename:
            // ⌘R: a single selection renames inline (issue 11); 2+ opens the batch
            // sheet (issue 07).
            if activeModel.selectedItems.count == 1 {
                activeModel.requestInlineRename()
            } else {
                beginRename()
            }
        case .showTags: beginTagging()
        case .openSelection: openSelection()
        case .preview: togglePreview()
        case .goToFolder: presentedSheet = .goToFolder
        case .toggleHidden: activeModel.showHidden.toggle()
        case .selectAll: activeModel.selectAll()
        case .selectNone: activeModel.selectNone()
        case .invertSelection: activeModel.invertSelection()
        case .focusFilter: focusFilter()
        case .revealInFinder: revealInFinder()
        case .copyPaths: copyPaths()
        case .showInfo: showFinderInfo()
        case .openWith:
            let urls = activeModel.selectionURLs
            guard !urls.isEmpty else { return }
            openWith.present(for: urls, favorites: favoriteApps,
                             onAddFavorite: { [weak self] in self?.addFavoriteApp($0) },
                             onRemoveFavorite: { [weak self] in self?.removeFavoriteApp($0) })
        case .moveToInactive:
            // No visible inactive target when the right panel is hidden.
            guard rightPanelVisible else { return }
            write(.move, sources: activeModel.selectionURLs, into: inactiveModel.directory)
        case .openPalette: togglePalette()
        }
    }

    // MARK: - Command palette (issue 19)

    /// ⌘K: open the palette, or close it if it's already the presented sheet. Does
    /// nothing if another modal is up (one modal at a time — the `presentedSheet`
    /// invariant).
    func togglePalette() {
        if case .palette = presentedSheet { presentedSheet = nil }
        else if presentedSheet == nil { presentedSheet = .palette }
    }

    /// Run a palette command: dismiss the palette first, then execute — so a command
    /// that opens its own sheet (rename / tags / go-to-folder) can present into the
    /// now-free modal slot.
    func runPaletteCommand(_ command: PaletteCommand) {
        presentedSheet = nil
        command.run(self)
    }

    // MARK: - Reveal / Copy paths / Get Info (issue 28)

    private func revealInFinder() {
        let urls = activeModel.selectionURLs
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    /// Copy the selection's absolute path(s) as plain text, one per line.
    private func copyPaths() {
        let urls = activeModel.selectionURLs
        guard !urls.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(urls.map(\.path).joined(separator: "\n"), forType: .string)
    }

    /// Open Finder's "Get Info" window(s) for the selection. There is no public
    /// Get-Info API, so drive Finder via AppleScript. Sandbox is off (ADR 0001) so
    /// no entitlement is needed; the first call shows a one-time automation-consent
    /// prompt for controlling Finder.
    private func showFinderInfo() {
        let urls = activeModel.selectionURLs
        guard !urls.isEmpty else { return }
        let lines = urls.map { url -> String in
            let escaped = url.path
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "    open information window of (POSIX file \"\(escaped)\" as alias)"
        }.joined(separator: "\n")
        let source = """
        tell application "Finder"
            activate
        \(lines)
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error { NSLog("Get Info via Finder failed: \(error)") }
    }

    // MARK: - Go to Folder / path navigation (issue 15)

    /// Navigate the Active Panel to a typed path. Returns false (and changes
    /// nothing) if the path doesn't resolve to an existing directory.
    @discardableResult
    func navigateActive(toPath raw: String) -> Bool {
        guard let url = PathInput.resolve(raw, relativeTo: activeModel.directory) else { return false }
        activeModel.go(to: url)
        return true
    }

    /// Navigate the Active Panel to a known directory URL (sidebar click,
    /// breadcrumb). Unlike `toPath`, the URL is already trusted.
    func navigateActive(to url: URL) {
        activeModel.go(to: url)
    }

    // MARK: - Pinned folders (sidebar, issue 16)

    func pin(_ url: URL) { pinnedFolders = PinnedFolders.adding(url, to: pinnedFolders) }
    func unpin(_ url: URL) { pinnedFolders = PinnedFolders.removing(url, from: pinnedFolders) }

    // MARK: - Favorite apps (Open-With menu, issue 28)

    func addFavoriteApp(_ app: URL) { favoriteApps = FavoriteApps.adding(app, to: favoriteApps) }
    func removeFavoriteApp(_ app: URL) { favoriteApps = FavoriteApps.removing(app, from: favoriteApps) }


    // MARK: - QuickLook

    /// Spacebar: toggle the shared QuickLook panel for the Active selection. Open
    /// → close; closed with a non-empty selection → open. Driven directly (no
    /// responder-chain plumbing).
    private func togglePreview() {
        let panel = QLPreviewPanel.shared()!
        if QLPreviewPanel.sharedPreviewPanelExists() && panel.isVisible {
            panel.orderOut(nil)
            return
        }
        let urls = activeModel.selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        quickLook.urls = urls
        panel.dataSource = quickLook
        panel.makeKeyAndOrderFront(nil)
        panel.reloadData()
    }

    // MARK: - Open (default app / navigate)

    /// Activate the Active Panel's selection (Return / double-click): a single
    /// folder navigates into it; files open in their default app (Finder
    /// behavior). A mixed selection opens the files and ignores folders.
    func openSelection() {
        let items = activeModel.selectedItems
        guard !items.isEmpty else { return }
        if items.count == 1, let only = items.first, only.isDirectory {
            activeModel.navigate(into: only)
            return
        }
        for item in items where !item.isDirectory {
            NSWorkspace.shared.open(item.url)
        }
    }

    // MARK: - Finder tags

    private func beginTagging() {
        guard !activeModel.selectedItems.isEmpty else { return }
        presentedSheet = .tags
    }

    /// Custom (non-built-in) tags already in use across either panel, so the
    /// picker can offer them for re-applying ("pick from the list"). Full
    /// integration with Finder's undocumented system tag store is a follow-up;
    /// this surfaces tags actually present on disk, which is robust.
    var customTagsInUse: [FinderTag] {
        let standardNames = Set(FinderTag.standard.map(\.name))
        var seen = Set<String>()
        var result: [FinderTag] = []
        for tag in left.availableTags + right.availableTags
        where !standardNames.contains(tag.name) && seen.insert(tag.name).inserted {
            result.append(tag)
        }
        return result
    }

    /// Toggle a tag across the Active selection: remove it if every selected item
    /// already has it, otherwise add it to all. One undoable `SetTagsOperation`.
    func toggleTag(_ tag: FinderTag) {
        let items = activeModel.selectedItems
        guard !items.isEmpty else { return }
        let onAll = items.allSatisfy { $0.tags.contains { $0.name == tag.name } }
        let targets: [(url: URL, newTags: [FinderTag])] = items.map { item in
            var tags = item.tags.filter { $0.name != tag.name } // drop existing copy first
            if !onAll { tags.append(tag) }                       // add unless removing
            return (item.url, tags)
        }
        let op = SetTagsOperation(targets: targets)
        coordinator.run(op)
    }

    // MARK: - Inline rename (issue 11)

    /// Commit an in-place rename of a single item to `newName`. Returns false (so
    /// the list reverts the cell) on an empty/unchanged name or a collision; true
    /// when a (one-step, undoable) `RenameOperation` was started.
    @discardableResult
    func renameInline(_ item: FileItem, to newName: String) -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != item.name else { return false }
        let dest = item.url.deletingLastPathComponent().appendingPathComponent(trimmed)
        // Reject a collision (no overwrite). A case-only rename of the same file on
        // a case-insensitive volume is allowed (mirrors issue 07's fix).
        let caseOnlySelfRename = trimmed.lowercased() == item.name.lowercased()
        if FileManager.default.fileExists(atPath: dest.path), !caseOnlySelfRename {
            NSSound.beep()
            return false
        }
        let op = RenameOperation(renames: [(from: item.url, to: dest)])
        coordinator.run(op)
        return true
    }

    // MARK: - Batch rename

    private func beginRename() {
        let items = activeModel.selectedItems
        guard !items.isEmpty else { return }
        presentedSheet = .rename(RenameRequest(items: items, directory: activeModel.directory))
    }

    /// Apply the sheet's computed new names as one undoable `RenameOperation`.
    func commitRename(_ request: RenameRequest, newNames: [String]) {
        let renames: [(from: URL, to: URL)] = zip(request.items, newNames).compactMap { item, name in
            guard name != item.name, !name.isEmpty else { return nil } // skip unchanged
            return (from: item.url, to: request.directory.appendingPathComponent(name))
        }
        presentedSheet = nil
        guard !renames.isEmpty else { return }
        let op = RenameOperation(renames: renames)
        coordinator.run(op)
    }

    // MARK: - Drag & drop (routed through the same write Operations)

    /// Handle file URLs dropped on `panel`. `targetFolder` is a folder row the
    /// user dropped onto (drop into it); otherwise the drop targets the panel's
    /// current directory. Defaults to copy (safe + undoable).
    func handleDrop(_ urls: [URL], on panel: PanelModel, targetFolder: FileItem?) {
        let destination = targetFolder?.url ?? panel.directory
        // Ignore a no-op drop into the same directory the items already live in.
        let sources = urls.filter { $0.deletingLastPathComponent() != destination }
        write(.copy, sources: sources, into: destination)
    }

    // MARK: - Clipboard (real macOS pasteboard, file URLs)

    private func clipboardCopy() {
        let urls = activeModel.selectionURLs
        guard !urls.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(urls as [NSURL])
    }

    private func clipboardURLs() -> [URL] {
        NSPasteboard.general.readObjects(forClasses: [NSURL.self]) as? [URL] ?? []
    }

    // MARK: - Copy / Move (collision-checked)

    /// Run a copy/move into `directory`, detecting collisions first. With no
    /// collisions it runs immediately; otherwise it pauses for the dialog.
    private func write(_ kind: PendingWrite.Kind, sources: [URL], into directory: URL) {
        guard !sources.isEmpty else { return }
        let collisions = detectCollisions(sources: sources, destinationDirectory: directory)
        if collisions.isEmpty {
            runWrite(kind, sources: sources, into: directory, resolution: .rename)
        } else {
            presentedSheet = .collision(PendingWrite(kind: kind, sources: sources,
                                                     destinationDirectory: directory,
                                                     collisionCount: collisions.count))
        }
    }

    func resolvePendingWrite(_ pending: PendingWrite, resolution: CollisionResolution) {
        runWrite(pending.kind, sources: pending.sources,
                 into: pending.destinationDirectory, resolution: resolution)
        presentedSheet = nil
    }

    private func runWrite(_ kind: PendingWrite.Kind, sources: [URL],
                          into directory: URL, resolution: CollisionResolution) {
        let op: Operation
        switch kind {
        case .copy: op = CopyOperation(sources: sources, destinationDirectory: directory, resolution: resolution)
        case .move: op = MoveOperation(sources: sources, destinationDirectory: directory, resolution: resolution)
        }
        coordinator.run(op)
    }

    // MARK: - Duplicate / Trash / Create

    /// Duplicate = copy into the same directory with rename ("name 2").
    private func duplicateSelection() {
        let sources = activeModel.selectionURLs
        guard !sources.isEmpty else { return }
        let op = CopyOperation(sources: sources, destinationDirectory: activeModel.directory, resolution: .rename)
        coordinator.run(op)
    }

    private func trashSelection() {
        let sources = activeModel.selectionURLs
        guard !sources.isEmpty else { return }
        let op = TrashOperation(sources: sources)
        coordinator.run(op)
    }

    private func create(_ kind: CreateOperation.Kind) {
        let op = CreateOperation(directory: activeModel.directory, kind: kind)
        coordinator.run(op)
    }

    private func refreshBoth() {
        left.refresh()
        right.refresh()
    }
}
