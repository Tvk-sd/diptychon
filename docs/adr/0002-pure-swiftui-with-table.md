# Pure SwiftUI UI, using `Table` for the file list

The whole UI is built in **pure SwiftUI** (no AppKit views), even though the
reference app (Nimble Commander) is AppKit and speed is a core promise. The
file list — the performance-critical heart — uses SwiftUI's **`Table`** (macOS),
not `List`, because `Table` is column-based, sortable, and bridged to
`NSTableView` internally, giving most of AppKit's list performance without
AppKit code.

## Considered Options

- **Hybrid (AppKit `NSTableView` for the list, SwiftUI for the rest)** — fastest,
  matches how serious Mac file managers are built; rejected for higher
  complexity and learning/agent-build cost.
- **Pure SwiftUI with `Table`** — chosen.
- Pure SwiftUI with `List` — rejected: `List` is built for dozens of rows, not a
  high-frequency data grid.

## Consequences

- Simpler, more uniform, faster-to-build codebase.
- Residual risk: very large folders (100k+) may eventually stutter; deep
  keyboard navigation (range selection, type-ahead) is fiddlier than in AppKit.
- **Escape hatch:** the file list is hidden behind a narrow protocol from day 1.
  Trigger to revisit — if a real folder of ~50,000 files visibly stutters while
  scrolling/keyboard-navigating, swap *only* the list layer for an AppKit
  `NSTableView` behind that protocol, leaving the rest of the app untouched.

## Update (2026-06-18, issue 06): hatch taken

The hatch was exercised earlier than the perf trigger anticipated — for
**input**, not performance. SwiftUI `Table` could not combine row drag-and-drop
with reliable single-click selection (any drag modifier on a row swallows the
selecting click; we also hit related focus/tap conflicts in issues 03–04). As
designed, only the list layer changed: `PanelFileList` now aliases
`NSTableViewFileList` (an `NSViewRepresentable` over `NSTableView`) behind the
unchanged `FileListView` protocol. The SwiftUI `TableFileListView` remains as a
reference implementation. This also pre-empts the 50k-row perf trigger.
