# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Claude Code plugin (`ago:`) for agentic orchestration. All markdown, no code.
Installed as a plugin via `claude plugin add /path/to/claude-workflow`.
See `platforms/claude-code.md` for integration instructions.

## Key Files

- `memory/AGENTS.md` — Entry point for agents: rules, file locations, commands
- `agents/master-session.md` — Master session: lifecycle, quality gates, collaborative workflow
- `conventions/roles.md` — 13 roles (12 project + WFDEV meta) (MASTER, PM, PROJ, ARCH, SEC, DEV, QAL, QAD, MKT, DOC, CICD, CONS, WFDEV)
- `conventions/file-structure.md` — `.workflow/` directory structure for target projects
- `conventions/naming.md` — Naming patterns: `E{NN}-name`, `T{NNN}-ROLE-name`, DR format
- `conventions/task-lifecycle.md` — Status flow: backlog → planned → in_progress → review → done
- `.claude-plugin/plugin.json` — Plugin manifest (name: `ago`)

## Architecture

The system has two sides:
1. **This repo (plugin)** — conventions, templates, agent definitions, skills, commands
2. **Target projects** — install this plugin; each gets a `.workflow/` directory

Session lifecycle: INIT → BRIEF → COLLABORATE → DECOMPOSE → APPROVE → DELEGATE → MONITOR → CONSOLIDATE → REVIEW → UPDATE

First-time flow: `ago:readiness` → `ago:bootstrap` → `ago:clarify`

Quality gates: See conventions/quality-gates.md (canonical source for T1-T4 tiers and review hierarchy)

Verification: SubagentStop hooks auto-check agent work against acceptance criteria (see hooks/hooks.json)

Superpowers: ago:clarify and ago:execute optionally leverage superpowers skills when available

## Editing Conventions

- Entity docs in `.workflow/` use YAML frontmatter (config, epic, task, decision, project docs, registry). Log files are exempt.
- Wikilinks (`[[...]]`) for cross-references
- Mermaid for timeline/Gantt visualization
- Task IDs are globally unique (strict increment, never reused)
- Decision Records are generated from raw logs by CONS role — agents don't write DRs directly

## Plugin Structure

- Commands: `commands/*.md` → `ago:status`, `ago:readiness`, `ago:bootstrap`, `ago:clarify`, `ago:execute`, `ago:review`, `ago:timeline`
- Skills: `skills/*/SKILL.md` → `ago:write-raw-log`, `ago:create-task`, etc.
- Agents: `agents/*.md` → `ago:product-manager`, `ago:architect`, etc.
- Hooks: `hooks/hooks.json` → SubagentStop verification (deterministic + LLM evaluation)

## Roadmap

Phase 2 (Activate) is in progress, Phase 3 (Hooks) is in progress. See README.md for full roadmap.
