import Foundation

/// Set Finder tags on a set of files as ONE undoable Operation (ADR 0004). On
/// apply it records each file's prior tags, so revert restores them exactly —
/// including back to untagged.
final class SetTagsOperation: Operation {
    private let targets: [(url: URL, newTags: [FinderTag])]
    private var priorTags: [(url: URL, tags: [FinderTag])] = []

    let title = "Set Tags"
    let isUndoable = true

    init(targets: [(url: URL, newTags: [FinderTag])]) { self.targets = targets }

    func apply(progress: @escaping (Double) -> Void) async throws {
        priorTags = targets.map { ($0.url, FinderTag.read(from: $0.url)) }
        for (i, target) in targets.enumerated() {
            try FinderTag.write(target.newTags, to: target.url)
            progress(Double(i + 1) / Double(max(targets.count, 1)))
        }
    }

    func revert() async throws {
        for prior in priorTags { try FinderTag.write(prior.tags, to: prior.url) }
    }
}
