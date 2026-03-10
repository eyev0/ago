# Design: `ago:fix-audit` — Automated Audit Item Resolution

**Date:** 2026-03-10
**Status:** Draft
**Author:** brainstorming session

## Problem

`ago:audit` produces structured reports with actionable items (acceptance criteria, file refs, severity). Currently these items are resolved manually. We want a command that dispatches parallel agents to fix them autonomously, with human oversight at the right moment.

## Core Decisions

### Tiered Autonomy (C model)
- **High:** plan reviewed before execution, individual ADR
- **Medium:** plan reviewed before execution, ADR if non-trivial
- **Low/chore:** batched (up to 5 per agent), grouped plan reviewed, single batch ADR for 3+ items

### ADR Generation (A model — per non-trivial fix)
- Each high/medium fix with a meaningful design choice gets its own ADR
- Low/chore batches get one summary ADR (if 3+ items)
- ADR status: "To Review" — agent decisions need human ratification

### Post-Fix Audit (B model — one retry)
- After execution, run `ago:audit` scoped to the agent's changes
- If new issues found → agent gets 1 retry attempt
- If still issues after retry → draft PR with audit notes attached

### Execution Model (one-shot command)
- `ago:fix-audit` is a single command, not a loop
- Workflow: `ago:audit` → review report → `ago:fix-audit` → review PRs → merge → `ago:audit` again

### Dependency Detection (file + import level)
- Items touching the same files → same agent (sequential within group)
- One-hop import expansion: if file A imports file B, items touching A and B are grouped
- No transitive closure — diminishing returns
- Groups with no file overlap run in parallel

### Single Approval Checkpoint
- Grouping screen is lightweight (just confirm batches)
- Planning wave: agents brainstorm + plan in parallel (read-only)
- Plan approval: all plans shown at once, approve/reject/edit per item
- After approval → fully autonomous execution

### Input via file path
- Command receives audit report path (via `@` tag)
- No CWD assumptions — works from any directory
- Git root detected from the report file's location

## Flow

```
                    ┌─────────────┐
                    │ Parse audit  │
                    │ report       │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ Dependency   │
                    │ analysis     │
                    │ (file+import)│
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ Grouping     │◄── lightweight confirm
                    │ screen       │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼────┐ ┌────▼─────┐ ┌────▼─────┐
        │ Agent 1   │ │ Agent 2   │ │ Agent N   │
        │ plan only │ │ plan only │ │ plan only │  ◄── Wave 1 (parallel)
        └─────┬────┘ └────┬─────┘ └────┬─────┘
              │            │            │
              └────────────┼────────────┘
                           │
                    ┌──────▼──────┐
                    │ Plan         │◄── THE approval checkpoint
                    │ approval     │    approve/reject/edit per item
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼────┐ ┌────▼─────┐ ┌────▼─────┐
        │ Agent 1   │ │ Agent 2   │ │ Agent N   │
        │ execute   │ │ execute   │ │ execute   │  ◄── Wave 2 (parallel)
        │ test      │ │ test      │ │ test      │
        │ audit     │ │ audit     │ │ audit     │
        │ ADR       │ │ ADR       │ │ ADR       │
        │ draft PR  │ │ draft PR  │ │ draft PR  │
        └─────┬────┘ └────┬─────┘ └────┬─────┘
              │            │            │
              └────────────┼────────────┘
                           │
                    ┌──────▼──────┐
                    │ Completion   │
                    │ summary      │
                    └─────────────┘
```

## Step-by-Step Specification

### Step 1: Parse Audit Report

Input: file path to audit report (from `$ARGUMENTS`)

1. Read the file
2. Validate: must contain `# Audit Report` and `## Action Items`
3. Parse action items from each severity section (Critical/High/Medium/Low)
4. For each unchecked item (`- [ ]`) extract:
   - `title` — bold text after checkbox
   - `description` — text after em-dash on same line
   - `acceptance` — line starting with `- Acceptance:`
   - `refs` — line starting with `- Refs:`
   - `files` — line starting with `- Files:`, split by `,`
5. Skip checked items (`- [x]`)
6. If zero unchecked items → "All action items resolved. Nothing to fix." → stop
7. Detect git root from the audit report's directory (walk up to find `.git`)

### Step 2: Dependency Analysis

