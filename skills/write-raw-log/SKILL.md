---
name: write-raw-log
description: Append an entry to the current role's raw log. Use after completing any significant work.
---

# Write Raw Log

Append a log entry to `.workflow/log/{ROLE}/{today's date}.md`.

## Steps

1. Determine the current date (YYYY-MM-DD)
2. Determine your role ID (from your agent definition)
3. Create the log directory if it doesn't exist: `.workflow/log/{ROLE}/`
4. Create or append to `.workflow/log/{ROLE}/{YYYY-MM-DD}.md`
5. Write entry using the template from `conventions/logging.md`:

```markdown
## {HH:MM} — {TASK_ID}
**Input:** {What you received as task/instruction}
**Actions:**
- {What you did, step by step}
**Output:** {What you produced}
**Decisions made:** {Any local decisions, or "None"}
**Status:** {New task status}
```

## Rules
- Append only — never modify existing entries
- Include task ID in every entry
- Be specific about files created/modified
- Note any decisions made, even small ones
