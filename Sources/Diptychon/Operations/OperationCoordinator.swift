import SwiftUI
import Observation

/// Drives `Operation`s and owns the multi-level undo/redo stacks (ADR 0004).
/// Runs work in a cancellable task and publishes progress for the UI.
@MainActor
@Observable
final class OperationCoordinator {
    struct Running {
        var title: String
        var fraction: Double
    }

    private(set) var undoStack: [Operation] = []
    private(set) var redoStack: [Operation] = []
    private(set) var running: Running?

    private var task: Task<Void, Never>?

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Apply `op`; on success push it onto the undo stack and clear redo.
    /// `onFinish` runs on the main actor after the work settles (success,
    /// cancel, or error) so callers can refresh affected Panels.
    func run(_ op: Operation, onFinish: @escaping () -> Void) {
        guard running == nil else { return }
        running = Running(title: op.title, fraction: 0)
        task = Task {
            do {
                try await op.apply { fraction in
                    Task { @MainActor in self.running?.fraction = fraction }
                }
                undoStack.append(op)
                redoStack.removeAll()
            } catch is CancellationError {
                try? await op.revert() // undo any partial work.
            } catch {
                // MVP: surface nothing beyond clearing state; later issues add error UI.
            }
            running = nil
            onFinish()
        }
    }

    func cancel() { task?.cancel() }

    func undo(onFinish: @escaping () -> Void) {
        guard running == nil, let op = undoStack.last else { return }
        undoStack.removeLast()
        guard op.isUndoable else { redoStack.append(op); onFinish(); return }
        running = Running(title: "Undo \(op.title)", fraction: 0)
        task = Task {
            try? await op.revert()
            redoStack.append(op)
            running = nil
            onFinish()
        }
    }

    func redo(onFinish: @escaping () -> Void) {
        guard running == nil, let op = redoStack.last else { return }
        redoStack.removeLast()
        running = Running(title: "Redo \(op.title)", fraction: 0)
        task = Task {
            do {
                try await op.apply { fraction in
                    Task { @MainActor in self.running?.fraction = fraction }
                }
                undoStack.append(op)
            } catch {
                // re-push so the redo isn't silently lost.
                redoStack.append(op)
            }
            running = nil
            onFinish()
        }
    }
}
