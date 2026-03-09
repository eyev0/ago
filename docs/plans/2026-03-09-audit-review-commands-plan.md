# Audit & Review Commands Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create three new ago commands (audit, research, sync-docs) that provide multi-role review, research capture, and documentation sync — working with existing `docs/` project structure, no `.workflow/` needed.

**Architecture:** Each command is a markdown file in `plugins/ago/commands/` with YAML frontmatter and step-by-step instructions. Commands spawn role agents via the Agent tool with custom audit-mode prompts (not the standard .workflow/-dependent prompts). Agent definitions are referenced for role context but overridden with audit-specific instructions.

**Tech Stack:** Claude Code plugin commands (markdown), Agent tool for subagents, git CLI for history

---

### Task 1: Create `ago:audit` command

**Files:**
- Create: `plugins/ago/commands/audit.md`

**Step 1: Write the audit command file**

```markdown
---
description: Multi-role retrospective review — ARCH, SEC, QAL, PM analyze recent work from different angles
argument-hint: "[--since '3 days ago' | --commits 20]"
---

# ago:audit

You are executing the `ago:audit` command. This performs a retrospective multi-role review of recent project work by analyzing git history, plans, code, and documentation. You act as MASTER — orchestrating role agents, not doing the review yourself.

**Arguments:** `$ARGUMENTS` (optional: `--since "3 days ago"`, `--commits 20`, or empty for auto-detection)

## Step 1 — Determine review scope

Determine which commits to review:

1. **If `$ARGUMENTS` contains `--since`:** Extract the date/duration and use `git log --oneline --since="{value}"`.
2. **If `$ARGUMENTS` contains `--commits`:** Extract the number N and use `git log --oneline -n {N}`.
3. **If `$ARGUMENTS` is empty:** Check if `docs/.last-audit` exists.
   - If it exists: read the SHA from it and use `git log --oneline {sha}..HEAD`.
   - If it does not exist: default to `git log --oneline -n 30`.

Run the git log command. If no commits are found, tell the user "No commits found in the specified range." and stop.

## Step 2 — Gather context

Read the following files to build context for the review agents (skip any that don't exist):

1. **Git log** — the commit list from Step 1 (already collected)
2. **Git diff stats** — run `git diff --stat {start_sha}..HEAD` to see which files changed
3. **Plans** — scan `docs/plans/` for files matching the date range of the commits. Read their headers to understand what was planned.
4. **ADRs** — read `docs/adr/README.md` (if it exists) for the ADR index. Note existing ADRs so agents don't duplicate them.
5. **Project docs** — read `CLAUDE.md` and any top-level product docs to understand project context.

Compile this into a context brief (in your working memory, not a file).

## Step 3 — Present scope to user

Show the user what will be reviewed:

```
## Audit Scope

**Commits:** {count} ({oldest_date} → {newest_date})
**Files changed:** {count} files across {directories}
**Plans found:** {list of plan files in date range, or "none"}
**Existing ADRs:** {count} ({highest number} is latest)

Launching 4 review agents: ARCH, SEC, QAL, PM
```

Ask the user: "Proceed with audit? (yes/no)"

**Do NOT launch agents until the user confirms.**

## Step 4 — Launch review agents

Spawn 4 agents in parallel using the Agent tool. Each agent gets the same context brief but different review instructions.

**For each agent, pass this prompt structure:**

```
You are the {ROLE} reviewer performing a retrospective audit.

## Context
- Project: {project name from CLAUDE.md}
- Review period: {date range}
- Commits: {full git log output}
- Files changed: {git diff stat output}
- Related plans: {list of plan file paths}
- Existing ADRs: {count, with titles of recent ones}

## Your Review Focus
{role-specific focus — see below}

## Instructions
1. Read the commit messages and diff stats to understand what changed
2. Read the most relevant changed files (focus on your area)
3. Read any related plans from docs/plans/
4. Analyze from your perspective
5. Produce a structured review with:
   - **Summary:** 2-3 sentences on what happened in your domain
   - **Findings:** Numbered list of observations (good or concerning)
   - **Decisions detected:** Any implicit or explicit decisions that should be an ADR
   - **Recommendations:** What to do next from your perspective

