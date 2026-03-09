---
description: Multi-role retrospective review — ARCH, SEC, QAL, PM analyze recent work from different angles
argument-hint: "[--since '3 days ago' | --commits 20]"
---

# ago:audit

You are executing the `ago:audit` command. This command performs a **multi-role retrospective review** of recent project work. Four review agents (ARCH, SEC, QAL, PM) analyze the same body of work from different angles, then findings are consolidated into a structured report with optional ADR generation.

**This command does NOT require `.workflow/` — it works with any project that has a `docs/` directory.**

**Argument:** `$ARGUMENTS` (optional scope filter — see Step 1).

## Step 1 — Determine Review Scope

Parse `$ARGUMENTS` to determine what range of work to audit:

- **`--since '{time expression}'`** — e.g., `--since '3 days ago'`, `--since '2025-01-15'`. Use this as the `git log --since` value.
- **`--commits {N}`** — e.g., `--commits 20`. Use `git log -N` to get the last N commits.
- **No arguments:** Check for the file `docs/.last-audit`.
  - If it exists, read the SHA from it and use `git log {SHA}..HEAD` as the scope (all commits since the last audit).
  - If it does not exist, default to `--commits 30` (last 30 commits).

Store the resolved scope description (e.g., "last 20 commits", "since 2025-01-15", "since last audit at abc1234") for display in Step 3.

If the resolved scope produces **zero commits**, tell the user: "No commits found in the specified range. Nothing to audit." and stop.

## Step 2 — Gather Context

Collect the following context within the resolved scope. Each item is optional — skip any that don't exist and note their absence. **Do not fail if any single source is missing.**

### 2a — Git history

Run `git log` for the resolved scope with `--oneline --stat` to get:
- List of commits (SHA, author, message)
- Files changed per commit with insertions/deletions

Store the full output as `COMMIT_LOG`.

### 2b — Diff statistics

Run `git diff --stat {scope_start}..HEAD` (or equivalent for the resolved scope) to get an aggregate summary of all changes. Store as `DIFF_STATS`.

### 2c — Plans and decisions

Read any files in these locations (if they exist):
- `docs/plans/` or `docs/plan/` — project plans, design docs
- `docs/adr/` — existing Architecture Decision Records
- `docs/decisions/` — alternative ADR location

For existing ADRs, note the **highest ADR number** in use (e.g., if `ADR-007-*.md` exists, the next ADR is `ADR-008`). Also read `docs/adr/README.md` if it exists to understand the index format.

### 2d — Project documentation

Read the following if they exist:
- `CLAUDE.md` — project instructions and architecture context
- `README.md` — project overview
- `docs/architecture.md` or similar top-level architecture doc

### 2e — Changed file contents (selective)

For files that appear heavily modified in the diff stats (top 10 by lines changed), read their current contents to give agents richer context. Do NOT read binary files, lockfiles, or generated files (e.g., `package-lock.json`, `*.min.js`, `dist/`).

Assemble all gathered context into a single block called `AUDIT_CONTEXT`:

```
## Audit Context

### Scope
{scope description}

### Commit Log
{COMMIT_LOG}

### Diff Statistics
{DIFF_STATS}

### Existing ADRs
{list of existing ADR files and their titles, or "None found"}

### Project Documentation
{summaries of CLAUDE.md, README.md, and architecture docs read}

### Plans
{summaries of any plan documents found, or "None found"}

### Key Changed Files
{contents of heavily-modified files, with file paths as headers}
```

## Step 3 — Present Scope and Confirm

Present the scope to the user before launching agents:

```
## Audit Scope

**Range:** {scope description}
**Commits:** {N} commits by {M} authors
**Files changed:** {N} files (+{insertions} -{deletions})
**Period:** {earliest commit date} to {latest commit date}
**Existing ADRs:** {count} found in docs/adr/

### Top Changed Files
| File | Lines Changed |
|------|--------------|
| {path} | +{ins} -{del} |
| ... | ... |

### Review Agents
| Agent | Focus |
|-------|-------|
| ARCH | Architecture decisions, tech debt, design patterns, dependencies |
| SEC | Security changes, secrets, auth/crypto, OWASP patterns |
| QAL | Test coverage gaps, test quality, edge cases, regression risk |
| PM | User-facing changes, scope drift, UX implications, doc gaps |
```

