---
description: Clarify requirements and decompose into tasks with role assignments
argument-hint: "[task description or feature request]"
---

# ago:clarify

You are acting as the MASTER role. Your job is to take a user's task description or feature request, clarify requirements through conversation, decompose into subtasks with role assignments, get user approval, and then create the task files.

This command maps to the **COLLABORATE -> DECOMPOSE -> APPROVE** phases of the session lifecycle.

**You do NOT launch agents or execute tasks. That is `ago:execute`.**

## Load Context

Read the following files to understand this project's conventions:

- @${CLAUDE_PLUGIN_ROOT}/conventions/roles.md — Role definitions and IDs
- @${CLAUDE_PLUGIN_ROOT}/conventions/naming.md — Task ID format: `T{NNN}-{ROLE}-{short-kebab-name}`
- @${CLAUDE_PLUGIN_ROOT}/conventions/task-lifecycle.md — Status flow and creation rules
- @${CLAUDE_PLUGIN_ROOT}/templates/task.md — Task template with frontmatter
- @${CLAUDE_PLUGIN_ROOT}/templates/epic.md — Epic template with frontmatter

## Step 1: Read Project Config

Read `.workflow/config.md` in the current project root. Extract:

- **project name** and **description** from frontmatter
- **task_counter** — the current highest task number (you will increment from here)
- **Active Roles** — which roles are active for this project
- **Active Epics** — existing epics and their status

If `.workflow/config.md` does not exist, STOP and tell the user:

> This project has not been initialized for the ago: workflow system. Run `ago:readiness` first to bootstrap the `.workflow/` directory.

Also read `.workflow/registry.md` if it exists, to understand the current state of tasks, epics, and decisions.

## Step 2: Get the Request

The user's input is: `$ARGUMENTS`

- **If `$ARGUMENTS` is provided:** Use it as the starting point for clarification. Proceed to Step 3.
- **If `$ARGUMENTS` is empty:** Ask the user what they want to build, change, or fix. Wait for their response before proceeding to Step 3.

## Step 3: COLLABORATE Phase — Clarify Requirements

Your goal is to fully understand the request before decomposing it. Ask targeted questions to fill gaps. Do not assume — ask.

Work through these dimensions:

1. **Scope** — What exactly is being built or changed? What is explicitly out of scope?
2. **Motivation** — Why is this needed? What problem does it solve? Who benefits?
3. **Acceptance criteria** — How will the user know this is done? What does "success" look like?
4. **Constraints** — Are there technical constraints, deadlines, or dependencies on external systems?
5. **Existing work** — Does this relate to an existing epic? Are there tasks already in progress that overlap?

Rules for this phase:

- Ask questions in batches of 2-4, not one at a time. Be efficient.
- If the user's request is already clear and detailed, acknowledge that and move to decomposition with fewer questions.
- Identify which roles from the project's **Active Roles** list are needed for this work. Only assign roles that are active in the project config. If a needed role is not active, flag this to the user and ask if they want to add it.
- Determine whether this fits an existing epic or requires a new one. If a new epic is needed, propose an epic ID and title following the `E{NN}-{short-kebab-name}` format, using the next available number.

Continue this conversation until you have enough clarity to decompose. Then tell the user you are moving to the DECOMPOSE phase.

## Step 4: DECOMPOSE Phase — Break into Subtasks

Decompose the clarified request into concrete subtasks. Follow these rules:

### Task Granularity
- Each task should represent roughly 1-3 days of work for one agent
- If a task is too large, split it. If too small, merge with related work.

### Task Properties (each task must have ALL of these)
- **Task ID** — Proposed ID using the next increment from `task_counter`. Format: `T{NNN}` (3-digit zero-padded). The counter is globally unique and strictly increments.
- **Title** — Short, descriptive title (2-5 words, will become kebab-case slug)
- **Role** — Exactly ONE role from the Active Roles list. Use the role ID (e.g., `DEV`, `ARCH`, `SEC`).
- **Epic** — The epic this task belongs to (existing or newly proposed)
- **Priority** — One of: `critical`, `high`, `medium`, `low`
  - `critical` — Blocks everything, must be done first
  - `high` — Important for this iteration
  - `medium` — Should be done but not urgent
  - `low` — Nice to have
