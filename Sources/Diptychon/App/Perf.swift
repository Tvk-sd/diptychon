import Foundation
import OSLog

/// Lightweight runtime-speed instrumentation (issue 22).
///
/// Emits baseline figures to the unified log — read in Console.app or via
/// `log stream`, no Instruments required:
///   • `cold-launch` — earliest app-controlled instant → first panel interactive.
///   • `list-load`   — directory enumeration + row build, with item count.
///
/// Capture a baseline (Release build, arm64):
///   1. Build & launch the Release app, navigate into the target folder.
///   2. `log show --last 2m --predicate 'subsystem == "com.diptychon.app"' --info`
/// See `context/performance.md` for recorded numbers + the 50k fixture recipe.
enum Perf {
    static let log = Logger(subsystem: "com.diptychon.app", category: "perf")

    /// Wall-clock at the earliest app-controlled instant (set in `DiptychonApp.init`).
    /// Consumed once — by the first panel to finish loading — so `cold-launch` is
    /// reported a single time per launch.
    @MainActor static var launchStart: DispatchTime?

    /// Report the cold-launch figure once, when the first panel becomes interactive.
    @MainActor static func markFirstPanelInteractive() {
        guard let start = launchStart else { return }
        launchStart = nil
        log.notice("cold-launch: first panel interactive in \(ms(since: start), format: .fixed(precision: 1)) ms")
    }

    /// Report a directory listing's load time (off-main enumeration + row build).
    static func markListLoad(items: Int, since start: DispatchTime) {
        log.notice("list-load: \(items) items in \(ms(since: start), format: .fixed(precision: 1)) ms")
    }

    private static func ms(since start: DispatchTime) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
    }
}
