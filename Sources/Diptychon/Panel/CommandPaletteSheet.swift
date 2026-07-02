import SwiftUI

/// The ⌘K command palette (issue 19): a centered search-over-commands overlay.
/// Type to fuzzy-filter, ↑/↓ to move, ↩ to run, ⎋ to dismiss. Disabled commands
/// are greyed (discoverability) and beep on ↩ rather than running.
struct CommandPaletteSheet: View {
    let model: WorkspaceModel
    @State private var query = ""
    @State private var highlighted = 0
    /// Bumped by keyboard navigation (only) to ask the list to scroll — hovering
    /// must move the highlight without scrolling the list under the cursor.
    @State private var scrollRequest = 0
    /// After a keyboard move, ignore hover briefly: scrolling slides a new row under
    /// a stationary cursor, whose `.onHover` would otherwise snap the selection back.
    @State private var suppressHoverUntil = Date.distantPast
    @FocusState private var searchFocused: Bool

    private var results: [PaletteCommand] { CommandCatalog.filter(query) }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            if results.isEmpty {
                Text("No commands")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                resultsList
            }
        }
        .frame(width: 520, height: 420)
        .onAppear { searchFocused = true }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Run a command…", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
                .onChange(of: query) { highlighted = 0; scrollRequest += 1 }
                .onKeyPress(.downArrow) { move(1); return .handled }
                .onKeyPress(.upArrow) { move(-1); return .handled }
                .onKeyPress(.return) { runHighlighted(); return .handled }
                .onKeyPress(.escape) { model.presentedSheet = nil; return .handled }
        }
        .padding(12)
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Identify rows by position, matching `.id(idx)` and the
                    // index-based `scrollTo`. Keying by `\.element.id` while also
                    // setting `.id(idx)` gave rows two identities, so a changed
                    // filter reused stale rows and showed the wrong titles.
                    ForEach(Array(results.enumerated()), id: \.offset) { idx, command in
                        row(command, idx: idx).id(idx)
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: scrollRequest) { proxy.scrollTo(highlighted, anchor: .center) }
        }
    }

    private func row(_ command: PaletteCommand, idx: Int) -> some View {
        let enabled = command.isEnabled(model)
        // A plain Button so the row has no system hover/press tint — the only
        // highlight is our `highlighted` background, identical for mouse and keyboard.
        return Button {
            highlighted = idx
            runHighlighted()
        } label: {
            HStack(spacing: 8) {
                Text(command.title)
                    .foregroundStyle(enabled ? .primary : .tertiary)
                Spacer(minLength: 8)
                Text(command.category)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if let shortcut = command.shortcut {
                    Text(shortcut)
                        .font(.callout)
                        .monospaced()
                        .foregroundStyle(enabled ? .secondary : Color.secondary.opacity(0.4))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(idx == highlighted ? Color.accentColor.opacity(0.18) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .onHover { hovering in
            // Mouse and keyboard share one highlight; hover never scrolls the list.
            if hovering, Date() >= suppressHoverUntil { highlighted = idx }
        }
    }

    /// Move the highlight by keyboard, wrapping around — and scroll to keep it in view.
    private func move(_ delta: Int) {
        guard !results.isEmpty else { return }
        highlighted = (highlighted + delta + results.count) % results.count
        suppressHoverUntil = Date().addingTimeInterval(0.3)
        scrollRequest += 1
    }

    /// Run the highlighted command (dismissing the palette first), or beep if it's
    /// disabled in the current context.
    private func runHighlighted() {
        guard results.indices.contains(highlighted) else { return }
        let command = results[highlighted]
        guard command.isEnabled(model) else { NSSound.beep(); return }
        model.runPaletteCommand(command)
    }
}
