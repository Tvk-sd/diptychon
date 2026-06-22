import SwiftUI

/// Tag picker for the Active selection (⌘T). Lists Finder's standard color tags
/// with a tri-state indicator — filled check = on every selected item, dash = on
/// some. Tapping toggles that tag across the whole selection as one undoable op,
/// reflected live (and in Finder).
struct TagPickerSheet: View {
    @Bindable var model: WorkspaceModel

    var body: some View {
        let items = model.activeModel.selectedItems
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags — \(items.count) item\(items.count == 1 ? "" : "s")")
                .font(.headline)

            VStack(spacing: 2) {
                ForEach(FinderTag.standard, id: \.name) { tag in
                    tagRow(tag, items: items)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button("Done") { model.tagging = false }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 280)
    }

    private func tagRow(_ tag: FinderTag, items: [FileItem]) -> some View {
        let onAll = !items.isEmpty && items.allSatisfy { $0.tags.contains { $0.name == tag.name } }
        let onSome = items.contains { $0.tags.contains { $0.name == tag.name } }
        let symbol = onAll ? "checkmark.circle.fill" : (onSome ? "minus.circle.fill" : "circle")
        return Button {
            model.toggleTag(tag)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(nsColor: tag.color.nsColor ?? .clear))
                    .frame(width: 12, height: 12)
                Text(tag.name)
                Spacer(minLength: 0)
                Image(systemName: symbol)
                    .foregroundStyle(onSome ? Color.accentColor : Color.secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle()) // whole row is the hit target for a real click.
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tag-\(tag.name)")
    }
}
