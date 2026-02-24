# CLAUDE.md — Agent Workflow System

This repository contains universal conventions for AI agent orchestration.

## For Master Session

When operating as a master session, read `master-session/instructions.md` first.
Follow the session lifecycle: INIT → BRIEF → COLLABORATE → DECOMPOSE → APPROVE → DELEGATE → MONITOR → CONSOLIDATE → REVIEW → UPDATE.

## For Role Agents

Each agent role is defined in `agents/{role-name}.md`. Follow your role definition strictly.
Always invoke the `write-raw-log` skill after completing work.

## Key Conventions

- All task IDs are globally unique (strict increment)
- Decision Records are generated from raw logs, not written by agents directly
- Every file in .workflow/ uses YAML frontmatter
- Wikilinks (`[[...]]`) for cross-references
- Mermaid for timeline visualization

## File Locations

- Conventions: `conventions/`
- Templates: `templates/`
- Agent definitions: `agents/`
- Skills: `skills/`
- Commands: `commands/`

## Commands

- `/status` — Show project status
- `/delegate` — Decompose and delegate task
- `/review` — Consolidate and review agent work
- `/timeline` — Regenerate Gantt charts
- `/collaborative` — Switch to collaborative mode (default)
- `/autonomous` — Switch to autonomous mode (TODO)
