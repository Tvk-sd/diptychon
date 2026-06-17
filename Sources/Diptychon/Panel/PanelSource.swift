import Foundation

/// ADR 0003 — the abstraction a Panel renders. In the MVP the only implementation
/// is `LocalDirectorySource`, but the rest of the app talks to this protocol, not
/// to the filesystem directly. Future sources — tag view, search results, archive
/// contents — become new conformances, not a rewrite of the Panel.
protocol PanelSource {
    /// Human-readable label for the source (shown in the Panel header).
    var title: String { get }

    /// Produce the rows to display. Implementations MUST do their heavy work off
    /// the main thread; callers may invoke this from a UI context and rely on the
    /// UI staying responsive while it runs.
    func load() async throws -> [FileItem]
}
