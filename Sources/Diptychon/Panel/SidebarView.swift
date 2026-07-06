import SwiftUI

/// A standard place in the sidebar's top section: a fixed system folder with an
/// SF Symbol. Resolved at build time via `FileManager` so paths are correct for
/// the current user (independent of any sandbox container).
struct SidebarPlace: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let url: URL

    /// The fixed v1 set (issue 16): Home, Desktop, Documents, Downloads,
    /// Applications. Any that can't be resolved are simply omitted.
    static var standard: [SidebarPlace] {
        let fm = FileManager.default
        func place(_ name: String, _ icon: String, _ dir: FileManager.SearchPathDirectory) -> SidebarPlace? {
            guard let url = try? fm.url(for: dir, in: .userDomainMask, appropriateFor: nil, create: false)
            else { return nil }
            return SidebarPlace(name: name, icon: icon, url: url)
        }
        var places: [SidebarPlace] = []
        places.append(SidebarPlace(name: "Home", icon: "house",
                                   url: URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)))
        places.append(contentsOf: [
            place("Desktop", "menubar.dock.rectangle", .desktopDirectory),
            place("Documents", "doc", .documentDirectory),
            place("Downloads", "arrow.down.circle", .downloadsDirectory),
            place("Applications", "app", .applicationDirectory),
        ].compactMap { $0 })
        return places
    }
}

/// A mounted external volume shown in the sidebar's **Devices** section (issue 46):
/// an SD card, USB drive, card reader, mass-storage camera, external disk, or an
/// attached disk image. The volume URL is its identity (a name can repeat), so a
/// remount/rename replaces the row cleanly. Enumerated by `WorkspaceModel`.
struct SidebarDevice: Identifiable, Equatable {
    let name: String
    let url: URL
    let icon: String
    var id: URL { url }

    init(name: String, url: URL, icon: String = "externaldrive") {
        self.name = name
        self.url = url
        self.icon = icon
    }
}

/// The left sidebar (issue 16): a calm, Notion-style list — grouped sections,
/// lighter than Finder. v1 shows **Places** (fixed system folders) and an
/// (initially empty) **Pinned** section. Clicking a row navigates the Active
/// Panel; the row matching the active directory is highlighted.
struct SidebarView: View {
    let model: WorkspaceModel
    /// True while a drag hovers the sidebar — highlights the drop zone.
    @State private var dropTargeted = false
    /// Drives ⌘F: `WorkspaceModel.searchFocusRequest` bumps → focus the Search field.
    @FocusState private var searchFocused: Bool

    private let places = SidebarPlace.standard

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                section(header: "Places") {
                    ForEach(places) { place in
                        row(name: place.name, icon: place.icon, url: place.url)
                    }
                }
                section(header: "Pinned") {
                    if model.pinnedFolders.isEmpty {
                        Text("No pinned folders")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 2)
                    } else {
                        ForEach(model.pinnedFolders, id: \.self) { url in
                            pinnedRow(url)
                        }
                    }
                }
                // Mounted removable/external volumes (issue 46). Rendered only when
                // something is plugged in — no empty chrome when the list is empty.
                // The list is live: `WorkspaceModel` refreshes it on mount/unmount.
                if !model.devices.isEmpty {
                    section(header: "Devices") {
                        ForEach(model.devices) { device in
                            deviceRow(device)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxHeight: .infinity)
        // Slightly tinted material so the sidebar reads as a distinct, recessed
        // surface vs the panels. `primary` opacity adapts to light/dark (lifts in
        // dark, darkens in light) — kept behind the rows so it doesn't dim text.
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .overlay(Color.primary.opacity(0.045))
        }
        // Drop a folder anywhere on the sidebar to pin it (issue 16, slice 3).
        // Files are ignored — the sidebar is a navigation surface.
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .padding(4)
                .opacity(dropTargeted ? 1 : 0)
                .allowsHitTesting(false)
        }
        .dropDestination(for: URL.self) { urls, _ in
            let folders = urls.filter(Self.isDirectory)
            folders.forEach { model.pin($0) }
            return !folders.isEmpty
        } isTargeted: { dropTargeted = $0 }
        .accessibilityIdentifier("sidebar")
        .onChange(of: model.searchFocusRequest) { searchFocused = true }
    }

    /// Recursive Search field (issue 21 slice 3): finds files in the subtree under
    /// the Active Panel's folder; results render in that panel. Binds to the active
    /// panel so it swaps context when the active panel changes. Go-to-Folder lives
    /// on ⇧⌘G. A clear (✕) button cancels the search and restores the listing.
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search…", text: Binding(
                get: { model.activeModel.searchQuery },
                set: { model.activeModel.searchQuery = $0 }
            ))
            .textFieldStyle(.plain)
            .accessibilityIdentifier("sidebar-search")
            .focused($searchFocused)
            if !model.activeModel.searchQuery.isEmpty {
                Button { model.activeModel.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 12)
        // Match TopBarView's 32pt height so this field's bottom divider lines up
        // with the top bar's divider across the sidebar/panel seam (issue 21).
        .frame(height: 32)
    }

    /// A pinned-folder row. If the folder no longer exists it's greyed and
    /// non-navigable (slice 3 resilience) but stays listed so it can be removed.
    private func pinnedRow(_ url: URL) -> some View {
        let exists = Self.isDirectory(url)
        return row(name: url.lastPathComponent,
                   icon: exists ? "folder" : "folder.badge.questionmark",
                   url: url, missing: !exists)
            .accessibilityIdentifier("pinned\(exists ? "" : "-missing"):\(url.lastPathComponent)")
            .contextMenu {
                Button("Remove from Sidebar") { model.unpin(url) }
            }
    }

    /// A device row (issue 46). Reuses `row`, so clicking navigates the active panel
    /// to the volume root and the row highlights when the panel sits on it. `row`
    /// re-checks the path at click time, so a volume ejected since render is a no-op
    /// rather than a crash.
    private func deviceRow(_ device: SidebarDevice) -> some View {
        row(name: device.name, icon: device.icon, url: device.url)
            .accessibilityIdentifier("device:\(device.name)")
    }

    @ViewBuilder
    private func section<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(header.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 2)
            content()
        }
    }

    private func row(name: String, icon: String, url: URL, missing: Bool = false) -> some View {
        let selected = !missing && url == model.activeModel.directory
        return Button {
            // Re-check at click time so a folder deleted since render is a no-op.
            guard Self.isDirectory(url) else { return }
            model.navigateActive(to: url)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundStyle(missing ? Color.secondary
                                     : (selected ? Color.accentColor : Color.secondary))
                Text(name)
                    .lineLimit(1)
                    .foregroundStyle(missing ? Color.secondary : Color.primary)
                Spacer(minLength: 0)
            }
            .opacity(missing ? 0.5 : 1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .help(missing ? "“\(name)” can’t be found — remove it from the sidebar" : url.path)
    }

    /// Whether `url` points to an existing directory (folders-only + resilience).
    private static func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}
