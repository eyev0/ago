# Executable Skills Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix all consistency issues, then rewrite 9 skill stubs into executable SKILL.md prompts that agents can invoke.

**Architecture:** Each SKILL.md becomes a self-contained prompt with frontmatter, input params, step-by-step instructions (with exact paths and inline templates), validation, and error handling. Skills are invoked explicitly by agents or commands.

**Tech Stack:** Markdown only. No code. Claude Code plugin system (SKILL.md format).

**Design doc:** `docs/plans/2026-02-25-executable-skills-design.md`

---

### Task 0: Consistency Fixes

Fix all AUDIT.md/TODO.md issues that block correct skill execution.

**Files to modify:**
- All 13 files in `agents/`
- `conventions/roles.md`
- `conventions/quality-gates.md`
- `conventions/logging.md`
- `conventions/naming.md`
- `conventions/task-lifecycle.md`
- `conventions/documentation.md`
- `conventions/decision-records.md`
- `conventions/file-structure.md`
- `master-session/instructions.md`
- `CLAUDE.md`
- `README.md`
- `memory/AGENTS.md`
- `memory/MEMORY.md`
- `templates/config.md`
- `templates/registry.md`
- `templates/agent-log-entry.md`
- `templates/project-docs/timeline.md` (new)
- `commands/clarify.md`

**Step 1: C1/P03 — Normalize paths in all 13 agent files**

In every file in `agents/`, replace bare `docs/`, `log/`, `decisions/`, `epics/` references with `.workflow/docs/`, `.workflow/log/`, `.workflow/decisions/`, `.workflow/epics/`. Do NOT change references to plugin files like `conventions/`, `templates/`, `agents/`, `skills/`, `commands/` — those are plugin paths, not `.workflow/` paths.

Affected patterns:
- `docs/architecture.md` → `.workflow/docs/architecture.md`
- `docs/status.md` → `.workflow/docs/status.md`
- `docs/security.md` → `.workflow/docs/security.md`
- `docs/testing.md` → `.workflow/docs/testing.md`
- `docs/marketing.md` → `.workflow/docs/marketing.md`
- `docs/eprd.md` → `.workflow/docs/eprd.md`
- `docs/timeline.md` → `.workflow/docs/timeline.md`
- `log/{ROLE}/` → `.workflow/log/{role}/`
- `log/master/` → `.workflow/log/master/`
- `decisions/` → `.workflow/decisions/`
- `epics/` → `.workflow/epics/`
- `registry.md` → `.workflow/registry.md`
- `config.md` → `.workflow/config.md`

Also fix in: `conventions/roles.md`, `conventions/logging.md`, `conventions/decision-records.md`, `conventions/file-structure.md`, `conventions/documentation.md`, `conventions/timeline.md`

**Step 2: C2 — Add workflow-developer to roles.md**

In `conventions/roles.md`, add after the CONS section:

```markdown
---

### WFDEV — Workflow Developer

**Responsibilities:**
- Develop and maintain the ago: plugin itself
- Implement skills, commands, and agent definitions
- Test workflow system on real projects
- Maintain conventions and templates

**Does NOT:**
- Perform project-specific work
- Make product/architecture decisions for target projects

**Artifacts:** Plugin updates, skill implementations, convention changes
```

Update role count in:
- `CLAUDE.md`: "12 role definitions" → "13 role definitions (12 project + 1 meta)"
- `README.md`: "12 Agent Roles" → "13 Agent Roles" and "12 specialized agent roles" → "13 agent roles (12 project + 1 meta)"
- `conventions/roles.md`: add WFDEV to the Role Registry table

**Step 3: C3 — Add evaluate-quality-gate to master-session skills table**

In `master-session/instructions.md`, add to the Available Skills table:

```markdown
| `ago:evaluate-quality-gate` | During consolidation, assess quality tiers |
```

**Step 4: H1 — Remove stale TODO from quality-gates.md**

