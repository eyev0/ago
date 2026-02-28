# Design: `ago:bootstrap` Command

**Date:** 2026-02-28
**Status:** Draft
**Author:** WFDEV

## Problem

`ago:readiness` creates the structural scaffold — `.workflow/` directory, config, registry, doc stubs. But the resulting workspace is structurally ready, not operationally ready. Agents launch without knowing:

- What this project is about (product vision, domain, users)
- How this project makes decisions (move fast vs. careful, consensus vs. owner-decides)
- What each role should specifically focus on for THIS project
- Which roles have authority over others, and in what order they engage

This context gap means every agent starts cold, spending tokens re-discovering project context from scattered sources (README, CLAUDE.md, package.json) instead of having a clear, structured mandate.

## Solution

A new command `ago:bootstrap` that runs after `ago:readiness`. It captures operational context through a hybrid scan + interview approach and produces two types of artifacts:

1. **`brief.md`** — shared project brief (vision, constraints, philosophy, role priorities)
2. **`roles/*.md`** — per-role mandate docs (first principles, focus areas, constraints)

## Output Artifacts

### Directory Structure

```
.workflow/
├── brief.md              ← NEW: Project brief (all roles read this)
├── roles/                ← NEW: Per-role mandate directory
│   ├── pm.md
│   ├── arch.md
│   ├── dev.md
│   ├── sec.md            (only if SEC is active)
│   ├── qal.md            (only if QAL is active)
│   ├── qad.md            (only if QAD is active)
│   ├── proj.md           (only if PROJ is active)
│   ├── mkt.md            (only if MKT is active)
│   ├── doc.md            (only if DOC is active)
│   ├── cicd.md           (only if CICD is active)
│   └── cons.md           (only if CONS is active)
├── config.md             (exists from readiness)
├── registry.md           (exists, updated by bootstrap)
├── docs/                 (stubs exist from readiness)
├── epics/
├── decisions/
└── log/
```

### `brief.md` Structure

```markdown
---
project: {name}
created: {date}
updated: {date}
---

## Product Vision
{What this product is, who it serves, why it matters}

## Target Users
{Primary personas, their needs, their context}

## Domain Context
{Industry, competitive landscape, market position}

## Operational Constraints
{Tech stack, deployment model, team size, release cadence, compliance requirements}

## Decision Philosophy
{How this project makes decisions — move fast vs careful,
 consensus vs owner-decides, experimentation tolerance}

## Role Priority Matrix

### Authority Hierarchy
{Which roles can block others, whose reviews are mandatory}
{e.g., "SEC reviews are mandatory before any deployment task closes"}

### Engagement Order
{Default sequencing for new work}
{e.g., "PM → ARCH → DEV → QAL/QAD → CICD"}

## Goals (Current)
{3-5 concrete near-term goals with owners}
```

### Per-Role Doc Structure (e.g. `roles/arch.md`)

```markdown
---
role: ARCH
project: {name}
focus: {one-line focus for this project}
priority: {1-N, engagement order position}
authority:
  reviews: [DEV, CICD]
  reviewed_by: [MASTER, user]
---

## First Principles
{2-3 guiding principles for ARCH on THIS project}
{e.g., "Prefer simplicity over flexibility — this is a prototype"}
{e.g., "All data flows must be auditable — regulated domain"}

## Focus Areas
{Specific technical areas ARCH should prioritize}
{e.g., "API design, database schema, auth flow"}

## Constraints
{Tech stack decisions already made, non-negotiables}
{e.g., "Must use PostgreSQL — existing infra. No new languages."}

## Key Questions
{Open questions this role should address first}
{e.g., "Monolith or services? Sync or async communication?"}
```

### Which Roles Get a Doc

Every active role **except**:
- **MASTER** — orchestrator, reads `brief.md` directly for full context
- **WFDEV** — meta-role, only used within the ago: plugin itself

## Command Behavior

### Prerequisites

- `.workflow/config.md` must exist (i.e., `ago:readiness` has been run)
- If `.workflow/brief.md` already exists, ask user whether to regenerate or skip

### Flags

- No flags — full hybrid scan + interview, generates all artifacts
- `--check` — show what would be generated without creating files
- `--role {ROLE}` — regenerate a single role doc (re-interview for that role only)

### Interview Flow

