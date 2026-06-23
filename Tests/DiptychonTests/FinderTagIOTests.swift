import XCTest
@testable import Diptychon

/// Tests the file I/O side of tags — `FinderTag.read(from:)` reading the real
/// `_kMDItemUserTags` xattr off disk (the codec itself is covered separately).
final class FinderTagIOTests: XCTestCase {
    private var fileURL: URL!

    override func setUpWithError() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("dipt-tagio-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("file.txt")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
    }

    private func writeTagXattr(_ entries: [String]) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: entries, format: .binary, options: 0)
        let rc = data.withUnsafeBytes {
            setxattr(fileURL.path, FinderTag.xattrName, $0.baseAddress, data.count, 0, 0)
        }
        XCTAssertEqual(rc, 0, "setxattr should succeed")
    }

    func testReadsTagsWithColorsFromDisk() throws {
        try writeTagXattr(["Red\n6", "Important"])
        XCTAssertEqual(FinderTag.read(from: fileURL), [
            FinderTag(name: "Red", color: .red),
            FinderTag(name: "Important", color: .none),
        ])
    }

    func testUntaggedFileReadsAsEmpty() {
        XCTAssertEqual(FinderTag.read(from: fileURL), [])
    }
}