In `conventions/quality-gates.md`, delete line 48:
```
> TODO: Implement quality gate evaluation as a skill (`ago:evaluate-quality-gate`) in Iteration 2.
```

**Step 5: H2/P04 — Lowercase log dirs everywhere**

Search all files for uppercase log paths and make lowercase:
- `log/ARCH/` → `log/arch/`
- `log/DEV/` → `log/dev/`
- `log/QAL/` → `log/qal/`
- etc.
- `log/{ROLE}/` → `log/{role}/` (template references)

Files: `conventions/logging.md`, `conventions/naming.md`, all agent files, `skills/write-raw-log/SKILL.md`, `memory/AGENTS.md`

**Step 6: H3 + H4 — Deduplicate quality gates, fix review hierarchy**

In `master-session/instructions.md`:
- Replace the "Quality Gate Evaluation" section (lines 28-66) with:
```markdown
## Quality Gate Evaluation (CONSOLIDATE Step)

See `conventions/quality-gates.md` for the full quality tier definitions (T1-T4), review hierarchy, anti-hallucination checks, and evaluation process. This is the canonical source.

During consolidation, invoke `ago:evaluate-quality-gate` for each agent output.
```

In `CLAUDE.md`:
- Replace the quality tiers/review hierarchy lines with:
```markdown
Quality gates: See `conventions/quality-gates.md` (canonical source for T1-T4 tiers and review hierarchy)
```

In `README.md`:
- Replace the review hierarchy line with:
```markdown
- **Quality Gates** — T1-T4 tier system (see `conventions/quality-gates.md`)
```

**Step 7: H5 — Fix convention file count in MEMORY.md**

In `memory/MEMORY.md`, fix the conventions line to list actual count: 9 files.

**Step 8: P05 — Document short ID as canonical**

In `conventions/naming.md`, add under Tasks section:

```markdown
The canonical task identifier is the short numeric ID (`T001`). The full directory slug (`T001-DEV-feature-name`) is derived. In frontmatter, use `id: T001`. In wikilinks, use the full slug: `[[T001-DEV-feature-name/task.md]]`.
```

**Step 9: P06 — Fix lifecycle transitions**

In `conventions/task-lifecycle.md`, ensure the transitions table includes:
- `blocked → planned`
- `blocked → in_progress`

And add a note: "Only MASTER can move a task to `done` (review → done)."

In `skills/update-task-status/SKILL.md`, ensure Valid Transitions lists:
```
blocked → planned | in_progress
```

(Already correct — just verify.)

**Step 10: P09/M2 — Narrow frontmatter rule**

In `CLAUDE.md`, change:
```
- All files in `.workflow/` use YAML frontmatter
```
to:
```
- Entity docs in `.workflow/` use YAML frontmatter (config, epic, task, decision, project docs, registry). Log files are exempt.
```

Same in `memory/AGENTS.md`.

**Step 11: P10 — Standardize command syntax**

