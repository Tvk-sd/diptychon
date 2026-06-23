import Foundation

/// Watches a single directory for content changes (entries added / removed /
/// renamed) and fires `onChange` on the main queue, debounced. Non-recursive —
/// a Panel only lists one level. Built on a `DispatchSource` vnode watch of the
/// directory's file descriptor: lighter than the `FSEventStream` C API and
/// sufficient for one directory. Re-create it to watch a different directory;
/// it stops itself on deinit.
final class DirectoryWatcher {
    private let onChange: () -> Void
    private let debounceInterval: TimeInterval
    private let queue = DispatchQueue(label: "diptychon.dirwatcher")
    private var source: DispatchSourceFileSystemObject?
    private var fd: CInt = -1
    private var debounce: DispatchWorkItem?

    init(url: URL, debounceInterval: TimeInterval = 0.15, onChange: @escaping () -> Void) {
        self.onChange = onChange
        self.debounceInterval = debounceInterval
        start(url: url)
    }

    deinit { stop() }

    private func start(url: URL) {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        fd = descriptor
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete],
            queue: queue)
        src.setEventHandler { [weak self] in self?.scheduleFire() }
        src.setCancelHandler { [weak self] in
            if let fd = self?.fd, fd >= 0 { close(fd) }
            self?.fd = -1
        }
        source = src
        src.resume()
    }

    /// Coalesce bursts of events (e.g. a multi-file copy) into one callback.
    private func scheduleFire() {
        debounce?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        debounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }

    func stop() {
        debounce?.cancel()
        source?.cancel()
        source = nil
    }
}