Then ask:

> Ready to launch 4 review agents. Proceed? (yes / no / adjust scope)

**Do NOT launch agents until the user explicitly confirms.** If the user wants to adjust scope, return to Step 1 with their new parameters.

## Step 4 — Launch Review Agents

Launch **4 agents in parallel** using the Agent tool. Each agent receives the identical `AUDIT_CONTEXT` but has a different review lens and instructions.

**Important:** These agents do NOT use `ago:` skills. They do not write logs, update task statuses, or modify files. They only analyze and return findings as structured text.

### Agent: ARCH (Architecture Review)

Use the Agent tool with this prompt:

```
You are performing an architecture review of recent project work.

## Your Review Lens

You focus on: architecture decisions, technical debt, system evolution, design patterns, dependency changes, and structural integrity.

## Context

{AUDIT_CONTEXT}

## Instructions

Analyze the commits and changes for architecture-relevant findings. For EVERY finding, you MUST cite specific evidence (commit SHA, file path, code pattern, or line reference).

Organize your response in exactly this format:

### Architecture Decisions Detected
For each decision you identify (explicit or implicit):
- **Title:** {short descriptive title}
- **Commit(s):** {SHA(s) where this decision is evident}
- **Context:** {why this decision was made — infer from commit messages, code patterns, surrounding changes}
- **Decision:** {what was decided}
- **Consequences:** {trade-offs, implications, risks}
- **Confidence:** {HIGH if explicitly stated in commit/docs, MEDIUM if clearly implied by code changes, LOW if inferred}

### Technical Debt
For each tech debt item:
- **Description:** {what the debt is}
- **Evidence:** {file(s) and pattern(s) that show this}
- **Severity:** {HIGH / MEDIUM / LOW}
- **Recommendation:** {what should be done}

### Design Pattern Observations
- Notable patterns introduced or changed
- Consistency issues across the codebase

### Dependency Changes
- New dependencies added and their implications
- Dependency version changes and risk assessment

If you find nothing notable in a section, write "None detected." Do NOT fabricate findings.
```

### Agent: SEC (Security Review)

Use the Agent tool with this prompt:

```
You are performing a security review of recent project work.

## Your Review Lens

You focus on: security-relevant changes, hardcoded secrets, authentication and authorization changes, cryptographic operations, input validation, OWASP Top 10 patterns, and dependency security.

## Context

{AUDIT_CONTEXT}

## Instructions

Analyze the commits and changes for security-relevant findings. For EVERY finding, you MUST cite specific evidence (commit SHA, file path, code pattern, or line reference). Do NOT report speculative issues without evidence in the actual changes.

Organize your response in exactly this format:

### Security Findings
For each finding:
- **Title:** {short descriptive title}
- **Severity:** {CRITICAL / HIGH / MEDIUM / LOW / INFO}
- **Evidence:** {exact file, line, commit SHA, or code pattern}
- **Description:** {what the issue is and why it matters}
- **Recommendation:** {specific remediation steps}

### Authentication & Authorization Changes
- Changes to auth flows, session management, token handling
- New or modified access control logic

### Secrets & Configuration
- Any hardcoded credentials, API keys, tokens, or secrets detected in the diff
- Configuration changes that affect security posture

### Input Validation & Data Handling
- New user input paths without validation
- SQL injection, XSS, or injection risk patterns
- Data serialization/deserialization changes

### Dependency Security
- New dependencies with known vulnerabilities (if identifiable from name/version)
- Dependencies pulled from untrusted sources

### Decisions with Security Implications
For each decision that affects security posture:
- **Title:** {short descriptive title}
- **Commit(s):** {SHA(s)}
- **Security Impact:** {what changed from a security perspective}
- **Risk Level:** {HIGH / MEDIUM / LOW}

If you find nothing notable in a section, write "None detected." Do NOT fabricate findings — false positives in security reviews erode trust.
```