Be specific — reference file paths, commit SHAs, and concrete code patterns.
Do NOT hallucinate findings. If you can't find evidence, say so.
```

### Role-specific focus:

**ARCH agent:**
```
## Your Review Focus
Architecture and technical design. Look for:
- Architectural decisions made (explicitly or implicitly in code)
- Tech debt introduced or resolved
- System boundaries changed (new modules, removed components, API changes)
- Design patterns used or violated
- Performance implications of changes
- Dependencies added or removed
```

**SEC agent:**
```
## Your Review Focus
Security posture. Look for:
- Security-relevant changes (auth, crypto, input handling, API endpoints)
- Hardcoded secrets, credentials, or tokens in commits
- Dependency changes that affect security surface
- Permission/access control changes
- Data handling patterns (PII, encryption, storage)
- OWASP Top 10 patterns in new/changed code
```

**QAL agent:**
```
## Your Review Focus
Quality and test coverage. Look for:
- Test files added, modified, or deleted
- Code changes without corresponding test changes
- Coverage gaps (new features without tests)
- Test quality (are tests meaningful or just checking happy paths?)
- Error handling patterns (are edge cases covered?)
- Regression risk from changes
```

**PM agent:**
```
## Your Review Focus
Product and user impact. Look for:
- User-facing changes (UI, API, behavior changes)
- Feature scope — does what was built match what was planned?
- Scope creep or missing requirements
- UX implications of technical decisions
- Product documentation gaps (README, user docs)
- Prioritization signals (what got attention vs what was deferred)
```

## Step 5 — Consolidate findings

After all 4 agents return, compile their results into a consolidated report:

```
## Audit Report — {date range}

### Summary
{2-3 sentences synthesizing across all 4 perspectives}

### ARCH Findings
{agent output}

### SEC Findings
{agent output}

### QAL Findings
{agent output}

### PM Findings
{agent output}

### Decisions Detected
{Merged and deduplicated list of decisions from all agents}

1. **{title}** (detected by: {ROLE(s)})
   Context: {why}
   Decision: {what was decided}

### Cross-cutting Concerns
{Any findings that multiple agents flagged}

### Recommendations
{Prioritized list of next actions}
```

## Step 6 — Propose ADRs

From the "Decisions Detected" list, identify which ones are significant enough to become ADRs. A decision is ADR-worthy if it:
- Affects architecture, security model, or technology choices
- Is hard to reverse
- Was made implicitly (in code) and should be documented explicitly

Present the proposed ADRs:

> **Proposed ADRs:**
> 1. ADR-{NNN}: {title} — {one-line summary}
> 2. ADR-{NNN}: {title} — {one-line summary}
>
> Write these ADRs? Enter numbers (e.g., "1, 2"), "all", or "none".

**Wait for user approval before writing any files.**

## Step 7 — Write ADRs

For each approved ADR:

1. Determine the next ADR number by scanning `docs/adr/` for the highest existing number and incrementing.
2. Create the file at `docs/adr/{NNN}-{kebab-case-title}.md` using this format:

```markdown
# ADR-{NNN}: {Title}

**Status:** Proposed
**Date:** {today YYYY-MM-DD}
**Detected by:** ago:audit ({ROLE(s)} review)

## Context
{Why this decision was made — from commit context and code analysis}

## Decision
{What was decided — extracted from actual code/commits}

## Consequences
{What this means going forward — positive and negative}
```

3. Update `docs/adr/README.md` — add the new ADR to the index table if a README exists.

Report each ADR created: "Created: `docs/adr/{filename}`"

## Step 8 — Update audit bookmark

Write the current HEAD SHA to `docs/.last-audit`:

```
{git rev-parse HEAD}
```

This single line is the only content. No other metadata.

## Step 9 — Final summary

```
## Audit Complete

- **Commits reviewed:** {count}
- **Agents ran:** ARCH, SEC, QAL, PM
- **Findings:** {total count across all agents}
- **ADRs created:** {count} ({filenames})
- **Bookmark updated:** docs/.last-audit → {short SHA}

Next audit will start from this point.
```

## Rules

- **Collaborative:** Never write ADRs without user approval.
- **Evidence-based:** Every finding must reference a commit, file, or code pattern. No speculation without marking it as such.
- **Non-destructive:** Never modify existing code. Only create docs/adr/ files and update docs/.last-audit.
- **Idempotent:** Running audit twice on the same range produces the same findings.
```

