import Foundation
import Observation

/// The virtual staging set (issue 20): an explicit, ordered collection of files the
/// user has gathered from **many** different folders, to operate on as one set.
///
/// Unlike a `LocalDirectorySource` it is *not* a directory — there is no parent to
/// watch (ADR 0003). It holds plain `URL`s; a `StagingSource` validates each one on
/// load. Session-only for v1: the set is not persisted across launches (paths go
/// stale), so this is in-memory state owned by the `WorkspaceModel`.
@MainActor
@Observable
final class StagingStore {
    /// The staged URLs in insertion order. Insertion order is meaningful — the user
    /// builds the list deliberately, so we preserve it rather than sorting.
    private(set) var urls: [URL] = []

    var isEmpty: Bool { urls.isEmpty }

    /// Add files to the set, preserving order and skipping ones already staged.
    /// Adding the same file twice is a no-op (the set is a set, ordered).
    func add(_ newURLs: [URL]) {
        for url in newURLs where !urls.contains(url) {
            urls.append(url)
        }
    }

    /// Remove files from the set (unstage). Non-destructive — the files stay on disk;
    /// this only edits the in-memory list.
    func remove(_ urls: [URL]) {
        let drop = Set(urls)
        self.urls.removeAll { drop.contains($0) }
    }
}