1. Collect all `files[]` from all items into a map: `file → [items]`
2. For items sharing any file → merge into one dependency group
3. Import expansion (one hop):
   - For each unique file, read it and extract imports/includes/use statements
   - If item A's file imports a file that item B touches → merge their groups
4. Result: list of dependency groups, each containing 1+ items

### Step 3: Agent Assignment

1. For each dependency group:
   - If it contains any High/Medium items → dedicated agent, items ordered by severity (high first)
   - If it contains only Low items → candidate for batching
2. Batch Low-only groups: merge up to 5 items per batch agent
   - Prefer merging groups that share the most files
   - Lone low items join nearest compatible batch
3. Result: list of agents, each with ordered items list and file set

### Step 4: Grouping Screen

Present to user:

```
## Fix Plan — {audit-report-filename}

**Items:** {N} unchecked ({breakdown by severity})
**Agents:** {N} ({M} parallel, {K} with internal sequential ordering)
**Estimated draft PRs:** {N}

### Agent 1 — Group A [{file list}]
  {SEVERITY} — {title}
  {SEVERITY} — {title}
  (sequential: items share files)

### Agent 2 — Group B [{file list}]
  {SEVERITY} — {title}
  (parallel with Agent 1)

### Agent 3 — Low batch [{file list}]
  LOW ×{N} — {title}, {title}, ...

Proceed with planning? [yes / adjust / cancel]
```

- **yes** → proceed to Wave 1
- **adjust** → user describes changes in natural language (e.g., "move item 3 to Agent 1", "split Agent 2 into two"). Orchestrator re-runs grouping with the constraint and re-presents the screen.
- **cancel** → stop

### Step 5: Wave 1 — Planning (parallel agents)

Launch N agents in parallel using the Agent tool. Each agent runs in an isolated worktree (`isolation: "worktree"`).

Each planning agent receives:
- Its assigned items (title, description, acceptance criteria, refs, files)
- Instruction to brainstorm approach and write a plan
- Instruction to NOT make any edits — read-only exploration
- The items' files to read for context

Planning agent prompt structure:
```
You are planning fixes for audit findings. Do NOT edit any files.

## Your Items
{items with full details}

## Instructions
For each item:
1. Read the referenced files to understand current state
2. Brainstorm 2-3 approaches
3. Pick the best approach — prefer the simplest that meets acceptance criteria
4. Write a concrete plan: what files to change, what to add/modify, key implementation details

For items marked as needing an ADR, note what the ADR will document (the design choice being made).

## Output Format
For each item:
### {title}
**Approach:** {chosen approach in 3-5 lines}
**Alternatives considered:** {brief list of rejected approaches and why}
**Files to modify:** {list}
**ADR needed:** {yes/no} — {what decision it documents, if yes}
**Risk:** {what could go wrong}
```

### Step 6: Plan Approval

After all planning agents return, present all plans:

```
## Plans Ready for Review

### Agent 1 — Group A

#### HIGH — Test streaming replacements with LocalAgreement-2
**Approach:** {agent's plan}
**Alternatives:** {what else was considered}
**ADR:** yes — documents LocalAgreement-2 test contract
**Risk:** {agent's risk assessment}
[approve / reject / edit guidance]

#### MEDIUM — Test boost bias during inference
**Approach:** {agent's plan}
...
[approve / reject / edit guidance]

### Agent 2 — Group B
...

Approve all? [yes / approve individually / cancel]
```

- **yes** → all approved, proceed to execution
- **approve individually** → user marks each item approve/reject/edit
- **cancel** → stop, no execution

For edited items: user's guidance text is appended to the plan and passed to the execution agent.

### Step 7: Wave 2 — Execution (parallel agents)

Launch agents for approved plans only. Each in isolated worktree.

