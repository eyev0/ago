# Phase 3: Verification Loop + Superpowers Integration — Design

> **Date:** 2026-02-27
> **Status:** Design approved
> **Scope:** hooks, command updates, master-session updates, superpowers integration

## Goal

Add a verification loop to the ago: workflow so that agent work is automatically checked against acceptance criteria before completion. Integrate superpowers skills (brainstorming, writing-plans, subagent-driven-development) as optional enhancements to ago:clarify and ago:execute.

## Architecture

### Part A: Verification Loop via Hooks

**Mechanism:** Two parallel SubagentStop command hooks fire when any subagent tries to stop:

1. **Deterministic hook** (`hooks/scripts/verify-and-log.sh`) — shell-based, 3 sequential stages:
   - **Stage 1 — Artifact check:** Verify required outputs exist (log entry written, task status updated, referenced files exist, frontmatter valid)
   - **Stage 2 — Criteria check:** Parse acceptance criteria from task.md, grep subagent transcript for evidence of each criterion being addressed
   - **Stage 3 — Write verification log:** Write mandatory log to `.workflow/log/{role}/verify-{task_id}-{attempt}.md` with checklist evaluation and retry prompt

2. **LLM evaluation hook** (`hooks/scripts/evaluate-and-log.sh`) — calls `claude -p --model haiku` via stdin with transcript + acceptance criteria. Writes detailed evaluation log to `.workflow/log/{role}/eval-{task_id}-{attempt}.md` with per-criterion evidence table, quality observations, and gaps. Returns `approve` (>= 80% completeness) or `block` with gap list.

**Conflict resolution:** Both hooks run in parallel. If either returns `block`, the subagent continues (block wins over approve — safety net).

**Retry flow:**
- Subagent completes work → SubagentStop fires → hooks evaluate → block with gaps → subagent continues with retry prompt
- Max 2 retries (3 total attempts). After max retries, approve with warnings in log.
- Retry count tracked via verify log files: count `verify-{task_id}-*.md` files in `.workflow/log/{role}/`

**Task ID extraction:** Parse from subagent transcript (`grep -oP 'Task: T\d+'` from `transcript_path` in stdin JSON).

### Part B: Superpowers Integration (Deep Merge)

**Principle:** ago: commands work standalone. If superpowers plugin is detected, commands delegate to superpowers skills for richer interaction.

**Detection:** Check if superpowers skills are available in the current session (test for skill existence at runtime).

**Mapping:**

| ago: command | Lifecycle phases | Without superpowers | With superpowers |
|-------------|-----------------|---------------------|------------------|
| `ago:clarify` | COLLABORATE → DECOMPOSE → APPROVE | Existing multi-step prompt | Invoke `/brainstorming` first (requirements refinement), then `/writing-plans` (task decomposition) |
| `ago:execute` | DELEGATE → MONITOR | Existing wave-based agent launch | Invoke `/subagent-driven-development` for task dispatch with review between tasks |

**Integration pattern for ago:clarify:**
1. Read project context (same as now)
2. **If superpowers available:** Invoke brainstorming skill with project context injected. Brainstorming explores requirements interactively. Output: validated design.
3. Then invoke writing-plans skill to convert design into ago:-compatible tasks (with frontmatter, role assignments, acceptance criteria)
4. **If superpowers unavailable:** Fall through to existing clarify logic (multi-step prompt)
5. APPROVE gate remains mandatory regardless of path

**Integration pattern for ago:execute:**
1. Build execution plan (same as now — waves, dependencies)
2. **If superpowers available:** Use subagent-driven-development pattern (fresh subagent per task, code review between tasks)
3. **If superpowers unavailable:** Use existing parallel wave launch
4. Verification hooks fire regardless of execution path

### Part C: Verification Log Format

Every verification attempt produces a mandatory log file:

```
.workflow/log/{role}/verify-{task_id}-{attempt}.md
```

Example: `.workflow/log/dev/verify-T001-1.md`

