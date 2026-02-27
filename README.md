# Claude Workflow (`ago:`)

Universal conventions for orchestrating AI agents across software projects. Packaged as a Claude Code plugin.

## What Is This?

A system of rules, templates, and agent definitions that standardize how AI agents (Claude Code, Codex) work together on projects. It defines:

- **Roles** — 13 agent roles (12 project + WFDEV meta) (Product Manager, Architect, Developer, etc.)
- **Conventions** — Naming, file structure, task lifecycle, decision records, logging
- **Templates** — Standardized formats for tasks, epics, DRs, project docs
- **Skills** — Shared capabilities any agent can invoke (`ago:write-raw-log`, `ago:create-task`, etc.)
- **Commands** — User-facing commands (`ago:status`, `ago:clarify`, `ago:execute`, `ago:review`, `ago:timeline`)
- **Master Session** — Orchestrator that coordinates all agent work
- **Quality Gates** — T1-T4 tier system to catch hallucinations and ensure grounded decisions

## Features

- **13 Agent Roles** with clear boundaries: MASTER, PM, PROJ, ARCH, SEC, DEV, QAL, QAD, MKT, DOC, CICD, CONS, WFDEV
- **Quality Gates** — T1-T4 tier system with senior-reviews-junior hierarchy (see conventions/quality-gates.md)
- **Two-level logging**: master log (delegations/decisions) + agent raw logs (actions/local decisions)
- **Decision Records generated from raw logs** by CONS role — agents don't write DRs directly
- **YAML frontmatter + Mermaid Gantt** — Obsidian-compatible, renders in GitHub
- **Platform-agnostic** — works with Claude Code (plugin); Codex support planned
- **Per-project `.workflow/`** directory with epics, tasks, docs, logs, decision records
- **Session lifecycle**: INIT → BRIEF → COLLABORATE → DECOMPOSE → APPROVE → DELEGATE → MONITOR → CONSOLIDATE → REVIEW → UPDATE
- **Collaborative mode** (default): master presents plan, user approves before delegation

## Quick Start

1. Install as Claude Code plugin: `claude plugin add /path/to/claude-workflow`
2. In your project, run `ago:readiness` to assess and bootstrap `.workflow/`
3. Use `ago:status` to see project state
4. Use `ago:clarify` to decompose tasks, then `ago:execute` to launch agents

## Structure

```
.claude-plugin/     — Plugin manifest (plugin.json)
conventions/        — Rules and standards
templates/          — File templates for projects
agents/             — Agent role definitions (13 files)
skills/             — Shared agent capabilities (9 skill subdirectories)
commands/           — Slash commands (6 commands)
hooks/              — SubagentStop verification hooks
platforms/          — Platform-specific adaptations (Claude Code, Codex)
memory/             — Shared agent context (AGENTS.md)
```

## Applying to a Project

See `conventions/file-structure.md` for the standard `.workflow/` structure.
See `platforms/claude-code.md` for Claude Code integration.
See `platforms/codex.md` for Codex integration.

## Roadmap

### Phase 1: Foundation — Done

Conventions, templates, agent definitions, skills, commands, master-session logic, platform guides. Applied to first project (Shepni).

### Phase 2: Activate on Real Tasks — In Progress

| Item | Status |
|------|--------|
| `ago:status` command | Done (tested on Shepni) |
| `ago:readiness` command — bootstrap project into workflow system | Done |
| `ago:clarify` command — requirements + task decomposition | Done |
| `ago:execute` command — launch agents for planned tasks | Done |
| `ago:review` command | Done |
| `ago:timeline` command | Done |
| Executable skills (all 9 skill SKILL.md files) | Done |
| End-to-end test on real project work | TODO |
| Plugin install script | TODO |

### Phase 3: Automation & Hooks — In Progress

| Item | Status |
|------|--------|
| SubagentStop verification hooks (verify-and-log.sh + evaluate-and-log.sh) | Done |
| Superpowers integration (ago:clarify + ago:execute) | Done |
| CONS agent as periodic process | TODO |
| Docs integrity CI check | TODO |

### Phase 4: Platform Expansion & Infra

| Item | Status |
|------|--------|
| Codex full integration | TODO |
| Self-hosted git (Gitea/Forgejo) | TODO |
| Obsidian vault sync (Dataview/Tasks plugins) | TODO |
| Cross-project task management | TODO |

### Open Questions

1. ~~Can Claude Code hooks reliably write to log files during subagent execution?~~ **Yes** — SubagentStop command hooks write verification logs to `.workflow/log/{role}/` (Phase 3)
2. How to map skills/agents to Codex's execution model?
3. Should CONS be periodic or on-demand?
4. Which Obsidian plugins best visualize Gantt + task dependencies?
