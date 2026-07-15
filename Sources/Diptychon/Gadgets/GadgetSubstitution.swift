import Foundation

/// The pane state a gadget template resolves against — a plain value so the
/// expansion below stays a pure, unit-testable function.
struct GadgetContext: Equatable {
    /// Absolute paths of the Active Panel's selection, in visible order.
    var activeSelectionPaths: [String] = []
    /// File names (last path components) of the selection, same order.
    var activeSelectionNames: [String] = []
    var activeFolderPath: String
    var inactiveFolderPath: String
    var userHome: String = NSHomeDirectory()
}

/// The six v1 variables (issue 36), matching Marta's names so their docs carry over.
enum GadgetVariable: String, CaseIterable {
    case activeSelectionPaths = "active.selection.paths"
    case activeSelectionNames = "active.selection.names"
    /// The first selected file — Diptychon has no separate cursor to expose here.
    case currentFilePath = "current.file.path"
    case activeFolderPath = "active.folder.path"
    case inactiveFolderPath = "inactive.folder.path"
    case userHome = "user.home"

    /// Multi-value variables fan one template argument out into one argv entry
    /// per selected file.
    var isMultiValue: Bool {
        self == .activeSelectionPaths || self == .activeSelectionNames
    }

    /// Whether resolving this variable needs a non-empty selection.
    var usesSelection: Bool { isMultiValue || self == .currentFilePath }
}

enum GadgetSubstitutionError: Error, Equatable {
    case unknownVariable(String, argument: String)
    case multipleMultiValueVariables(argument: String)
    case multiValueNotAllowed(variable: String, location: String)
    case selectionRequired(variable: String)

    var message: String {
        switch self {
        case .unknownVariable(let name, let arg):
            return "Unknown variable ${\(name)} in \"\(arg)\""
        case .multipleMultiValueVariables(let arg):
            return "\"\(arg)\" uses more than one multi-value variable — only one of ${active.selection.paths} / ${active.selection.names} per argument"
        case .multiValueNotAllowed(let name, let location):
            return "${\(name)} expands to multiple values and can't be used in \(location)"
        case .selectionRequired(let name):
            return "${\(name)} needs a selected file"
        }
    }
}

/// Pure expansion of gadget templates. Multi-value variables become **separate
/// argv entries** (`--f=${active.selection.paths}` → `--f=/a`, `--f=/b`), never
/// one space-joined string — that's what makes filenames with spaces safe
/// without any quoting.
enum GadgetSubstitution {
    /// Expand an argv template: each entry yields one or more argv entries.
    static func expandArgs(_ templates: [String], context: GadgetContext) throws -> [String] {
        try templates.flatMap { try expandArgument($0, context: context) }
    }

    /// Expand one template argument into its argv entries.
    static func expandArgument(_ template: String, context: GadgetContext) throws -> [String] {
        let vars = try variables(in: template)
        let multis = vars.filter(\.isMultiValue)
        guard multis.count <= 1 else {
            throw GadgetSubstitutionError.multipleMultiValueVariables(argument: template)
        }
        if vars.contains(.currentFilePath), context.activeSelectionPaths.isEmpty {
            throw GadgetSubstitutionError.selectionRequired(variable: GadgetVariable.currentFilePath.rawValue)
        }
        let base = replaceSingleValueTokens(in: template, context: context)
        guard let multi = multis.first else { return [base] }
        let values = multi == .activeSelectionPaths ? context.activeSelectionPaths : context.activeSelectionNames
        return values.map { base.replacingOccurrences(of: token(multi), with: $0) }
    }

    /// Expand a template that must stay a single string (target, workingDirectory).
    static func expandSingle(_ template: String, location: String, context: GadgetContext) throws -> String {
        let vars = try variables(in: template)
        if let multi = vars.first(where: \.isMultiValue) {
            throw GadgetSubstitutionError.multiValueNotAllowed(variable: multi.rawValue, location: location)
        }
        if vars.contains(.currentFilePath), context.activeSelectionPaths.isEmpty {
            throw GadgetSubstitutionError.selectionRequired(variable: GadgetVariable.currentFilePath.rawValue)
        }
        return replaceSingleValueTokens(in: template, context: context)
    }

    /// Whether any of the gadget's templates references a selection-dependent
    /// variable — drives palette enablement (greyed without a selection).
    static func referencesSelection(_ gadget: Gadget) -> Bool {
        let templates = [gadget.target] + (gadget.args ?? []) + [gadget.workingDirectory].compactMap { $0 }
        return templates.contains { template in
            ((try? variables(in: template)) ?? []).contains(where: \.usesSelection)
        }
    }

    /// All `${…}` tokens in `template`, resolved to variables. Unknown names are
    /// an error — failing loud beats silently handing `${typo}` to a tool.
    static func variables(in template: String) throws -> Set<GadgetVariable> {
        var found = Set<GadgetVariable>()
        for name in tokenNames(in: template) {
            guard let variable = GadgetVariable(rawValue: name) else {
                throw GadgetSubstitutionError.unknownVariable(name, argument: template)
            }
            found.insert(variable)
        }
        return found
    }

    // MARK: - Internals

    private static func token(_ variable: GadgetVariable) -> String { "${\(variable.rawValue)}" }

    private static func replaceSingleValueTokens(in template: String, context: GadgetContext) -> String {
        var out = template
        let singles: [(GadgetVariable, String)] = [
            (.currentFilePath, context.activeSelectionPaths.first ?? ""),
            (.activeFolderPath, context.activeFolderPath),
            (.inactiveFolderPath, context.inactiveFolderPath),
            (.userHome, context.userHome),
        ]
        for (variable, value) in singles {
            out = out.replacingOccurrences(of: token(variable), with: value)
        }
        return out
    }

    /// The raw names inside `${…}` — a hand-rolled scan (no regex literal in
    /// Swift-5 language mode).
    private static func tokenNames(in template: String) -> [String] {
        var names: [String] = []
        var rest = template[...]
        while let start = rest.range(of: "${") {
            guard let end = rest[start.upperBound...].range(of: "}") else { break }
            names.append(String(rest[start.upperBound..<end.lowerBound]))
            rest = rest[end.upperBound...]
        }
        return names
    }
}
