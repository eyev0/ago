---
description: Parse audit report action items, plan fixes via parallel agents, execute in worktrees with ADR generation
argument-hint: "<path/to/audit-report.md>"
---

# ago:fix-audit

You are executing the `ago:fix-audit` command. This command takes an **audit report** (produced by `ago:audit`), parses its action items, groups them by file dependency, dispatches parallel agents to plan and execute fixes, generates ADRs for non-trivial decisions, and creates draft PRs.

**This command does NOT require `.workflow/` — it works with any project that has a `docs/` directory.**

**Argument:** `$ARGUMENTS` (path to an audit report file — typically provided via `@` file tag).

## Step 1 — Parse Audit Report

Read the file at `$ARGUMENTS`.

- **If `$ARGUMENTS` is empty or blank:** Ask the user: "Which audit report should I fix? Provide a path (e.g., `docs/audit/2026-03-10-audit.md`)." Wait for a response. Do not proceed until a path is provided.
- **If the file does not exist:** Tell the user: "File not found: {path}. Check the path and try again." Stop.

### 1a — Validate format

The file must contain both `# Audit Report` and `## Action Items`. If either is missing, tell the user:

> This file does not look like an `ago:audit` report. Expected `# Audit Report` header and `## Action Items` section.
> Found: {list what IS present}

Stop.

### 1b — Parse action items

Walk the `## Action Items` section. It contains severity sub-sections: `### Critical`, `### High`, `### Medium`, `### Low / Recommendations` (or `### Low`).

For each sub-section, find unchecked items matching this pattern:

```
- [ ] **{title}** — {description}
  - Acceptance: {acceptance criteria}
  - Refs: {agent refs, ADR links}
  - Files: {comma-separated file paths}
```

Extract from each unchecked `- [ ]` item:
- `title` — the bold text after the checkbox
- `description` — text after the em-dash on the same line
- `acceptance` — the line starting with `- Acceptance:`
- `refs` — the line starting with `- Refs:`
- `files` — the line starting with `- Files:`, split by comma and trimmed
- `severity` — from the parent sub-section header (CRITICAL, HIGH, MEDIUM, LOW)

**Skip checked items** (`- [x]`). These are already resolved.

If zero unchecked items remain, tell the user: "All action items in this report are already resolved. Nothing to fix." Stop.

### 1c — Detect git root

From the audit report's directory, walk up the directory tree to find the nearest `.git` directory. This is the project root. All file paths in items are relative to this root.

Store the parsed items grouped by severity as `PARSED_ITEMS`. Store the total count and per-severity breakdown.

## Step 2 — Dependency Analysis

Group items so that agents don't conflict on shared files.

### 2a — File-level grouping

Build a map: `file_path -> [items that reference this file]`.

For items that share any file, merge them into the same **dependency group**. Use union-find logic: if item A touches files {X, Y} and item B touches files {Y, Z}, they belong in one group covering {X, Y, Z}.

### 2b — Import expansion (one hop)

For each unique file across all items, read it and extract import/include/use statements:

- **Rust:** `use crate::...`, `mod ...;`, `use super::...`
- **Swift:** `import ...`
- **TypeScript/JavaScript:** `import ... from '...'`, `require('...')`, `import('...')`
- **Python:** `import ...`, `from ... import ...`
- **Go:** `import "..."`, `import (...)`
- **Other languages:** Skip import analysis, fall back to file-level grouping only

Resolve import paths to actual file paths where possible (relative imports, crate-local imports). For imports that can't be resolved, skip them.

If item A's file imports a file that item B touches (directly, one hop only — no transitive closure), merge their dependency groups.

### 2c — Output

