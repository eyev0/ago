---
name: ago-fix-audit
description: Use when the user wants to execute fixes from an ago audit report, especially when the report contains grouped action items, acceptance criteria, and file references
---

# ago-fix-audit

## Overview

Execute an `ago` audit report by turning unchecked action items into an approved fix plan, then carrying that plan through isolated implementation, review, and report updates.

Core principle: plan first, get explicit approval twice, then execute in parallel only where file ownership does not conflict.

## When to Use

- The user has an `ago:audit` report with unresolved action items
- The report already contains acceptance criteria and file references
- The user wants grouped planning, execution, ADR capture, and draft-PR style output

Do not use this skill when:
- there is no audit report yet
- the user wants a fresh audit rather than fixes
- the work is a single tiny edit that does not need grouping or approval waves

## Inputs

- Audit report path, usually under `docs/audit/YYYY-MM-DD-audit.md`

Expected report structure:

```text
# Audit Report
## Action Items
### Critical / High / Medium / Low
- [ ] **Title** — description
  - Acceptance: ...
  - Refs: ...
  - Files: ...
```

## Workflow

### 1. Parse the audit report

- Read the file given by the user
- Stop if the path is missing or the file does not exist
- Confirm the file looks like an `ago` audit report by checking for `# Audit Report` and `## Action Items`
- Extract only unchecked items
- For each item, capture:
  - title
  - description
  - acceptance criteria
  - refs
  - files
  - severity
- Stop if all items are already checked

Resolve the git root from the audit report location so all file paths are interpreted relative to the project.

### 2. Build dependency groups

Group items so execution agents do not fight over the same files.

- Merge items that reference the same file
- Expand one hop through imports when that can be resolved
- Keep Critical, High, and Medium work in dedicated groups
- Merge low-only groups into cleanup batches of up to 5 items

Output a concrete agent plan:
- agent label
- items in severity order
- files touched
- whether work inside that group must stay sequential

### 3. Approval gate: grouping screen

Show the grouped execution plan before any planning agents run.

Present:
- total unchecked items by severity
- number of proposed agents
- top file sets per agent
- item list per agent

Ask for one of:
- `yes`
- `adjust`
- `cancel`

Do not continue until the user explicitly approves.

### 4. Wave 1: planning agents

Launch planning agents in parallel. They are read-only.

Each planning agent must:
- read the files for its assigned items
- brainstorm 2-3 approaches
- choose the simplest complete approach
- specify files to modify
- decide whether an ADR is needed
- note implementation risks

The planning output for each item must include:
- approach
- alternatives considered
- files to modify
- ADR needed: yes/no
- risk

### 5. Approval gate: plan review

Present all plans together and wait for approval again.

Valid responses:
- `yes`
- `approve individually`
- `cancel`

If the user edits an item plan, carry that guidance into execution exactly.

Before execution:
- inspect existing ADRs in `docs/adr/` or `docs/decisions/`
- allocate ADR numbers centrally
- never let parallel agents choose ADR numbers themselves

### 6. Wave 2: execution agents

Launch execution agents only for approved items, each in an isolated worktree or equivalent isolated branch context.

Each execution agent must:
- implement only the approved plan
- verify acceptance criteria item by item
- run the best available project test command
- retry once if tests fail
- self-review its diff
- create ADRs for items that were pre-allocated ADR numbers
- commit with an `ago:fix-audit` reference
- create a draft PR when `gh` is available, otherwise report the branch name

Batch rule:
- if a low-severity batch contains 3 or more items, create one batch ADR
- otherwise skip ADR creation for that batch

### 7. Post-fix audit

After each execution agent finishes:

- diff the agent branch against its base
- run a focused review agent against that diff
- verify acceptance criteria and scan for new issues

If the review is clean:
- accept the result

If the review finds issues:
- launch one retry agent on the same branch
- fix only the listed findings
- do not retry more than once

### 8. Completion

At the end, present:
- items fixed vs failed vs rejected
- PR or branch reference per item/group
- ADRs created
- post-fix audit status per agent

Then update the original audit report:
- mark fixed items as `[x]`
- append PR, branch, and ADR references where available

Suggested next steps:
1. Review and merge draft PRs in dependency order
2. Re-run `ago:audit`
3. Review ADRs marked `To Review`

### 9. Bridge for unresolved work

If everything is fixed cleanly, stop after the completion summary.

If unresolved items remain:
- present them explicitly
- reference the updated audit report and any ADRs created
- offer a brainstorming handoff for unresolved items

## Artifact Outputs

- Updated audit report at its original path
- Optional ADRs under `docs/adr/NNN-{title}.md`
- Draft PRs or branch names for implementation agents

## Rules

- Require user approval twice: once for grouping, once for the final plans
- Keep planning agents read-only
- Keep execution agents isolated from each other
- Use only project-local evidence: report contents, referenced files, test output, diff review
- Create ADRs with status `To Review`
- Never merge PRs automatically
- Re-running this skill must skip already checked audit items
- If `gh` is unavailable, degrade gracefully to branch-name reporting
- If no test command exists, say so and continue with explicit note
