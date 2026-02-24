---
name: update-task-status
description: Update a task's status in its frontmatter. Use when starting, completing, or blocking a task.
---

# Update Task Status

Update the `status` and `updated` fields in a task's frontmatter.

## Steps

1. Read the task.md file
2. Validate the transition is allowed (see conventions/task-lifecycle.md)
3. Update `status` field to new value
4. Update `updated` field to today's date
5. If moving to `blocked`, add blocker reference in Notes section
6. Log the status change via `write-raw-log` skill

## Valid Transitions
- backlog → planned
- planned → in_progress
- in_progress → review | blocked
- review → done | in_progress
- blocked → planned | in_progress
