import XCTest
@testable import Diptychon

/// Issue 54: reading the global `NSFileViewer` default correctly.
///
/// Only the interpretation is tested, never the write — writing would change the
/// machine's real reveal handler, which is exactly the setting Till uses daily. The
/// pure function takes the raw value, so the test never touches the system.
///
/// Same shape as `PathInputTests`: raw input, expected meaning.
final class RevealHandlerTests: XCTestCase {

    private let us = "com.diptychon.app"

    /// No key set is the macOS default: Finder reveals.
    func testMissingKeyMeansFinder() {
        XCTAssertEqual(RevealHandler.state(forRawValue: nil, ourBundleID: us), .systemDefault)
    }

    /// An empty string is a leftover, not a handler. Treating it as "some other app"
    /// would put a blank name in the UI.
    func testEmptyValueMeansFinder() {
        XCTAssertEqual(RevealHandler.state(forRawValue: "", ourBundleID: us), .systemDefault)
        XCTAssertEqual(RevealHandler.state(forRawValue: "   ", ourBundleID: us), .systemDefault)
    }

    func testOurBundleIDMeansUs() {
        XCTAssertEqual(RevealHandler.state(forRawValue: us, ourBundleID: us), .diptychon)
    }

    /// Launch Services treats bundle ids case-insensitively, so a hand-typed variant
    /// still has to read as us — otherwise the switch shows "off" while reveals do
    /// land in Diptychon.
    func testOurBundleIDMatchesRegardlessOfCase() {
        XCTAssertEqual(RevealHandler.state(forRawValue: "Com.Diptychon.App", ourBundleID: us),
                       .diptychon)
    }

    /// The third state the UI must not swallow: someone else holds the setting.
    func testAnotherFileManagerIsNamed() {
        XCTAssertEqual(RevealHandler.state(forRawValue: "com.binarynights.ForkLift-3", ourBundleID: us),
                       .otherApp("com.binarynights.ForkLift-3"))
    }

    /// Finder written in explicitly is still "another app", not the absence of a
    /// setting — which is why `disable()` deletes the key instead of writing this.
    func testExplicitFinderIsNotTheSameAsNoSetting() {
        XCTAssertEqual(RevealHandler.state(forRawValue: "com.apple.finder", ourBundleID: us),
                       .otherApp("com.apple.finder"))
    }

    /// The fallback matters: under XCTest the bundle identifier belongs to the test
    /// runner, so `appBundleID` must still name the app rather than return nil.
    func testAppBundleIDIsNeverEmpty() {
        XCTAssertFalse(RevealHandler.appBundleID.isEmpty)
    }
}
