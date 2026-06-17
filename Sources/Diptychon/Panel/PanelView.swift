import SwiftUI

/// One Panel: a header showing the source title and the file list below it.
/// Renders whatever its `PanelSource` provides via the `PanelFileList` swap point.
struct PanelView: View {
    @State private var model: PanelModel

    init(source: PanelSource) {
        _model = State(initialValue: PanelModel(source: source))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .task { await model.load() }
    }

    private var header: some View {
        Text(model.title)
            .font(.headline)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            // The UI stays live here while the directory loads off-thread.
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let items):
            PanelFileList(items: items)
        case .failed(let message):
            ContentUnavailableView("Couldn't read folder", systemImage: "exclamationmark.triangle", description: Text(message))
        }
    }
}
