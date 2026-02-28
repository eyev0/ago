---
description: Show current project/epic status with active tasks and blockers
argument-hint: "[epic-id]"
---

# ago:status

Display a read-only status report for the project or a specific epic. You MUST NOT modify any files.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `$1` | No | Epic ID to filter by (e.g., `E01`). If omitted, show full project status. |

## Instructions

### Step 1 — Verify project initialization

Check that `.workflow/config.md` exists. If it does not exist, report:

> This project has not been initialized with a `.workflow/` directory. Run `ago:readiness` first.

Stop here if the file is missing.

### Step 2 — Read project sources

Read these files (skip any that don't exist and note their absence):

1. `.workflow/config.md` — project name, description, active epics list, active roles
2. `.workflow/registry.md` — entity index (epics, tasks, decision records, project documents)
3. `.workflow/docs/status.md` — current phase, active work, blockers, recently completed

### Step 3 — Gather task details

If the registry lists epics and tasks, read the relevant epic and task files to get current frontmatter status values:

- **If `$1` is provided (epic filter):** Read `.workflow/epics/{$1}/epic.md` and all `task.md` files under `.workflow/epics/{$1}/tasks/*/task.md`. If the epic directory does not exist, report "Epic {$1} not found in `.workflow/epics/`" and stop.
- **If `$1` is omitted (full project):** Read all epic files at `.workflow/epics/*/epic.md` and all task files at `.workflow/epics/*/tasks/*/task.md`.

For each task, extract from its YAML frontmatter: `id`, `title`, `status`, `role`, `epic`, `priority`, `depends_on`, `blocks`.

### Step 4 — Compile the status report

Present the report using the format below. Adapt sections based on what data is available — omit empty sections rather than showing blank tables.

#### 4a — Project header

```
# Project Status: {project name}

**Phase:** {current phase from docs/status.md, or "Unknown" if not available}
**Active Roles:** {comma-separated role list from config.md}
```

If `$1` was provided, add: `**Filtered to:** {$1} — {epic title}`

#### 4b — Epic overview

Show all epics (or the filtered epic) with a progress summary. For each epic, count tasks by status.

```
## Epics

| Epic | Title | Status | Done | In Progress | Blocked | Review | Planned | Backlog |
|------|-------|--------|------|-------------|---------|--------|---------|---------|
| E01  | ...   | ...    | 3    | 2           | 1       | 0      | 1       | 0       |
```

#### 4c — Tasks requiring attention

Group tasks into sections by priority. Show these sections in this order, skipping any that have no tasks:

**Blocked tasks** — these need resolution:

```
## Blocked

| Task | Title | Role | Epic | Blocked By | Priority |
|------|-------|------|------|------------|----------|
```

For blocked tasks, check the `depends_on` field and the task's Notes section for blocker context. Include that context in the "Blocked By" column.

**In-progress tasks** — currently active work:

```
## In Progress

| Task | Title | Role | Epic | Priority |
|------|-------|------|------|----------|
```

**Tasks in review** — awaiting validation:

```
## In Review

| Task | Title | Role | Epic | Priority |
|------|-------|------|------|----------|
```

**Planned tasks** — ready to start:

```
## Planned

| Task | Title | Role | Epic | Priority | Depends On |
|------|-------|------|------|----------|------------|
```

#### 4d — Recent completions

List tasks with `status: done`, most recently updated first. Show up to 10.

```
## Recently Completed

| Task | Title | Role | Epic |
|------|-------|------|------|
```

If no tasks are done, omit this section.

#### 4e — Blockers summary

If any blocked tasks exist, provide a plain-text summary of each blocker and what needs to happen to resolve it. Pull context from the task's `depends_on` field, Notes section, and any related entries in `.workflow/docs/status.md`.

```
## Blockers

- **T003** (DEV): Blocked by T001 (ARCH) which is still in review. Resolution: complete ARCH review of T001.
- **T007** (QAD): Blocked by missing test environment. Resolution: CICD to provision staging.
```

### Step 5 — Handle edge cases

- **No epics exist:** Report "No epics found. The project has been initialized but no work has been planned yet."
- **No tasks exist:** Report "No tasks found. Use `ago:clarify` to decompose work into tasks."
- **Registry is empty but epic directories exist:** Read epic directories directly — the registry may be out of date. Note this in the report: "Note: registry.md appears out of date. Status was gathered directly from epic/task files."
- **Files have missing or malformed frontmatter:** Skip them and note at the bottom: "Warning: Could not parse {filename} — missing or malformed frontmatter."

## Reminders

- This is a **read-only** command. Do not create, modify, or delete any files.
- Use data from YAML frontmatter as the source of truth for task/epic status, not prose sections.
- When the registry and the actual task files disagree, trust the task files.
