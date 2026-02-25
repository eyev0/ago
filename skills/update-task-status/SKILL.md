---
name: ago:update-task-status
description: Update a task's status in its frontmatter. Invoke when starting, completing, blocking, or unblocking a task.
version: 0.2.0
---

# ago:update-task-status

Update the `status` and `updated` fields in a task's YAML frontmatter.

## When to Use

Invoke whenever a task changes status: starting work, finishing, hitting a blocker, or resolving one.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| task_id | Yes | Short task ID (e.g., `T001`) |
| new_status | Yes | Target status: `planned`, `in_progress`, `review`, `blocked`, `done` |
| blocker_ref | No | Required if new_status is `blocked` — reference to what's blocking |

## Valid Transitions

| From | To | Who can do it |
|------|----|---------------|
| backlog | planned | MASTER, PROJ |
| planned | in_progress | Agent (assignee) |
| in_progress | review | Agent (assignee) |
| in_progress | blocked | Agent (assignee) |
| review | done | MASTER only |
| review | in_progress | MASTER (revision needed) |
| blocked | planned | MASTER, PROJ |
| blocked | in_progress | Agent (assignee) |

## Instructions

1. **Find the task:** Search `.workflow/epics/*/tasks/T{NNN}-*/task.md` matching the short ID
   - The task directory starts with the short ID followed by a hyphen
2. **Read frontmatter:** Parse the current `status` field
3. **Validate transition:** Check the From → To transition is allowed (see table above)
   - If invalid: STOP and report the error. Do not force the transition.
4. **Check dependencies:** If moving to `in_progress`, verify all `depends_on` tasks have status `done`
   - If any dependency is not `done`: STOP and report which dependencies are blocking
5. **Update frontmatter:**
   - Set `status: {new_status}`
   - Set `updated: {YYYY-MM-DD}`
6. **If blocking:** Add a note in the Notes section: `Blocked by: {blocker_ref}`
7. **Log the change:**
   - If you are an agent (not MASTER): invoke `ago:write-raw-log` with the status change
   - If you are MASTER: log in `.workflow/log/master/{YYYY-MM-DD}.md` only

## Validation

- task.md frontmatter shows the new status
- `updated` date is today
- Transition was valid per the table

## Error Handling

- If task not found: STOP — report "Task {task_id} not found in any epic"
- If transition invalid: STOP — report "Cannot transition from {current} to {new_status}"
- If dependency not met: STOP — report "Task {dep_id} must be done first"