### Agent: QAL (Quality & Testing Review)

Use the Agent tool with this prompt:

```
You are performing a quality and testing review of recent project work.

## Your Review Lens

You focus on: test coverage, code without tests, test quality and robustness, edge case coverage, regression risk, and quality patterns.

## Context

{AUDIT_CONTEXT}

## Instructions

Analyze the commits and changes for quality and testing findings. For EVERY finding, you MUST cite specific evidence (commit SHA, file path, code pattern, or line reference).

Organize your response in exactly this format:

### Test Coverage Gaps
For each gap:
- **File/Module:** {path to production code that changed}
- **Change Description:** {what was added or modified}
- **Test Status:** {TESTED / PARTIALLY_TESTED / UNTESTED}
- **Evidence:** {path to test file if tested, or "No test file found" if untested}
- **Risk:** {what could break without tests}

### Test Quality Observations
- Tests that only check happy paths
- Tests with weak assertions (e.g., just checking truthiness instead of exact values)
- Tests that are tightly coupled to implementation details
- Flaky test patterns (timeouts, race conditions, order dependence)

### Edge Cases & Error Handling
- New code paths without error handling
- Missing boundary condition tests
- Async operations without timeout/retry handling

### Regression Risk Assessment
For changes most likely to cause regressions:
- **Change:** {what changed}
- **Commit:** {SHA}
- **Risk Level:** {HIGH / MEDIUM / LOW}
- **Why:** {what makes this risky}
- **Mitigation:** {what tests or safeguards exist, or should exist}

### Quality Decisions
For each decision affecting quality approach:
- **Title:** {short descriptive title}
- **Commit(s):** {SHA(s)}
- **Decision:** {what quality approach was taken}
- **Trade-off:** {what was sacrificed for what gain}

If you find nothing notable in a section, write "None detected." Do NOT fabricate findings.
```

### Agent: PM (Product & Scope Review)

Use the Agent tool with this prompt:

```
You are performing a product and scope review of recent project work.

## Your Review Lens

You focus on: user-facing changes, scope drift relative to plans, UX implications, product documentation gaps, feature completeness, and alignment with project goals.

## Context

{AUDIT_CONTEXT}

## Instructions

Analyze the commits and changes for product-relevant findings. For EVERY finding, you MUST cite specific evidence (commit SHA, file path, code pattern, or line reference).

Organize your response in exactly this format:

### User-Facing Changes
For each change visible to users:
- **Change:** {what changed from the user's perspective}
- **Commit(s):** {SHA(s)}
- **Type:** {NEW_FEATURE / ENHANCEMENT / BREAKING_CHANGE / BUG_FIX / UX_CHANGE}
- **Documentation:** {is this documented? where?}

### Scope Assessment
- **Planned work completed:** {what from plans/ was accomplished}
- **Unplanned work:** {changes that don't appear in any plan — not necessarily bad, just notable}
- **Planned work not started:** {items in plans/ with no corresponding commits}
- **Scope drift indicators:** {work that expanded beyond original plan boundaries}

### Documentation Gaps
For each gap:
- **What changed:** {the feature or behavior that changed}
- **What's missing:** {README update, API docs, changelog entry, user guide, etc.}
- **Evidence:** {file changed without corresponding doc update}

### Product Decisions
For each product-level decision:
- **Title:** {short descriptive title}
- **Commit(s):** {SHA(s)}
- **Decision:** {what product direction was taken}
- **User Impact:** {how this affects end users}
- **Confidence:** {HIGH / MEDIUM / LOW — based on whether this aligns with stated plans}

### Release Readiness
- Are the changes in a releasable state?
- Any partially-implemented features that shouldn't be shipped?
- Breaking changes that need migration guides?

If you find nothing notable in a section, write "None detected." Do NOT fabricate findings.
```

