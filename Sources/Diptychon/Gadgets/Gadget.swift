import Foundation

/// A user-defined external-tool action (issue 36). Declarative on purpose — no
/// scripting surface, that's the product line. Two kinds, mirroring Marta:
/// an *application* gadget opens the current selection with a fixed `.app`
/// (a saved, named "Open With"); an *executable* gadget runs a binary with a
/// templated argv (see `GadgetSubstitution`).
struct Gadget: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case application, executable
    }

    let id: String
    let name: String
    let type: Kind
    /// `.app` path (application) or binary path (executable). May reference
    /// single-value variables (e.g. `${user.home}`), expanded at run time.
    let target: String
    /// argv template — executable gadgets only. Each entry may reference
    /// substitution variables; an entry with a multi-value variable fans out
    /// into one argv entry per selected file, never a space-joined string.
    var args: [String]?
    /// Working directory for executable gadgets; single-value variables allowed.
    var workingDirectory: String?
}

/// Reads `gadgets.json`. Tolerant per entry: one malformed gadget is skipped
/// (and reported) without dropping the valid ones; a missing file just means
/// "no gadgets" — the feature is opt-in.
enum GadgetConfig {
    struct LoadResult: Equatable {
        var gadgets: [Gadget] = []
        var errors: [String] = []
    }

    static func load(from url: URL) -> LoadResult {
        guard FileManager.default.fileExists(atPath: url.path) else { return LoadResult() }
        do {
            return decode(try Data(contentsOf: url))
        } catch {
            return LoadResult(errors: ["Could not read \(url.lastPathComponent): \(error.localizedDescription)"])
        }
    }

    static func decode(_ data: Data) -> LoadResult {
        // Each entry decodes independently so a typo in gadget 3 can't take
        // down gadgets 1–2 — the failure surfaces as a message instead.
        struct Raw: Decodable { let gadgets: [LossyGadget] }
        let raw: Raw
        do {
            raw = try JSONDecoder().decode(Raw.self, from: data)
        } catch {
            return LoadResult(errors: ["gadgets.json is not valid JSON with a \"gadgets\" array: \(describe(error))"])
        }

        var result = LoadResult()
        var seenIDs = Set<String>()
        for (index, entry) in raw.gadgets.enumerated() {
            guard let gadget = entry.gadget else {
                result.errors.append("Gadget #\(index + 1): \(entry.error ?? "could not decode")")
                continue
            }
            if let problem = validate(gadget) {
                result.errors.append("Gadget #\(index + 1) (\(gadget.id)): \(problem)")
            } else if !seenIDs.insert(gadget.id).inserted {
                result.errors.append("Gadget #\(index + 1): duplicate id \"\(gadget.id)\" — skipped")
            } else {
                result.gadgets.append(gadget)
            }
        }
        return result
    }

    private static func validate(_ gadget: Gadget) -> String? {
        if gadget.id.trimmingCharacters(in: .whitespaces).isEmpty { return "\"id\" must not be empty" }
        if gadget.name.trimmingCharacters(in: .whitespaces).isEmpty { return "\"name\" must not be empty" }
        if gadget.target.trimmingCharacters(in: .whitespaces).isEmpty { return "\"target\" must not be empty" }
        return nil
    }

    private struct LossyGadget: Decodable {
        let gadget: Gadget?
        let error: String?
        init(from decoder: Decoder) {
            do { gadget = try Gadget(from: decoder); error = nil }
            catch let decodeError { gadget = nil; error = describe(decodeError) }
        }
    }

    /// `DecodingError` rendered for a human editing JSON by hand.
    private static func describe(_ error: Error) -> String {
        guard let decoding = error as? DecodingError else { return error.localizedDescription }
        switch decoding {
        case .keyNotFound(let key, _): return "missing required field \"\(key.stringValue)\""
        case .typeMismatch(_, let ctx), .dataCorrupted(let ctx): return ctx.debugDescription
        case .valueNotFound(_, let ctx): return ctx.debugDescription
        @unknown default: return "\(decoding)"
        }
    }
}
