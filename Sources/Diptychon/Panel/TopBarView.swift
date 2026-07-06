import SwiftUI

/// The Active Panel's nav row (issue 21): an Up button, back/forward, and a clickable
/// **breadcrumb** of that panel's path. It lives in the true top bar
/// (`WorkspaceView.headerBar`), right of the Search field; a trailing Spacer fills the
/// remaining width so the Filter cell can cap the far edge. Everything binds to the
/// Active Panel, so it swaps context when the active panel changes.
struct TopBarView: View {
    let model: WorkspaceModel

    /// up / back / forward + clickable breadcrumb, in a single row inside the header.
    /// Search sits to the left in its own cell; the Filter caps the trailing edge;
    /// the window/view toggles live on the bottom bar.
    var body: some View {
        HStack(spacing: 8) {
            Button { model.activeModel.navigateUp() } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(!model.activeModel.canGoUp)
            .help("Go up (⌘↑)")

            // Full-height seam splitting the go-to-top button off from the
            // back/forward pair.
            Divider()

            Button { model.activeModel.goBack() } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            .disabled(!model.activeModel.canGoBack)
            .help("Back (⌘[)")

            Button { model.activeModel.goForward() } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
            .disabled(!model.activeModel.canGoForward)
            .help("Forward (⌘])")

            Divider()

            breadcrumb

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
    }

    /// The active panel's path as clickable segments. Deep paths show a leading "…"
    /// and the last few segments so the bar never overflows.
    @ViewBuilder
    private var breadcrumb: some View {
        let crumbs = trail(of: model.activeModel.directory)
        let shown = Array(crumbs.suffix(5))
        HStack(spacing: 4) {
            if crumbs.count > shown.count {
                Text("…").foregroundStyle(.secondary)
                chevron
            }
            ForEach(shown, id: \.self) { url in
                Button { model.navigateActive(to: url) } label: {
                    Text(label(for: url))
                        .fontWeight(url == model.activeModel.directory ? .semibold : .regular)
                        .foregroundStyle(url == model.activeModel.directory ? .primary : .secondary)
                        .lineLimit(1)
                }
                .buttonStyle(.borderless)
                if url != shown.last {
                    chevron
                }
            }
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
    }

    private func label(for url: URL) -> String {
        let name = url.lastPathComponent
        return name.isEmpty ? "/" : name
    }

    /// Root → current chain of directory URLs. Built from the *absolute*, standardized
    /// path's components — NOT by looping `deletingLastPathComponent()`, which never
    /// converges for the directory-style URLs `contentsOfDirectory` returns (it loops
    /// forever instead of reaching root), which pinned the CPU and froze the app.
    private func trail(of directory: URL) -> [URL] {
        let absolute = URL(fileURLWithPath: directory.path).standardizedFileURL
        var result: [URL] = [URL(fileURLWithPath: "/")]
        var url = result[0]
        for component in absolute.pathComponents where component != "/" {
            url.appendPathComponent(component)
            result.append(url)
        }
        return result
    }
}

/// The Active Panel's name filter (issue 21), extracted from the nav row so the header
/// can position it as its own trailing cell — one that lines up flush with the
/// preview/aux pane below it (mirroring how Search caps the sidebar column). Binds
/// straight to the active PanelModel so it swaps context with the active panel, and
/// owns the ⌘⇧F focus plumbing. The field fills whatever width its parent cell gives.
struct FilterFieldView: View {
    let model: WorkspaceModel
    /// Drives ⌘⇧F: `WorkspaceModel.filterFocusRequest` bumps → focus the Filter field.
    @FocusState private var filterFocused: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(.secondary)
            TextField("Filter", text: Binding(
                get: { model.activeModel.filter },
                set: { model.activeModel.filter = $0 }
            ))
            .textFieldStyle(.plain)
            .frame(maxWidth: .infinity)
            .focused($filterFocused)
        }
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity)
        .help("Search inside the current folder, recursively (⌘⇧F). Use Search for everything.")
        .onChange(of: model.filterFocusRequest) { filterFocused = true }
    }
}
