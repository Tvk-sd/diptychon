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

/// The left sidebar (issue 16): a calm, Notion-style list — grouped sections,
/// lighter than Finder. v1 shows **Places** (fixed system folders) and an
/// (initially empty) **Pinned** section. Clicking a row navigates the Active
/// Panel; the row matching the active directory is highlighted.
struct SidebarView: View {
    let model: WorkspaceModel

    private let places = SidebarPlace.standard

    var body: some View {
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
                            row(name: url.lastPathComponent, icon: "folder", url: url)
                                .accessibilityIdentifier("pinned:\(url.lastPathComponent)")
                                .contextMenu {
                                    Button("Remove from Sidebar") { model.unpin(url) }
                                }
                        }
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .frame(maxHeight: .infinity)
        .background(.regularMaterial)
        .accessibilityIdentifier("sidebar")
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

    private func row(name: String, icon: String, url: URL) -> some View {
        let selected = url == model.activeModel.directory
        return Button {
            model.navigateActive(to: url)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                Text(name)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
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
    }
}
