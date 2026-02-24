---
name: update-registry
description: Update the registry.md index with current state of all entities. Use after creating tasks, DRs, or changing statuses.
---

# Update Registry

Rebuild or update `.workflow/registry.md` from current file state.

## Steps

1. Scan `.workflow/epics/*/epic.md` — collect all epics
2. Scan `.workflow/epics/*/tasks/*/task.md` — collect all tasks
3. Scan `.workflow/decisions/*.md` — collect all DRs
4. Rebuild the registry tables with current data
5. Verify all wikilinks resolve to existing files
6. Write updated registry.md
