import SwiftUI
import XCTest
@testable import Diptychon

/// Issue 45: the pure layout math behind the persisted split. This is the
/// trust-critical part — a restored fraction must never open a zero-width / broken
/// pane (issue 41 governing principle), which `leftWidth`/`clampLeft` guarantee
/// independently of SwiftUI.
final class SplitPaneTests: XCTestCase {

    private typealias Split = SplitPane<EmptyView, EmptyView>
    private let min: CGFloat = 180
    private let divider: CGFloat = 1

    func testHalfSplit() {
        let w = Split.leftWidth(fraction: 0.5, total: 1000, minPane: min, divider: divider)
        XCTAssertEqual(w, 500, accuracy: 0.001)
    }

    func testExtremeFractionClampsToLeaveRightPaneMinimum() {
        // 0.99 would starve the right pane; clamp to available − min.
        let w = Split.leftWidth(fraction: 0.99, total: 1000, minPane: min, divider: divider)
        XCTAssertEqual(w, 1000 - divider - min, accuracy: 0.001) // 819
    }

    func testZeroFractionClampsToLeftMinimum() {
        let w = Split.leftWidth(fraction: 0.0, total: 1000, minPane: min, divider: divider)
        XCTAssertEqual(w, min, accuracy: 0.001)
    }

    func testWindowTooNarrowForTwoMinimumsSplitsEvenly() {
        // 300 can't fit two 180 panes — fall back to an even split, never starve one.
        let w = Split.leftWidth(fraction: 0.8, total: 300, minPane: min, divider: divider)
        XCTAssertEqual(w, (300 - divider) / 2, accuracy: 0.001)
    }

    func testRestoredRatioAlwaysLeavesBothPanesAtLeastMinimum() {
        // Whatever fraction was stored, both panes end up ≥ min at a workable width.
        let total: CGFloat = 800
        for pct in stride(from: 0.0, through: 1.0, by: 0.05) {
            let leftW = Split.leftWidth(fraction: pct, total: total, minPane: min, divider: divider)
            let rightW = total - leftW - divider
            XCTAssertGreaterThanOrEqual(leftW, min, "left starved at fraction \(pct)")
            XCTAssertGreaterThanOrEqual(rightW, min, "right starved at fraction \(pct)")
        }
    }
}
