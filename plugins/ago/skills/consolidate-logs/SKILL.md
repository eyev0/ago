---
name: ago:consolidate-logs
description: This skill should be used when an agent needs to "consolidate logs", "extract decisions from logs", or "review agent output". Reads agent raw logs, extracts significant decisions into DRs, and flags conflicts after agents complete work.
version: 0.2.0
---

# ago:consolidate-logs

Read raw agent logs, identify decisions, create Decision Records, and flag conflicts.

## When to Use

During the CONSOLIDATE step (step 8 of session lifecycle), after agents have completed their work. Also callable via `ago:review` command.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| date | No | Date to consolidate (YYYY-MM-DD). Defaults to today. |
| role | No | Specific role to consolidate. If omitted, consolidate all roles. |
| task_id | No | Specific task to consolidate. If omitted, consolidate all tasks. |

## Instructions

1. **Identify log files:** Scan `.workflow/log/` directories
   - If `role` specified: only `.workflow/log/{role}/{date}.md`
   - If `task_id` specified: scan all role logs for entries referencing that task
   - If neither: scan all `.workflow/log/*/{date}.md`
2. **Parse log entries:** Each entry starts with `## HH:MM — T{NNN}`
   - Extract: task_id, input, actions, output, decisions, status
3. **Identify decisions:** For each entry, check the "Decisions made" section
   - If "None" or empty: skip
   - If contains text: evaluate significance
4. **Evaluate significance:** A decision warrants a DR if:
   - It affects architecture, security, or product scope
   - It impacts multiple tasks or components
   - It has long-term consequences
   - It represents a choice between alternatives
   Minor decisions (naming, formatting, local implementation details) do NOT need DRs.
5. **Create DRs:** For each significant decision, invoke `ago:create-decision-record` with extracted data
6. **Check for conflicts:** Compare decisions across different roles:
   - Does a DEV decision contradict an ARCH decision?
   - Does a QAD finding conflict with DEV's approach?
   - If conflicts found: flag them for MASTER review
7. **Update project docs:** If decisions affect project documents (architecture, security, etc.), note the updates needed
8. **Log consolidation:** Write a summary entry in `.workflow/log/master/{date}.md`:

```markdown
## {HH:MM} — Consolidation

**Logs reviewed:** {count} entries across {count} roles
**Decisions found:** {count} ({count} significant → DRs created)
**Conflicts:** {count or "None"}
**Docs to update:** {list or "None"}
```

## Validation

- All log files for the date/role/task were read
- DRs were created for significant decisions
- Conflicts were flagged (not silently ignored)
- Consolidation summary was logged

## Error Handling

- If no log files found for the date: Report "No logs found for {date}" — this is not an error if no work was done
- If log entry has malformed format: Skip it, log a warning

## References

- `conventions/logging.md` — canonical source for log format and conventions
