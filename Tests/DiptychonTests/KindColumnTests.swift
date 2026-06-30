import XCTest
import UniformTypeIdentifiers
@testable import Diptychon

/// Issue 29: the Kind column derives a Finder-style type string and sorts by it.
final class KindColumnTests: XCTestCase {

    func testKindIsTheUppercasedExtensionWithFolderAndFallback() {
        XCTAssertEqual(FileItem.kind(for: URL(fileURLWithPath: "/x"), isDirectory: true, contentType: nil), "Folder")
        XCTAssertEqual(FileItem.kind(for: URL(fileURLWithPath: "/doc.pdf"), isDirectory: false, contentType: nil), "PDF")
        XCTAssertEqual(FileItem.kind(for: URL(fileURLWithPath: "/img.PNG"), isDirectory: false, contentType: nil), "PNG",
                       "extension is normalised to uppercase")
        // Extension-less: fall back to the content type's canonical extension.
        XCTAssertEqual(FileItem.kind(for: URL(fileURLWithPath: "/notes"), isDirectory: false, contentType: .plainText),
                       UTType.plainText.preferredFilenameExtension?.uppercased())
        XCTAssertEqual(FileItem.kind(for: URL(fileURLWithPath: "/blob"), isDirectory: false, contentType: nil), "—",
                       "no extension and no type → dash, never blank")
    }

    func testRowsSortByKind() {
        let pdf = FileItem(url: URL(fileURLWithPath: "/a"), name: "a", size: nil,
                           modificationDate: nil, isDirectory: false, kind: "PDF")
        let folder = FileItem(url: URL(fileURLWithPath: "/b"), name: "b", size: nil,
                              modificationDate: nil, isDirectory: true, kind: "Folder")
        let sorted = [pdf, folder].sorted(using: [KeyPathComparator(\FileItem.kind)])
        XCTAssertEqual(sorted.map(\.kind), ["Folder", "PDF"], "ascending kind sort")
    }
}
