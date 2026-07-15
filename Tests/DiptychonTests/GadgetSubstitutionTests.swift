import XCTest
@testable import Diptychon

/// Issue 36: the pure template-expansion engine. The load-bearing property is
/// argv safety — multi-value variables become separate argv entries, so
/// filenames with spaces survive without quoting.
final class GadgetSubstitutionTests: XCTestCase {

    private let context = GadgetContext(
        activeSelectionPaths: ["/tmp/a one.txt", "/tmp/b.txt"],
        activeSelectionNames: ["a one.txt", "b.txt"],
        activeFolderPath: "/tmp",
        inactiveFolderPath: "/Users/x/Downloads",
        userHome: "/Users/x"
    )

    // MARK: All six variables

    func testAllSingleValueVariablesResolve() throws {
        XCTAssertEqual(try GadgetSubstitution.expandArgs(
            ["${current.file.path}", "${active.folder.path}", "${inactive.folder.path}", "${user.home}"],
            context: context),
            ["/tmp/a one.txt", "/tmp", "/Users/x/Downloads", "/Users/x"])
    }

    func testMultiValuePathsExpandToOneArgvEntryPerFile() throws {
        XCTAssertEqual(try GadgetSubstitution.expandArgs(["${active.selection.paths}"], context: context),
                       ["/tmp/a one.txt", "/tmp/b.txt"])
        XCTAssertEqual(try GadgetSubstitution.expandArgs(["${active.selection.names}"], context: context),
                       ["a one.txt", "b.txt"])
    }

    func testFilenameWithSpaceStaysOneIntactArgument() throws {
        let argv = try GadgetSubstitution.expandArgs(["-i", "${active.selection.paths}"], context: context)
        XCTAssertEqual(argv, ["-i", "/tmp/a one.txt", "/tmp/b.txt"])
        XCTAssertTrue(argv.contains("/tmp/a one.txt")) // never split at the space
    }

    /// An embedded multi-value variable fans the whole argument out per file.
    func testEmbeddedMultiValueTemplateFansOut() throws {
        XCTAssertEqual(try GadgetSubstitution.expandArgs(["--file=${active.selection.paths}"], context: context),
                       ["--file=/tmp/a one.txt", "--file=/tmp/b.txt"])
    }

    func testMixedSingleAndMultiInOneArgument() throws {
        XCTAssertEqual(try GadgetSubstitution.expandArgs(["${user.home}/${active.selection.names}"], context: context),
                       ["/Users/x/a one.txt", "/Users/x/b.txt"])
    }

    // MARK: Errors

    func testTwoMultiValueVariablesInOneArgumentIsAnError() {
        XCTAssertThrowsError(try GadgetSubstitution.expandArgs(
            ["${active.selection.paths}:${active.selection.names}"], context: context)) {
            XCTAssertEqual($0 as? GadgetSubstitutionError,
                           .multipleMultiValueVariables(argument: "${active.selection.paths}:${active.selection.names}"))
        }
    }

    func testUnknownVariableIsAnErrorNotPassedThrough() {
        XCTAssertThrowsError(try GadgetSubstitution.expandArgs(["${selectoin.paths}"], context: context)) {
            XCTAssertEqual($0 as? GadgetSubstitutionError,
                           .unknownVariable("selectoin.paths", argument: "${selectoin.paths}"))
        }
    }

    func testCurrentFilePathWithEmptySelectionIsAnError() {
        var empty = context
        empty.activeSelectionPaths = []
        empty.activeSelectionNames = []
        XCTAssertThrowsError(try GadgetSubstitution.expandArgs(["${current.file.path}"], context: empty)) {
            XCTAssertEqual($0 as? GadgetSubstitutionError, .selectionRequired(variable: "current.file.path"))
        }
    }

    func testExpandSingleRejectsMultiValueVariables() {
        XCTAssertThrowsError(try GadgetSubstitution.expandSingle(
            "${active.selection.paths}", location: "target", context: context)) {
            XCTAssertEqual($0 as? GadgetSubstitutionError,
                           .multiValueNotAllowed(variable: "active.selection.paths", location: "target"))
        }
        XCTAssertEqual(try? GadgetSubstitution.expandSingle("${user.home}/bin/x", location: "target", context: context),
                       "/Users/x/bin/x")
    }

    // MARK: Enablement metadata

    func testReferencesSelectionDrivesEnablement() {
        let usesSelection = Gadget(id: "a", name: "A", type: .executable, target: "/bin/echo",
                                   args: ["${active.selection.paths}"], workingDirectory: nil)
        let folderOnly = Gadget(id: "b", name: "B", type: .executable, target: "/bin/echo",
                                args: ["${active.folder.path}"], workingDirectory: nil)
        XCTAssertTrue(GadgetSubstitution.referencesSelection(usesSelection))
        XCTAssertFalse(GadgetSubstitution.referencesSelection(folderOnly))
    }
}