```
Step 1: Prerequisites
  └─ Verify .workflow/config.md exists
  └─ Read active roles from config.md

Step 2: Scan & Pre-fill
  └─ Read README, CLAUDE.md, package.json, existing .workflow/docs/*
  └─ Extract: project vision, tech stack, goals, constraints
  └─ Build pre-filled draft context

Step 3: Product Brief Interview (→ brief.md)
  ├─ Vision: "Here's what I found: {scanned}. Accurate? Adjust?"
  ├─ Users: "Who are the target users?"
  ├─ Domain: "What's the domain/industry context?"
  ├─ Constraints: "Operational constraints? (compliance, team, cadence)"
  ├─ Philosophy: "How does this project make decisions?"
  └─ Goals: "What are the 3-5 current goals?"

Step 4: Role Priority Matrix (→ brief.md § Role Priority Matrix)
  ├─ Show default engagement order based on project type
  ├─ Ask: "Adjust the priority order?"
  └─ Ask: "Any mandatory review gates?"

Step 5: Per-Role Mandates (→ roles/*.md)
  For each active role (grouped by tier):

  Core roles (always detailed interview):
    PM, ARCH, DEV

  Conditional roles (lighter interview, only if active):
    SEC, QAL, QAD, PROJ, MKT, DOC, CICD, CONS

  For each:
  ├─ Pre-fill focus from scanned context
  ├─ Ask: "What should {ROLE} focus on specifically for this project?"
  ├─ Ask: "Any first principles or constraints for {ROLE}?"
  └─ Generate roles/{role}.md

Step 6: Generate & Confirm
  ├─ Show summary of all files to be created
  ├─ User confirms
  ├─ Write brief.md
  ├─ Write roles/*.md for each active role
  ├─ Update registry.md with new files
  └─ Show summary and next steps
```

### Interview Strategy

**Hybrid scan + questions** — scan existing artifacts to pre-fill what can be inferred, then ask targeted questions only for gaps. This respects existing documentation and minimizes user effort.

Questions use `AskUserQuestion` with multiple-choice options where possible. Open-ended questions are used for vision, philosophy, and first principles where the user's own words matter.

For conditional roles, if the scanned context provides enough signal (e.g., security posture is clear from SECURITY.md), present the pre-filled version for confirmation rather than asking from scratch.

## Agent Integration

### How Agents Load Context

**Shared context** — add to `memory/AGENTS.md` under "For Role Agents":

```markdown
## For Role Agents

0. Read `.workflow/brief.md` for project context, decision philosophy, and role priorities
1. Read `.workflow/roles/{your-role}.md` for your project-specific mandate and focus areas
2. Follow your role definition in `agents/{your-role}.md`
3. Always invoke the `ago:write-raw-log` skill after completing work.
```

**Per-agent update** — each agent's "Before Starting Work" section gains:

```markdown
## Before Starting Work
1. Read `.workflow/brief.md` for project context and priorities
2. Read `.workflow/roles/{role}.md` for your specific mandate
3. Read the task.md for your assigned task
...
```

### Graceful Degradation

If `brief.md` or `roles/*.md` don't exist (bootstrap wasn't run), agents fall back to current behavior — reading project docs directly. No hard dependency. The "Before Starting Work" instructions say "Read if it exists."

## Relationship to `ago:readiness`

```
ago:readiness (structural)          ago:bootstrap (operational)
─────────────────────────           ───────────────────────────
Scans project artifacts             Reads config.md + scanned data
Recommends roles                    Interviews for context
Creates .workflow/ scaffold         Creates brief.md + roles/*.md
Creates doc stubs                   Updates registry.md
         ↓ runs first                        ↓ runs after
```

`ago:readiness` remains unchanged. `ago:bootstrap` is additive.

Typical first-time flow:
1. `ago:readiness` — scan, recommend roles, create scaffold
2. `ago:bootstrap` — interview, capture context, create mandates
3. `ago:clarify` — define first epic/tasks

## Implementation Scope

### New Files to Create

| File | Purpose |
|------|---------|
| `commands/bootstrap.md` | Command definition |
| `templates/brief.md` | Template for `.workflow/brief.md` |
| `templates/role.md` | Template for `.workflow/roles/{role}.md` |

### Files to Update

| File | Change |
|------|--------|
| `conventions/file-structure.md` | Add `brief.md` and `roles/` directory |
| `conventions/naming.md` | Add `roles/{role-id-lowercase}.md` naming |
| `memory/AGENTS.md` | Add brief.md and role doc reads |
| `agents/*.md` (all role agents) | Add role doc read to "Before Starting Work" |
| `templates/registry.md` | Add brief.md and roles section |

### Not Changed

- `ago:readiness` — no modifications
- `conventions/roles.md` — role definitions unchanged
- `conventions/quality-gates.md` — review hierarchy unchanged
- `hooks/` — no hook changes

## Open Questions

1. **Role doc updates** — when should role docs be regenerated? Only via `ago:bootstrap --role {ROLE}`, or also when roles are added/removed via config changes?
2. **Brief evolution** — should `brief.md` be updated as the project evolves (e.g., goals change), or is it a point-in-time snapshot? Recommendation: living document, updated by MASTER or user.
3. **MASTER reads role docs?** — should MASTER read all role docs for full context, or just `brief.md`? Recommendation: MASTER reads `brief.md` only; individual role docs are for the roles themselves.
