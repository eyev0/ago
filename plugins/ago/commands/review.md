---
description: Collect agent results, consolidate logs, create DRs, review with user
argument-hint: "[task_id]"
---

# ago:review

You are executing the `ago:review` command. This command covers the CONSOLIDATE and REVIEW phases of the session lifecycle. Your job is to collect agent work products, assess quality, present findings to the user, and — with their approval — formalize decisions and complete tasks.

**Argument:** `$ARGUMENTS` (optional task ID, e.g., `T003`). If empty, review all recent agent work.

## Step 1 — Load Project Context

Read `.workflow/config.md` to understand the project name, active roles, and current epic focus.

If `.workflow/config.md` does not exist, STOP and tell the user: "No `.workflow/` directory found. Run `ago:readiness` first to initialize the project."

## Step 2 — Discover Agent Logs

Scan `.workflow/log/` for agent log directories and their daily log files.

- If `$1` is provided (a task ID like `T003`): scan all role log directories for entries that reference `$1`. Only include entries containing that task ID.
- If `$1` is empty: scan all `.workflow/log/*/` directories for the most recent log files (today first, then the most recent date with entries).

If no log files are found, tell the user: "No agent logs found. Agents have not yet produced work to review." and stop.

## Step 3 — Consolidate Logs

Follow the `ago:consolidate-logs` skill instructions:

@${CLAUDE_PLUGIN_ROOT}/skills/consolidate-logs/SKILL.md

Parse each log entry (format: `## HH:MM — T{NNN}`) and extract:
- Task ID
- Actions taken
- Decisions made
- Current status

Identify **significant decisions** — those that affect architecture, security, product scope, multiple components, or represent a choice between alternatives. Minor decisions (naming, formatting, local details) do not need DRs.

Check for **conflicts** across roles:
- Does a DEV decision contradict an ARCH decision?
- Does a QAD finding conflict with DEV's approach?
- Do any two agents disagree on approach, scope, or technology choice?

## Step 4 — Evaluate Quality

For each agent's work, follow the `ago:evaluate-quality-gate` skill:

@${CLAUDE_PLUGIN_ROOT}/skills/evaluate-quality-gate/SKILL.md

Apply the quality tiers from the project conventions:

@${CLAUDE_PLUGIN_ROOT}/conventions/quality-gates.md

Assign each decision/artifact a tier:
- **T1 (Verified):** Grounded in code/docs, no hallucination risk — accept
- **T2 (Probable):** Reasonable inference, minor assumptions — accept, optional senior review
- **T3 (Speculative):** Assumptions not validated — must be validated before acceptance
- **T4 (Ungrounded):** No evidence in codebase — reject, flag for redo

For T3/T4 items, identify the reviewer using the review hierarchy:
- DEV output → reviewed by ARCH
- QAD output → reviewed by QAL
- MKT output → reviewed by PM
- DEV (security) → reviewed by SEC
- CICD output → reviewed by ARCH
- DEV (frontend) → reviewed by PM + ARCH

## Step 5 — Present Findings to User

Display a structured summary. This is the core of the review — present everything clearly so the user can make informed decisions.

### Format

```
## Review Summary

**Scope:** {task ID if filtered, or "all recent work"}
**Logs reviewed:** {count} entries across {roles list}
**Date range:** {date(s) covered}

### Agent Work

For each role that produced work:

**{ROLE} — {task ID(s)}**
- Actions: {brief summary of what was done}
- Quality: {T1/T2/T3/T4} — {one-line justification}
- Decisions: {list of decisions found, or "None"}

### Decisions Proposed

{Numbered list of significant decisions extracted from logs}

1. **{short title}** (by {ROLE}, re: {task ID})
   Context: {why this decision was made}
   Decision: {what was decided}
   Quality: {tier}

2. ...

### Conflicts

{List any conflicts between agents, or "No conflicts detected."}

### Quality Concerns

{List any T3/T4 items that need attention, with recommended reviewer, or "All work rated T1/T2 — no concerns."}
```

## Step 6 — Ask User for DR Approval

After presenting findings, ask the user:

> **Which decisions should become formal Decision Records?**
> Enter the numbers from the list above (e.g., "1, 3"), "all", or "none".

Wait for the user's response. Do not proceed until they answer.

## Step 7 — Create Decision Records

For each decision the user approved, follow the `ago:create-decision-record` skill:

@${CLAUDE_PLUGIN_ROOT}/skills/create-decision-record/SKILL.md

Create DR files in `.workflow/decisions/` with `status: proposed`. Link each DR to its originating task and add it to the registry.

Report each DR created: "Created DR: `{filename}` for {short title}"

## Step 8 — Ask User for Task Completions

If any tasks have their work validated (T1/T2 quality, no unresolved conflicts), ask the user:

> **The following tasks appear ready to mark as done:**
> - {task ID}: {title} (quality: {tier})
>
> Transition these to `done`? Enter task IDs (e.g., "T003, T005"), "all", or "none".

Wait for the user's response. Do not proceed until they answer.

Note: Only tasks currently in `review` status can transition to `done`. If a task is still `in_progress`, it must first move to `review`. Inform the user if any tasks are not yet eligible.

## Step 9 — Update Task Statuses

For each task the user approved, follow the `ago:update-task-status` skill:

@${CLAUDE_PLUGIN_ROOT}/skills/update-task-status/SKILL.md

Transition approved tasks to `done`. Log each transition.

For T3/T4 items that the user did not explicitly approve, leave them in their current status and note the required reviewer.

## Step 10 — Update Registry

After all DRs are created and task statuses updated, follow the `ago:update-registry` skill to rebuild the registry index:

@${CLAUDE_PLUGIN_ROOT}/skills/update-registry/SKILL.md

## Step 11 — Log the Review

Write a consolidation summary entry in `.workflow/log/master/{YYYY-MM-DD}.md`:

```markdown
## {HH:MM} — Review (ago:review)

**Scope:** {task ID or "all recent work"}
**Logs reviewed:** {count} entries across {count} roles
**Decisions found:** {count} ({count} significant → {count} DRs created)
**Conflicts:** {count or "None"}
**Tasks completed:** {list of task IDs moved to done, or "None"}
**Quality summary:** {count} T1, {count} T2, {count} T3, {count} T4
```

## Step 12 — Final Report

Present a brief closing summary:

```
## Review Complete

- DRs created: {count}
- Tasks marked done: {count}
- Items needing follow-up: {count} (T3/T4 items pending senior review)
- Registry updated: yes/no

{If there are T3/T4 items:}
Next steps: {REVIEWER_ROLE} should review {item description} before acceptance.
```

## Rules

- **Collaborative:** Never create DRs or complete tasks without user approval. Always ask first.
- **Transparent:** Show the user everything you found. Do not silently skip decisions or conflicts.
- **Quality-first:** T3/T4 items must be flagged, never quietly accepted.
- **Append-only logging:** Never edit previous log entries. Only append new ones.
- **Valid transitions only:** Only transition tasks through allowed status paths (see `ago:update-task-status` skill for the valid transitions table).