**Step 2: Verify command file renders correctly**

Run: `head -5 plugins/ago/commands/audit.md`
Expected: YAML frontmatter with description and argument-hint

**Step 3: Commit**

```bash
git add plugins/ago/commands/audit.md
git commit -m "feat: add ago:audit command — multi-role retrospective review"
```

---

### Task 2: Create `ago:research` command

**Files:**
- Create: `plugins/ago/commands/research.md`

**Step 1: Write the research command file**

```markdown
---
description: Structured research session — deep-research a topic and save findings as a docs artifact
argument-hint: "<topic>"
---

# ago:research

You are executing the `ago:research` command. This structures a research session into a reusable artifact with clear findings and conclusions.

**Arguments:** `$ARGUMENTS` (required: research topic or question)

## Step 1 — Validate input

If `$ARGUMENTS` is empty, ask the user: "What topic do you want to research?" and wait for their response.

## Step 2 — Understand project context

Read these files (skip any that don't exist):
1. `CLAUDE.md` — project overview and tech stack
2. `docs/adr/README.md` — existing decisions (to avoid re-researching settled questions)
3. Any existing `docs/research/` files — to understand what's been researched before

## Step 3 — Formulate research questions

Based on the topic and project context, propose 3-5 specific research questions:

```
## Research Plan: {topic}

**Questions to investigate:**
1. {specific question}
2. {specific question}
3. {specific question}

**Approach:** {web search / code analysis / benchmark / comparison}
**Expected output:** {what the artifact will contain}
```

Ask: "Good research questions? Adjust or proceed?"

**Wait for user confirmation.**

## Step 4 — Conduct research

For each research question:

1. Use WebSearch/WebFetch for external information
2. Use Read/Grep/Glob for codebase analysis
3. Use Bash for running benchmarks or tests if applicable
4. Cross-reference findings with existing ADRs

Track sources for each finding. Every claim must have a source.

## Step 5 — Write research artifact

Create the file at `docs/research/{YYYY-MM-DD}-{kebab-case-topic}.md`:

```markdown
# Research: {Topic Title}

**Date:** {YYYY-MM-DD}
**Author:** ago:research (ARCH/SEC/PM perspective)
**Status:** Complete | Partial (needs follow-up)

## Context
{Why this research was conducted — 2-3 sentences}

## Questions Investigated
1. {question}
2. {question}

## Findings

### {Question 1 summary}
{findings with sources}

**Sources:**
- {URL or file path}
- {URL or file path}

### {Question 2 summary}
{findings with sources}

## Conclusions
{Key takeaways — numbered list}

## Recommendations
{What to do with these findings — actionable next steps}

## Architectural Decisions
{If any findings imply an architectural decision, list them here}
- **{decision title}:** {one-line description} → suggested ADR
```

## Step 6 — Propose ADRs (if applicable)

If the research uncovered architectural decisions (technology choices, approach selections, trade-offs resolved), propose them as ADRs:

> **This research suggests the following ADRs:**
> 1. ADR-{NNN}: {title}
>
> Write these ADRs to `docs/adr/`? Enter numbers, "all", or "none".

If approved, write ADRs using the same format as `ago:audit` Step 7. Update `docs/adr/README.md` index.

## Step 7 — Report

```
## Research Complete

- **Topic:** {topic}
- **Artifact:** `docs/research/{filename}`
- **Sources cited:** {count}
- **ADRs created:** {count or "none"}
- **Status:** {Complete | Partial — needs follow-up on: ...}
```

## Rules

- **Every claim needs a source.** No unsourced assertions.
- **Collaborative:** Ask before writing ADRs. The research artifact itself is written without asking (that's the point of the command).
- **Honest about gaps:** If a question can't be fully answered, say so and mark the research as Partial.
- **No hallucinated benchmarks.** If you haven't run a benchmark, don't report numbers.
```

**Step 2: Verify command file**

Run: `head -5 plugins/ago/commands/research.md`
Expected: YAML frontmatter with description and argument-hint

**Step 3: Commit**

```bash
git add plugins/ago/commands/research.md
git commit -m "feat: add ago:research command — structured research with artifact output"
```

