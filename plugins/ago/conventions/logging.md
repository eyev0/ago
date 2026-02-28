# Logging Conventions

## Two-Level Logging

| Level | Writer | Content | Location |
|-------|--------|---------|----------|
| Master log | MASTER | Delegations, validations, conflicts, decisions | `.workflow/log/master/` |
| Agent log | Each role | Actions, local decisions, input/output | `.workflow/log/{role}/` |

## Master Log Format

Daily file: `.workflow/log/master/{YYYY-MM-DD}.md`

```markdown
# {YYYY-MM-DD}

## {HH:MM} — {Action type}
{Description of what happened}
- {Detail 1}
- {Detail 2}
```

Action types: Task delegation, Review results, Decision accepted, Conflict resolved, Status update

## Agent Log Format

Daily file: `.workflow/log/{role}/{YYYY-MM-DD}.md`

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

## Verification Log Format

Created automatically by the SubagentStop verification hook (`verify-and-log.sh`). One file per verification attempt.

File: `.workflow/log/{role}/verify-{task_id}-{attempt}.md`

Example: `.workflow/log/dev/verify-T001-1.md`

Each verification log contains:
- **Artifact Check** — Required outputs: log entry, task status, referenced files, frontmatter
- **Acceptance Criteria Evaluation** — Each criterion checked against subagent transcript
- **Completeness score** — Percentage of criteria met (threshold: 80%)
- **Decision** — APPROVE or BLOCK
- **Retry Prompt** — (if BLOCK) Specific gaps the agent must address

## LLM Evaluation Log Format

Created automatically by the SubagentStop LLM evaluation hook (`evaluate-and-log.sh`). One file per evaluation attempt.

File: `.workflow/log/{role}/eval-{task_id}-{attempt}.md`

Example: `.workflow/log/dev/eval-T001-1.md`

Each evaluation log contains:
- **Criteria Assessment** — Table with per-criterion Status (MET/GAP/PARTIAL) and Evidence
- **Quality Observations** — What was done well and what is concerning
- **Gaps to Address** — Specific unmet criteria that need work
- **Completeness score** — Percentage of criteria fully MET (threshold: 80%)
- **Decision** — APPROVE or BLOCK

### Graceful Degradation
- If `claude -p` fails, the hook approves by default (no false blocks from LLM failure)
- Deterministic verification log (`verify-*.md`) always exists as fallback

### Retry Rules
- Max 3 attempts per task (configurable in `verify-and-log.sh`)
- After max retries, auto-approve with warnings logged
- Retry count tracked by counting `verify-{task_id}-*.md` files (deterministic) and `eval-{task_id}-*.md` files (LLM)

## Hook-Based Verification

SubagentStop hooks automatically verify agent work (both command type, run in parallel):
- **Deterministic hook** (`hooks/scripts/verify-and-log.sh`) — artifact check + criteria check + write verification log
- **LLM evaluation hook** (`hooks/scripts/evaluate-and-log.sh`) — independent `claude -p` haiku evaluation + write evaluation log

If either hook returns `block`, the agent continues working. Two log files per attempt:
- `verify-{task_id}-{attempt}.md` — facts (checklist, grep-based criteria)
- `eval-{task_id}-{attempt}.md` — judgment (per-criterion evidence, quality observations, gaps)

See `hooks/hooks.json` for configuration.
