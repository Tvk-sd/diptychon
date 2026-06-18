import Foundation

/// A batch-rename transformation, modeled on Finder's three exclusive modes:
/// Replace Text, Add Text, and Format (name + counter). Pure value type so name
/// computation is unit-testable without any UI. Regex is out of MVP scope (→ v1.1).
enum RenameRule: Equatable {
    enum Position: String, CaseIterable, Identifiable {
        case before = "before name"
        case after = "after name"
        var id: String { rawValue }
    }

    enum CaseMode: String, CaseIterable, Identifiable {
        case lower = "lowercase"
        case upper = "UPPERCASE"
        case capitalized = "Capitalized"
        var id: String { rawValue }
    }

    case replaceText(find: String, with: String)
    case addText(String, Position)
    case format(name: String, start: Int, padding: Int)
    case changeCase(CaseMode)

    /// New file name for `original` at `index`. Extension is preserved;
    /// transforms apply to the base name only.
    func newName(for original: String, index: Int) -> String {
        let ns = original as NSString
        let ext = ns.pathExtension
        let base = ns.deletingPathExtension
        let newBase: String

        switch self {
        case let .replaceText(find, with):
            newBase = find.isEmpty ? base : base.replacingOccurrences(of: find, with: with)
        case let .addText(text, position):
            newBase = position == .before ? text + base : base + text
        case let .format(name, start, padding):
            let n = start + index
            newBase = "\(name) \(String(format: "%0\(max(padding, 1))d", n))"
        case let .changeCase(mode):
            switch mode {
            case .lower: newBase = base.lowercased()
            case .upper: newBase = base.uppercased()
            case .capitalized: newBase = base.capitalized
            }
        }
        return ext.isEmpty ? newBase : "\(newBase).\(ext)"
    }

    func newNames(for originals: [String]) -> [String] {
        originals.enumerated().map { newName(for: $1, index: $0) }
    }
}

/// Indices of entries that collide and must block the rename:
/// (a) two outputs map to the same name, or
/// (b) an output would clobber an existing file in `directory` that isn't itself
///     one of the originals being renamed.
func renameCollisionIndices(originals: [String], newNames: [String], directory: URL) -> Set<Int> {
    var collisions = Set<Int>()

    var seen: [String: Int] = [:]
    for (i, name) in newNames.enumerated() {
        if let first = seen[name] { collisions.insert(first); collisions.insert(i) }
        else { seen[name] = i }
    }

    let originalSet = Set(originals)
    let fm = FileManager.default
    for (i, name) in newNames.enumerated() where name != originals[i] {
        let path = directory.appendingPathComponent(name).path
        if fm.fileExists(atPath: path) && !originalSet.contains(name) {
            collisions.insert(i)
        }
    }
    return collisions
}
