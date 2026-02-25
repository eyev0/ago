---
name: ago:create-task
description: Create a new task with proper directory structure, frontmatter, and registry entry. Invoke during task decomposition (ago:clarify).
version: 0.2.0
---

# ago:create-task

Create a task directory, task.md file, and update the registry.

## When to Use

Invoke during the DECOMPOSE/APPROVE phase, typically called by `ago:clarify` after the user approves the task breakdown.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| epic_id | Yes | Epic this task belongs to (e.g., `E01`) |
| role | Yes | Role that will execute, uppercase (e.g., `DEV`, `ARCH`) |
| title | Yes | Short task title (2-5 words, kebab-case for slug) |
| description | Yes | What needs to be done and why |
| priority | Yes | `critical`, `high`, `medium`, `low` |
| acceptance_criteria | Yes | List of criteria that define "done" |
| depends_on | No | List of task IDs this depends on (e.g., `[T001, T002]`) |
| blocks | No | List of task IDs this blocks |

## Instructions

1. **Read config:** Open `.workflow/config.md` and read the `task_counter` from frontmatter
2. **Increment counter:** New task number = `task_counter + 1`
3. **Update config:** Write the new `task_counter` value back to `.workflow/config.md` frontmatter
4. **Format IDs:**
   - Short ID: `T{NNN}` (zero-padded to 3 digits, e.g., `T001`)
   - Directory slug: `T{NNN}-{ROLE}-{title-in-kebab-case}` (role uppercase in slug)
5. **Create directory:** `.workflow/epics/{epic_id}/tasks/{slug}/`
6. **Create artifacts dir:** `.workflow/epics/{epic_id}/tasks/{slug}/artifacts/`
7. **Create task.md** with this content:

```markdown
---
id: {short_id}
role: {ROLE}
title: {title}
epic: {epic_id}
status: backlog
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
priority: {priority}
depends_on: {depends_on or []}
blocks: {blocks or []}
related_decisions: []
---

## Description

{description}

## Acceptance Criteria

- [ ] {criterion 1}
- [ ] {criterion 2}
...

## Artifacts

{Links to role reports will be added as work progresses}

## Notes

```

8. **Update registry:** Invoke `ago:update-registry` or manually add a row to the Active Tasks table in `.workflow/registry.md`
9. **Return:** the short ID (`T001`) and full path to the created task.md

## Validation

- Task directory exists at expected path
- task.md has valid YAML frontmatter
- `task_counter` in config.md was incremented
- Registry has a new row for this task

## Error Handling

- If `.workflow/config.md` doesn't exist: STOP — project not initialized
- If the epic directory doesn't exist (`.workflow/epics/{epic_id}/`): Create it with an `epic.md` stub
- If `task_counter` can't be read: STOP — config.md may be corrupt
