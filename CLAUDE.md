# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Claude Code plugin (`ago:`) for agentic orchestration. All markdown, no code.
Installed as a plugin via `claude plugin add /path/to/claude-workflow`.
See `platforms/claude-code.md` for integration instructions.

## Key Files

- `memory/AGENTS.md` — Entry point for agents: rules, file locations, commands
- `master-session/instructions.md` — Master session lifecycle and quality gates
- `conventions/roles.md` — 12 role definitions (MASTER, PM, PROJ, ARCH, SEC, DEV, QAL, QAD, MKT, DOC, CICD, CONS)
- `conventions/file-structure.md` — `.workflow/` directory structure for target projects
- `conventions/naming.md` — Naming patterns: `E{NN}-name`, `T{NNN}-ROLE-name`, DR format
- `conventions/task-lifecycle.md` — Status flow: backlog → planned → in_progress → review → done
- `.claude-plugin/plugin.json` — Plugin manifest (name: `ago`)

## Architecture

The system has two sides:
1. **This repo (plugin)** — conventions, templates, agent definitions, skills, commands
2. **Target projects** — install this plugin; each gets a `.workflow/` directory

Session lifecycle: INIT → BRIEF → COLLABORATE → DECOMPOSE → APPROVE → DELEGATE → MONITOR → CONSOLIDATE → REVIEW → UPDATE

Review hierarchy: ARCH reviews DEV, QAL reviews QAD, PM reviews MKT, SEC reviews DEV
Quality tiers: T1 (Verified) → T2 (Probable) → T3 (Speculative) → T4 (Ungrounded)

## Plugin Structure

- Commands: `commands/*.md` → `ago:status`, `ago:readiness`, `ago:clarify`, `ago:execute`, `ago:review`, `ago:timeline`
- Skills: `skills/*/SKILL.md` → `ago:write-raw-log`, `ago:create-task`, etc.
- Agents: `agents/*.md` → `ago:product-manager`, `ago:architect`, etc.

## Editing Conventions

- All files in `.workflow/` use YAML frontmatter
- Wikilinks (`[[...]]`) for cross-references
- Mermaid for timeline/Gantt visualization
- Task IDs are globally unique (strict increment, never reused)
- Decision Records are generated from raw logs by CONS role — agents don't write DRs directly

## Roadmap

Phase 2 (Activate) is in progress. See README.md for full roadmap.
Tested: `ago:status`. TODO: `ago:readiness`, `ago:clarify`, `ago:execute`, `ago:review`, `ago:timeline`, executable skills.