Search all files for `/ago:` and replace with `ago:`. Check commands/*.md, README.md, CLAUDE.md, all agent files.

**Step 12: P13 — Restrict DOC scope**

In `agents/documentation.md`, update boundaries to clarify DOC only edits `.workflow/docs/` files, not repo-level docs (README, CONTRIBUTING, etc.).

**Step 13: P14 — Document MASTER logging rule**

In `conventions/logging.md`, add under Rules:

```markdown
6. When MASTER performs a status transition (e.g., review → done), the entry goes in `log/master/` only — not in the agent's role log.
```

**Step 14: P15 — Clarify ago:clarify creates task.md**

In `commands/clarify.md`, update step list:

```markdown
## What This Command Does
1. Takes a task description or feature request from user
2. Clarifies requirements (scope, motivation, acceptance criteria)
3. Identifies which roles are needed
4. Decomposes into subtasks with role assignments
5. User approves the decomposition
6. Creates task.md files in .workflow/epics/ (invokes `ago:create-task`)
7. Updates registry (invokes `ago:update-registry`)

Does NOT launch agents — use `ago:execute` for that.
```

**Step 15: P16 — Remove hardcoded path from config template**

In `templates/config.md`, remove the `conventions_repo: ~/dev/claude-workflow` line.

**Step 16: P17 — Document wikilink convention**

In `conventions/documentation.md` (if exists) or `conventions/naming.md`, add:

```markdown
## Wikilinks

Wikilinks use full slug and point to the file, not the directory:
- Tasks: `[[T001-DEV-feature-name/task.md]]`
- Decisions: `[[ARCH-E01-T003-onnx-vs-tflite.md]]`
- Project docs: `[[eprd.md]]`, `[[architecture.md]]`
```

**Step 17: M3 — Fix agent-log-entry template**

In `templates/agent-log-entry.md`, change:
```
**Status:** {New task status: in_progress | review | blocked}
```
to:
```
**Status:** {New task status: in_progress | review | blocked | planned}
```

Add a note: "Agents cannot set `done` — only MASTER can transition to `done`."

**Step 18: M4 — Create timeline template**

Create `templates/project-docs/timeline.md`:

```markdown
---
owner: PROJ
updated: {YYYY-MM-DD}
---

# Project Timeline

> Auto-generated by `ago:generate-timeline`. Do not edit manually.

{Mermaid Gantt chart will be inserted here by the skill.}
```

**Step 19: Commit**

```
git add -A
git commit -m "fix: resolve all AUDIT.md consistency issues (C1-C3, H1-H5, M2-M5, P03-P17)"
```

---

### Task 1: Rewrite `ago:write-raw-log` SKILL.md

**Files:**
- Modify: `skills/write-raw-log/SKILL.md`

**Step 1: Write the executable skill**

Rewrite `skills/write-raw-log/SKILL.md` with:

```markdown
---
name: ago:write-raw-log
description: Append a log entry to the current role's raw log. Invoke after completing any significant work on a task.
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
| new_status | Yes | Task status after this work: `in_progress`, `review`, `blocked`, `planned` |

## Instructions

1. Determine today's date in `YYYY-MM-DD` format
2. Determine current time in `HH:MM` format
3. Ensure directory exists: `.workflow/log/{role}/`
   - If it doesn't exist, create it
4. Open or create file: `.workflow/log/{role}/{YYYY-MM-DD}.md`
   - If file is new, add a heading: `# {YYYY-MM-DD}`
   - If file exists, append to it
5. Append this entry:

```
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
```

**Step 2: Commit**

```
git add skills/write-raw-log/SKILL.md
git commit -m "feat: make ago:write-raw-log executable"
```

---

### Task 2: Rewrite `ago:create-task` SKILL.md

**Files:**
- Modify: `skills/create-task/SKILL.md`

**Step 1: Write the executable skill**

Rewrite `skills/create-task/SKILL.md` with:

```markdown
---
name: ago:create-task
description: Create a new task with proper directory structure, frontmatter, and registry entry. Invoke during task decomposition (ago:clarify).
version: 0.2.0
---

# ago:create-task

Create a task directory, task.md file, and update the registry.

## When to Use

Invoke during the DECOMPOSE/APPROVE phase, typically called by `ago:clarify` after the user approves the task breakdown.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| epic_id | Yes | Epic this task belongs to (e.g., `E01`) |
| role | Yes | Role that will execute (e.g., `dev`, `arch`) |
| title | Yes | Short task title (2-5 words, kebab-case for slug) |
| description | Yes | What needs to be done and why |
| priority | Yes | `critical`, `high`, `medium`, `low` |
| acceptance_criteria | Yes | List of criteria that define "done" |
| depends_on | No | List of task IDs this depends on (e.g., `[T001, T002]`) |
| blocks | No | List of task IDs this blocks |

## Instructions

1. **Read config:** Open `.workflow/config.md` and read the `task_counter` from frontmatter
2. **Increment counter:** New task number = `task_counter + 1`
3. **Update config:** Write the new `task_counter` value back to `.workflow/config.md` frontmatter
4. **Format IDs:**
   - Short ID: `T{NNN}` (zero-padded to 3 digits, e.g., `T001`)
   - Directory slug: `T{NNN}-{ROLE}-{title-in-kebab-case}` (role uppercase in slug)
5. **Create directory:** `.workflow/epics/{epic_id}/tasks/{slug}/`
6. **Create artifacts dir:** `.workflow/epics/{epic_id}/tasks/{slug}/artifacts/`
7. **Create task.md** with this content:

```
---
id: {short_id}
role: {ROLE}
title: {title}
epic: {epic_id}
status: backlog
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
priority: {priority}
depends_on: {depends_on or []}
blocks: {blocks or []}
related_decisions: []
---

## Description

{description}

## Acceptance Criteria

- [ ] {criterion 1}
- [ ] {criterion 2}
...

## Artifacts

{Links to role reports will be added as work progresses}

## Notes

```

8. **Update registry:** Invoke `ago:update-registry` or manually add a row to the Active Tasks table in `.workflow/registry.md`
9. **Return:** the short ID (`T001`) and full path to the created task.md

## Validation

- Task directory exists at expected path
- task.md has valid YAML frontmatter
- `task_counter` in config.md was incremented
- Registry has a new row for this task

## Error Handling

- If `.workflow/config.md` doesn't exist: STOP — project not initialized
- If the epic directory doesn't exist (`.workflow/epics/{epic_id}/`): Create it with an `epic.md` stub
- If `task_counter` can't be read: STOP — config.md may be corrupt
```

**Step 2: Commit**

```
git add skills/create-task/SKILL.md
git commit -m "feat: make ago:create-task executable"
```

---

### Task 3: Rewrite `ago:update-task-status` SKILL.md

**Files:**
- Modify: `skills/update-task-status/SKILL.md`

**Step 1: Write the executable skill**

Rewrite `skills/update-task-status/SKILL.md` with:

```markdown
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
```

**Step 2: Commit**

```
git add skills/update-task-status/SKILL.md
git commit -m "feat: make ago:update-task-status executable"
```

---

### Task 4: Rewrite `ago:create-decision-record` SKILL.md

**Files:**
- Modify: `skills/create-decision-record/SKILL.md`

**Step 1: Write the executable skill**

Rewrite `skills/create-decision-record/SKILL.md` with:

```markdown
---
name: ago:create-decision-record
description: Create a formal Decision Record from agent log findings. Invoke during consolidation when a significant decision is found.
version: 0.2.0
---

# ago:create-decision-record

Create a DR file in `.workflow/decisions/` and link it to the originating task.

## When to Use

During consolidation (CONSOLIDATE step), when `ago:consolidate-logs` finds a significant decision in an agent's log that warrants formal documentation.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| role | Yes | Role that made the decision (uppercase, e.g., `ARCH`) |
| epic_id | Yes | Epic ID (e.g., `E01`) |
| task_id | Yes | Short task ID (e.g., `T003`) |
| description | Yes | Short kebab-case description (e.g., `onnx-vs-tflite`) |
| context | Yes | Why this decision needed to be made |
| options | Yes | List of options considered, each with pros/cons |
| decision | Yes | What was decided and why |
| consequences | Yes | Impact on the project |

## Instructions

1. **Build filename:** `{ROLE}-{EPIC}-{TASK}-{description}.md`
   - Example: `ARCH-E01-T003-onnx-vs-tflite.md`
2. **Create file** at `.workflow/decisions/{filename}` with this content:

```
---
id: {ROLE}-{EPIC}-{TASK}-{description}
role: {ROLE}
epic: {EPIC}
task: {TASK}
status: proposed
date: {YYYY-MM-DD}
supersedes:
---

## Context

{context}

## Options Considered

### Option 1: {name}
- Pros: {advantages}
- Cons: {disadvantages}

### Option 2: {name}
- Pros: {advantages}
- Cons: {disadvantages}

## Decision

{decision}

## Consequences

{consequences}
```

3. **Link to task:** Find the task.md for {task_id}, add the DR id to the `related_decisions` list in frontmatter
4. **Update registry:** Add a row to the Decision Records table in `.workflow/registry.md`:
   ```
   | {id} | proposed | {ROLE} | {EPIC} | {TASK} | {YYYY-MM-DD} |
   ```

## Validation

- DR file exists at `.workflow/decisions/{filename}`
- DR has valid YAML frontmatter with `status: proposed`
- Task.md `related_decisions` includes the DR id
- Registry has a new row

## Error Handling

- If `.workflow/decisions/` doesn't exist: Create it
- If task.md not found: Create the DR anyway, log a warning about missing task link
- If a DR with the same filename already exists: Append a numeric suffix (e.g., `-2`)
```

**Step 2: Commit**

```
git add skills/create-decision-record/SKILL.md
git commit -m "feat: make ago:create-decision-record executable"
```

---

### Task 5: Rewrite `ago:update-registry` SKILL.md

**Files:**
- Modify: `skills/update-registry/SKILL.md`

**Step 1: Write the executable skill**

Rewrite `skills/update-registry/SKILL.md` with:

```markdown
---
name: ago:update-registry
description: Rebuild the registry.md index from the current filesystem state. Invoke after creating tasks, DRs, or changing statuses.
version: 0.2.0
---

# ago:update-registry

Scan `.workflow/` and rebuild `.workflow/registry.md` with current data.

## When to Use

After any structural change: task creation, status changes, DR creation. Can also be run periodically to ensure consistency.

## Input

No parameters required. Reads directly from filesystem.

## Instructions

1. **Scan epics:** Read all `.workflow/epics/*/epic.md` files
   - Extract: id, title, status from frontmatter
   - Count tasks per epic
2. **Scan tasks:** Read all `.workflow/epics/*/tasks/*/task.md` files
   - Extract: id, title, status, role, epic, priority from frontmatter
3. **Scan decisions:** Read all `.workflow/decisions/*.md` files
   - Extract: id, status, role, epic, task, date from frontmatter
4. **Compute summary stats:**
   - total_epics: count of epics
   - total_tasks: count of tasks
   - total_decisions: count of DRs
   - active_roles: unique roles from tasks with status != done
5. **Write `.workflow/registry.md`:**

```
---
last_updated: {YYYY-MM-DD}
total_epics: {count}
total_tasks: {count}
total_decisions: {count}
active_roles: [{list}]
---

# Registry

> Auto-updated index of all project entities. Source of truth for navigation.

## Epics

| ID | Title | Status | Tasks | Timeline |
|----|-------|--------|-------|----------|
| {id} | {title} | {status} | {count} | [[{id}/timeline.md]] |

## Active Tasks

| ID | Title | Status | Role | Epic | Priority |
|----|-------|--------|------|------|----------|
| {id} | [[{slug}/task.md]] | {status} | {role} | {epic} | {priority} |

## Decision Records

| ID | Status | Role | Epic | Task | Date |
|----|--------|------|------|------|------|
| [[{id}]] | {status} | {role} | {epic} | {task} | {date} |

## Project Documents

| Document | Owner | Last Updated |
|----------|-------|-------------|
| [[eprd.md]] | PM | {date from frontmatter or blank} |
| [[architecture.md]] | ARCH | {date} |
| [[security.md]] | SEC | {date} |
| [[testing.md]] | QAL | {date} |
| [[marketing.md]] | MKT | {date} |
| [[status.md]] | PROJ | {date} |
| [[timeline.md]] | PROJ | {date} |
```

6. **Validate wikilinks:** For each `[[...]]` in the registry, check the target file exists
   - Log warnings for broken links

## Validation

- `.workflow/registry.md` exists and has valid frontmatter
- All epics, tasks, and DRs in the filesystem appear in the registry
- Wikilinks resolve to existing files

## Error Handling

- If `.workflow/` doesn't exist: STOP — project not initialized
- If no epics exist: Write a registry with empty tables
- If a task.md has invalid frontmatter: Skip it, log a warning
```

**Step 2: Commit**

```
git add skills/update-registry/SKILL.md
git commit -m "feat: make ago:update-registry executable"
```

---

### Task 6: Rewrite `ago:generate-timeline` SKILL.md

**Files:**
- Modify: `skills/generate-timeline/SKILL.md`

**Step 1: Write the executable skill**

Rewrite `skills/generate-timeline/SKILL.md` with:

```markdown
---
name: ago:generate-timeline
description: Generate Mermaid Gantt charts from task metadata at project and epic levels. Invoke after status changes or via ago:timeline command.
version: 0.2.0
---

# ago:generate-timeline

Create or update Mermaid Gantt chart files from task frontmatter.

## When to Use

After task status changes, or when the user invokes `ago:timeline`. Generates both epic-level and project-level timelines.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| epic_id | No | If provided, only regenerate this epic's timeline. Otherwise, regenerate all. |

## Status-to-Tag Mapping

| Task Status | Mermaid Tag |
|-------------|-------------|
| done | `done` |
| in_progress | `active` |
| blocked | `crit` |
| planned | (no tag) |
| backlog | (not shown — excluded from chart) |

## Instructions

### Epic-Level Timeline

For each epic (or the specified epic):

1. Read all `.workflow/epics/{epic_id}/tasks/*/task.md` files
2. For each task, extract from frontmatter: `id`, `title`, `role`, `status`, `depends_on`, `created`, `updated`
3. Skip tasks with status `backlog`
4. Build Mermaid Gantt block:

```
---
owner: PROJ
updated: {YYYY-MM-DD}
---

