import SwiftUI

/// A horizontal two-pane split whose divider fraction is **app state** (issue 45).
///
/// SwiftUI's `HSplitView` gives a draggable divider but exposes no readable/bindable
/// fraction, so there is nothing to persist on save or apply on restore. This replaces
/// it with a `GeometryReader`-driven split bound to a `Double` fraction (0…1), so the
/// ratio can round-trip through `WorkspaceState.splitRatio` (issue 41).
///
/// **Governing principle (issue 41):** a restore that confuses is worse than none. So
/// the stored fraction is never trusted blindly — `leftWidth(...)` clamps it against the
/// current window width every layout, keeping both panes ≥ `minPaneWidth`. A fraction
/// saved on a wide window can't restore a zero-width pane on a narrow one.
struct SplitPane<Left: View, Right: View>: View {
    @Binding var fraction: Double
    var minPaneWidth: CGFloat = 180
    var dividerWidth: CGFloat = 1
    /// Invisible hit area on each side of the 1pt divider so it's easy to grab.
    var dividerHitSlop: CGFloat = 5
    @ViewBuilder var left: Left
    @ViewBuilder var right: Right

    /// Fixed coordinate space for the drag — anchored to the whole container, not the
    /// divider handle (which moves as you drag). Reading the pointer's absolute x here
    /// keeps the divider glued to the cursor instead of chasing a moving target.
    private let space = "SplitPaneContainer"

    var body: some View {
        GeometryReader { geo in
            let total = geo.size.width
            let leftW = Self.leftWidth(fraction: fraction, total: total,
                                       minPane: minPaneWidth, divider: dividerWidth)
            let rightW = max(0, total - leftW - dividerWidth)
            HStack(spacing: 0) {
                left.frame(width: leftW)
                divider(total: total)
                right.frame(width: rightW)
            }
            .coordinateSpace(name: space)
        }
    }

    private func divider(total: CGFloat) -> some View {
        // The visible line stays 1pt wide (so the width math above is exact); a wider
        // transparent overlay carries the hover + drag so the divider is easy to grab
        // without consuming layout space.
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(width: dividerWidth)
            .frame(maxHeight: .infinity)
            .overlay {
                Color.clear
                    .frame(width: dividerWidth + dividerHitSlop * 2)
                    .contentShape(Rectangle())
                    .onHover { inside in
                        if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
                    }
                    .gesture(
                        // Absolute pointer x in the fixed container space → the divider
                        // tracks the cursor 1:1 with no stutter. Center the 1pt line on
                        // the pointer (hence − dividerWidth/2) before clamping.
                        DragGesture(minimumDistance: 0, coordinateSpace: .named(space))
                            .onChanged { value in
                                guard total > 0 else { return }
                                let newLeft = Self.clampLeft(value.location.x - dividerWidth / 2,
                                                             total: total,
                                                             minPane: minPaneWidth,
                                                             divider: dividerWidth)
                                fraction = Double(newLeft / total)
                            }
                    )
            }
    }

    // MARK: - Pure layout math (unit-tested)

    /// The left pane's width for a given fraction and container width, clamped so both
    /// panes keep at least `minPane`. If the window is too narrow to honor two minimums,
    /// the space is split evenly rather than starving one pane.
    static func leftWidth(fraction: Double, total: CGFloat,
                          minPane: CGFloat, divider: CGFloat) -> CGFloat {
        clampLeft(CGFloat(fraction) * total, total: total, minPane: minPane, divider: divider)
    }

    /// Clamp a proposed left width into `[minPane, available − minPane]`, falling back to
    /// an even split when the container can't fit two minimum panes.
    static func clampLeft(_ proposed: CGFloat, total: CGFloat,
                          minPane: CGFloat, divider: CGFloat) -> CGFloat {
        let available = total - divider
        guard available > minPane * 2 else { return max(0, available / 2) }
        return min(max(proposed, minPane), available - minPane)
    }
}
