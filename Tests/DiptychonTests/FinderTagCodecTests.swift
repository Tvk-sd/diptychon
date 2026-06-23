import XCTest
@testable import Diptychon

/// Unit tests for `FinderTagCodec` — the pure encode/decode of the
/// `_kMDItemUserTags` xattr payload. The hard part of issue 08 is on-disk
/// fidelity with Finder, so these run without any filesystem.
final class FinderTagCodecTests: XCTestCase {

    /// A real binary-plist payload captured from a file tagged Red + Important
    /// (Red = color index 6, Important = no color stored as index 0). Decoding
    /// this proves we read Finder's actual on-disk format, not a guess.
    private let finderSample = Data(base64Encoded:
        "YnBsaXN0MDCiAQJVUmVkCjZbSW1wb3J0YW50CjAICxEAAAAAAAABAQAAAAAAAAADAAAAAAAAAAAAAAAAAAAAHQ=="
    )!

    func testDecodesRealFinderPayload() {
        let tags = FinderTagCodec.decode(finderSample)
        XCTAssertEqual(tags, [
            FinderTag(name: "Red", color: .red),
            FinderTag(name: "Important", color: .none),
        ])
    }

    func testRoundTripsThroughEncodeDecode() {
        let tags = [
            FinderTag(name: "Work", color: .blue),
            FinderTag(name: "Urgent", color: .orange),
            FinderTag(name: "Plain", color: .none),
        ]
        XCTAssertEqual(FinderTagCodec.decode(FinderTagCodec.encode(tags)), tags)
    }

    func testEncodesNoneColorAsBareName() {
        // A .none tag must serialize as just its name (no "\n0"), as Finder does.
        let data = FinderTagCodec.encode([FinderTag(name: "Plain", color: .none)])
        let strings = try! PropertyListSerialization
            .propertyList(from: data, options: [], format: nil) as! [String]
        XCTAssertEqual(strings, ["Plain"])
    }

    func testEncodesColorAsNameNewlineIndex() {
        let data = FinderTagCodec.encode([FinderTag(name: "Red", color: .red)])
        let strings = try! PropertyListSerialization
            .propertyList(from: data, options: [], format: nil) as! [String]
        XCTAssertEqual(strings, ["Red\n6"])
    }

    func testEmptyDataYieldsNoTags() {
        XCTAssertEqual(FinderTagCodec.decode(Data()), [])
    }

    func testGarbageDataYieldsNoTagsWithoutCrashing() {
        XCTAssertEqual(FinderTagCodec.decode(Data([0x00, 0x01, 0x02, 0xff])), [])
    }

    func testEncodeProducesABinaryPlist() {
        let data = FinderTagCodec.encode([FinderTag(name: "X", color: .green)])
        XCTAssertEqual(data.prefix(8), Data("bplist00".utf8))
    }
}