# {Epic Title} Timeline

> Auto-generated by `ago:generate-timeline`. Do not edit manually.

` ``mermaid
gantt
    dateFormat YYYY-MM-DD
    axisFormat %Y-%m-%d
    tickInterval 1week
    todayMarker stroke-width:3px,stroke:#f00

    section {Epic Title}
    {id}-{ROLE} {title}  :{tag}, {id}, {start_date_or_after}, {duration}
` ``
```

- `start_date_or_after`: Use `created` date if no dependencies. Use `after {dep_id}` if `depends_on` is set.
- `duration`: Estimate from `created` to `updated` dates, minimum `1d`. If no good estimate, use `7d`.
- `tag`: Map from status (see table above). Omit for planned.

5. Write to `.workflow/epics/{epic_id}/timeline.md`

### Project-Level Timeline

1. Read all `.workflow/epics/*/epic.md` files
2. For each epic, determine:
   - Start date: earliest task `created` date
   - End date: latest task `updated` date
   - Status: if all tasks done → done; if any in_progress → active; if any blocked → crit
3. Generate project-level Gantt with epics as sections
4. Add milestone for each epic completion
5. Write to `.workflow/docs/timeline.md`

## Validation

- Timeline files exist at expected paths
- Mermaid syntax is valid (sections, tasks, tags)
- All non-backlog tasks appear in their epic timeline

## Error Handling

- If no tasks exist in an epic: Write a timeline with an empty section
- If task has no `created` date: Use today's date
- If circular dependencies in `depends_on`: Log warning, use `created` date instead of `after`
```

**Step 2: Commit**

```
git add skills/generate-timeline/SKILL.md
git commit -m "feat: make ago:generate-timeline executable"
```

---

### Task 7: Rewrite `ago:consolidate-logs` SKILL.md

**Files:**
- Modify: `skills/consolidate-logs/SKILL.md`

**Step 1: Write the executable skill**

Rewrite `skills/consolidate-logs/SKILL.md` with:

```markdown
---
name: ago:consolidate-logs
description: Read agent raw logs, extract significant decisions into DRs, flag conflicts. Invoke after agents complete work (CONSOLIDATE step).
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

```
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
```

**Step 2: Commit**

```
git add skills/consolidate-logs/SKILL.md
git commit -m "feat: make ago:consolidate-logs executable"
```

---

### Task 8: Rewrite `ago:validate-docs-integrity` SKILL.md

**Files:**
- Modify: `skills/validate-docs-integrity/SKILL.md`

**Step 1: Write the executable skill**

Rewrite `skills/validate-docs-integrity/SKILL.md` with:

```markdown
---
name: ago:validate-docs-integrity
description: Check documentation integrity — wikilinks, references, cross-document consistency. Invoke periodically or after major changes.
version: 0.2.0
---

# ago:validate-docs-integrity

Validate all cross-references and consistency within `.workflow/`.

## When to Use

Periodically, after major changes, or when suspicious inconsistencies are noticed. DOC role scope is limited to `.workflow/docs/` — repo-level docs (README, etc.) are out of scope.

## Input

No parameters required. Scans the entire `.workflow/` directory.

## Checks

### 1. Wikilink Validation
- Find all `[[...]]` patterns in `.workflow/` files
- Wikilinks must use full slug format: `[[T001-DEV-feature/task.md]]`
- Verify each target file exists
- Severity: **Error** if target doesn't exist

### 2. Task Reference Validation
- All task IDs mentioned in any `.workflow/` file must have a corresponding directory
- Pattern: `T{NNN}` should match `.workflow/epics/*/tasks/T{NNN}-*/`
- Severity: **Error** if directory doesn't exist

### 3. DR Reference Validation
- All DR IDs in task frontmatter (`related_decisions`) must exist in `.workflow/decisions/`
- Severity: **Error** if file doesn't exist

### 4. Status Consistency
- For each task in `.workflow/registry.md`, compare status with actual `task.md` frontmatter
- They must match
- Severity: **Error** if mismatch

### 5. Orphan Detection
- Files in `artifacts/` directories not linked from any task.md
- DR files not referenced by any task
- Severity: **Warning**

### 6. Frontmatter Validation
- Entity docs (config, epic, task, decision, project docs, registry) MUST have YAML frontmatter
- Log files are exempt
- Required fields per type:
  - Task: id, role, title, epic, status, created, updated, priority
  - DR: id, role, epic, task, status, date
  - Epic: (at minimum id, title, status)
  - Config: project, task_counter
  - Registry: last_updated
- Severity: **Error** for missing required fields, **Warning** for missing optional fields

### 7. Counter Validation
- `task_counter` in `.workflow/config.md` must be >= the highest task number found
- Severity: **Error** if counter is lower

## Instructions

1. Run all 7 checks in order
2. Collect results into a report

## Output

Generate a report:

```markdown
# Documentation Integrity Report

