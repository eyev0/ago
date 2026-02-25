# Design: Make ago: Skills Executable

> Date: 2026-02-25
> Status: Approved

## Goal

Convert 9 skill stubs (procedural documentation) into executable Claude Code plugin skills that agents can invoke explicitly. Fix all consistency issues blocking correct execution.

## Decisions Made

| Topic | Decision |
|-------|----------|
| P03 | All paths normalized to `.workflow/...` |
| P04 | Lowercase log dirs: `log/master/`, `log/dev/`, etc. |
| P05 | `id: T001` (short numeric) is canonical, directory slug is derived |
| P06 | `blocked → planned \| in_progress` (flexible) |
| P09 | Frontmatter on entity docs + registry. Logs exempt |
| P10 | `ago:status` everywhere, no slash prefix |
| P13 | DOC only edits `.workflow/docs/` — repo-level docs out of scope |
| P14 | MASTER logs transitions in `log/master/` only |
| P15 | `ago:clarify` creates task.md files. `ago:execute` launches agents for existing tasks |
| P16 | Remove `conventions_repo` field from config template |
| P17 | Wikilinks use full slug: `[[T001-DEV-feature/task.md]]` |
| H4 | `conventions/quality-gates.md` is canonical source for quality tiers and review hierarchy |
| Invocation model | Explicit invocation — agents call skills by name, commands also call skills internally |

## Execution Plan

### Phase 0: Consistency Fixes

Single agent. Fix all blocking issues before skill implementation.

**Critical (C1-C3):**
- C1/P03: Normalize paths to `.workflow/...` in all 13 agent files
- C2: Add workflow-developer to `conventions/roles.md`, fix "12" → "13" in CLAUDE.md/README
- C3: Add `ago:evaluate-quality-gate` to master-session skills table

**High (H1-H5, P05, P06, P10, P14, P15):**
- H1: Remove stale TODO from `conventions/quality-gates.md`
- H2/P04: Lowercase all log dirs everywhere
- H3: Fix review hierarchy in README (reference canonical source)
- H4: Deduplicate quality gates — `conventions/quality-gates.md` is canonical, master-session and CLAUDE.md reference it
- H5: Fix convention file count in MEMORY.md
- P05: Document short ID as canonical in `conventions/naming.md`
- P06: Allow `blocked → planned | in_progress` in both convention and skill
- P10: Remove all `/ago:` occurrences, use `ago:` only
- P14: Document MASTER logs own transitions in `conventions/logging.md`
- P15: Clarify that `ago:clarify` creates task.md in `commands/clarify.md`

**Medium (M2-M5, P13, P16, P17):**
- M3: Fix agent-log-entry template statuses
- M4: Create `templates/project-docs/timeline.md`
- P09/M2: Narrow frontmatter rule — entity docs + registry only, logs exempt
- P13: Restrict DOC to `.workflow/docs/` only
- P16: Remove `conventions_repo` from config template
- P17: Document full-slug wikilinks: `[[T001-DEV-feature/task.md]]`

### Phase 1: Foundation Skills

Three parallel agents. No cross-skill dependencies.

**Agent 1: `ago:write-raw-log`**
- Trigger: After any significant agent action
- Input: role ID, task ID, input, actions, output, decisions, status
- Creates `.workflow/log/{role}/{YYYY-MM-DD}.md` (append-only)
- No frontmatter on log files
- Lowercase directory names

**Agent 2: `ago:create-task`**
- Trigger: During DECOMPOSE/APPROVE (called by `ago:clarify`)
- Input: epic ID, role, title, description, priority, dependencies, acceptance criteria
- Reads config.md for counter, increments, creates directory + task.md + artifacts/
- Updates registry
- Canonical ID is short (`T001`), directory slug is `T001-{ROLE}-{short-name}`

**Agent 3: `ago:update-task-status`**
- Trigger: When task status changes
- Input: task ID, new status
- Validates transition per `conventions/task-lifecycle.md`
- Updates frontmatter fields: `status`, `updated`
- MASTER logs own transitions in `log/master/` only
- Calls `ago:write-raw-log` for agent-driven transitions

### Phase 2: Document Skills

Three parallel agents. May reference foundation skills.

**Agent 4: `ago:create-decision-record`**
- Trigger: During consolidation when significant decision found
- Input: role, epic, task, description, context, options, decision, consequences
- Creates file in `.workflow/decisions/{ROLE}-{EPIC}-{TASK}-{desc}.md`
- Links DR in task's `related_decisions` field
- Updates registry

**Agent 5: `ago:update-registry`**
- Trigger: After creating tasks, DRs, or status changes
- Scans `.workflow/epics/`, `.workflow/decisions/`
- Rebuilds registry tables with frontmatter (last_updated, totals, active_roles)
- Validates wikilinks resolve to existing files (full slug format)

**Agent 6: `ago:generate-timeline`**
- Trigger: After status changes or on `ago:timeline` command
- Reads task.md frontmatter across epics
- Generates Mermaid Gantt at epic level and project level
- Writes to `.workflow/epics/{id}/timeline.md` and `.workflow/docs/timeline.md`

### Phase 3: Composite Skills

Three parallel agents. Call other skills.

**Agent 7: `ago:consolidate-logs`**
- Reads `.workflow/log/{role}/` for specified date/task
- Extracts decisions from "Decisions made" sections
- Calls `ago:create-decision-record` for significant decisions
- Flags conflicts between roles for MASTER review
- Updates project docs

**Agent 8: `ago:validate-docs-integrity`**
- Checks wikilinks resolve (full slug format: `[[T001-DEV-feature/task.md]]`)
- Validates task IDs exist as directories
- Validates DR references exist in `.workflow/decisions/`
- Checks registry status matches task.md status
- Checks frontmatter only on entity docs + registry (not logs)
- DOC scope: `.workflow/docs/` only
- Outputs error/warning report

**Agent 9: `ago:evaluate-quality-gate`**
- Reads agent logs and artifacts for completed task
- Runs anti-hallucination checks (code ref, consistency, scope, context)
- Assigns T1-T4 tier per `conventions/quality-gates.md` (canonical source)
- Flags T3/T4 for senior review per review hierarchy
- Logs evaluation in master log

## What "Executable" Means

Each SKILL.md is rewritten as a complete prompt with:

1. **Frontmatter**: `name`, `description` (trigger context), `version`
2. **Purpose**: One-line when to use
3. **Input**: Required and optional parameters
4. **Instructions**: Step-by-step with exact file paths, templates inline, validation checks
5. **Output**: What the skill produces
6. **Error handling**: What to do when files missing, transitions invalid, etc.

## Agent Team Structure

| Phase | Agents | Parallelism | Depends on |
|-------|--------|-------------|------------|
| 0 | 1 consistency fixer | Sequential | Nothing |
| 1 | 3 foundation agents | Parallel within phase | Phase 0 |
| 2 | 3 document agents | Parallel within phase | Phase 1 |
| 3 | 3 composite agents | Parallel within phase | Phase 2 |

Total: 10 agents, 4 sequential phases, max 3 parallel within a phase.
