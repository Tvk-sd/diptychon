import SwiftUI

/// Non-blocking activity pane (issue 34, Slice 1). Surfaces the *running* Operation
/// — title + determinate progress + Cancel — as a bottom-left card the user can work
/// alongside, replacing the old full-screen blocking modal. This is the "transfer
/// pane" trust signal from the netnography (ForkLift praise / Nimble "no transfer
/// pane"); the full pending-queue + merge live in later slices of #34.
///
/// Presentation only: it reads the coordinator's `running` snapshot and reports the
/// two user verbs (cancel the op, close the pane) back to the owner — it holds no
/// state and does not touch the Operation spine.
struct ActivityPanel: View {
    let running: OperationCoordinator.Running?
    let onCancel: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Label("Activity", systemImage: "list.bullet.rectangle")
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 12)
                Button(action: onClose) { Image(systemName: "xmark") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Close Activity")
                    .accessibilityIdentifier("activity-close")
            }
            Divider()
            if let running {
                VStack(alignment: .leading, spacing: 6) {
                    Text(running.title)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    HStack(spacing: 8) {
                        ProgressView(value: running.fraction)
                        Button("Cancel", role: .cancel, action: onCancel)
                            .controlSize(.small)
                            .accessibilityIdentifier("activity-cancel")
                    }
                }
            } else {
                Text("No active operations")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .shadow(radius: 8, y: 2)
        .padding(12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("activity-panel")
    }
}
