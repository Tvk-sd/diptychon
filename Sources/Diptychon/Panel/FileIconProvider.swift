import AppKit
import UniformTypeIdentifiers

/// Supplies real, Finder-grade file-type icons for list rows — keyed off the
/// file *extension*, never the on-disk path. Resolving by `UTType(filenameExtension:)`
/// means a row's icon costs no `stat`/disk hit, so it preserves the no-per-file-syscall
/// guarantee that keeps 50k-file folders smooth (PRD §2). The trade-off vs.
/// `NSWorkspace.icon(forFile:)`: all `.pdf` share one icon (no custom per-file or
/// app-bundle icons). That's the right default; per-file icons / Quick Look
/// thumbnails are a separate, opt-in tier.
///
/// Icons are cached by key (the lowercased extension, or sentinels for folders /
/// extensionless files) so repeated lookups across a big listing are dictionary
/// hits. `@MainActor` because `NSWorkspace`/`NSImage` aren't thread-safe and the
/// cells that call this are main-thread anyway.
@MainActor
enum FileIconProvider {
    private static var cache: [String: NSImage] = [:]

    /// The icon for a row. Folders get the system folder icon; files get their
    /// type's icon resolved from the extension. Always returns *something* (falls
    /// back to a generic document icon).
    static func icon(for item: FileItem) -> NSImage {
        let key = item.isDirectory ? "/dir" : (item.url.pathExtension.lowercased().isEmpty
                                               ? "/file" : item.url.pathExtension.lowercased())
        if let cached = cache[key] { return cached }

        let type: UTType
        if item.isDirectory {
            type = .folder
        } else if !item.url.pathExtension.isEmpty,
                  let fromExt = UTType(filenameExtension: item.url.pathExtension) {
            type = fromExt
        } else {
            type = .data // generic document
        }
        let image = NSWorkspace.shared.icon(for: type)
        cache[key] = image
        return image
    }
}
