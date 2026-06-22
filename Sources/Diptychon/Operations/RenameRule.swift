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
/// (b) an output would clobber an existing file in `directory` that the batch
///     isn't itself moving out of the way.
///
/// Name comparison follows the volume's case sensitivity: on a case-insensitive
/// volume (the macOS default), `alpha.txt` and `ALPHA.txt` are the same name. So
/// a *case-only* rename of a file (e.g. `alpha.txt` → `ALPHA.txt`) is NOT a
/// collision — it's the file renaming itself — and two outputs differing only in
/// case ARE a collision.
func renameCollisionIndices(originals: [String], newNames: [String], directory: URL) -> Set<Int> {
    renameCollisionIndices(originals: originals, newNames: newNames, directory: directory,
                           caseInsensitive: directoryIsCaseInsensitive(directory))
}

/// Testable core: `caseInsensitive` is injected so both volume kinds can be
/// exercised without depending on the test machine's filesystem.
func renameCollisionIndices(originals: [String], newNames: [String], directory: URL,
                            caseInsensitive: Bool) -> Set<Int> {
    func norm(_ s: String) -> String { caseInsensitive ? s.lowercased() : s }

    var collisions = Set<Int>()

    // (a) two outputs map to the same name (case-folded on case-insensitive volumes).
    var seen: [String: Int] = [:]
    for (i, name) in newNames.enumerated() {
        let key = norm(name)
        if let first = seen[key] { collisions.insert(first); collisions.insert(i) }
        else { seen[key] = i }
    }

    // Names this batch vacates: originals whose name actually changes. A file
    // staying put (unchanged) still occupies its name, so it can be clobbered.
    let vacated = Set(zip(originals, newNames).filter { $0 != $1 }.map { norm($0.0) })

    // (b) output clobbers a surviving on-disk file. Skip pure case-only self
    // renames (output normalizes to the item's own original name).
    let fm = FileManager.default
    for (i, name) in newNames.enumerated() where norm(name) != norm(originals[i]) {
        let path = directory.appendingPathComponent(name).path
        if fm.fileExists(atPath: path) && !vacated.contains(norm(name)) {
            collisions.insert(i)
        }
    }
    return collisions
}

/// Whether `directory`'s volume treats names case-insensitively (macOS default).
/// Defaults to case-insensitive when the trait can't be read.
private func directoryIsCaseInsensitive(_ directory: URL) -> Bool {
    let caseSensitive = (try? directory.resourceValues(forKeys: [.volumeSupportsCaseSensitiveNamesKey]))?
        .volumeSupportsCaseSensitiveNames ?? false
    return !caseSensitive
}
