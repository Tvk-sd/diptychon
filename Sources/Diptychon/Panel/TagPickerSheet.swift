import SwiftUI

/// Tag picker for the Active selection (⌘T). Lists Finder's standard color tags
/// with a tri-state indicator — filled check = on every selected item, dash = on
/// some. Tapping toggles that tag across the whole selection as one undoable op,
/// reflected live (and in Finder).
struct TagPickerSheet: View {
    @Bindable var model: WorkspaceModel

    /// New-tag composer state (slice 5 / AC3).
    @State private var newName = ""
    @State private var newColor: FinderTagColor = .none

    var body: some View {
        let items = model.activeModel.selectedItems
        let custom = model.customTagsInUse
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags — \(items.count) item\(items.count == 1 ? "" : "s")")
                .font(.headline)

            VStack(spacing: 2) {
                ForEach(FinderTag.standard, id: \.name) { tag in
                    tagRow(tag, items: items)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if !custom.isEmpty {
                    Divider().padding(.vertical, 4)
                    ForEach(custom, id: \.name) { tag in
                        tagRow(tag, items: items)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Divider()
            newTagComposer

            HStack {
                Spacer()
                Button("Done") { model.tagging = false }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    /// Create a brand-new tag (name + optional built-in color) and apply it to the
    /// selection. Routes through `toggleTag`, so it's one undoable op like any
    /// other tag change. Custom-color *sidebar* registration in Finder is a
    /// follow-up; the tag + color are written correctly to the file xattr.
    private var newTagComposer: some View {
        HStack(spacing: 8) {
            Menu {
                Button { newColor = .none } label: { Label("No Color", systemImage: "circle") }
                ForEach(FinderTag.standard, id: \.name) { tag in
                    Button { newColor = tag.color } label: {
                        Label {
                            Text(tag.name)
                        } icon: {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(Color(nsColor: tag.color.nsColor ?? .secondaryLabelColor))
                        }
                    }
                }
            } label: {
                Image(systemName: "circle.fill")
                    .foregroundStyle(Color(nsColor: newColor.nsColor ?? .secondaryLabelColor))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("New tag color")

            TextField("New tag", text: $newName)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addNewTag)
                .accessibilityIdentifier("new-tag-name")

            Button("Add", action: addNewTag)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("new-tag-add")
        }
    }

    private func addNewTag() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        model.toggleTag(FinderTag(name: name, color: newColor))
        newName = ""
        newColor = .none
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
