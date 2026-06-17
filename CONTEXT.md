# Diptychon

A fast, keyboard-first, dual-panel file manager for macOS — a lightweight Finder
alternative in the spirit of Nimble Commander. The name (a diptych, a two-panel
work) reflects the dual-panel core.

## Language

**Panel**:
One of the two side-by-side views, each showing the contents of a single
directory.
_Avoid_: pane, window

**Active Panel**:
The panel that currently has focus. It is the source of keyboard-driven
operations. Exactly one panel is active at any time.
_Avoid_: focused panel, current panel, source panel

**Inactive Panel**:
The panel without focus. It is the destination of the dedicated "send to other
panel" Commander gesture (default ⌥⌘→ / ⌥⌘←).
_Avoid_: target panel, other panel

**Destination**:
Where an operation puts its result. It is resolved per gesture, not fixed:
clipboard paste (⌘V) targets the Active Panel; the Commander gesture targets the
Inactive Panel; drag & drop targets wherever the user drops.
_Avoid_: target

**Panel Source**:
The thing a Panel lists. In the MVP always a local directory, but modeled as an
abstraction so future sources (tag view, search results, archive contents) plug
in without changing the rest of the app.
_Avoid_: data source, provider, location

**Tag**:
An Apple Finder tag — a colored, named label stored in the file's
`com.apple.metadata:_kMDItemUserTags` extended attribute. Always round-trip
compatible with Finder: tags set here appear in Finder and vice versa. The app
never keeps a parallel tagging system.
_Avoid_: label, marker, custom tag

**Operation**:
A file action the user performs (move, rename, delete-to-trash, copy). Each
Operation knows its own inverse so it can be undone, except overwrites, which
destroy the original and cannot be reversed.
_Avoid_: command, action, task
