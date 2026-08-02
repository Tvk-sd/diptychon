import SwiftUI

/// A vertical two-pane split whose divider fraction is **app state** (issue 65).
///
/// The vertical twin of `SplitPane` — same reasoning, same governing principle:
/// the stored fraction is never trusted blindly, `topHeight(...)` clamps it against
/// the current container height every layout so a ratio saved on a tall window can't
/// restore a zero-height pane on a short one.
///
/// Split out rather than generalized over an axis: the two differ in cursor
/// (`resizeUpDown`), in the minimums (the file list and a terminal want different
/// floors), and `SplitPane`'s math is unit-tested against the horizontal case.
/// One axis-generic container would have made both harder to read for no gain.
struct VSplitPane<Top: View, Bottom: View>: View {
    @Binding var fraction: Double
    /// The file list needs more room to stay useful than the terminal does.
    var minTopHeight: CGFloat = 120
    var minBottomHeight: CGFloat = 80
    var dividerHeight: CGFloat = 1
    /// Invisible hit area above and below the 1pt divider so it's easy to grab.
    var dividerHitSlop: CGFloat = 5
    @ViewBuilder var top: Top
    @ViewBuilder var bottom: Bottom

    /// Fixed coordinate space for the drag — anchored to the whole container, not the
    /// divider handle, so the divider tracks the cursor instead of chasing itself.
    private let space = "VSplitPaneContainer"

    var body: some View {
        GeometryReader { geo in
            let total = geo.size.height
            let topH = Self.topHeight(fraction: fraction, total: total,
                                      minTop: minTopHeight, minBottom: minBottomHeight,
                                      divider: dividerHeight)
            let bottomH = max(0, total - topH - dividerHeight)
            VStack(spacing: 0) {
                top.frame(height: topH)
                divider(total: total)
                bottom.frame(height: bottomH)
            }
            .coordinateSpace(name: space)
        }
    }

    private func divider(total: CGFloat) -> some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: dividerHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                Color.clear
                    .frame(height: dividerHeight + dividerHitSlop * 2)
                    .contentShape(Rectangle())
                    .onHover { inside in
                        if inside { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named(space))
                            .onChanged { value in
                                guard total > 0 else { return }
                                let newTop = Self.clampTop(value.location.y - dividerHeight / 2,
                                                           total: total,
                                                           minTop: minTopHeight,
                                                           minBottom: minBottomHeight,
                                                           divider: dividerHeight)
                                fraction = Double(newTop / total)
                            }
                    )
            }
    }

    // MARK: - Pure layout math (unit-tested)

    /// The top pane's height for a given fraction and container height, clamped so both
    /// panes keep at least their minimum.
    static func topHeight(fraction: Double, total: CGFloat,
                          minTop: CGFloat, minBottom: CGFloat, divider: CGFloat) -> CGFloat {
        clampTop(CGFloat(fraction) * total, total: total,
                 minTop: minTop, minBottom: minBottom, divider: divider)
    }

    /// Clamp a proposed top height into `[minTop, available − minBottom]`. When the
    /// container can't fit both minimums, the space is split proportionally to them
    /// rather than starving one pane — the terminal keeps a usable sliver instead of
    /// collapsing to nothing on a short window.
    static func clampTop(_ proposed: CGFloat, total: CGFloat,
                         minTop: CGFloat, minBottom: CGFloat, divider: CGFloat) -> CGFloat {
        let available = total - divider
        guard available > minTop + minBottom else {
            let share = minTop / max(minTop + minBottom, 1)
            return max(0, available * share)
        }
        return min(max(proposed, minTop), available - minBottom)
    }
}
