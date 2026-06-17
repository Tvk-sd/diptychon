import SwiftUI

/// The dual-panel workspace: two Panels side by side, each navigating
/// independently. Exactly one is the Active Panel (see `/CONTEXT.md`); Tab
/// switches focus between them. Each Panel keeps its own selection because each
/// owns a separate `PanelModel`.
struct WorkspaceView: View {
    enum Side { case left, right }

    @State private var left = PanelModel(directory: .startDirectory)
    @State private var right = PanelModel(directory: .startDirectory)
    @FocusState private var focus: Side?

    var body: some View {
        HStack(spacing: 0) {
            PanelView(model: left, isActive: focus == .left)
                .focusable()
                .focused($focus, equals: .left)

            Divider()

            PanelView(model: right, isActive: focus == .right)
                .focusable()
                .focused($focus, equals: .right)
        }
        .onAppear { if focus == nil { focus = .left } }
        // Tab switches the Active Panel.
        .onKeyPress(.tab) {
            focus = (focus == .right) ? .left : .right
            return .handled
        }
    }
}

extension URL {
    /// The directory both Panels open on initially: `DIPTYCHON_DIR` if set, else
    /// the current user's home directory (independent of any sandbox container).
    static var startDirectory: URL {
        if let override = ProcessInfo.processInfo.environment["DIPTYCHON_DIR"] {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    }
}
