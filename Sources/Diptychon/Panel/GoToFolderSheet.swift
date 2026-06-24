import SwiftUI

/// Go to Folder (⇧⌘G): type or paste a path to jump the Active Panel there
/// (issue 15). Pre-filled with the current directory; invalid paths show an
/// inline error rather than navigating.
struct GoToFolderSheet: View {
    @Bindable var model: WorkspaceModel
    @State private var path = ""
    @State private var showError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Go to Folder").font(.headline)

            TextField("/path/to/folder", text: $path)
                .textFieldStyle(.roundedBorder)
                .frame(width: 380)
                .onSubmit(go)
                .onChange(of: path) { showError = false }
                .accessibilityIdentifier("goto-path")

            if showError {
                Label("No folder at that path.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") { model.goingToFolder = false }
                    .keyboardShortcut(.cancelAction)
                Button("Go", action: go)
                    .keyboardShortcut(.defaultAction)
                    .disabled(path.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .onAppear { path = model.activeModel.directory.path }
    }

    private func go() {
        if model.navigateActive(toPath: path) {
            model.goingToFolder = false
        } else {
            showError = true
        }
    }
}
