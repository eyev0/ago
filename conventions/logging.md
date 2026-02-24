# Logging Conventions

## Two-Level Logging

| Level | Writer | Content | Location |
|-------|--------|---------|----------|
| Master log | MASTER | Delegations, validations, conflicts, decisions | `log/master/` |
| Agent log | Each role | Actions, local decisions, input/output | `log/{ROLE}/` |

## Master Log Format

Daily file: `log/master/{YYYY-MM-DD}.md`

```markdown
# {YYYY-MM-DD}

## {HH:MM} — {Action type}
{Description of what happened}
- {Detail 1}
- {Detail 2}
```

Action types: Task delegation, Review results, Decision accepted, Conflict resolved, Status update

## Agent Log Format

Daily file: `log/{ROLE}/{YYYY-MM-DD}.md`

Each entry:
```markdown
## {HH:MM} — {Task ID}
**Input:** What the agent received as task/instruction
**Actions:**
- {Action 1}
- {Action 2}
**Output:** What was produced
**Decisions made:** {Any local decisions, or "None"}
**Status:** {New task status after this work}
```

## Rules

1. Logs are append-only — never edit previous entries
2. Every agent action MUST be logged (mandatory)
3. Log entries reference task IDs
4. Decisions in agent logs are candidates for DR extraction
5. Master log captures cross-agent events only

## Future: Hook-Based Automation

> TODO: Investigate Claude Code hooks (PreToolUse/PostToolUse/Stop) for automated logging.
> Goal: agents don't manually log — hooks capture input/output automatically.
