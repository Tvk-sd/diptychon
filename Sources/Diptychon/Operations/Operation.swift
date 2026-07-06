import Foundation

/// ADR 0004 — every file operation is modeled as a reversible `Operation` that
/// knows its own inverse, so a multi-level undo stack is cheap. (CONTEXT.md calls
/// this an *Operation*, deliberately not "command".)
///
/// `apply` does the work and reports 0...1 progress; `revert` is the inverse.
/// Overwrites destroy the original and cannot be reversed -> `isUndoable == false`
/// and `revert()` must not be called.
protocol Operation: AnyObject {
    var title: String { get }
    var isUndoable: Bool { get }
    func apply(progress: @escaping (Double) -> Void) async throws
    func revert() async throws
}

/// How to resolve a pre-write name collision (chosen before any bytes are written).
enum CollisionResolution {
    case overwrite // destroys the existing file — NOT undoable.
    case rename    // write under a unique " 2"/" 3"… name.
    case skip      // leave the existing file, don't copy this source.
}

/// Run blocking filesystem work off the main thread **while still honoring the
/// caller's cancellation.** `Task.detached` deliberately inherits nothing from its
/// parent — priority, task-locals, *and cancellation* — so a bare
/// `Task.detached { … Task.checkCancellation() … }.value` can never be stopped by the
/// coordinator: cancelling the awaiting parent leaves the detached loop running to
/// completion (the "Cancel does nothing" bug, issue 34).
/// `withTaskCancellationHandler` bridges the gap: when the awaiting parent is
/// cancelled it forwards the cancel to the detached task, so the loop's existing
/// `Task.checkCancellation()` finally throws `CancellationError` — which the
/// `OperationCoordinator` catches to `revert()` the partial work.
func runOffMainCancellable(_ work: @escaping @Sendable () throws -> Void) async throws {
    let task = Task.detached(priority: .userInitiated, operation: work)
    try await withTaskCancellationHandler {
        try await task.value
    } onCancel: {
        task.cancel()
    }
}

/// Copy a set of sources into a destination directory (the Commander gesture).
/// Records the URLs it newly created so `revert` can delete exactly those.
final class CopyOperation: Operation {
    let sources: [URL]
    let destinationDirectory: URL
    let resolution: CollisionResolution

    private(set) var createdURLs: [URL] = []
    private(set) var didOverwrite = false

    init(sources: [URL], destinationDirectory: URL, resolution: CollisionResolution) {
        self.sources = sources
        self.destinationDirectory = destinationDirectory
        self.resolution = resolution
    }

    var title: String {
        sources.count == 1
            ? "Copy “\(sources[0].lastPathComponent)”"
            : "Copy \(sources.count) items"
    }

    // Overwriting destroys the original; once that happened there is no inverse.
    var isUndoable: Bool { !didOverwrite }

    func apply(progress: @escaping (Double) -> Void) async throws {
        let sources = self.sources
        let destDir = self.destinationDirectory
        let resolution = self.resolution

        try await runOffMainCancellable { [weak self] in
            let fm = FileManager.default
            let total = max(sources.count, 1)
            for (index, src) in sources.enumerated() {
                try Task.checkCancellation()
                var dest = destDir.appendingPathComponent(src.lastPathComponent)

                if fm.fileExists(atPath: dest.path) {
                    switch resolution {
                    case .skip:
                        progress(Double(index + 1) / Double(total))
                        continue
                    case .overwrite:
                        // Pasting an item into the folder it already lives in resolves
                        // dest == src. Removing then re-copying would destroy it (and an
                        // overwrite is not undoable). Treat self-overwrite as a no-op.
                        if dest.standardizedFileURL == src.standardizedFileURL {
                            progress(Double(index + 1) / Double(total))
                            continue
                        }
                        try? fm.removeItem(at: dest)
                        self?.didOverwrite = true
                    case .rename:
                        dest = Self.uniqueDestination(for: dest, fm: fm)
                    }
                }

                try fm.copyItem(at: src, to: dest)
                self?.createdURLs.append(dest)
                progress(Double(index + 1) / Double(total))
            }
        }
    }

    func revert() async throws {
        let created = createdURLs
        await Task.detached(priority: .userInitiated) { [weak self] in
            let fm = FileManager.default
            for url in created.reversed() {
                try? fm.removeItem(at: url)
            }
            self?.createdURLs = []
        }.value
    }

    /// "name.ext" -> "name 2.ext", "name 3.ext"… until free.
    static func uniqueDestination(for url: URL, fm: FileManager) -> URL {
        let dir = url.deletingLastPathComponent()
        let ext = url.pathExtension
        let base = url.deletingPathExtension().lastPathComponent
        var n = 2
        while true {
            let candidateName = ext.isEmpty ? "\(base) \(n)" : "\(base) \(n).\(ext)"
            let candidate = dir.appendingPathComponent(candidateName)
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            n += 1
        }
    }
}

/// Sources whose name already exists in `destinationDirectory` (pre-write check).
func detectCollisions(sources: [URL], destinationDirectory: URL) -> [URL] {
    let fm = FileManager.default
    return sources.filter {
        fm.fileExists(atPath: destinationDirectory.appendingPathComponent($0.lastPathComponent).path)
    }
}
