import Foundation

/// An Apple Finder tag: a colored, named label stored in a file's
/// `com.apple.metadata:_kMDItemUserTags` extended attribute (CONTEXT.md → Tag).
/// Always round-trip compatible with Finder — the app keeps no parallel store.
struct FinderTag: Equatable, Hashable {
    var name: String
    var color: FinderTagColor
}

/// Finder's eight tag color slots. The raw value is the color index stored on
/// disk after the tag name (`"name\n6"` = Red). `none` (0) is a named tag with no
/// color. Order matches Finder; index 6 = Red is confirmed against a
/// Finder-written sample.
enum FinderTagColor: Int, CaseIterable {
    case none = 0
    case gray = 1
    case green = 2
    case purple = 3
    case blue = 4
    case yellow = 5
    case red = 6
    case orange = 7
}

extension FinderTag {
    /// The extended-attribute name Finder uses for user tags.
    static let xattrName = "com.apple.metadata:_kMDItemUserTags"

    /// A file's Finder tags (with colors), read straight from its xattr. `[]` if
    /// the file has no tags or the attribute can't be read.
    static func read(from url: URL) -> [FinderTag] {
        guard let data = url.extendedAttribute(named: xattrName) else { return [] }
        return FinderTagCodec.decode(data)
    }

    /// Write tags to a file's xattr. Empty tags removes the attribute entirely, so
    /// an untagged file carries no `_kMDItemUserTags` (matching Finder).
    static func write(_ tags: [FinderTag], to url: URL) throws {
        if tags.isEmpty {
            try url.removeExtendedAttribute(named: xattrName)
        } else {
            try url.setExtendedAttribute(named: xattrName, data: FinderTagCodec.encode(tags))
        }
    }

    /// Finder's seven standard color tags, named as Finder names them.
    static let standard: [FinderTag] = [
        FinderTag(name: "Red", color: .red),
        FinderTag(name: "Orange", color: .orange),
        FinderTag(name: "Yellow", color: .yellow),
        FinderTag(name: "Green", color: .green),
        FinderTag(name: "Blue", color: .blue),
        FinderTag(name: "Purple", color: .purple),
        FinderTag(name: "Gray", color: .gray),
    ]
}

extension URL {
    /// Raw bytes of an extended attribute, or `nil` if it isn't set.
    func extendedAttribute(named name: String) -> Data? {
        withUnsafeFileSystemRepresentation { fsPath -> Data? in
            let length = getxattr(fsPath, name, nil, 0, 0, 0)
            guard length >= 0 else { return nil }
            var data = Data(count: length)
            let read = data.withUnsafeMutableBytes { getxattr(fsPath, name, $0.baseAddress, length, 0, 0) }
            return read >= 0 ? data : nil
        }
    }

    /// Write (create/replace) an extended attribute.
    func setExtendedAttribute(named name: String, data: Data) throws {
        try withUnsafeFileSystemRepresentation { fsPath in
            let rc = data.withUnsafeBytes { setxattr(fsPath, name, $0.baseAddress, data.count, 0, 0) }
            if rc != 0 { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
        }
    }

    /// Remove an extended attribute. Absent attribute (`ENOATTR`) is a no-op.
    func removeExtendedAttribute(named name: String) throws {
        try withUnsafeFileSystemRepresentation { fsPath in
            let rc = removexattr(fsPath, name, 0)
            if rc != 0 && errno != ENOATTR { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
        }
    }
}

/// Encodes/decodes the `_kMDItemUserTags` payload: a binary-plist array of
/// `"name"` or `"name\n<colorIndex>"` strings. Pure (operates on `Data`) so it is
/// unit-testable without touching the filesystem.
enum FinderTagCodec {
    /// Parse the xattr payload into tags. Empty data (no xattr) → no tags.
    /// Unknown/garbage entries are skipped rather than throwing — a tag display
    /// must never crash a directory listing.
    static func decode(_ data: Data) -> [FinderTag] {
        guard !data.isEmpty,
              let entries = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let strings = entries as? [String]
        else { return [] }

        return strings.map { entry in
            // "name" or "name\n<index>". A name may itself contain newlines only
            // in pathological cases; the LAST line is the color index when numeric.
            if let nl = entry.lastIndex(of: "\n"),
               let index = Int(entry[entry.index(after: nl)...]),
               let color = FinderTagColor(rawValue: index) {
                return FinderTag(name: String(entry[..<nl]), color: color)
            }
            return FinderTag(name: entry, color: .none)
        }
    }

    /// Serialize tags to a binary-plist payload Finder reads. A `.none` tag is
    /// written as just its name (no `\n0`), matching how Finder stores it.
    static func encode(_ tags: [FinderTag]) -> Data {
        let strings = tags.map { tag in
            tag.color == .none ? tag.name : "\(tag.name)\n\(tag.color.rawValue)"
        }
        return (try? PropertyListSerialization.data(fromPropertyList: strings,
                                                    format: .binary, options: 0)) ?? Data()
    }
}