---

### Task 3: Create `ago:sync-docs` command

**Files:**
- Create: `plugins/ago/commands/sync-docs.md`

**Step 1: Write the sync-docs command file**

```markdown
---
description: Synchronize project documentation with current code state, using ADRs as source of truth
argument-hint: "[docs/path/to/specific-file.md]"
---

# ago:sync-docs

You are executing the `ago:sync-docs` command. This checks project documentation for freshness against the actual code and ADRs, then proposes or applies updates. ADRs are the primary source of truth for decisions.

**Arguments:** `$ARGUMENTS` (optional: specific doc path to check, or empty for full scan)

## Step 1 — Scan documentation inventory

Build an inventory of all documentation:

1. **ADRs** — read all files in `docs/adr/`. These are the source of truth for decisions.
2. **Plans** — list `docs/plans/` files with dates.
3. **Product docs** — list any other docs (`docs/product/`, `docs/research/`, etc.)
4. **Top-level docs** — `README.md`, `CLAUDE.md`, any other .md files in project root.
5. **Component docs** — scan for `README.md` or `CLAUDE.md` in subdirectories.

If `$ARGUMENTS` specifies a path, focus only on that file and its related ADRs.

Present the inventory:

```
## Documentation Inventory

| Category | Files | Latest Update |
|----------|-------|---------------|
| ADRs | {count} | {most recent date} |
| Plans | {count} | {most recent date} |
| Product | {count} | {most recent date} |
| Component | {count} | {list} |
```

## Step 2 — Build decision map from ADRs

Read each ADR and extract:
- **Status** (Accepted, Proposed, Superseded, Deprecated)
- **Key facts** (technology choices, architecture patterns, what was added/removed)
- **Supersession chain** (which ADRs replace others)

This decision map is your primary reference for what's "true" about the project.

## Step 3 — Cross-reference with code

For each accepted ADR, verify that the code reflects the decision:

1. Check if the technology/pattern mentioned in the ADR actually exists in the codebase
2. Check if superseded ADRs have remnants still in docs (e.g., docs still reference Tauri after ADR-012 switched to native Swift)
3. Check if code has evolved beyond what ADRs document (new patterns not captured)

Use Grep and Glob to search for relevant patterns. Be efficient — check key indicators, don't read every file.

## Step 4 — Find documentation gaps

Compare the decision map + code state against existing docs:

### Stale content (docs describe something that no longer exists)
- References to removed components (e.g., Chrome extension after ADR-005)
- Outdated architecture descriptions
- Dead links to removed files
- Obsolete configuration or setup instructions

### Missing content (code exists but isn't documented)
- New components without docs
- Significant features without architectural context
- API changes not reflected in docs

### Outdated content (facts changed but docs weren't updated)
- Version numbers
- Architecture diagrams/descriptions that don't match current code
- Status/progress information that's behind
- Tech stack descriptions that don't match ADRs

## Step 5 — Present findings

```
## Documentation Sync Report

