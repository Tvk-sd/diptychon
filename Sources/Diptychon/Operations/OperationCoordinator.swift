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

    /// Fired on the main actor after any Operation settles (run success, cancel,
    /// or error; undo; redo) so the owner can re-list affected Panels in one place.
    /// Set once by the owner; the early-return guards (busy, empty stack) do *not*
    /// fire it, since nothing changed.
    var onOperationSettled: () -> Void = {}

    /// Fired after an undo/redo settles, with a human message + SF Symbol, so the UI
    /// can flash a transient toast ("Undone — Moved 12 items") — making the otherwise
    /// invisible undo legible (issue 18, Tier 1). Forward operations don't toast: the
    /// user just did them on purpose; it's the *reversal* that needs surfacing.
    var onUndoRedoToast: (_ text: String, _ systemImage: String) -> Void = { _, _ in }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Apply `op`; on success push it onto the undo stack and clear redo.
    func run(_ op: Operation) {
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
            onOperationSettled()
        }
    }

    func cancel() { task?.cancel() }

    func undo() {
        guard running == nil, let op = undoStack.last else { return }
        undoStack.removeLast()
        guard op.isUndoable else {
            // Overwrites destroyed the original — honest toast, no false "undone".
            redoStack.append(op)
            onUndoRedoToast("Can’t undo \(op.title) — files were overwritten", "exclamationmark.triangle")
            onOperationSettled()
            return
        }
        running = Running(title: "Undo \(op.title)", fraction: 0)
        task = Task {
            do {
                try await op.revert()
                redoStack.append(op)
                onUndoRedoToast("Undone — \(op.title)", "arrow.uturn.backward")
            } catch {
                // Revert failed (e.g. an old name is occupied again): the op is
                // still applied, so keep it undoable and say so — never a false
                // "Undone" for files that didn't move back.
                undoStack.append(op)
                onUndoRedoToast("Couldn’t undo \(op.title)", "exclamationmark.triangle")
            }
            running = nil
            onOperationSettled()
        }
    }

    func redo() {
        guard running == nil, let op = redoStack.last else { return }
        redoStack.removeLast()
        running = Running(title: "Redo \(op.title)", fraction: 0)
        task = Task {
            do {
                try await op.apply { fraction in
                    Task { @MainActor in self.running?.fraction = fraction }
                }
                undoStack.append(op)
                onUndoRedoToast("Redone — \(op.title)", "arrow.uturn.forward")
            } catch {
                // re-push so the redo isn't silently lost.
                redoStack.append(op)
                onUndoRedoToast("Couldn’t redo \(op.title)", "exclamationmark.triangle")
            }
            running = nil
            onOperationSettled()
        }
    }
}
