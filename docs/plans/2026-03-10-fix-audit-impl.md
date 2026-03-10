# `ago:fix-audit` Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `ago:fix-audit` command that parses an audit report, groups action items by dependency, plans fixes via parallel agents, gets user approval, then executes fixes in isolated worktrees with ADR generation and draft PRs.

**Architecture:** Single command file (`fix-audit.md`) following the same natural-language-prompt pattern as `audit.md`, `research.md`, `write-adr.md`, and `audit-docs.md`. The command orchestrates parallel agents via the Agent tool with `isolation: "worktree"`. No external dependencies.

**Tech Stack:** Claude Code plugin command (markdown prompt), Agent tool with worktree isolation, `gh` CLI for draft PRs.

**Design spec:** `docs/plans/2026-03-10-fix-audit-design.md`

---

## Chunk 1: Command File — Core Structure

### Task 1: Create command file with frontmatter and Steps 1-3

**Files:**
- Create: `plugins/ago/commands/fix-audit.md`

- [ ] **Step 1: Write YAML frontmatter**

```yaml
---
description: Parse audit report action items, plan fixes via parallel agents, execute in worktrees with ADR generation
argument-hint: "<path/to/audit-report.md>"
---
```

Pattern matches existing commands: `description` is a one-liner, `argument-hint` shows expected input.

- [ ] **Step 2: Write command header and introduction**

```markdown
# ago:fix-audit

You are executing the `ago:fix-audit` command. This command takes an **audit report** (produced by `ago:audit`), parses its action items, groups them by file dependency, dispatches parallel agents to plan and execute fixes, generates ADRs for non-trivial decisions, and creates draft PRs.

**This command does NOT require `.workflow/` — it works with any project that has a `docs/` directory.**

**Argument:** `$ARGUMENTS` (path to an audit report file — typically provided via `@` file tag).
```

- [ ] **Step 3: Write Step 1 — Parse Audit Report**

This step reads and validates the audit report file, extracts unchecked action items with their metadata (title, description, acceptance criteria, refs, files), detects git root from the file's location.

Key parsing rules:
- Sections delimited by `### Critical`, `### High`, `### Medium`, `### Low / Recommendations`
- Each item: `- [ ] **{title}** — {description}` followed by indented metadata lines
- Skip `- [x]` items (already resolved)
- Extract `files` by splitting the `- Files:` line on commas and trimming backticks/whitespace

Must handle: file not found, not an audit report (missing headers), zero unchecked items.

- [ ] **Step 4: Write Step 2 — Dependency Analysis**

This step builds a dependency graph from the parsed items' file lists:
1. Build `file → [items]` map from all items' `files[]`
2. Merge items sharing any file into dependency groups (union-find style)
3. One-hop import expansion: read each unique file, extract import/include/use statements, merge groups connected by imports
4. Output: list of dependency groups

Important: instruct Claude to read the actual files to find imports. Languages to handle: Rust (`use`/`mod`), Swift (`import`), TypeScript/JS (`import`/`require`), Python (`import`/`from`). For unknown languages, skip import expansion — file-level grouping is sufficient.

- [ ] **Step 5: Write Step 3 — Agent Assignment**

Groups → agents:
- Dependency groups with Critical/High/Medium items → dedicated agent, items ordered by severity (critical first)
- Low-only groups → batch candidates, merge up to 5 per agent
- Output: ordered list of agents with their items and file sets

- [ ] **Step 6: Verify structure matches existing command patterns**

Read the written file and compare structure against `audit.md`:
- Same frontmatter pattern
- Same step numbering style
- Same `$ARGUMENTS` reference
- Same "does NOT require .workflow" disclaimer

Run: `wc -l plugins/ago/commands/fix-audit.md` to verify progress.

- [ ] **Step 7: Commit**

```bash
git add plugins/ago/commands/fix-audit.md
git commit -m "feat(ago): add fix-audit command — steps 1-3 (parse, deps, assign)"
```

---

### Task 2: Write Steps 4-6 — Grouping Screen, Planning Wave, Plan Approval

**Files:**
- Modify: `plugins/ago/commands/fix-audit.md`

- [ ] **Step 1: Write Step 4 — Grouping Screen**

Present the execution plan to the user for lightweight confirmation. Format:
```
## Fix Plan — {filename}
**Items:** N unchecked (breakdown)
**Agents:** N (M parallel, K sequential)
**Estimated draft PRs:** N

### Agent 1 — Group A [files]
  SEVERITY — title
  ...
```

Options: `[yes / adjust / cancel]`
- `adjust`: user describes changes in natural language, orchestrator re-groups and re-presents
- Important: **do NOT proceed until user confirms**

