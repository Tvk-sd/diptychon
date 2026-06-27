import SwiftUI

/// The unified top bar above both panels (issue 21). It acts on the **Active
/// Panel**: an Up button and a clickable **breadcrumb** of that panel's path.
/// Back/forward land in slice 2; search + the hidden/tag controls move here in
/// slice 3. A view-switcher and time-travel control get clean slots later.
struct TopBarView: View {
    let model: WorkspaceModel
    /// Drives ⌘F: `WorkspaceModel.filterFocusRequest` bumps → focus the Filter field.
    @FocusState private var filterFocused: Bool

    /// The Active Panel's navigation row: up / back / forward + clickable
    /// breadcrumb + name filter. The app name and the window/view-toggle icons
    /// live one row up in the full-width header (`WorkspaceView.headerBar`), so
    /// the sidebar toggle keeps a fixed spot instead of jumping when folded.
    var body: some View {
        HStack(spacing: 8) {
            Button { model.activeModel.navigateUp() } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(!model.activeModel.canGoUp)
            .help("Go up (⌘↑)")

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

            Divider().frame(height: 16)

            breadcrumb

            Spacer(minLength: 8)

            // Name filter for the Active Panel (issue 21). Binds straight to the
            // active PanelModel so it swaps context when the active panel changes.
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(.secondary)
                TextField("Filter", text: Binding(
                    get: { model.activeModel.filter },
                    set: { model.activeModel.filter = $0 }
                ))
                .textFieldStyle(.plain)
                .frame(width: 140)
                .focused($filterFocused)
            }
            .help("Filter the active panel by name (⌘F)")
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .onChange(of: model.filterFocusRequest) { filterFocused = true }
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