**Date:** {YYYY-MM-DD}
**Total entities checked:** {count}
**Errors:** {count}
**Warnings:** {count}

## Errors

| # | Check | File | Issue |
|---|-------|------|-------|
| 1 | Wikilink | .workflow/registry.md | [[T001-DEV-foo/task.md]] target not found |

## Warnings

| # | Check | File | Issue |
|---|-------|------|-------|
| 1 | Orphan | .workflow/decisions/ARCH-E01-T003-foo.md | Not referenced by any task |

## Summary

{Brief interpretation of results}
```

3. Output the report to the user (do not write it to a file unless asked)

## Error Handling

- If `.workflow/` doesn't exist: STOP — project not initialized
- If a file can't be parsed: Skip it, add a warning to the report
```

**Step 2: Commit**

```
git add skills/validate-docs-integrity/SKILL.md
git commit -m "feat: make ago:validate-docs-integrity executable"
```

---

### Task 9: Rewrite `ago:evaluate-quality-gate` SKILL.md

**Files:**
- Modify: `skills/evaluate-quality-gate/SKILL.md`

**Step 1: Write the executable skill**

Rewrite `skills/evaluate-quality-gate/SKILL.md` with:

```markdown
---
name: ago:evaluate-quality-gate
description: Evaluate agent output for quality and hallucination risk, assign T1-T4 tiers, trigger senior review. Invoke during consolidation for each completed task.
version: 0.2.0
---

# ago:evaluate-quality-gate

Assess agent decisions and artifacts for quality, assign tiers, trigger reviews.

## When to Use

During the CONSOLIDATE step, for each agent output. Called by MASTER or CONS. References `conventions/quality-gates.md` as the canonical source for tier definitions and review hierarchy.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| task_id | Yes | Short task ID (e.g., `T001`) |
| role | Yes | Role that produced the output (e.g., `dev`) |

## Instructions

1. **Read the agent's work:** Find log entries for {task_id} in `.workflow/log/{role}/`
2. **Read artifacts:** Check `.workflow/epics/*/tasks/T{NNN}-*/artifacts/` for deliverables
3. **For each decision or artifact, run these checks:**

### Anti-Hallucination Checks

| Check | Question | Pass → | Fail → |
|-------|----------|--------|--------|
| Code reference | Does it reference real files/functions that exist? | +T1 evidence | +T3/T4 evidence |
| Consistency | Does it align with existing DRs and project docs? | +T1 evidence | +T3 evidence |
| Scope | Is the agent operating within role boundaries? | neutral | +T4 evidence |
| Context | Does output reflect actual project state? | +T1 evidence | +T4 evidence |

4. **Assign tier based on evidence:**
   - All checks pass, grounded in code/docs → **T1 (Verified)**
   - Most checks pass, minor assumptions stated → **T2 (Probable)**
   - Some checks fail, assumptions not validated → **T3 (Speculative)**
   - Multiple checks fail, no evidence in codebase → **T4 (Ungrounded)**

5. **Determine reviewer (for T3/T4):** Using the review hierarchy from `conventions/quality-gates.md`:
   - DEV output → reviewed by ARCH
   - QAD output → reviewed by QAL
   - MKT output → reviewed by PM
   - DEV (security) → reviewed by SEC
   - CICD output → reviewed by ARCH
   - DEV (frontend) → reviewed by PM + ARCH

6. **Log the evaluation** in `.workflow/log/master/{date}.md`:

```
## {HH:MM} — Quality Gate: {task_id}

