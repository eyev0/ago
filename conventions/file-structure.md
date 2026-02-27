# File Structure Convention

Every project using the agent workflow system contains a `.workflow/` directory at the project root.

## Standard Structure

```
.workflow/
├── config.md          <- Project configuration
├── registry.md        <- Index of all entities
├── docs/              <- Living project documents
├── epics/             <- Epic directories with tasks
├── decisions/         <- All Decision Records
└── log/               <- Session and agent logs
```

## config.md

Contains project metadata:
- Project name and description
- List of active epics
- Active roles for this project
- Current task counter (for global increment)
- Links to conventions repo

## registry.md

Single-page index with links to:
- All epics (with status)
- All active tasks (with status, assignee)
- All Decision Records (with status)
- All project documents

Updated by MASTER or DOC role after changes.

## docs/

Living documents owned by specific roles. Each has `owner` in frontmatter.
Updated continuously as the project evolves.

See `conventions/naming.md` for fixed filenames.

## epics/

One directory per epic. Each contains:
- `epic.md` — Epic description, goals, acceptance criteria
- `timeline.md` — Mermaid Gantt for this epic
- `tasks/` — Task directories

## epics/*/tasks/

One directory per task. Naming: `T{NNN}-{ROLE}-{short-name}/`

Each contains:
- `task.md` — Task definition with YAML frontmatter
- `artifacts/` — Reports and deliverables from any role

## decisions/

Flat directory. All Decision Records from all roles and tasks.
Naming provides full context: `{ROLE}-{EPIC}-{TASK}-{description}.md`

## log/

Append-only logs. One directory per role + master.
Daily files: `{YYYY-MM-DD}.md`

Verification logs (created by SubagentStop hooks):
- `verify-{task_id}-{attempt}.md` — deterministic artifact/criteria check (e.g., `verify-T001-1.md`)
- `eval-{task_id}-{attempt}.md` — LLM evaluation (e.g., `eval-T001-1.md`)
