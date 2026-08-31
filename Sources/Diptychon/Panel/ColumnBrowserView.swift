import SwiftUI

/// The column browser (issue 91): one folder per column, each showing what is
/// selected in the column to its left — the Finder's column view, and the thing Till
/// expected when a folder was clicked.
///
/// It is not a variant of the brief view. The brief view breaks **one folder across
/// several columns**; this shows **several folders, one per column**. One is for
/// taking in a big folder, the other for walking a deep tree.
///
/// **Everything here is derived from the pane's `directory`** (see `ColumnChain`).
/// The last column is that folder, which is the list the pane already owns — so its
/// selection remains the one operations act on, and no other part of the app needs to
/// know this view exists.
struct ColumnBrowserView: View {
    let model: PanelModel
    /// Column width. Fixed for now: whether it needs dragging and remembering is a
    /// question the real use answers, and guessing would add persisted state nobody
    /// asked for.
    private static let columnWidth: CGFloat = 240

    let onDrop: (_ urls: [URL], _ targetFolder: FileItem?) -> Void
    var onPin: (_ folder: URL) -> Void = { _ in }
    var onAddToStaging: (_ urls: [URL]) -> Void = { _ in }
    var onActivate: (_ item: FileItem) -> Void = { _ in }
    var onRename: (_ item: FileItem, _ newName: String) -> Bool = { _, _ in false }
    var hasKeyFocus: Bool = true
    var accessibilityID: String = ""

    var body: some View {
        let chain = model.columnChain
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    ForEach(Array(chain.enumerated()), id: \.element) { index, url in
                        column(at: index, url: url, chain: chain)
                            .frame(width: Self.columnWidth)
                            .id(url)
                        // The same hairline the brief view rules its columns with, so
                        // the app has one grid language rather than two.
                        Divider()
                    }
                }
                .frame(maxHeight: .infinity)
            }
            // Follow the navigation instead of waiting for the user to scroll: the
            // column they just opened is the one they are looking for.
            .onChange(of: model.directory) {
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(model.directory, anchor: .trailing)
                }
            }
            .onAppear { proxy.scrollTo(model.directory, anchor: .trailing) }
        }
    }

    /// One column. The last one is the pane's own model — hence its own selection
    /// binding; the ancestors are cached models whose "selection" is not the user's
    /// but the child that leads onward, so it is derived rather than stored.
    @ViewBuilder
    private func column(at index: Int, url: URL, chain: [URL]) -> some View {
        let isLast = index == chain.count - 1
        let columnModel = model.columnModel(for: url)
        @Bindable var bindable = columnModel

        // One name-only column each, reusing the brief view's renderer at a column
        // count of 1. The detailed table would repeat its Name/Type/Date/Size headers
        // in every column and leave nothing but truncated names in 240pt — checked on
        // the running build before this swap. This also inherits #37's row bands and
        // hairlines, so both multi-column views share one grid language.
        BriefFileListView(
            items: columnModel.visibleItems,
            selection: isLast
                ? $bindable.selection
                : Binding(
                    get: { derivedSelection(at: index, chain: chain, in: columnModel) },
                    set: { newValue in apply(newValue, at: index, chain: chain, in: columnModel) }
                  ),
            sortOrder: $bindable.sortOrder,
            onDrop: onDrop,
            onPin: onPin,
            onAddToStaging: onAddToStaging,
            onRemoveFromStaging: nil,
            onActivate: { item in
                // A folder opens as a column; a file opens for real, same as the table.
                if item.isDirectory { model.openColumn(item.url) } else { onActivate(item) }
            },
            renameRequest: isLast ? columnModel.inlineRenameRequest : nil,
            onRename: onRename,
            accessibilityID: isLast ? accessibilityID : "\(accessibilityID)-column-\(index)"
        )
        .briefColumns(1)
        .onHorizontalStep { right in step(right: right, from: index, chain: chain) }
        .claimingKeyFocus(hasKeyFocus && isLast)
    }

    /// ← and → step between columns, which is what they mean to the eye here — ↑ and ↓
    /// stay inside one. Both are expressed as a move of `directory`, like every other
    /// change in this view.
    ///
    /// → on a folder opens it as the next column and lands the keyboard there (the
    /// pane's own list claims focus, since the new folder becomes the last column).
    /// → on a file does nothing: there is nothing to the right of it.
    /// ← goes to the parent, which keeps the column you came from on screen with your
    /// place in it still highlighted.
    private func step(right: Bool, from index: Int, chain: [URL]) {
        if right {
            guard let item = model.selectedItems.first, item.isDirectory else { return }
            model.openColumn(item.url)
        } else {
            let current = chain[index]
            guard current.path != "/" else { return }
            model.openColumn(current.deletingLastPathComponent())
        }
    }

    /// What is highlighted in an ancestor column: the child that leads to the next
    /// column. Nothing remembers this — it falls out of the chain.
    private func derivedSelection(at index: Int, chain: [URL],
                                  in columnModel: PanelModel) -> Set<FileItem.ID> {
        guard let child = ColumnChain.selectedChild(inColumnAt: index, chain: chain),
              let item = columnModel.visibleItems.first(where: { $0.url == child })
        else { return [] }
        return [item.id]
    }

    /// A click in any column. This is the whole interaction model:
    ///
    ///     folder F picked in column i → directory = F        (the chain grows)
    ///     file   X picked in column i → directory = folder i (the chain is cut back)
    ///
    /// Both fall out of moving `directory`; nothing else is tracked. Picking a file in
    /// a middle column drops the columns to its right because the chain then ends at
    /// the folder that file lives in.
    private func apply(_ newValue: Set<FileItem.ID>, at index: Int, chain: [URL],
                       in columnModel: PanelModel) {
        guard let id = newValue.first,
              let item = columnModel.visibleItems.first(where: { $0.id == id }) else { return }
        if item.isDirectory {
            model.openColumn(item.url)
        } else {
            model.openColumn(chain[index])
            model.selection = [item.id]
        }
    }
}