### Stale (references removed/changed things)
1. **{file}:{line}** — {what's stale and why (reference ADR if applicable)}
2. ...

### Missing (undocumented)
1. **{component/feature}** — {what should be documented}
2. ...

### Outdated (facts changed)
1. **{file}:{section}** — {what's wrong and what it should say}
2. ...

### Up to Date
- {files that are current} ✓
```

Ask: "Apply fixes? Options: all / pick numbers / none / let me review each"

## Step 6 — Apply updates

Based on user choice, update docs:

- **For stale content:** Remove or update references. If a whole section is about a removed component, suggest removing it.
- **For missing content:** Draft new sections or files based on ADRs + code.
- **For outdated content:** Update the specific facts.

For each change, show a brief before/after or diff summary.

**Never delete documentation files without explicit user confirmation.** Prefer updating over deleting.

## Step 7 — Report

```
## Sync Complete

- **Files scanned:** {count}
- **Issues found:** {stale} stale, {missing} missing, {outdated} outdated
- **Files updated:** {count} ({list})
- **Files unchanged:** {count}

All documentation is now consistent with ADRs and current code state.
```

## Rules

- **ADRs are truth.** If a doc contradicts an accepted ADR, the doc is wrong.
- **Collaborative:** Always show proposed changes before applying. Never silently modify docs.
- **Conservative:** When uncertain about a change, flag it for review rather than applying.
- **Referential:** When updating docs, add references to relevant ADRs where helpful (e.g., "See [ADR-012](docs/adr/012-native-swift-macos-app.md)").
- **Non-destructive on code:** Never modify source code. Only documentation files.
```

**Step 2: Verify command file**

Run: `head -5 plugins/ago/commands/sync-docs.md`
Expected: YAML frontmatter with description and argument-hint

**Step 3: Commit**

```bash
git add plugins/ago/commands/sync-docs.md
git commit -m "feat: add ago:sync-docs command — documentation sync from ADRs and code"
```

---

### Task 4: Update plugin manifest and CLAUDE.md

**Files:**
- Modify: `plugins/ago/.claude-plugin/plugin.json` — bump version to 0.5.0
- Modify: `CLAUDE.md` — add new commands to the commands table

**Step 1: Bump plugin version**

In `plugins/ago/.claude-plugin/plugin.json`, change version from `"0.4.0"` to `"0.5.0"`.

Also update `"version"` in `.claude-plugin/marketplace.json` to match.

**Step 2: Update CLAUDE.md commands table**

Add the three new commands to the existing table:

```markdown
| `ago:audit` | Multi-role retrospective review from git history + docs |
| `ago:research` | Structured research session → artifact in docs/research/ |
| `ago:sync-docs` | Synchronize documentation with ADRs and current code |
```

**Step 3: Commit**

```bash
git add plugins/ago/.claude-plugin/plugin.json .claude-plugin/marketplace.json CLAUDE.md
git commit -m "chore: register new audit/research/sync-docs commands, bump to v0.5.0"
```

---

### Task 5: Smoke test — run `ago:audit` on shepni

This is a manual test. In a Claude Code session with the ago plugin installed and shepni as the working directory:

**Step 1: Run the audit command**

```
/ago:audit --commits 20
```

**Step 2: Verify behavior**
- [ ] Command reads last 20 commits from shepni
- [ ] Shows audit scope summary (commits, files changed, plans found, existing ADRs)
- [ ] Asks for confirmation before launching agents
- [ ] Launches 4 agents (ARCH, SEC, QAL, PM) in parallel
- [ ] Each agent returns structured findings
- [ ] Consolidated report is presented
- [ ] If decisions detected, prompts for ADR creation
- [ ] Writes `.last-audit` bookmark

**Step 3: Verify outputs**
- [ ] Any created ADRs follow shepni's format (ADR-NNN with Context/Decision/Consequences)
- [ ] `docs/.last-audit` contains a valid git SHA
- [ ] No files were modified outside of `docs/`

---

### Task 6: Smoke test — run `ago:research` on shepni

**Step 1: Run the research command**

```
/ago:research CoreML acceleration for Parakeet model on Apple Silicon
```

**Step 2: Verify behavior**
- [ ] Proposes research questions
- [ ] Asks for confirmation
- [ ] Conducts web search and code analysis
- [ ] Writes artifact to `docs/research/2026-03-09-coreml-acceleration.md`
- [ ] If architectural decision found, proposes ADR

**Step 3: Verify output format**
- [ ] Research doc has: Context, Questions, Findings with sources, Conclusions, Recommendations
- [ ] Every claim has a source citation
- [ ] File is self-contained and useful on re-read

---

### Task 7: Smoke test — run `ago:sync-docs` on shepni

**Step 1: Run the sync-docs command**

```
/ago:sync-docs
```

**Step 2: Verify behavior**
- [ ] Builds documentation inventory
- [ ] Reads all ADRs and builds decision map
- [ ] Cross-references ADRs with code
- [ ] Finds stale references (e.g., Chrome extension, Tauri, Windows mentions after superseding ADRs)
- [ ] Presents findings with specific file:line references
- [ ] Asks before applying any changes
- [ ] Updates only documentation files

**Step 3: Verify known issues are caught**
- [ ] Detects that ADR-003 (Tauri) was superseded by ADR-012 (native Swift) — any docs still referencing Tauri should be flagged
- [ ] Detects that ADR-005 removed Chrome extension — any docs still referencing it should be flagged
- [ ] Detects stale research docs that are no longer relevant