## Step 5 — Consolidate Findings

After all 4 agents return, consolidate their findings into a single structured report. Present this to the user:

```
## Audit Report

**Scope:** {scope description}
**Commits:** {N} commits ({earliest date} to {latest date})
**Agents:** ARCH, SEC, QAL, PM

---

### Critical & High Severity Items

{Collect all CRITICAL and HIGH severity findings from all agents into one list, sorted by severity. Include the originating agent role.}

1. **[{AGENT}] {title}** — {severity}
   {one-line summary with evidence reference}

2. ...

(If none: "No critical or high severity items found.")

---

### Architecture Review (ARCH)

{Paste the ARCH agent's full structured response}

---

### Security Review (SEC)

{Paste the SEC agent's full structured response}

---

### Quality Review (QAL)

{Paste the QAL agent's full structured response}

---

### Product Review (PM)

{Paste the PM agent's full structured response}

---

### Cross-Cutting Observations

{Identify themes that appear across multiple agents' findings:}
- Patterns noted by 2+ agents
- Contradictions between agents (e.g., ARCH says a pattern is good, SEC says it's risky)
- Findings that reinforce each other

---

### Summary Statistics

| Category | Count |
|----------|-------|
| Architecture decisions detected | {N} |
| Security findings | {N} (Critical: {N}, High: {N}, Medium: {N}, Low: {N}) |
| Test coverage gaps | {N} |
| Documentation gaps | {N} |
| Product decisions detected | {N} |
| Total items for follow-up | {N} |
```

## Step 6 — Propose ADRs

Collect all **decisions** identified by the agents (from "Architecture Decisions Detected", "Decisions with Security Implications", "Quality Decisions", and "Product Decisions" sections). Filter to only those with **MEDIUM or HIGH confidence** — do not propose ADRs for LOW confidence decisions.

If there are zero candidate decisions, skip to Step 8.

Present the candidates to the user:

```
## Proposed ADRs

The following decisions were detected in the reviewed commits. Would you like to formalize any as Architecture Decision Records?

| # | Title | Detected By | Confidence | Commit(s) |
|---|-------|-------------|------------|-----------|
| 1 | {title} | {ARCH/SEC/QAL/PM} | {HIGH/MEDIUM} | {short SHA(s)} |
| 2 | {title} | {ARCH/SEC/QAL/PM} | {HIGH/MEDIUM} | {short SHA(s)} |
| ... | ... | ... | ... | ... |
```

Then ask:

> **Which decisions should become ADRs?**
> Enter numbers (e.g., "1, 3"), "all", or "none".

**Wait for the user's response. Do not proceed until they answer.**

## Step 7 — Write Approved ADRs

For each decision the user approved, create an ADR file in `docs/adr/`.

### Determine next ADR number

From Step 2c, you know the highest existing ADR number. Increment from there. If no ADRs exist yet, start at `ADR-001`.

### ADR file format

Filename: `docs/adr/ADR-{NNN}-{kebab-case-title}.md`

Content:

```markdown
# ADR-{NNN}: {Title}

**Status:** Accepted
**Date:** {YYYY-MM-DD — today's date}
**Deciders:** ago:audit ({AGENT} agent)

## Context

{Context from the agent's finding — why this decision was needed. Reference specific commits and files.}

## Decision

{What was decided — extracted from the agent's finding.}

## Consequences

### Positive
- {positive consequence}

### Negative
- {negative consequence or trade-off}

### Risks
- {identified risks, if any}

## Evidence

- Commit(s): {full SHA(s) with commit messages}
- Files: {key files where this decision is implemented}
- Detected by: {AGENT} agent during ago:audit
```

### Create `docs/adr/` directory if needed

If `docs/adr/` does not exist, create it before writing ADR files.

### Update ADR index

If `docs/adr/README.md` exists, read it to understand its format, then append the new ADR(s) to its index table or list, matching the existing format exactly.

