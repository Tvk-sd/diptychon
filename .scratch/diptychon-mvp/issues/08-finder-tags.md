# 08 — Finder tags

Status: ready-for-agent

## Parent

`.scratch/diptychon-mvp/PRD.md`

## What to build

Real Apple Finder tags, round-trip compatible (see `/CONTEXT.md` → Tag): tags
read/written via the `com.apple.metadata:_kMDItemUserTags` extended attribute,
including color, so a tag set here appears in Finder and vice versa. Display tags
(color dot + name) on files in a Panel, set/remove tags on the selection, create
a new tag and choose from the system tag list, and filter the Active Panel by
tag.

Note: writing tags that Finder displays correctly involves low-level xattr work
and the system tag list (stored separately by Finder). Treat round-trip fidelity
with Finder as the bar.

## Acceptance criteria

- [ ] Existing Finder tags display on files (color + name).
- [ ] Setting/removing a tag on the selection is reflected in Finder, and tags
      set in Finder appear here.
- [ ] User can create a new tag and pick from the system tag list.
- [ ] The Active Panel can be filtered to show only files with a chosen tag.

## Blocked by

- `03-dual-panels-focus`