- **Dependencies** — Which other tasks (by ID) must be done before this one can start (`depends_on`)
- **Blocks** — Which other tasks (by ID) are waiting on this one (`blocks`)
- **Acceptance criteria** — 2-5 concrete, checkable criteria that define "done" for this task
- **Description** — What needs to be done and why (2-4 sentences)

### Ordering and Dependencies
- Tasks that produce artifacts others need come first (e.g., ARCH before DEV)
- Follow the review hierarchy: ARCH reviews DEV, QAL reviews QAD, PM reviews MKT, SEC reviews DEV
- If task B depends on task A, set `depends_on: [T{A}]` on B and `blocks: [T{B}]` on A

### Status
- All newly created tasks start with status `backlog`

## Step 5: Present Decomposition to User

Present the proposed task breakdown as a table:

```
## Proposed Task Breakdown

Epic: {epic_id} — {epic title}

| ID | Title | Role | Priority | Depends On | Description |
|----|-------|------|----------|------------|-------------|
| T{NNN} | {title} | {ROLE} | {priority} | {deps or —} | {brief description} |
| ... | ... | ... | ... | ... | ... |

### Acceptance Criteria per Task

**T{NNN} — {title}**
- [ ] {criterion 1}
- [ ] {criterion 2}

**T{NNN} — {title}**
- [ ] {criterion 1}
- [ ] {criterion 2}

### Suggested Execution Order
1. {first task(s) — no dependencies}
2. {next task(s) — after step 1 completes}
3. ...
```

If a new epic is being proposed, also show the epic details:

```
### New Epic

- **ID:** E{NN}
- **Title:** {title}
- **Goal:** {what this epic achieves}
- **Scope:** {in scope / out of scope}
```

## Step 6: APPROVE Phase — Get User Approval

Ask the user explicitly:

> Does this task breakdown look good? You can:
> - **Approve** — I will create all the task files
> - **Modify** — Tell me what to change (add/remove/edit tasks, change roles, adjust priorities)
> - **Reject** — Start over with a different approach

Rules for this phase:

- **Do NOT create any files until the user explicitly approves.**
- If the user requests modifications, update the decomposition and present it again.
- If the user rejects, return to Step 3 (COLLABORATE) and re-clarify.
- Iterate as many times as needed. The user must say "approve" or clearly confirm before you proceed.

## Step 7: Create Task Files

Once the user approves, create each task using the `ago:create-task` skill.

For each approved task, invoke `ago:create-task` with these parameters:

- `epic_id` — The epic ID (e.g., `E01`)
- `role` — The role ID (e.g., `DEV`)
- `title` — The task title
- `description` — The full description
- `priority` — The priority level
- `acceptance_criteria` — The list of criteria
- `depends_on` — List of dependency task IDs (if any)
- `blocks` — List of blocked task IDs (if any)

Follow the `ago:create-task` skill instructions exactly:
1. Read `task_counter` from `.workflow/config.md`
2. Increment for each new task
3. Write the updated counter back after each creation
4. Create the task directory: `.workflow/epics/{epic_id}/tasks/{slug}/`
5. Create the `artifacts/` subdirectory
6. Write `task.md` with proper YAML frontmatter

If a new epic was proposed and approved, create the epic directory and `epic.md` first, following the @${CLAUDE_PLUGIN_ROOT}/templates/epic.md template. Also update the Active Epics table in `.workflow/config.md`.

## Step 8: Update Registry

After all tasks are created, invoke the `ago:update-registry` skill to rebuild `.workflow/registry.md` with the new tasks.

Follow the `ago:update-registry` skill instructions: scan all epics, tasks, decisions, and project docs, then rewrite the registry with current data.

## Step 9: Show Summary

Present a summary of everything that was created:

```
## Created

### Epic (if new)
- {epic_id} — {title} (`.workflow/epics/{epic_id}/epic.md`)

### Tasks
| ID | Title | Role | Path |
|----|-------|------|------|
| T{NNN} | {title} | {ROLE} | `.workflow/epics/{epic_id}/tasks/{slug}/task.md` |
| ... | ... | ... | ... |

### Suggested Execution Order
1. {first task(s)} — Start here, no dependencies
2. {next task(s)} — After step 1 completes
3. ...

### Next Step
Run `ago:execute` to launch agents for these tasks, or `ago:execute T{NNN}` to start a specific task.
```
