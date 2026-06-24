import SwiftUI
import Quartz

/// Inline preview / inspector pane (issue 14): a live `QLPreviewView` of the
/// Active Panel's current selection plus basic metadata. Distinct from the
/// floating spacebar QuickLook (issue 09) — this stays docked on the right and
/// follows the active selection. Toggled from the toolbar (⇧⌘P).
struct PreviewPane: View {
    let model: WorkspaceModel

    var body: some View {
        let items = model.activeModel.selectedItems
        Group {
            if items.count == 1, let item = items.first {
                VStack(spacing: 0) {
                    QuickLookPreview(url: item.url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Divider()
                    MetadataView(item: item)
                }
            } else {
                ContentUnavailableView(
                    items.isEmpty ? "No Selection" : "\(items.count) Items Selected",
                    systemImage: "sidebar.right",
                    description: Text(items.isEmpty
                        ? "Select a file to preview it."
                        : "Select a single file to preview it.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// SwiftUI wrapper over AppKit's `QLPreviewView` (live, embeddable preview).
private struct QuickLookPreview: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal) ?? QLPreviewView()
        view.autostarts = true
        view.previewItem = url as NSURL
        return view
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        // Only reset when the item actually changed (avoids reload flicker).
        if nsView.previewItem?.previewItemURL != url {
            nsView.previewItem = url as NSURL
        }
    }
}

/// Name + key file facts under the preview (name, kind, size, dates).
private struct MetadataView: View {
    let item: FileItem

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()

    var body: some View {
        let extra = Self.extraInfo(for: item.url)
        VStack(alignment: .leading, spacing: 6) {
            Text(item.name)
                .font(.headline)
                .lineLimit(2)
                .truncationMode(.middle)
            row("Kind", extra.kind)
            if let size = item.size {
                row("Size", ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
            }
            if let created = extra.created { row("Created", Self.dateFormatter.string(from: created)) }
            if let modified = item.modificationDate { row("Modified", Self.dateFormatter.string(from: modified)) }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ label: String, _ value: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "—").multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    /// Kind + creation date aren't on `FileItem`; fetch them on demand (one stat
    /// per selection change is cheap and keeps the row model lean).
    private static func extraInfo(for url: URL) -> (kind: String?, created: Date?) {
        let values = try? url.resourceValues(forKeys: [
            .localizedTypeDescriptionKey, .creationDateKey,
        ])
        return (values?.localizedTypeDescription, values?.creationDate)
    }
}
