---
name: ago-audit
description: Use when the user wants a multi-angle retrospective audit of recent project work, commits, or a recent delivery window
---

# ago-audit

## Overview

Run a structured retrospective review of recent work using four review lenses: architecture, security, quality, and product. Gather scope and project context first, show the resolved audit range, and wait for approval before launching review agents.

Primary artifact: `docs/audit/YYYY-MM-DD-audit.md`

## When to Use

- The user wants a code audit, release review, or "what changed and what should we fix?"
- The user points at recent commits, a date range, or asks to review work since the last audit
- The user wants multi-role findings consolidated into one report with action items

Do not use for forward-looking research. Use `ago-research` for that.

## Inputs

Accept an optional scope hint from the user:

- `--since '3 days ago'`
- `--since '2026-03-01'`
- `--commits 20`
- `abc123..def456`

Without an explicit scope:

- Check `docs/.last-audit`
- If it exists, audit `{SHA}..HEAD`
- Otherwise default to the last 30 commits

If the resolved scope has zero commits, stop and tell the user there is nothing to audit.

## Process

### 1. Resolve scope

Compute:

- range description
- commit count
- author count
- period covered
- top changed files

### 2. Gather audit context

Collect:

- `git log --oneline --stat` for the chosen range
- aggregate diff stats
- existing plans and ADRs under `docs/`
- `README.md`, `CLAUDE.md`, and top-level architecture docs if present
- current contents of the most heavily changed source files

Skip missing sources without failing.

### 3. Present scope and confirm

Before dispatching reviewers, show the user:

- resolved range
- commit/file volume
- time window
- existing ADR count
- top changed files
- review agents: `ARCH`, `SEC`, `QAL`, `PM`

Ask for confirmation. Do not launch review agents until the user explicitly approves or adjusts the scope.

### 4. Launch four review agents

Give every review agent the same audit context, but different review lenses:

- `ARCH`: architecture decisions, structure, debt, dependencies
- `SEC`: secrets, auth, trust boundaries, dependency risk
- `QAL`: tests, edge cases, regression risk, quality signals
- `PM`: user-facing impact, scope drift, documentation gaps, release readiness

Require evidence in every finding: commit SHA, file path, line reference, or code pattern.

### 5. Consolidate into one report

Produce a single audit report that contains:

- scope summary
- critical and high-severity roll-up
- full `ARCH`, `SEC`, `QAL`, and `PM` sections
- cross-cutting observations
- summary statistics

Write the report to:

`docs/audit/YYYY-MM-DD-audit.md`

Create `docs/audit/` if needed.

### 6. Propose ADRs

If the review surfaced medium- or high-confidence architecture, security, quality, or product decisions, propose them as ADR candidates.

Ask the user which ones to formalize. Only write ADRs after approval.

If approved:

- determine the next ADR number from `docs/adr/` or `docs/decisions/`
- write accepted ADRs under `docs/adr/`
- update `docs/adr/README.md` only if it already exists

### 7. Update last-audit bookmark

Write the current `HEAD` SHA to `docs/.last-audit`.

### 8. Bridge to implementation

After the report and any approved ADRs are written, offer a planning handoff using file references rather than inlined content.

If there are actionable follow-ups, present:

- report path
- ADR paths created in this run
- top action items
- suggested pipeline: brainstorming -> writing-plans -> implementation

If the user says yes, start that planning flow. If not, stop with artifacts on disk.

## Output Contract

- `docs/audit/YYYY-MM-DD-audit.md`
- optionally `docs/adr/ADR-{NNN}-{title}.md`
- `docs/.last-audit`

## Rules

- Require explicit approval before launching review agents.
- Do not fabricate findings or confidence.
- Every follow-up item needs evidence.
- Skip missing docs gracefully.
- Use the user's actual audit range; do not silently widen it.
- Write the report even if there are no severe issues.
