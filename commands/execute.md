---
description: Launch agents for planned tasks
argument-hint: "[task-id|epic-id]"
---

# ago:execute

Launch role agents to execute planned tasks. This command maps to the DELEGATE and MONITOR phases of the session lifecycle. You are acting as MASTER — the orchestrator, not an executor.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `$1` | No | A task ID (`T001`), epic ID (`E01`), or omitted for all planned tasks. |

## Instructions

### Step 1 — Verify project initialization

Check that `.workflow/config.md` exists. If it does not exist, report:

> This project has not been initialized with a `.workflow/` directory. Run `ago:readiness` first.

Stop here if the file is missing.

### Step 2 — Read project context

Read these files (skip any that don't exist and note their absence):

1. `.workflow/config.md` — project name, active epics, active roles
2. `.workflow/registry.md` — entity index (epics, tasks)
3. `.workflow/docs/status.md` — current phase, blockers

### Step 3 — Find target tasks

Determine which tasks are candidates for execution based on `$ARGUMENTS`:

- **If `$1` matches `T\d+`:** Find the single task matching that ID. Search `.workflow/epics/*/tasks/T{NNN}-*/task.md` where the directory starts with the given ID followed by a hyphen.
- **If `$1` matches `E\d+`:** Read all task files under `.workflow/epics/{$1}/tasks/*/task.md`. If the epic directory does not exist, report "Epic {$1} not found in `.workflow/epics/`" and stop.
- **If no argument:** Read all task files across `.workflow/epics/*/tasks/*/task.md`.

For each task found, extract from its YAML frontmatter: `id`, `title`, `status`, `role`, `epic`, `priority`, `depends_on`, `acceptance_criteria`.

### Step 4 — Filter to eligible tasks

A task is eligible for execution only if ALL of the following are true:

1. **Status is `planned`** — skip tasks in any other status
2. **All `depends_on` tasks are `done`** — read each dependency's task.md and verify its status. If any dependency is not `done`, the task is not eligible.
3. **Task has a `role` assignment** — skip tasks without a role

If a specific task ID was requested via `$1` and it is not eligible, explain why:
- If status is not `planned`: "Task {id} has status `{status}` — only `planned` tasks can be executed."
- If a dependency is unresolved: "Task {id} depends on {dep_id} which has status `{dep_status}` — it must be `done` first."
- If no role is assigned: "Task {id} has no role assignment — assign a role before executing."

Stop here if no eligible tasks remain.

### Step 5 — Build execution plan

Group the eligible tasks into execution waves based on their dependency relationships:

- **Wave 1:** All eligible tasks that have no dependencies on other eligible tasks (independent — can run in parallel)
- **Wave 2:** Tasks whose dependencies are all in Wave 1 (run after Wave 1 completes)
- **Wave N:** Continue until all eligible tasks are assigned a wave

Present the execution plan to the user:

```
## Execution Plan

### Wave 1 (parallel)
| Task | Title | Role | Agent | Priority |
|------|-------|------|-------|----------|
| T001 | ...   | ARCH | architect.md | high |
| T002 | ...   | DEV  | developer.md | high |

### Wave 2 (after Wave 1)
| Task | Title | Role | Agent | Priority |
|------|-------|------|-------|----------|
| T003 | ...   | QAD  | qa-dev.md | medium |

**Total:** {N} tasks across {M} waves
```

### Step 6 — Get user confirmation

Ask the user to confirm before launching any agents:

> Ready to launch {N} agents for {N} tasks. Proceed? (yes/no)

**Do NOT launch agents or modify any files until the user explicitly confirms.** This is collaborative mode — user approval is mandatory.

If the user declines, stop. If the user wants to modify the plan (remove tasks, change order), adjust accordingly and re-present.

### Step 7 — Execute each wave

Process waves sequentially. Within each wave, launch all tasks in parallel.

For each task in the current wave:

#### 7a — Transition task to `in_progress`

Invoke the `ago:update-task-status` skill:
- `task_id`: the task's short ID (e.g., `T001`)
- `new_status`: `in_progress`

#### 7b — Log the delegation

Invoke the `ago:write-raw-log` skill:
- `role`: `master`
- `task_id`: the task's short ID
- `input`: "Execute task {task_id}: {task_title}"
- `actions`: ["Delegated to {ROLE} agent ({agent_file})"]
- `output`: "Agent launched for {task_id}"
- `decisions`: "None"
- `new_status`: `in_progress`

#### 7c — Launch the role agent

Use the Task tool to spawn the agent. Map the task's `role` to the agent file:

| Role | Agent file |
|------|-----------|
| ARCH | `@${CLAUDE_PLUGIN_ROOT}/agents/architect.md` |
| DEV | `@${CLAUDE_PLUGIN_ROOT}/agents/developer.md` |
| PM | `@${CLAUDE_PLUGIN_ROOT}/agents/product-manager.md` |
| PROJ | `@${CLAUDE_PLUGIN_ROOT}/agents/project-manager.md` |
| SEC | `@${CLAUDE_PLUGIN_ROOT}/agents/security-engineer.md` |
| QAL | `@${CLAUDE_PLUGIN_ROOT}/agents/qa-lead.md` |
| QAD | `@${CLAUDE_PLUGIN_ROOT}/agents/qa-dev.md` |
| DOC | `@${CLAUDE_PLUGIN_ROOT}/agents/documentation.md` |
| MKT | `@${CLAUDE_PLUGIN_ROOT}/agents/marketer.md` |
| CICD | `@${CLAUDE_PLUGIN_ROOT}/agents/cicd.md` |
| CONS | `@${CLAUDE_PLUGIN_ROOT}/agents/consolidator.md` |

Pass the agent these instructions in the Task tool prompt:

```
You are the {ROLE} agent. Read your role definition for full context.

## Your Assignment

**Task:** {task_id} — {task_title}
**Epic:** {epic_id}
**Priority:** {priority}

## Task Description
{full description from task.md body}

## Acceptance Criteria
{acceptance_criteria from task frontmatter or body}

## Context
- Project config: .workflow/config.md
- Your task file: .workflow/epics/{epic_id}/tasks/{task_dir}/task.md

## Skills Available
- `ago:write-raw-log` — Log your work (MANDATORY after completing)
- `ago:update-task-status` — Set task to `review` when done

## Instructions
1. Read your task file for full details
2. Read any referenced Decision Records or docs
3. Do the work described in the task
4. Log your work via `ago:write-raw-log`
5. Set task status to `review` via `ago:update-task-status`
```

For tasks within the same wave (no mutual dependencies), launch all agents in parallel using multiple Task tool calls.

#### 7d — Wait for wave completion

Wait for all agents in the current wave to complete before starting the next wave. As agents finish, report their status to the user:

```
- T001 (ARCH): completed, status set to `review`
- T002 (DEV): completed, status set to `review`
```

If an agent reports a blocker or error, surface it immediately and ask the user how to proceed.

### Step 8 — Report results

After all waves complete, present a summary:

```
## Execution Complete

| Task | Role | Result | New Status |
|------|------|--------|------------|
| T001 | ARCH | Completed | review |
| T002 | DEV  | Completed | review |
| T003 | QAD  | Completed | review |

**Next step:** Run `ago:review` to consolidate agent results, evaluate quality, and generate Decision Records.
```

### Step 9 — Log session outcome

Invoke `ago:write-raw-log` to record the overall execution in the master log:
- `role`: `master`
- `task_id`: first task ID (or "batch" if multiple)
- `input`: "Execute {N} planned tasks"
- `actions`: ["Launched {N} agents across {M} waves", "All agents completed"]
- `output`: "Execution complete. Tasks moved to review: {list of task IDs}"
- `decisions`: "None"
- `new_status`: `in_progress`

## Edge Cases

- **No planned tasks found:** Report "No planned tasks found. Use `ago:clarify` to decompose work into tasks, then plan them."
- **All planned tasks are blocked:** Report which tasks are blocked and by what. Suggest resolving blockers first.
- **Unknown role in task:** Report "Task {id} has role `{role}` which does not map to a known agent. Known roles: ARCH, DEV, PM, PROJ, SEC, QAL, QAD, DOC, MKT, CICD, CONS."
- **Agent fails or times out:** Log the failure in master log, report to user, keep the task as `in_progress` (do NOT mark it `review` or `done`).
- **User cancels mid-execution:** Stop launching new agents. Tasks already in progress continue — they will be in `in_progress` status and can be re-addressed later.

## Reminders

- You are MASTER — orchestrate, do not execute role-specific work yourself.
- User must confirm before any agents are launched.
- Every delegation must be logged in the master log.
- Independent tasks run in parallel, dependent tasks run sequentially.
- After execution, always suggest `ago:review` as the next step.
