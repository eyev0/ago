# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Claude Code plugin (`ago:`) for agentic orchestration. All markdown, no code.

### Install

From GitHub:
```
/plugin marketplace add eyev0/claude-workflow
/plugin install ago@claude-workflow
```

From a local clone:
```
/plugin marketplace add ./path/to/claude-workflow
/plugin install ago@claude-workflow
```

First-time setup in target project: `ago:readiness` → `ago:bootstrap` → `ago:clarify`

## Architecture

The system has two sides:
1. **This repo (plugin)** — conventions, templates, agent definitions, skills, commands
2. **Target projects** — install this plugin; each gets a `.workflow/` directory

Session lifecycle: INIT → BRIEF → COLLABORATE → DECOMPOSE → APPROVE → DELEGATE → MONITOR → CONSOLIDATE → REVIEW → UPDATE

Quality gates: See conventions/quality-gates.md (canonical source for T1-T4 tiers and review hierarchy)

Verification: SubagentStop hooks auto-check agent work against acceptance criteria (see hooks/hooks.json)

Superpowers: ago:clarify and ago:execute optionally leverage superpowers skills when available

## Commands

| Command | Description |
|---------|-------------|
| `ago:readiness` | Scan project, recommend roles, create `.workflow/` |
| `ago:bootstrap` | Capture product brief and role mandates |
| `ago:clarify` | Clarify requirements, decompose into tasks |
| `ago:execute` | Launch agents for planned tasks |
| `ago:review` | Consolidate results, evaluate quality |
| `ago:status` | Show current project state |
| `ago:timeline` | Generate/update Mermaid Gantt timeline |

## Skills

Skills are invoked by agents during execution (not directly by users):

| Skill | Purpose |
|-------|---------|
| `ago:write-raw-log` | Log agent work |
| `ago:create-task` | Create task files |
| `ago:update-task-status` | Transition task status |
| `ago:create-decision-record` | Generate DRs |
| `ago:consolidate-logs` | Merge agent logs |
| `ago:generate-timeline` | Build Mermaid Gantt |
| `ago:update-registry` | Rebuild entity index |
| `ago:validate-docs-integrity` | Check doc references |
| `ago:evaluate-quality-gate` | Assess quality tier |

## Agent Rules

- Agents follow their role definition in `agents/{role}.md`
- Log all work to `.workflow/log/{role}/{YYYY-MM-DD}.md`
- Use templates from `templates/` when creating new files
- Never modify files outside your role's scope
- Always invoke `ago:write-raw-log` after completing work

## Editing Conventions

- Entity docs in `.workflow/` use YAML frontmatter (config, epic, task, decision, project docs, registry). Log files are exempt.
- Wikilinks (`[[...]]`) for cross-references
- Mermaid for timeline/Gantt visualization
- Task IDs are globally unique (strict increment, never reused)
- Decision Records are generated from raw logs by CONS role — agents don't write DRs directly

## Conventions Reference

- `conventions/roles.md` — Role definitions and boundaries
- `conventions/task-lifecycle.md` — Task statuses and transitions
- `conventions/naming.md` — File and entity naming
- `conventions/file-structure.md` — Project .workflow/ structure
- `conventions/logging.md` — Logging format and rules
- `conventions/quality-gates.md` — T1-T4 quality tiers

## Plugin Structure

| Directory | Contents |
|-----------|----------|
| `.claude-plugin/` | Plugin manifest and marketplace config |
| `commands/` | 7 user-facing slash commands |
| `agents/` | 13 agent role definitions |
| `skills/` | 9 shared capabilities (logging, task management, quality) |
| `hooks/` | SubagentStop verification hooks |
| `conventions/` | Rules: roles, naming, file structure, lifecycle, quality gates |
| `templates/` | YAML frontmatter templates for all entity types |

### Mapping

| Workflow Concept | Claude Code Entity |
|-----------------|-------------------|
| Role | Agent definition (`agents/`) |
| Skill | `ago:{skill-name}` (`skills/{skill-name}/SKILL.md`) |
| Command | `ago:{command}` (`commands/{command}.md`) |
| Master Session | Main conversation running `ago:execute` |
| Agent Logs | `.workflow/log/{role}/*.md` |

## Roadmap

Phase 2 (Activate) is in progress, Phase 3 (Hooks) is in progress. See README.md for full roadmap.