- [ ] **Step 2: Write Step 5 — Wave 1: Planning**

Launch N planning agents in parallel using the Agent tool. Each agent:
- Receives its items with full details
- Reads referenced files for context (read-only, no edits)
- Brainstorms 2-3 approaches per item
- Picks simplest approach meeting acceptance criteria
- Returns structured plan per item (approach, alternatives, files, ADR needed, risk)

Planning agents are read-only — instruct them explicitly to NOT edit files. No worktree isolation needed for planning agents (they don't write anything). Use default isolation.

Include the full planning agent prompt template in the command.

- [ ] **Step 3: Write Step 6 — Plan Approval**

After all planning agents return, present all plans at once. Per item: approach, alternatives, ADR decision, risk assessment.

Options:
- `yes` — all approved
- `approve individually` — per-item approve/reject/edit
- `cancel` — stop

For edited items: user's guidance text appended to plan.

**ADR number pre-allocation:** Between approval and execution, read existing ADRs in `docs/adr/`, determine highest number, allocate sequential numbers to each agent's approved ADR-needing items. Pass pre-allocated numbers to execution agents.

- [ ] **Step 4: Commit**

```bash
git add plugins/ago/commands/fix-audit.md
git commit -m "feat(ago): fix-audit steps 4-6 (grouping, planning wave, approval)"
```

---

### Task 3: Write Steps 7-9 — Execution, Post-Fix Audit, Completion

**Files:**
- Modify: `plugins/ago/commands/fix-audit.md`

- [ ] **Step 1: Write Step 7 — Wave 2: Execution**

Launch agents for approved plans only, each in isolated worktree.

Execution agent prompt template must include:
1. The approved plan text (with user edits if any)
2. Items with acceptance criteria
3. Instructions: implement → verify acceptance → run tests → retry once on failure → self-review
4. ADR generation instructions with pre-allocated number and template
5. Commit message format: `fix({scope}): {summary}\n\nRefs: ago:fix-audit, {report path}`
6. Draft PR creation via `gh pr create --draft`

ADR template follows project convention:
- Filename: `{NNN}-{kebab-case-title}.md` (detect existing convention)
- Status: "To Review"
- Includes: Context, Decision, Alternatives Considered, Consequences, Verification, Origin
- For batch ADRs (3+ low items in batch): one ADR covering all items. Batches with fewer than 3 items skip ADR generation.

Include the full execution agent prompt template and the full ADR template in the command.

- [ ] **Step 2: Write Step 8 — Post-Fix Audit**

Lightweight re-audit per agent (NOT full `ago:audit`):
1. Launch single review agent with the execution agent's diff
2. Agent checks: new issues introduced? Acceptance criteria met?
3. If clean → pass
4. If findings → launch NEW agent in same worktree with original plan + diff + findings
5. Retry agent makes targeted fixes only
6. After retry → create/update draft PR regardless, note unresolved findings

- [ ] **Step 3: Write Step 9 — Completion**

Collect all agent results, present summary table:
- Per item: severity, status, PR link, ADR link
- Post-fix audit results per agent
- ADRs created list

Update original audit report: mark fixed items `[x]` with PR/ADR references.

Include worktree conflict warning in completion summary: "Draft PRs branch from the same base — review and merge in order, rebasing as needed to resolve conflicts."

- [ ] **Step 4: Write Step 10 — Bridge**

Following the pattern from all other `ago:` commands (`audit.md`, `research.md`, `write-adr.md`, `audit-docs.md`), add a bridge section at the end.

If all items were fixed and all post-fix audits are clean → skip bridge, end with summary.

If unresolved items or failed fixes remain, present:
```
## Remaining work

**Artifacts:**
- Draft PRs: {list with links}
- ADRs created: {list}
- Unresolved items: {list}

**Suggested next step:** Review and merge draft PRs, then run `ago:audit` to verify resolution.
For unresolved items: brainstorming → writing-plans → implementation

Want to start brainstorming with unresolved items?
[yes / adjust context / not now]
```

- **"yes"** → invoke `superpowers:brainstorming` with unresolved items as context
- **"not now"** → end, artifacts on disk

- [ ] **Step 5: Commit**

```bash
git add plugins/ago/commands/fix-audit.md
git commit -m "feat(ago): fix-audit steps 7-10 (execution, post-audit, completion, bridge)"
```

---

## Chunk 2: Rules, Edge Cases, and Integration

### Task 4: Write Rules section and edge case handling

**Files:**
- Modify: `plugins/ago/commands/fix-audit.md`

- [ ] **Step 1: Write Rules section**

Following the pattern from `audit.md` and other commands. Rules:
- **Collaborative** — never execute without user approval at the plan stage
- **Evidence-based** — agents must reference specific files and acceptance criteria
- **No `.workflow/` dependency** — uses only `docs/`, git, and `gh` CLI
- **Agents are isolated** — each agent works in its own worktree, no cross-agent communication
- **ADR status: To Review** — agent decisions need human ratification
- **Draft PRs only** — agents never merge, user is the merge gatekeeper
- **Idempotent** — running on same report skips `[x]` items, safe to re-run
- **Graceful degradation** — if `gh` CLI unavailable, skip PR creation and report. If no test command detected, skip test step. If import analysis fails for a language, fall back to file-level grouping.

- [ ] **Step 2: Write edge case handling inline**

Ensure these are addressed at the appropriate steps (not as a separate section — integrated into the step instructions):
- Empty/no unchecked items → Step 1 stops with message
- Single dependency group → Step 3 assigns one agent
- Agent failure → Step 9 marks as failed, doesn't block others
- No `docs/adr/` → Step 7 agent creates it
- No test command → Step 7 agent skips tests, notes in PR
- `gh` not available → Step 7 agent skips PR, reports branch name instead

- [ ] **Step 3: Commit**

```bash
git add plugins/ago/commands/fix-audit.md
git commit -m "feat(ago): fix-audit rules and edge case handling"
```

---

### Task 5: Update plugin metadata and documentation

**Files:**
- Modify: `CLAUDE.md`
- Modify: `plugins/ago/.claude-plugin/plugin.json`

- [ ] **Step 1: Add fix-audit to CLAUDE.md command table**

In the Commands table, add:
```
| `ago:fix-audit` | Parse audit report, plan + execute fixes via parallel agents in worktrees |
```

- [ ] **Step 2: Bump version and update description in plugin.json**

Minor version bump (new command = new feature, backward-compatible): `1.1.0` → `1.2.0`

Update `description` to: `"Lightweight code audit, research, documentation review, ADR capture, and automated fix commands"`

Add `"fix"` to `keywords` array.

- [ ] **Step 3: Update MEMORY.md**

Add `ago:fix-audit` to the "Lightweight Commands" section in `/Users/eyev/.claude/projects/-Users-eyev-dev-claude-workflow/memory/MEMORY.md`:
```
- `ago:fix-audit` — Parse audit report → dependency analysis → parallel agent planning → approval → execution in worktrees → ADRs + draft PRs. Tiered autonomy: Critical/High/Medium get plans reviewed, Low batched.
```

- [ ] **Step 4: Verify command auto-discovery**

Claude Code auto-discovers commands from `plugins/ago/commands/`. Verify no registration needed in `plugin.json` by checking that existing commands (audit, research, etc.) are NOT individually listed in plugin.json — they're discovered by directory convention.

Run: `cat plugins/ago/.claude-plugin/plugin.json` to confirm.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md plugins/ago/.claude-plugin/plugin.json
git commit -m "docs: add fix-audit to command table, bump version to 1.2.0"
```

---

### Task 6: Final verification

**Files:**
- Read: `plugins/ago/commands/fix-audit.md` (full review)

- [ ] **Step 1: Verify command file completeness**

Read the full command file and check:
- All 10 steps present and in order (including Step 10 — Bridge)
- YAML frontmatter valid
- Agent prompt templates complete (planning + execution + review + retry)
- ADR template matches project convention
- Rules section present
- All user interaction points have explicit "wait for response" instructions
- No references to `.workflow/`

- [ ] **Step 2: Verify consistency with design spec**

Cross-reference against `docs/plans/2026-03-10-fix-audit-design.md`:
- Tiered autonomy: Critical/High/Medium get individual plans+ADRs, Low batched ✓
- Dependency analysis: file + one-hop import ✓
- Two prompts: grouping (lightweight) + plan approval (the real checkpoint) ✓
- Post-fix audit: lightweight review + 1 retry via new agent ✓
- ADR numbers pre-allocated by orchestrator ✓
- Draft PRs only ✓

- [ ] **Step 3: Check file size is reasonable**

Run: `wc -l plugins/ago/commands/fix-audit.md`
Expected: 500-750 lines (audit.md is 650 lines, fix-audit should be similar or larger given it has more agent prompts)

- [ ] **Step 4: Commit any fixes**

If any issues found in verification, fix and commit:
```bash
git add plugins/ago/commands/fix-audit.md
git commit -m "fix(ago): fix-audit verification fixes"
```