Execution agent prompt structure:
```
You are implementing fixes for audit findings. Follow the approved plan exactly.

## Your Plan
{approved plan text, including any user edits}

## Items
{items with acceptance criteria}

## Instructions
For each item in order:
1. Implement the fix as described in the plan
2. Verify against acceptance criteria
3. Run relevant tests (detect test command from project: cargo test, swift test, npm test, etc.)
4. If tests fail → fix and retry once

After all items are implemented:
5. Run the full test suite
6. Self-review: re-read your changes, check for obvious mistakes

## ADR Generation
For items marked ADR: yes, create ADR file in docs/adr/:

Filename: docs/adr/{NNN}-{kebab-case-title}.md
(Match existing project convention — detect naming pattern from existing ADRs in docs/adr/)

# ADR-{NNN}: {Title}

**Status:** To Review
**Date:** {date}
**Deciders:** ago:fix-audit (autonomous agent)

## Context
{from the original audit finding — why this needed fixing}

## Decision
{the approach taken}

## Alternatives Considered
{from the planning phase}

## Consequences
### Positive
{benefits}
### Negative
{trade-offs}

## Verification
- Acceptance criteria: {from audit}
- Result: {pass/fail with evidence}

## Origin
- Audit report: {path to audit report}
- Finding refs: {original refs from audit}
- PR: {will be filled by orchestrator}

For batch ADRs (low items, 3+), create one ADR covering all items in the batch.

## Commit
Commit all changes with message:
fix({scope}): {summary of what was fixed}

Refs: ago:fix-audit, {audit report path}

## Draft PR
Create a draft PR with:
- Title: fix({scope}): {summary}
- Body: what was fixed, approach taken, ADR links, acceptance criteria results
```

### Step 8: Post-Fix Audit

After each execution agent completes, run a lightweight re-audit of just that agent's changes (NOT a full `ago:audit` — that would be overkill):

1. Launch a single review agent on the worktree branch with the agent's diff (`git diff main...HEAD`) as context
2. Agent checks: does the diff introduce new issues? Does it meet the original acceptance criteria?
3. If zero new findings → pass
4. If new findings found:
   - Launch a NEW agent in the same worktree (subagents cannot be resumed) with:
     (a) the original approved plan
     (b) the diff of changes already made (`git diff` from the execution agent's work)
     (c) the new audit findings to address
   - This retry agent makes targeted fixes only — not a full re-implementation
   - After retry, create/update the draft PR regardless
   - Note any unresolved findings in the PR description

### Step 9: Completion

After all agents finish:

1. Collect results from all agents
2. Present summary:

```
## Fix Run Complete

**Source:** {audit-report-filename}
**Agents:** {N} dispatched, {M} completed, {K} failed
**Items fixed:** {X}/{Y} ({Z} rejected at planning)

### Results

| # | Item | Severity | Status | PR | ADR |
|---|------|----------|--------|----|-----|
| 1 | {title} | HIGH | ✓ fixed | #{num} (draft) | ADR-{NNN} |
| 2 | {title} | MEDIUM | ✗ failed (test) | #{num} (draft) | — |
| ... | ... | ... | ... | ... | ... |

### Post-Fix Audit Results
- Agent 1: {N} new findings ({details or "clean"})
- Agent 2: ...

### ADRs Created (all Status: To Review)
- docs/adr/{NNN}-{title}.md
- ...

Next: review draft PRs, merge, then run ago:audit to verify.
```

3. Update original audit report — mark fixed items:
```
- [x] **{title}** — Fixed by ago:fix-audit, PR #{num}, ADR-{NNN}
```

## Edge Cases

- **Empty audit report** — no unchecked items → stop with message
- **All items in one dependency group** — single agent, sequential execution
- **Agent fails mid-execution** — mark items as failed in summary, don't block other agents
- **Test suite not detected** — skip test step, note in PR description
- **No `docs/adr/` directory** — create it before writing ADRs
- **ADR numbering collision** — orchestrator reads existing ADRs and allocates specific ADR numbers to each agent between plan approval (Step 6) and execution dispatch (Step 7). Each execution agent receives its pre-assigned ADR number(s) — agents never pick their own numbers
- **Worktree conflicts** — each agent branches from the same base; PRs may conflict with each other. Note in completion summary: "Review PRs in order, rebase as needed"
- **Audit report not found** — error with helpful message
- **Audit report format mismatch** — error listing what's missing

## What This Is NOT

- Not a loop — run once, get results
- Not a replacement for code review — draft PRs still need human review
- Agents don't merge anything — you are the merge gatekeeper
- ADRs are "To Review" — agent decisions aren't automatically accepted
- Not a CI system — runs in your local Claude Code session

## Future Simplifications

If two approval steps (grouping + plans) feels heavy in practice:
- Collapse to one: show plans directly without grouping confirmation
- Or: auto-approve low-risk groupings, only confirm when dependency analysis is ambiguous

If planning wave adds too much latency:
- Skip planning for Low items — they execute directly from acceptance criteria
- Only plan High/Medium items
