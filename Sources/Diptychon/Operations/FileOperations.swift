import Foundation

/// Move sources into a destination directory. Inverse moves them back to where
/// they came from. Overwriting destroys the existing file -> not undoable.
final class MoveOperation: Operation {
    let sources: [URL]
    let destinationDirectory: URL
    let resolution: CollisionResolution

    private(set) var moves: [(from: URL, to: URL)] = []
    private(set) var didOverwrite = false

    init(sources: [URL], destinationDirectory: URL, resolution: CollisionResolution) {
        self.sources = sources
        self.destinationDirectory = destinationDirectory
        self.resolution = resolution
    }

    var title: String {
        sources.count == 1 ? "Move “\(sources[0].lastPathComponent)”" : "Move \(sources.count) items"
    }
    var isUndoable: Bool { !didOverwrite }

    func apply(progress: @escaping (Double) -> Void) async throws {
        let sources = self.sources, destDir = self.destinationDirectory, resolution = self.resolution
        try await Task.detached(priority: .userInitiated) { [weak self] in
            let fm = FileManager.default
            let total = max(sources.count, 1)
            for (index, src) in sources.enumerated() {
                try Task.checkCancellation()
                // Skip no-op moves (already in the destination directory).
                if src.deletingLastPathComponent() == destDir {
                    progress(Double(index + 1) / Double(total)); continue
                }
                var dest = destDir.appendingPathComponent(src.lastPathComponent)
                if fm.fileExists(atPath: dest.path) {
                    switch resolution {
                    case .skip: progress(Double(index + 1) / Double(total)); continue
                    case .overwrite: try? fm.removeItem(at: dest); self?.didOverwrite = true
                    case .rename: dest = CopyOperation.uniqueDestination(for: dest, fm: fm)
                    }
                }
                try fm.moveItem(at: src, to: dest)
                self?.moves.append((from: src, to: dest))
                progress(Double(index + 1) / Double(total))
            }
        }.value
    }

    func revert() async throws {
        let moves = self.moves
        await Task.detached(priority: .userInitiated) { [weak self] in
            let fm = FileManager.default
            for move in moves.reversed() {
                try? fm.moveItem(at: move.to, to: move.from)
            }
            self?.moves = []
        }.value
    }
}

/// Move sources to the macOS Trash (never a hard delete). Inverse restores each
/// item from its Trash location back to where it was.
final class TrashOperation: Operation {
    let sources: [URL]
    private(set) var trashed: [(original: URL, inTrash: URL)] = []

    init(sources: [URL]) { self.sources = sources }

    var title: String {
        sources.count == 1 ? "Move “\(sources[0].lastPathComponent)” to Trash"
                           : "Move \(sources.count) items to Trash"
    }
    var isUndoable: Bool { true }

    func apply(progress: @escaping (Double) -> Void) async throws {
        let sources = self.sources
        try await Task.detached(priority: .userInitiated) { [weak self] in
            let fm = FileManager.default
            let total = max(sources.count, 1)
            for (index, src) in sources.enumerated() {
                try Task.checkCancellation()
                var resulting: NSURL?
                try fm.trashItem(at: src, resultingItemURL: &resulting)
                if let inTrash = resulting as URL? {
                    self?.trashed.append((original: src, inTrash: inTrash))
                }
                progress(Double(index + 1) / Double(total))
            }
        }.value
    }

    func revert() async throws {
        let trashed = self.trashed
        await Task.detached(priority: .userInitiated) { [weak self] in
            let fm = FileManager.default
            for item in trashed.reversed() {
                try? fm.moveItem(at: item.inTrash, to: item.original)
            }
            self?.trashed = []
        }.value
    }
}

/// Create a new empty folder or file in a directory, under a unique
/// "untitled …" name. Inverse deletes what was created.
final class CreateOperation: Operation {
    enum Kind { case folder, file }

    let directory: URL
    let kind: Kind
    private(set) var createdURL: URL?

    init(directory: URL, kind: Kind) {
        self.directory = directory
        self.kind = kind
    }

    var title: String { kind == .folder ? "New Folder" : "New File" }
    var isUndoable: Bool { true }

    func apply(progress: @escaping (Double) -> Void) async throws {
        let directory = self.directory, kind = self.kind
        try await Task.detached(priority: .userInitiated) { [weak self] in
            let fm = FileManager.default
            let base = kind == .folder ? "untitled folder" : "untitled file"
            var url = directory.appendingPathComponent(base)
            if fm.fileExists(atPath: url.path) {
                url = CopyOperation.uniqueDestination(for: url, fm: fm)
            }
            switch kind {
            case .folder: try fm.createDirectory(at: url, withIntermediateDirectories: false)
            case .file: fm.createFile(atPath: url.path, contents: Data())
            }
            self?.createdURL = url
            progress(1.0)
        }.value
    }

    func revert() async throws {
        let url = createdURL
        await Task.detached(priority: .userInitiated) { [weak self] in
            if let url { try? FileManager.default.removeItem(at: url) }
            self?.createdURL = nil
        }.value
    }
}
