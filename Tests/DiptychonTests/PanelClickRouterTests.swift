import CoreGraphics
import XCTest
@testable import Diptychon

/// Issue 89: the pure geometry behind "which Panel did that click activate?".
///
/// Same shape as `SplitPaneTests` / `VSplitPaneTests` — the decision used to be an
/// `if`-chain inside an `NSEvent` monitor closure, reachable only by driving a real
/// window. As a function it can be pinned down band by band.
///
/// A 1000x800 window with a 24pt title bar, so the usable content runs y ∈ (0, 776].
final class PanelClickRouterTests: XCTestCase {

    private let contentTop: CGFloat = 776
    private let contentBottom: CGFloat = 0
    private let minX: CGFloat = 0
    private let maxX: CGFloat = 1000

    private func target(x: CGFloat, y: CGFloat,
                        sidebarVisible: Bool = true,
                        rightPane: WorkspaceModel.RightPane = .none,
                        rightPanelVisible: Bool = true) -> PanelClickTarget {
        PanelClickRouter.target(x: x, y: y,
                                contentTop: contentTop, contentBottom: contentBottom,
                                minX: minX, maxX: maxX,
                                sidebarVisible: sidebarVisible,
                                rightPane: rightPane,
                                rightPanelVisible: rightPanelVisible)
    }

    /// Mid-height of the Panel area — clear of both bands.
    private let panelY: CGFloat = 400
    /// Inside the bottom bar: the toggles sit in the bottom 33pt.
    private let bottomBarY: CGFloat = 16
    /// Inside the header band.
    private var headerY: CGFloat { contentTop - 16 }

    // MARK: - The bug (issue 89)

    /// The regression this ticket exists for: the Terminal/Preview/Staging/Activity
    /// toggles sit at the far right of the bottom bar. With both Panels open, that
    /// click used to read as "right half of the window" and flip the Active Panel —
    /// and the terminal's cwd is set once, at open, so the wrong Panel stuck.
    func testClickOnTheBottomBarTogglesActivatesNoPanel() {
        XCTAssertEqual(target(x: 940, y: bottomBarY), .none)
    }

    /// Same click with an aux pane open — the Panel area's right edge moves inward, so
    /// the click may land outside it. The band must answer `.none` either way.
    func testClickOnTheBottomBarTogglesActivatesNoPanelWithAuxPaneOpen() {
        XCTAssertEqual(target(x: 940, y: bottomBarY, rightPane: .preview), .none)
    }

    /// The Staging pane's x-range overlaps the bottom bar's right end. Without the
    /// band, a toggle click would silently hand operation focus to Staging.
    func testClickOnTheBottomBarDoesNotHandFocusToStaging() {
        XCTAssertEqual(target(x: 940, y: bottomBarY, rightPane: .staging), .none)
    }

    func testClickOnTheSidebarToggleAtTheBottomLeftActivatesNoPanel() {
        XCTAssertEqual(target(x: 180, y: bottomBarY), .none)
    }

    /// Empty bottom-bar space is chrome too.
    func testClickOnEmptyBottomBarSpaceActivatesNoPanel() {
        XCTAssertEqual(target(x: 500, y: bottomBarY), .none)
    }

    /// The band's exact edge — the assertion that breaks if the bar's height changes
    /// without `bottomBand` being re-measured. Top of the band is still the bar; one
    /// point above it is Panel space again.
    func testTheBottomBandEndsExactlyAtTheBarsTopEdge() {
        XCTAssertEqual(target(x: 300, y: contentBottom + PanelClickRouter.bottomBand),
                       .none)
        XCTAssertEqual(target(x: 300, y: contentBottom + PanelClickRouter.bottomBand + 1),
                       .leftPanel)
    }

    /// Mirror of the above for the header band, so both edges are pinned by the same
    /// kind of test.
    func testTheHeaderBandEndsExactlyAtItsLowerEdge() {
        XCTAssertEqual(target(x: 300, y: contentTop - PanelClickRouter.headerBand), .none)
        XCTAssertEqual(target(x: 300, y: contentTop - PanelClickRouter.headerBand - 1),
                       .leftPanel)
    }

    // MARK: - Panels

    func testClickInTheLeftPanelActivatesTheLeftPanel() {
        XCTAssertEqual(target(x: 300, y: panelY), .leftPanel)
    }

    func testClickInTheRightPanelActivatesTheRightPanel() {
        XCTAssertEqual(target(x: 800, y: panelY), .rightPanel)
    }

    /// With the right Panel hidden the left one spans the whole area, so even a click
    /// far right belongs to it.
    func testClickOnTheRightWithTheRightPanelHiddenActivatesTheLeftPanel() {
        XCTAssertEqual(target(x: 800, y: panelY, rightPanelVisible: false), .leftPanel)
    }

    /// The dividing line itself belongs to the right Panel — an arbitrary but fixed
    /// choice, pinned so it can't drift.
    func testTheMidlineBelongsToTheRightPanel() {
        let mid = (PanelClickRouter.sidebarEdge + maxX) / 2
        XCTAssertEqual(target(x: mid, y: panelY), .rightPanel)
        XCTAssertEqual(target(x: mid - 1, y: panelY), .leftPanel)
    }

    /// Folding the sidebar moves the Panel area's left edge — and with it the midline.
    func testFoldingTheSidebarMovesTheMidline() {
        // Sidebar shown: the Panels run 201…1000, midline 600.5.
        // Sidebar folded: they run 0…1000, midline 500.
        // x = 520 therefore changes sides with the sidebar.
        XCTAssertEqual(target(x: 520, y: panelY, sidebarVisible: true), .leftPanel)
        XCTAssertEqual(target(x: 520, y: panelY, sidebarVisible: false), .rightPanel)
    }

    // MARK: - Chrome

    func testClickInTheHeaderActivatesNoPanel() {
        XCTAssertEqual(target(x: 800, y: headerY), .none)
    }

    /// The Filter field caps the header's right edge. Clicking it must not steal the
    /// Active Panel — the original reason the header band exists.
    func testClickOnTheFilterFieldActivatesNoPanel() {
        XCTAssertEqual(target(x: 960, y: headerY), .none)
    }

    func testClickInTheSidebarActivatesNoPanel() {
        XCTAssertEqual(target(x: 100, y: panelY), .none)
    }

    func testClickInThePreviewPaneActivatesNoPanel() {
        XCTAssertEqual(target(x: 900, y: panelY, rightPane: .preview), .none)
    }

    // MARK: - Staging

    func testClickInTheStagingPaneMakesItTheOperationSource() {
        XCTAssertEqual(target(x: 900, y: panelY, rightPane: .staging), .staging)
    }

    /// Staging is the only aux pane that claims clicks; the preview does not.
    func testTheStagingClaimStopsAtThePanelEdge() {
        let edge = maxX - PanelClickRouter.auxPaneWidth
        XCTAssertEqual(target(x: edge, y: panelY, rightPane: .staging), .rightPanel)
        XCTAssertEqual(target(x: edge + 1, y: panelY, rightPane: .staging), .staging)
    }
}
