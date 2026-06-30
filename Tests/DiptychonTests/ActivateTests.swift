import XCTest
@testable import Diptychon

/// Issue 25: double-click activates only the **clicked** row, never the selection.
/// The click→clickedRow routing lives in AppKit (verified manually); this covers the
/// model-level `activate(_:in:)` it calls — folder navigates the panel, and the acted
/// item is the one passed, independent of what is selected.
@MainActor
final class ActivateTests: XCTestCase {

    func testActivateFolderNavigatesThatPanelToTheClickedFolder() {
        let model = WorkspaceModel()
        let start = model.left.directory
        let folder = start.appendingPathComponent("sub")
        let item = FileItem(url: folder, name: "sub", size: nil,
                            modificationDate: nil, isDirectory: true)

        model.activate(item, in: model.left)

        XCTAssertEqual(model.left.directory, folder, "activating a folder navigates that panel into it")
    }

    func testActivateActsOnTheGivenItemNotTheSelection() {
        let model = WorkspaceModel()
        let start = model.left.directory
        // A different item is "selected"; activate is given another folder entirely.
        model.left.selection = [start.appendingPathComponent("other")]
        let clicked = start.appendingPathComponent("clicked")
        let item = FileItem(url: clicked, name: "clicked", size: nil,
                            modificationDate: nil, isDirectory: true)

        model.activate(item, in: model.left)

        XCTAssertEqual(model.left.directory, clicked,
                       "activate follows the passed (clicked) item, not the selection")
    }
}
