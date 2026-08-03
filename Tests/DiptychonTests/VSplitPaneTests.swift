import SwiftUI
import XCTest
@testable import Diptychon

/// Issue 65: the pure layout math behind the persisted terminal split. Same
/// trust-critical property as `SplitPaneTests` — a restored fraction must never open
/// a zero-height pane — but with *asymmetric* minimums, since the file list needs
/// more room than the terminal does.
final class VSplitPaneTests: XCTestCase {

    private typealias Split = VSplitPane<EmptyView, EmptyView>
    private let minTop: CGFloat = 120
    private let minBottom: CGFloat = 80
    private let divider: CGFloat = 1

    func testDefaultFractionGivesPanelsMostOfTheHeight() {
        let h = Split.topHeight(fraction: 0.7, total: 1000,
                                minTop: minTop, minBottom: minBottom, divider: divider)
        XCTAssertEqual(h, 700, accuracy: 0.001)
    }

    func testExtremeFractionLeavesTheTerminalItsMinimum() {
        // 0.99 would starve the terminal — clamp to available − minBottom.
        let h = Split.topHeight(fraction: 0.99, total: 1000,
                                minTop: minTop, minBottom: minBottom, divider: divider)
        XCTAssertEqual(h, 999 - minBottom, accuracy: 0.001)
    }

    func testZeroFractionLeavesTheFileListItsMinimum() {
        let h = Split.topHeight(fraction: 0.0, total: 1000,
                                minTop: minTop, minBottom: minBottom, divider: divider)
        XCTAssertEqual(h, minTop, accuracy: 0.001)
    }

    /// The governing principle from issue 41: a ratio saved on a tall window must not
    /// restore a broken layout on a short one. 0.95 of 260pt would leave the terminal
    /// 12pt; the clamp gives it its minimum instead.
    func testRatioSavedOnATallWindowIsClampedOnAShortOne() {
        let h = Split.topHeight(fraction: 0.95, total: 260,
                                minTop: minTop, minBottom: minBottom, divider: divider)
        XCTAssertEqual(h, 259 - minBottom, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(h, minTop)
    }

    /// Too short for both minimums: split proportionally rather than starving one.
    /// The terminal keeps a usable sliver instead of collapsing to nothing.
    func testTooShortForBothMinimumsSplitsProportionally() {
        let total: CGFloat = 100
        let h = Split.topHeight(fraction: 0.7, total: total,
                                minTop: minTop, minBottom: minBottom, divider: divider)
        let available = total - divider
        XCTAssertEqual(h, available * (minTop / (minTop + minBottom)), accuracy: 0.001)
        XCTAssertGreaterThan(h, 0)
        XCTAssertLessThan(h, available)
    }

    func testOutOfRangeFractionsStayInsideTheContainer() {
        for fraction in [-1.0, 0.0, 0.5, 1.0, 2.0] {
            let h = Split.topHeight(fraction: fraction, total: 800,
                                    minTop: minTop, minBottom: minBottom, divider: divider)
            XCTAssertGreaterThanOrEqual(h, 0)
            XCTAssertLessThanOrEqual(h, 800)
        }
    }
}