Result: a list of dependency groups, each containing:
- A set of items (with their full details)
- A set of files (union of all items' files plus import-expanded files)
- A flag: `has_file_overlap` (true if any two items share a file — means sequential execution within the group)

## Step 3 — Agent Assignment

### 3a — Dedicated agents for non-low groups

For each dependency group that contains any Critical, High, or Medium item:
- Assign a **dedicated agent**
- Order items within the group by severity: Critical first, then High, then Medium, then Low
- Critical items are treated the same as High for planning and execution: dedicated agent, individual ADR, full plan review
- These items execute sequentially within the agent (they share files)

### 3b — Batch low-only groups

For dependency groups containing only Low items:
- These are **batch candidates**
- Merge up to 5 Low items per batch agent
- Prefer merging groups that share the most files
- Lone low items that don't share files with any other group join the nearest batch (or form a new batch if none exists)

### 3c — Output

An ordered list of agents, each with:
- Agent number (1-based)
- A descriptive group label (e.g., "Group A", "Low batch 1")
- Ordered list of items
- Set of files the agent will touch
- Whether items are sequential (file overlap) or independent

## Step 4 — Grouping Screen

Present the plan to the user for lightweight confirmation:

```
## Fix Plan — {audit-report-filename}

**Items:** {N} unchecked ({X} critical, {Y} high, {Z} medium, {W} low)
**Agents:** {N} ({M} parallel, {K} with internal sequential ordering)
**Estimated draft PRs:** {N}

### Agent 1 — {group label} [{file list, abbreviated if >5}]
  {SEVERITY} — {title}
  {SEVERITY} — {title}

### Agent 2 — {group label} [{file list}]
  {SEVERITY} — {title}

### Agent 3 — Low batch [{file list}]
  LOW x{N} — {title}, {title}, ...

Proceed with planning? [yes / adjust / cancel]
```

- **yes** — proceed to Wave 1 (Step 5)
- **adjust** — user describes changes in natural language (e.g., "move item 3 to Agent 1", "split Agent 2 into two"). Re-run grouping with the constraint and re-present this screen.
- **cancel** — stop

**Do NOT proceed until the user explicitly confirms.**

## Step 5 — Wave 1: Planning (parallel agents)

Launch N planning agents in parallel using the Agent tool. **No worktree isolation** (use default isolation) — planning agents are read-only and make no edits.

Each planning agent receives its assigned items and explores the codebase to formulate a fix plan. They do NOT edit any files.

For each agent, use the Agent tool with this prompt:

```
You are planning fixes for audit findings. Do NOT edit any files — this is a read-only planning phase.

## Your Items

{For each item, include ALL details:}

### Item: {title}
- **Severity:** {CRITICAL/HIGH/MEDIUM/LOW}
- **Description:** {description}
- **Acceptance criteria:** {acceptance}
- **Refs:** {refs}
- **Files:** {files list}

{Repeat for each item assigned to this agent}

## Instructions

For each item in order:

1. **Read the referenced files** to understand the current state of the code
2. **Brainstorm 2-3 approaches** to fix the issue
3. **Pick the best approach** — prefer the simplest solution that fully meets the acceptance criteria
4. **Write a concrete plan:** what files to change, what to add or modify, key implementation details
5. For items where the fix involves a meaningful design choice (not just a bug fix or typo), note that an **ADR is needed** and describe what decision the ADR will document

## Output Format

For each item, output exactly this structure:

### {title}
**Approach:** {chosen approach in 3-5 lines — specific enough that another agent can implement it}
**Alternatives considered:** {brief list of rejected approaches and why they were rejected}
**Files to modify:** {list of files with what changes each needs}
**ADR needed:** {yes/no} — {if yes: what decision this ADR documents}
**Risk:** {what could go wrong during implementation, and how to mitigate}
```

## Step 6 — Plan Approval + ADR Number Pre-Allocation

After all planning agents return, present all plans at once for review.

### 6a — Present plans

```
## Plans Ready for Review

### Agent 1 — {group label}

#### {SEVERITY} — {title}
**Approach:** {agent's planned approach}
**Alternatives:** {what else was considered}
**ADR:** {yes — what it documents / no}
**Risk:** {agent's risk assessment}

#### {SEVERITY} — {title}
**Approach:** ...
...

### Agent 2 — {group label}
...

---

Approve all? [yes / approve individually / cancel]
```

- **yes** — all plans approved, proceed
- **approve individually** — user marks each item: approve / reject / edit. For edited items, user provides guidance text that gets appended to the plan.
- **cancel** — stop, no execution

**Wait for the user's response. Do not proceed until they answer.**

### 6b — ADR number pre-allocation

**Critical sub-step** — do this between approval and execution dispatch.

1. Read existing ADRs in `docs/adr/` (or `docs/decisions/`)
2. Determine the highest existing ADR number
3. For each approved item marked "ADR needed: yes", allocate the next sequential number
4. For batch agents with 3+ low items, allocate one number for the batch ADR
5. For batch agents with fewer than 3 low items, skip ADR generation
6. Pass pre-allocated ADR numbers to each execution agent

**Agents never pick their own ADR numbers.** This prevents collisions between parallel agents.

## Step 7 — Wave 2: Execution (parallel agents)

Launch agents for **approved plans only**. Each execution agent runs in an isolated worktree (`isolation: "worktree"`).

Rejected items are skipped entirely. Edited items carry the user's guidance text appended to the plan.

For each agent, use the Agent tool with `isolation: "worktree"` and this prompt:

```
You are implementing fixes for audit findings. Follow the approved plan.

## Your Approved Plan

{For each approved item in this agent:}

### Item: {title}
- **Severity:** {CRITICAL/HIGH/MEDIUM/LOW}
- **Description:** {description}
- **Acceptance criteria:** {acceptance}
- **Refs:** {refs}
- **Files:** {files list}
- **Approved approach:** {the plan from Wave 1, including any user edit guidance}
- **ADR number:** {pre-allocated NNN, or "none"}

{Repeat for each item}

## Implementation Instructions

For each item, in order:

1. **Implement the fix** as described in the approved approach
2. **Verify against acceptance criteria** — re-read the changed code and confirm each criterion is met
3. **Run relevant tests** — detect the project's test command:
   - `Cargo.toml` present → `cargo test`
   - `Package.swift` present → `swift test`
   - `package.json` with `test` script → `npm test` (or `yarn test`, `pnpm test`)
   - `pytest.ini` / `setup.py` / `pyproject.toml` → `pytest`
   - `go.mod` present → `go test ./...`
   - `Makefile` with `test` target → `make test`
   - If no test command detected → skip tests, note in output
4. **If tests fail** → diagnose, fix, and retry once. If still failing after retry, note the failure and continue.

After all items are implemented:

5. **Self-review:** re-read all your changes as a unified diff (`git diff`). Check for:
   - Obvious mistakes or typos
   - Leftover debug code
   - Changes outside the scope of the approved plan
   - Consistency with the rest of the codebase

## ADR Generation

For each item where an ADR number was assigned, create the ADR file.

**Filename:** `docs/adr/{NNN}-{kebab-case-title}.md`

Match the existing project's ADR naming convention. Look at existing files in `docs/adr/` to detect whether the project uses `ADR-{NNN}-` prefix, bare `{NNN}-` prefix, or another pattern.

Create `docs/adr/` directory if it does not exist.

**ADR content:**

```markdown
# ADR-{NNN}: {Title}

**Status:** To Review
**Date:** {YYYY-MM-DD}
**Deciders:** ago:fix-audit (autonomous agent)

## Context

{From the original audit finding — why this needed fixing. Reference the audit report and specific files.}

## Decision

{The approach taken — what was implemented and why this approach was chosen.}

## Alternatives Considered

{From the planning phase — what other approaches were evaluated and why they were rejected.}

## Consequences

### Positive
- {What becomes easier, safer, or better}

### Negative
- {Trade-offs accepted, complexity introduced}

## Verification

- **Acceptance criteria:** {from the audit item}
- **Result:** {pass/fail with evidence — what you checked and what you found}

## Origin

- **Audit report:** {path to the audit report file}
- **Finding refs:** {original refs from the audit item}
- **Fix PR:** {will be filled after PR creation}
```

**Batch ADRs:** If this agent has 3 or more Low items, create **one** ADR covering all of them. Title it descriptively (e.g., "Low-severity cleanup batch from {date} audit"). If fewer than 3 Low items, skip ADR generation for those items.

## Commit

Stage all changes and commit:

```
fix({scope}): {concise summary of what was fixed}

Refs: ago:fix-audit, {audit report path}
```

Where `{scope}` is derived from the primary file or module changed. For batch fixes, use a general scope like `cleanup` or `audit-fixes`.

## Draft PR

Create a draft PR using the `gh` CLI:

```bash
gh pr create --draft --title "fix({scope}): {summary}" --body "{body}"
```

The PR body should include:
- **What was fixed:** list of items with titles and severities
- **Approach:** brief summary of the implementation approach
- **ADR links:** links to any ADR files created (relative paths)
- **Acceptance criteria results:** pass/fail for each item
- **Post-fix audit:** (to be filled by orchestrator)

If the `gh` CLI is not available or authentication fails, skip PR creation. Instead, report the branch name so the user can create the PR manually.

## Output

Report back with:
- List of items: title, severity, status (fixed/failed), acceptance result
- Files changed
- ADR(s) created (paths)
- PR number and URL (or branch name if gh unavailable)
- Test results (pass/fail/skipped)
- Any issues encountered
```

## Step 8 — Post-Fix Audit

After each execution agent completes, run a **lightweight re-audit** of that agent's changes. This is NOT a full `ago:audit` — it targets only the new diff.

### 8a — Launch review agent

For each completed execution agent:

1. The **orchestrator** runs `git diff {base-branch}...{agent-branch}` to capture the full diff of the execution agent's work
2. Launch a single review agent (no worktree isolation, default isolation) with the diff injected into the prompt:

```
You are reviewing changes made by an automated fix agent. Your job is to check for new issues introduced and verify acceptance criteria.

## Original Items

{List of items this agent was supposed to fix, with acceptance criteria}

## Changes Made

{The diff output captured by the orchestrator — injected here, not computed by this agent}

## Instructions

1. **Acceptance check:** For each item, verify the acceptance criteria are met by the diff. Mark each as PASS or FAIL with specific evidence.

2. **New issue scan:** Check the diff for:
   - New bugs or logic errors introduced
   - Security issues (hardcoded secrets, injection vectors, missing validation)
   - Test gaps (new code without tests, if the project has tests)
   - Style/consistency issues with surrounding code
   - Unintended side effects

3. **Verdict:**
   - If all acceptance criteria pass AND no new issues → **CLEAN**
   - If any issues found → list them with severity and specific file/line references

## Output Format

### Acceptance Results
| Item | Criteria | Result | Evidence |
|------|----------|--------|----------|
| {title} | {criterion} | PASS/FAIL | {what you checked} |

### New Issues
{If CLEAN: "No new issues detected."}
{If issues found:}
- **{severity}** — {title}: {description} ({file}:{line})

### Verdict: {CLEAN / NEEDS_RETRY}
```

### 8b — Handle results

- **CLEAN** — pass. The agent's work is accepted.
- **NEEDS_RETRY** — launch a NEW agent with `isolation: "worktree"` on the **same branch** as the execution agent's worktree. The execution agent must have committed its work (Step 7 requires a commit), so the retry agent will see the committed changes when it checks out the branch. The retry agent makes targeted fixes:

```
You are making targeted fixes to address issues found during post-fix review. Fix ONLY the specific issues listed — do not re-implement or refactor beyond what is needed.

## Original Plan
{The approved plan from Wave 1}

## Changes Already Made
{git diff showing the execution agent's work}

## Issues to Fix
{The new issues identified by the review agent}

## Instructions
1. Fix each listed issue
2. Do NOT undo or rewrite the execution agent's correct work
3. Run tests after fixes
4. Amend the existing commit or create a follow-up commit:
   fix({scope}): address post-fix review findings

   Refs: ago:fix-audit, {audit report path}
5. Update the draft PR (or create it if it doesn't exist yet)

## Output
- List of issues: which were fixed, which remain unresolved
- Test results
- Updated PR number/URL
```

After the retry agent completes, **do not retry again**. One retry maximum. If issues remain after retry, note them in the PR description as unresolved findings and proceed.

## Step 9 — Completion

After all agents (execution + post-fix audit + retries) have finished, collect all results and present the summary.

### 9a — Summary table

```
## Fix Run Complete

**Source:** {audit-report-filename}
**Agents:** {N} dispatched, {M} completed, {K} failed
**Items fixed:** {X}/{Y} ({Z} rejected at planning)

### Results

| # | Item | Severity | Status | PR | ADR |
|---|------|----------|--------|----|-----|
| 1 | {title} | HIGH | fixed | #{num} (draft) | ADR-{NNN} |
| 2 | {title} | MEDIUM | fixed | #{num} (draft) | -- |
| 3 | {title} | LOW | failed (test) | #{num} (draft) | -- |
| 4 | {title} | MEDIUM | rejected | -- | -- |

### Post-Fix Audit Results
- Agent 1: CLEAN
- Agent 2: 1 new finding (resolved on retry)
- Agent 3: 2 unresolved findings (noted in PR)

### ADRs Created (all Status: To Review)
- `docs/adr/{NNN}-{title}.md`
- `docs/adr/{NNN}-{title}.md`

**Note:** Draft PRs branch from the same base — review and merge in order, rebasing as needed.
```

### 9b — Update original audit report

Read the original audit report file. For each item that was successfully fixed, change its checkbox from `- [ ]` to `- [x]` and append fix metadata:

```
- [x] **{title}** — Fixed by ago:fix-audit, PR #{num}, ADR-{NNN}
```

If the item had no ADR, omit the ADR reference. If no PR was created (gh unavailable), reference the branch name instead.

Write the updated audit report back to disk.

### 9c — Suggest next steps

```
Next steps:
1. Review draft PRs and merge in order (rebase as needed)
2. Run `ago:audit` again after merging to verify resolution
3. Review ADRs marked "To Review" and accept or revise them
```

## Step 10 — Bridge

If **all items were fixed** and **all post-fix audits were clean**: skip the bridge. End with the summary from Step 9 and the suggestion: "All items resolved cleanly. Run `ago:audit` again to verify."

If there are **unresolved items, failed fixes, or post-fix audit findings**, present the bridge:

```
## Unresolved Items

{List items that were not fully resolved — failed fixes, rejected items, unresolved post-fix findings}

These items may benefit from a collaborative brainstorming session to explore alternative approaches.

**Artifacts:**
- `{audit report path}` (updated with fix results)
{- `docs/adr/{NNN}-{title}.md` (for each ADR created)}
{- Draft PRs: #{num}, #{num}, ...}

**Unresolved context:**
{- 1 line per unresolved item with its core challenge}

Want to brainstorm approaches for unresolved items?
[yes / adjust context / not now]
```

- **"yes"** — Invoke `superpowers:brainstorming` skill. Pass the context block above as the starting point. Brainstorming will read the referenced artifact files for full details.
- **"adjust context"** — Let the user modify the context block, then invoke brainstorming with the adjusted version.
- **"not now"** — End the command. All artifacts are on disk for later use.

## Rules

- **Collaborative** — never execute without user approval at the plan stage. Two explicit checkpoints: grouping screen (Step 4) and plan approval (Step 6). Users can adjust, reject, or edit at both.
- **Evidence-based** — agents must reference specific files and acceptance criteria. Plans without concrete file references are rejected. Post-fix audits verify against acceptance criteria with evidence.
- **No `.workflow/` dependency** — uses only `docs/`, git, and the `gh` CLI. Works with any project that has a `docs/` directory.
- **Agents are isolated** — each execution agent runs in its own worktree. No cross-agent communication. The orchestrator is the only coordinator.
- **ADR status: To Review** — all ADRs created by agents use "To Review" status. Agent decisions need human ratification. `ago:audit-docs` will flag unreviewed ADRs.
- **Draft PRs only** — agents never merge. The user is the merge gatekeeper. PRs are always created with `--draft`.
- **Idempotent** — re-running `ago:fix-audit` on the same report skips `[x]` items. Only unchecked items are processed. Running it again after partial completion picks up where it left off.
- **Graceful degradation** — `gh` CLI unavailable: skip PR creation, report branch names. No test command detected: skip tests, note in output. Import analysis fails for unknown language: fall back to file-level grouping only. Single agent failure does not block other agents.
- **One-shot** — this is a single command execution, not a loop. The workflow is: `ago:audit` -> review -> `ago:fix-audit` -> review PRs -> merge -> `ago:audit` again.
- **ADR numbers are pre-allocated** — the orchestrator assigns ADR numbers between plan approval and execution dispatch. Agents never choose their own numbers. This prevents collisions between parallel agents.