```markdown
## Verification Report — {task_id} — Attempt {N}

**Timestamp:** {ISO-8601}
**Task:** {task_id} — {task_title}
**Role:** {role}
**Attempt:** {N} of 3

### Artifact Check
- [x] Log entry written to .workflow/log/{role}/
- [ ] Task status updated to review
- [x] Referenced files exist
- [ ] Frontmatter valid in task.md

### Acceptance Criteria Evaluation
- [x] JWT validation middleware exists
- [ ] Error responses follow API schema
- [ ] Unit tests cover happy path

### Completeness: {N}%

### Decision: BLOCK | APPROVE

### Retry Prompt (if BLOCK)
Address these gaps before completing:
1. Update task status to `review` via ago:update-task-status
2. Ensure error responses match the schema in docs/api-schema.md
3. Add unit tests for the JWT validation happy path
```

### Part D: LLM Evaluation Log Format

The LLM evaluation hook writes a separate log file per verification attempt:

```
.workflow/log/{role}/eval-{task_id}-{attempt}.md
```

Example: `.workflow/log/dev/eval-T001-1.md`

```markdown
## LLM Evaluation — {task_id} — Attempt {N}

**Timestamp:** {ISO-8601}
**Task:** {task_id} — {task_title}
**Role:** {role}
**Evaluator:** LLM (claude -p haiku)

### Criteria Assessment
| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | JWT validation middleware exists | MET | Found in src/middleware/auth.ts |
| 2 | Error responses follow API schema | GAP | No evidence of schema validation |
| 3 | Unit tests cover happy path | PARTIAL | Tests exist but missing edge cases |

### Quality Observations
- Middleware implementation follows established patterns
- Missing error schema validation is a significant gap

### Gaps to Address
1. Error responses don't follow API schema — add validation
2. Unit tests need edge case coverage

### Completeness: 33%
### Decision: BLOCK
```

**Two logs per verification attempt:**

| File | Source | Content |
|------|--------|---------|
| `verify-{task_id}-{attempt}.md` | Shell script (deterministic) | Artifact checklist, grep-based criteria check, retry prompt |
| `eval-{task_id}-{attempt}.md` | LLM evaluation (claude -p haiku) | Per-criterion evidence, quality observations, detailed gaps |

## Files to Create/Modify

### New files:
- `hooks/hooks.json` — SubagentStop hook configuration (two command hooks)
- `hooks/scripts/verify-and-log.sh` — deterministic 3-stage verification script
- `hooks/scripts/evaluate-and-log.sh` — LLM evaluation script (claude -p haiku)

### Modified files:
- `commands/clarify.md` — Add superpowers detection + delegation
- `commands/execute.md` — Add superpowers detection + delegation
- `agents/master-session.md` — Reference hooks, update lifecycle description
- `conventions/logging.md` — Add verification log format
- `.claude-plugin/plugin.json` — Register hooks
- `README.md` — Update Phase 3 status
- `CLAUDE.md` — Reference hooks
- `AUDIT.md` — Add changelog entry
- `memory/MEMORY.md` — Update project memory

## Key Constraints

- Both hooks are command type, run in parallel — no chaining between hooks
- Hooks cannot spawn subagents — verification must complete within hook execution
- LLM hook calls `claude -p --model haiku` — uses current session auth, no API key needed
- LLM hook gracefully degrades: if `claude -p` fails, approve by default (no false blocks)
- SubagentStop hook receives `transcript_path` in stdin JSON — primary data source
- Max script timeout: 30s for deterministic hook, 60s for LLM evaluation hook
- Superpowers dependency is optional — never hard-fail if missing

## Open Questions Resolved

| Question | Decision |
|----------|----------|
| Can hooks spawn agents? | No. Use single-script approach instead. |
| How to chain evaluation → logging? | Single script, 3 sequential stages internally. |
| Where to track retry count? | Count verify log files per task. |
| How to detect superpowers? | Runtime skill availability check. |
| What if hooks disagree? | Block wins over approve (safety-first). |
| How does LLM hook persist findings? | Command hook calls `claude -p`, writes eval log to separate file. |
| Why not prompt-type hook? | Prompt hooks can't write files. Command hook with `claude -p` gives full control + persistence. |
