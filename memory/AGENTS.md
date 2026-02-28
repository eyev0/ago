# AGENTS.md — Agent Workflow System

This repository is a Claude Code plugin (`ago:`) for agentic orchestration.

## For Master Session

The master session agent definition is `agents/master-session.md` — it is self-contained with lifecycle, quality gates, and collaborative workflow.
Follow the session lifecycle: INIT → BRIEF → COLLABORATE → DECOMPOSE → APPROVE → DELEGATE → MONITOR → CONSOLIDATE → REVIEW → UPDATE.

## For Role Agents

Before starting any work:
0. Read `.workflow/brief.md` for project context, decision philosophy, and role priorities (if it exists)
1. Read `.workflow/roles/{your-role}.md` for your project-specific mandate and focus areas (if it exists)
2. Follow your role definition in `agents/{your-role}.md`

Always invoke the `ago:write-raw-log` skill after completing work.

## Key Rules

1. Follow your role definition in `agents/{your-role}.md`
2. Log all work to `.workflow/log/{role}/{YYYY-MM-DD}.md`
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
- Skills: `skills/*/SKILL.md`
- Commands: `commands/`
- Plugin manifest: `.claude-plugin/plugin.json`

## Conventions

Read these files for the full rule set:
- `conventions/roles.md` — Role definitions and boundaries
- `conventions/task-lifecycle.md` — Task statuses and transitions
- `conventions/naming.md` — File and entity naming
- `conventions/file-structure.md` — Project .workflow/ structure
- `conventions/logging.md` — Logging format and rules
- `conventions/quality-gates.md` — T1-T4 quality tiers

## Commands

- `ago:status` — Show project status
- `ago:readiness` — Assess project readiness and bootstrap `.workflow/` from existing docs
- `ago:bootstrap` — Capture operational context: product brief, role mandates, decision philosophy
- `ago:clarify` — Clarify requirements and decompose into tasks
- `ago:execute` — Launch agents for planned tasks
- `ago:review` — Consolidate and review agent work
- `ago:timeline` — Regenerate Gantt charts