**Role:** {role}
**Items evaluated:** {count}

| Item | Tier | Evidence | Reviewer | Recommendation |
|------|------|----------|----------|----------------|
| {description} | T{n} | {summary} | {reviewer or "—"} | {accept/review/reject/redo} |

**Overall:** {T1/T2 → ready for acceptance | T3/T4 → requires senior review}
```

7. **Actions by tier:**
   - T1: Mark as ready for DR acceptance
   - T2: Mark as ready, flag for optional senior review
   - T3: Flag for mandatory senior review, do NOT accept until reviewed
   - T4: Reject. Flag for redo by the original agent.

## Validation

- Every decision/artifact from the task was evaluated
- T3/T4 items have a designated reviewer
- Evaluation was logged in master log

## Error Handling

- If no log entries found for task: Report "No agent logs found for {task_id}" — cannot evaluate
- If artifacts directory is empty: Evaluate based on log entries only
- If role not in review hierarchy: Default reviewer is MASTER
```

**Step 2: Commit**

```
git add skills/evaluate-quality-gate/SKILL.md
git commit -m "feat: make ago:evaluate-quality-gate executable"
```

---

### Task 10: Final verification and commit

**Step 1: Verify all 9 skills have the executable format**

Check each SKILL.md has:
- [ ] Frontmatter with name, description, version
- [ ] Input parameters table
- [ ] Step-by-step instructions with exact paths
- [ ] Validation section
- [ ] Error handling section

**Step 2: Update MEMORY.md**

Update `memory/MEMORY.md` to reflect skills are now executable (not stubs).

**Step 3: Update README.md roadmap**

Mark "Executable skills" as Done in Phase 2 table.

**Step 4: Final commit**

```
git add -A
git commit -m "docs: mark executable skills as complete in roadmap"
```
