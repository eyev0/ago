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

The repo uses a marketplace layout with plugins under `plugins/`:
1. **This repo** — marketplace wrapper; plugin content lives in `plugins/ago/`
2. **Target projects** — install this plugin; each gets a `.workflow/` directory

Session lifecycle: INIT → BRIEF → COLLABORATE → DECOMPOSE → APPROVE → DELEGATE → MONITOR → CONSOLIDATE → REVIEW → UPDATE

Quality gates: See plugins/ago/conventions/quality-gates.md (canonical source for T1-T4 tiers and review hierarchy)

Verification: SubagentStop hooks auto-check agent work against acceptance criteria (see plugins/ago/hooks/hooks.json)

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
| `ago:audit` | Multi-role retrospective review from git history + docs |
| `ago:research` | Structured research session → artifact in docs/research/ |
| `ago:sync-docs` | Synchronize documentation with ADRs and current code |

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

- Agents follow their role definition in `plugins/ago/agents/{role}.md`
- Log all work to `.workflow/log/{role}/{YYYY-MM-DD}.md`
- Use templates from `plugins/ago/templates/` when creating new files
- Never modify files outside your role's scope
- Always invoke `ago:write-raw-log` after completing work

## Editing Conventions

- Entity docs in `.workflow/` use YAML frontmatter (config, epic, task, decision, project docs, registry). Log files are exempt.
- Wikilinks (`[[...]]`) for cross-references
- Mermaid for timeline/Gantt visualization
- Task IDs are globally unique (strict increment, never reused)
- Decision Records are generated from raw logs by CONS role — agents don't write DRs directly

## Conventions Reference

- `plugins/ago/conventions/roles.md` — Role definitions and boundaries
- `plugins/ago/conventions/task-lifecycle.md` — Task statuses and transitions
- `plugins/ago/conventions/naming.md` — File and entity naming
- `plugins/ago/conventions/file-structure.md` — Project .workflow/ structure
- `plugins/ago/conventions/logging.md` — Logging format and rules
- `plugins/ago/conventions/quality-gates.md` — T1-T4 quality tiers

## Plugin Structure

| Directory | Contents |
|-----------|----------|
| `.claude-plugin/` | Marketplace config |
| `plugins/ago/.claude-plugin/` | Plugin manifest |
| `plugins/ago/commands/` | 10 user-facing slash commands |
| `plugins/ago/agents/` | 13 agent role definitions |
| `plugins/ago/skills/` | 9 shared capabilities (logging, task management, quality) |
| `plugins/ago/hooks/` | SubagentStop verification hooks |
| `plugins/ago/conventions/` | Rules: roles, naming, file structure, lifecycle, quality gates |
| `plugins/ago/templates/` | YAML frontmatter templates for all entity types |

### Mapping

| Workflow Concept | Claude Code Entity |
|-----------------|-------------------|
| Role | Agent definition (`plugins/ago/agents/`) |
| Skill | `ago:{skill-name}` (`plugins/ago/skills/{skill-name}/SKILL.md`) |
| Command | `ago:{command}` (`plugins/ago/commands/{command}.md`) |
| Master Session | Main conversation running `ago:execute` |
| Agent Logs | `.workflow/log/{role}/*.md` |

## Roadmap

Phase 2 (Activate) is in progress, Phase 3 (Hooks) is in progress. See README.md for full roadmap.
