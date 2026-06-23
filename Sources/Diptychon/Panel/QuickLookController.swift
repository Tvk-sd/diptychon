import AppKit
import Quartz

/// Data source + delegate for the shared `QLPreviewPanel` (spacebar preview).
/// Holds the URLs to preview; `WorkspaceModel` drives the panel directly
/// (assign data source + `makeKeyAndOrderFront`) rather than via the responder
/// chain, which is awkward to join from SwiftUI.
@MainActor
final class QuickLookController: NSObject, QLPreviewPanelDataSource {
    var urls: [URL] = []

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { urls.count }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as NSURL
    }
}
