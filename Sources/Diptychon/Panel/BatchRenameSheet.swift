import SwiftUI

/// Batch-rename sheet modeled on Finder: pick a mode (Replace Text / Add Text /
/// Format), fill its fields, and see a live before/after preview. Nothing is
/// written until "Rename"; the button is disabled while any name collides
/// (collisions are flagged red in the preview).
struct BatchRenameSheet: View {
    let items: [FileItem]
    let directory: URL
    let onCommit: (_ newNames: [String]) -> Void
    let onCancel: () -> Void

    enum Mode: String, CaseIterable, Identifiable {
        case replace = "Replace Text"
        case add = "Add Text"
        case format = "Name + Number"
        case changeCase = "Case"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .replace
    @State private var find = ""
    @State private var replaceWith = ""
    @State private var addText = ""
    @State private var addPosition: RenameRule.Position = .after
    @State private var formatName = "File"
    @State private var startNumber = 1
    @State private var padding = 1
    @State private var caseMode: RenameRule.CaseMode = .lower

    private var rule: RenameRule {
        switch mode {
        case .replace: return .replaceText(find: find, with: replaceWith)
        case .add: return .addText(addText, addPosition)
        case .format: return .format(name: formatName, start: startNumber, padding: padding)
        case .changeCase: return .changeCase(caseMode)
        }
    }

    private var originals: [String] { items.map(\.name) }
    private var newNames: [String] { rule.newNames(for: originals) }
    private var collisions: Set<Int> {
        renameCollisionIndices(originals: originals, newNames: newNames, directory: directory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rename \(items.count) item\(items.count == 1 ? "" : "s")")
                .font(.headline)

            Picker("", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            modeControls

            Divider()
            Text("Preview").font(.subheadline).foregroundStyle(.secondary)
            preview

            HStack {
                if !collisions.isEmpty {
                    Label("\(collisions.count) name collision\(collisions.count == 1 ? "" : "s")",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red).font(.callout)
                }
                Spacer()
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Rename") { onCommit(newNames) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!collisions.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 580, height: 480)
    }

    @ViewBuilder
    private var modeControls: some View {
        switch mode {
        case .replace:
            HStack {
                TextField("Find", text: $find)
                TextField("Replace with", text: $replaceWith)
            }
            .textFieldStyle(.roundedBorder)
        case .add:
            HStack {
                TextField("Text", text: $addText)
                    .textFieldStyle(.roundedBorder)
                Picker("", selection: $addPosition) {
                    ForEach(RenameRule.Position.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .frame(width: 140)
            }
        case .format:
            HStack {
                TextField("Name", text: $formatName)
                    .textFieldStyle(.roundedBorder)
                Stepper("Start \(startNumber)", value: $startNumber, in: 0...100_000)
                Stepper("Pad \(padding)", value: $padding, in: 1...6)
            }
        case .changeCase:
            Picker("", selection: $caseMode) {
                ForEach(RenameRule.CaseMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
    }

    private var preview: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        Text(item.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1).truncationMode(.middle)
                        Image(systemName: "arrow.right").foregroundStyle(.secondary)
                        Text(newNames[index])
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1).truncationMode(.middle)
                            .foregroundStyle(collisions.contains(index) ? .red : .primary)
                    }
                    .padding(.vertical, 3).padding(.horizontal, 8)
                    .background(index.isMultiple(of: 2) ? Color.clear : Color.gray.opacity(0.08))
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.06)))
    }
}
