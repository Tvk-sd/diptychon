# PLAN

_No active task._

Last task: **issue 30 (staging panel — stage & view, the tracer slice)** — done,
user-verified in the running app, on branch `feat/30-stage-and-view-files` (not pushed).
`StagingStore` + `StagingSource` + `FileItem.isMissing` + `PanelModel.showingStaging`
(source swap) + ⌘⇧S add / ⌘⇧B toggle + empty placeholder. 92 unit tests green (3 new).

Grab next (issue 20 backlog): **#31** add-surface + header toggle button and **#32**
operate-on-set are both parallelizable off #30; **#33** manage+degrade last. Missing-item
greying/exclusion (the `isMissing` flag already ships) lands in #33.
