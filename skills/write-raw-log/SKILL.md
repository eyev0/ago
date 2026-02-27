---
name: ago:write-raw-log
description: This skill should be used when an agent needs to "write a log entry", "record completed work", or "append to the raw log". Appends a timestamped log entry to the current role's raw log after completing any significant work on a task.
version: 0.2.0
---

# ago:write-raw-log

Append a timestamped log entry to `.workflow/log/{role}/{YYYY-MM-DD}.md`.

## When to Use

Invoke this skill after completing any significant action on a task. Every agent MUST log their work — this is mandatory, not optional.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| role | Yes | Your role ID, lowercase (e.g., `dev`, `arch`, `master`) |
| task_id | Yes | Short task ID (e.g., `T001`) |
| input | Yes | What you received as task/instruction |
| actions | Yes | List of actions performed |
| output | Yes | What was produced (files, reports, decisions) |
| decisions | No | Local decisions made, or "None" |
| new_status | Yes | Task status after this work: `planned`, `in_progress`, `review`, `blocked` |

## Instructions

1. Determine today's date in `YYYY-MM-DD` format
2. Determine current time in `HH:MM` format
3. Ensure directory exists: `.workflow/log/{role}/`
   - If it doesn't exist, create it
4. Open or create file: `.workflow/log/{role}/{YYYY-MM-DD}.md`
   - If file is new, add a heading: `# {YYYY-MM-DD}`
   - If file exists, append to it
5. Append this entry:

```markdown
## {HH:MM} — {task_id}

**Input:** {input}

**Actions:**
- {action 1}
- {action 2}
- ...

**Output:** {output}

**Decisions made:** {decisions, or "None"}

**Status:** {new_status}
```

6. Do NOT add YAML frontmatter to log files — they are exempt

## Validation

- File exists at `.workflow/log/{role}/{YYYY-MM-DD}.md`
- Entry was appended (not overwriting previous entries)
- Role directory is lowercase

## Error Handling

- If `.workflow/` doesn't exist: STOP. The project hasn't been initialized with `ago:readiness`.
- If `.workflow/log/` doesn't exist: Create it along with the role subdirectory.
