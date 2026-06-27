import Foundation

/// Breaks the AppKit↔SwiftUI selection feedback loop for the file list.
///
/// `NSTableView` is imperative; the Panel's `selection` is a reactive binding. Each
/// side writing the other risks an infinite echo and selection thrash. Two rules,
/// both here so they're testable without a live table or render cycle:
///
/// - **Echo suppression (binding → table):** ignore a binding value that merely
///   matches what the table just published; only apply genuinely external changes
///   (e.g. navigation clearing the selection).
/// - **Reentrancy (table → binding):** while we apply a selection to the table
///   programmatically, the delegate callback that fires is *ours* — drop it.
///
/// The Coordinator keeps the imperative table I/O; this owns only the decision.
struct SelectionEchoGuard {
    private var lastPublished = Set<FileItem.ID>()
    private(set) var isApplying = false

    /// Table → binding. Returns the ids to publish, or `nil` if this change is our
    /// own programmatic selection echoing back (suppress it). Records what we publish.
    mutating func captureFromTable(_ ids: Set<FileItem.ID>) -> Set<FileItem.ID>? {
        guard !isApplying else { return nil }
        lastPublished = ids
        return ids
    }

    /// Binding → table. `true` when the binding changed externally (apply it);
    /// `false` when it merely echoes what the table just published (skip). Records
    /// the value it accepts.
    mutating func shouldApply(_ binding: Set<FileItem.ID>) -> Bool {
        guard binding != lastPublished else { return false }
        lastPublished = binding
        return true
    }

    /// Bracket the imperative `selectRowIndexes` call. Separate begin/end (not a
    /// closure) so the reentrant delegate callback isn't an overlapping exclusive
    /// access to this value. AppKit fires the selection notification synchronously
    /// inside the select call, so it sees `isApplying == true`.
    mutating func beginApply() { isApplying = true }
    mutating func endApply() { isApplying = false }
}
