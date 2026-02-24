# AGENTS.md — Agent Workflow System

This repository contains universal conventions for AI agent orchestration.

## For Master Session

When operating as a master session, read `master-session/instructions.md` first.
Follow the session lifecycle: INIT → BRIEF → COLLABORATE → DECOMPOSE → APPROVE → DELEGATE → MONITOR → CONSOLIDATE → REVIEW → UPDATE.

## For Role Agents

Each agent role is defined in `agents/{role-name}.md`. Follow your role definition strictly.
Always invoke the `write-raw-log` skill after completing work.

## Key Rules

1. Follow your role definition in `agents/{your-role}.md`
2. Log all work to `.workflow/log/{ROLE}/{YYYY-MM-DD}.md`
3. Use templates from `templates/` when creating new files
4. Follow naming conventions from `conventions/naming.md`
5. Never modify files outside your role's scope
6. All task IDs are globally unique (strict increment)
7. Decision Records are generated from raw logs, not written by agents directly
8. Every file in `.workflow/` uses YAML frontmatter
9. Wikilinks (`[[...]]`) for cross-references
10. Mermaid for timeline visualization

## File Locations

- Conventions: `conventions/`
- Templates: `templates/`
- Agent definitions: `agents/`
- Skills: `skills/`
- Commands: `commands/`

## Conventions

Read these files for the full rule set:
- `conventions/roles.md` — Role definitions and boundaries
- `conventions/task-lifecycle.md` — Task statuses and transitions
- `conventions/naming.md` — File and entity naming
- `conventions/file-structure.md` — Project .workflow/ structure
- `conventions/logging.md` — Logging format and rules
- `conventions/quality-gates.md` — T1-T4 quality tiers

## Commands

- `/status` — Show project status
- `/delegate` — Decompose and delegate task
- `/review` — Consolidate and review agent work
- `/timeline` — Regenerate Gantt charts
- `/collaborative` — Switch to collaborative mode (default)
- `/autonomous` — Switch to autonomous mode (TODO)
