import AppKit

/// Pops up an "Open With" menu for a set of files (⌘↩, issue 28). Layout:
///   • the user's favorite apps, pinned at the top (always shown);
///   • the apps macOS suggests for the file (minus any already favorited);
///   • management — "Other…", "Add App to Favorites…", and a "Remove from
///     Favorites" submenu.
///
/// A standalone `NSObject` so it can be the `@objc` target for the menu items —
/// `WorkspaceModel` isn't an `NSObject`, and the table's row-context menu builder
/// (`NSTableViewFileList`) can't be reached from a global chord. Favorites are owned
/// and persisted by `WorkspaceModel`; this controller reflects them and routes
/// add/remove back through closures.
@MainActor
final class OpenWithController: NSObject {
    /// What an "open" item launches: `app == nil` means the "Other…" chooser.
    private struct Open { let urls: [URL]; let app: URL? }

    private var onAddFavorite: ((URL) -> Void)?
    private var onRemoveFavorite: ((URL) -> Void)?

    /// Show the menu at the mouse location. `favorites` are always shown (the point
    /// of a favorite is quick access regardless of file type). No-op on an empty set.
    func present(for urls: [URL], favorites: [URL],
                 onAddFavorite: @escaping (URL) -> Void,
                 onRemoveFavorite: @escaping (URL) -> Void) {
        guard let first = urls.first else { return }
        self.onAddFavorite = onAddFavorite
        self.onRemoveFavorite = onRemoveFavorite

        let menu = NSMenu()

        // Favorites first — always available.
        for app in favorites {
            menu.addItem(openItem(app: app, urls: urls))
        }
        if !favorites.isEmpty { menu.addItem(.separator()) }

        // Apps macOS suggests for this file, minus any already favorited.
        let favoritePaths = Set(favorites.map { $0.standardizedFileURL.path })
        let suggested = NSWorkspace.shared.urlsForApplications(toOpen: first)
            .filter { !favoritePaths.contains($0.standardizedFileURL.path) }
        for app in suggested {
            menu.addItem(openItem(app: app, urls: urls))
        }
        if !suggested.isEmpty { menu.addItem(.separator()) }

        // Management.
        let other = NSMenuItem(title: "Other…", action: #selector(openWithOther(_:)), keyEquivalent: "")
        other.target = self
        other.representedObject = Open(urls: urls, app: nil)
        menu.addItem(other)

        let add = NSMenuItem(title: "Add App to Favorites…", action: #selector(addFavorite(_:)), keyEquivalent: "")
        add.target = self
        menu.addItem(add)

        if !favorites.isEmpty {
            let remove = NSMenuItem(title: "Remove from Favorites", action: nil, keyEquivalent: "")
            let sub = NSMenu()
            for app in favorites {
                let item = NSMenuItem(title: displayName(of: app), action: #selector(removeFavorite(_:)), keyEquivalent: "")
                item.target = self
                item.image = icon(of: app)
                item.representedObject = app
                sub.addItem(item)
            }
            remove.submenu = sub
            menu.addItem(remove)
        }

        // `in: nil` ⇒ the location is in screen coordinates.
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    // MARK: - Menu item builders

    private func openItem(app: URL, urls: [URL]) -> NSMenuItem {
        let item = NSMenuItem(title: displayName(of: app), action: #selector(openWithApp(_:)), keyEquivalent: "")
        item.target = self
        item.image = icon(of: app)
        item.representedObject = Open(urls: urls, app: app)
        return item
    }

    private func displayName(of app: URL) -> String {
        FileManager.default.displayName(atPath: app.path)
    }

    private func icon(of app: URL) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: app.path)
        icon.size = NSSize(width: 16, height: 16)
        return icon
    }

    // MARK: - Actions

    @objc private func openWithApp(_ sender: NSMenuItem) {
        guard let req = sender.representedObject as? Open, let app = req.app else { return }
        NSWorkspace.shared.open(req.urls, withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
    }

    @objc private func openWithOther(_ sender: NSMenuItem) {
        guard let req = sender.representedObject as? Open, let app = chooseApplication() else { return }
        NSWorkspace.shared.open(req.urls, withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
    }

    @objc private func addFavorite(_ sender: NSMenuItem) {
        guard let app = chooseApplication() else { return }
        onAddFavorite?(app)
    }

    @objc private func removeFavorite(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? URL else { return }
        onRemoveFavorite?(app)
    }

    /// Shared app picker for "Other…" and "Add App to Favorites…".
    private func chooseApplication() -> URL? {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
