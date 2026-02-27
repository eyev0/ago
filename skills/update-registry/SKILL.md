---
name: ago:update-registry
description: This skill should be used when an agent needs to "update the registry", "rebuild the index", or "sync registry with filesystem". Rebuilds the registry.md index from the current filesystem state after creating tasks, DRs, or changing statuses.
version: 0.2.0
---

# ago:update-registry

Scan `.workflow/` and rebuild `.workflow/registry.md` with current data.

## When to Use

After any structural change: task creation, status changes, DR creation. Can also be run periodically to ensure consistency.

## Input

No parameters required. Reads directly from filesystem.

## Instructions

1. **Scan epics:** Read all `.workflow/epics/*/epic.md` files
   - Extract: id, title, status from frontmatter
   - Count tasks per epic
2. **Scan tasks:** Read all `.workflow/epics/*/tasks/*/task.md` files
   - Extract: id, title, status, role, epic, priority from frontmatter
3. **Scan decisions:** Read all `.workflow/decisions/*.md` files
   - Extract: id, status, role, epic, task, date from frontmatter
4. **Scan project docs:** Read all `.workflow/docs/*.md` files
   - Extract: owner and updated from frontmatter (if present)
5. **Compute summary stats:**
   - total_epics: count of epics
   - total_tasks: count of tasks
   - total_decisions: count of DRs
   - active_roles: unique roles from tasks with status != done
6. **Write `.workflow/registry.md`:**

```markdown
---
last_updated: {YYYY-MM-DD}
total_epics: {count}
total_tasks: {count}
total_decisions: {count}
active_roles: [{list}]
---

# Registry

> Auto-updated index of all project entities. Source of truth for navigation.

## Epics

| ID | Title | Status | Tasks | Timeline |
|----|-------|--------|-------|----------|
| {id} | {title} | {status} | {count} | [[{id}/timeline.md]] |

## Active Tasks

| ID | Title | Status | Role | Epic | Priority |
|----|-------|--------|------|------|----------|
| {id} | [[{slug}/task.md]] | {status} | {role} | {epic} | {priority} |

## Decision Records

| ID | Status | Role | Epic | Task | Date |
|----|--------|------|------|------|------|
| [[{id}]] | {status} | {role} | {epic} | {task} | {date} |

## Project Documents

| Document | Owner | Last Updated |
|----------|-------|-------------|
| [[eprd.md]] | PM | {date or blank} |
| [[architecture.md]] | ARCH | {date} |
| [[security.md]] | SEC | {date} |
| [[testing.md]] | QAL | {date} |
| [[marketing.md]] | MKT | {date} |
| [[status.md]] | PROJ | {date} |
| [[timeline.md]] | PROJ | {date} |
```

7. **Validate wikilinks:** For each `[[...]]` in the registry, check the target file exists
   - Log warnings for broken links

## Validation

- `.workflow/registry.md` exists and has valid frontmatter
- All epics, tasks, and DRs in the filesystem appear in the registry
- Wikilinks resolve to existing files

## Error Handling

- If `.workflow/` doesn't exist: STOP — project not initialized
- If no epics exist: Write a registry with empty tables
- If a task.md has invalid frontmatter: Skip it, log a warning
