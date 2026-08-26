import CoreGraphics

/// What a left-mouse-down means for Panel activation (issue 89).
enum PanelClickTarget: Equatable {
    case leftPanel
    case rightPanel
    /// The Staging pane becomes the operation source.
    case staging
    /// Window chrome — header band, bottom bar, sidebar, preview. Activates nothing.
    case none
}

/// Routes a click to the region it landed in, as pure geometry.
///
/// The Active Panel is derived from *where* a click lands rather than from the first
/// responder, so every band of chrome has to be named explicitly — anything not
/// excluded reads as "a click in a Panel". Issue 89: the bottom bar was never
/// excluded, so its toggles (Terminal, Preview, Staging, Activity, Sidebar) sit in the
/// right half of the window and silently flipped the Active Panel to `.right` before
/// their own action ran. For the Terminal that is not a passing glitch: the shell's
/// cwd is set once, at open, so the wrong Panel meant a permanently wrong shell.
///
/// Pure on purpose. The decision used to live inline in the `NSEvent` monitor, where
/// it could only be exercised by driving a real window; here it is a function with a
/// return value, and `PanelClickRouterTests` covers every band.
///
/// The terminal is *not* handled here. It spans both Panels, so it has to be
/// hit-tested against the real view hierarchy (`TerminalSession.containsClick`) rather
/// than measured — the caller asks that first and never reaches this function.
enum PanelClickRouter {
    /// Header row (32pt) plus its divider. A measured constant, not a derived one:
    /// if `WorkspaceView.headerBar` changes height, re-measure rather than guess.
    static let headerBand: CGFloat = 34
    /// Bottom bar (32pt) plus its divider — same measured contract as `headerBand`.
    static let bottomBand: CGFloat = 33
    /// Sidebar width (200pt) plus its divider.
    static let sidebarEdge: CGFloat = 201
    /// Preview/Staging column width (300pt) plus its divider.
    static let auxPaneWidth: CGFloat = 301

    /// - Parameters:
    ///   - x, y: the click in window coordinates.
    ///   - contentTop, contentBottom: the usable content area's edges — the window's
    ///     `contentLayoutRect`, *not* the content view's bounds. The content view is
    ///     full-size (it spans behind the title bar), so measuring the header band
    ///     from the window top would miss it.
    ///   - minX, maxX: the content view's horizontal edges.
    static func target(x: CGFloat, y: CGFloat,
                       contentTop: CGFloat, contentBottom: CGFloat,
                       minX: CGFloat, maxX: CGFloat,
                       sidebarVisible: Bool,
                       rightPane: WorkspaceModel.RightPane,
                       rightPanelVisible: Bool) -> PanelClickTarget {
        // Header: Search, the nav row (back/forward, breadcrumb) and the Filter field.
        // Clicking the Filter must not steal the Active Panel by its x-position.
        if y >= contentTop - headerBand { return .none }
        // Bottom bar: the pane toggles. Same reasoning, opposite edge (issue 89).
        if y <= contentBottom + bottomBand { return .none }

        // The Panels occupy the space between the sidebar (issue 16) and the
        // preview/staging column (issue 14). With the right Panel hidden, the left one
        // spans that whole area.
        let leftEdge = sidebarVisible ? sidebarEdge : minX
        let rightEdge = rightPane != .none ? maxX - auxPaneWidth : maxX

        if x >= leftEdge && x <= rightEdge {
            let panelsMid = (leftEdge + rightEdge) / 2
            return (rightPanelVisible && x >= panelsMid) ? .rightPanel : .leftPanel
        }
        if rightPane == .staging && x > rightEdge { return .staging }
        // Sidebar, or the preview column: clicking there must NOT re-activate a Panel,
        // else clicking the sidebar with the right Panel active would flip to left and
        // navigate the wrong side.
        return .none
    }
}