If `docs/adr/README.md` does not exist, do NOT create one — only update it if it already exists.

Report each ADR created:

```
Created: docs/adr/ADR-{NNN}-{kebab-case-title}.md
```

## Step 8 — Write Last-Audit Bookmark

Get the current HEAD SHA:

```bash
git rev-parse HEAD
```

Write it to `docs/.last-audit`:

```
{full HEAD SHA}
```

This is a single line containing only the SHA, no trailing newline or extra content. Create the file if it does not exist. Create the `docs/` directory if it does not exist.

## Step 9 — Save Audit Report

Write the full audit report to `docs/audit/{YYYY-MM-DD}-audit.md`. Create the `docs/audit/` directory if it does not exist.

The report file captures everything from this audit in a format that future sessions can read and act on:

```markdown
# Audit Report — {YYYY-MM-DD}

**Scope:** {commits count} commits ({date range})
**Agents:** ARCH, SEC, QAL, PM
**ADRs created:** {list with links}

## Summary
{2-3 sentence synthesis across all perspectives}

## Critical & High Findings

| # | Agent | Severity | Finding | File |
|---|-------|----------|---------|------|
{table of critical and high items}

## All Findings

### ARCH
{numbered findings}

### SEC
{numbered findings}

### QAL
{numbered findings}

### PM
{numbered findings}

## Decisions → ADRs
{list of ADRs created with links}

## Action Items

### Critical
{for each critical finding:}
- [ ] **{title}** — {description}
  - Acceptance: {how to verify this is fixed}
  - Refs: {agent}-{finding#}, {ADR link if relevant}
  - Files: {specific file paths to change}

### High
{same format}

### Medium
{same format}

### Low / Recommendations
{same format, less detail}
```

The Action Items section uses checkbox format so it can be:
- Fed into a new session: "Fix issues from `docs/audit/{date}-audit.md`"
- Tracked visually as items are resolved
- Parsed by `writing-plans` as input requirements

**Do not ask permission to write the report file** — this is the primary output of the audit command, like how `ago:research` writes its artifact without asking.

## Step 10 — Final Summary

Present the closing summary in chat:

```
## Audit Complete

**Scope:** {scope description}
**Commits reviewed:** {N}
**Findings:** {total count across all agents} ({critical} critical, {high} high, {medium} medium, {low} low)
**ADRs created:** {count} ({list filenames})
**Report saved:** docs/audit/{YYYY-MM-DD}-audit.md
**Last-audit bookmark:** updated to {short SHA}

### Top Action Items
{List critical and high items as checkboxes:}
- [ ] {title} — {one-line description}

### Next Steps
- Open a new session and run: "Fix critical issues from docs/audit/{date}-audit.md"
- Or use /writing-plans with the report as input
- Run `ago:audit` again after fixes to verify
```

## Rules

- **Collaborative:** Never write ADR files or `docs/.last-audit` without user approval (except the bookmark, which is always written). Always present findings and ask before creating files.
- **Evidence-based:** Every finding must reference a specific commit SHA, file path, or code pattern. Instruct agents to never fabricate findings. If an agent returns findings without evidence, flag them as unsubstantiated in the consolidated report.
- **No `.workflow/` dependency:** This command does not read from or write to `.workflow/`. It uses only `docs/`, git history, and standard project files.
- **Agents are read-only analysts:** The 4 review agents do NOT modify files, run commands with side effects, or use `ago:` skills. They analyze the provided context and return structured text.
- **Idempotent scope:** If the user runs `ago:audit` twice with the same scope, only the second run should detect the ADRs created by the first run as "existing ADRs" — the audit itself should not change its own scope.
- **Respect existing format:** When writing ADRs, match the style of existing ADRs in the project if any exist. The format in Step 7 is the default — adapt it if the project uses a different ADR format.
- **Graceful degradation:** If git is unavailable, if `docs/` doesn't exist, or if any context source is missing, work with what is available. Only hard-fail if there are zero commits to review.
