---
name: ago-audit-docs
description: Use when the user wants to audit documentation against current code, ADRs, or recent project reality, especially if docs may be stale, missing, or contradictory
---

# ago-audit-docs

## Overview

Audit project documentation against current code and ADRs, then save a persistent report to `docs/audit/YYYY-MM-DD-docs.md`.

ADRs are the source of truth when they exist. If an accepted ADR and a doc disagree, the doc is wrong.

## When to Use

Use this skill when the user wants to:
- audit all docs for staleness or drift
- check one specific documentation file
- compare docs against ADRs or current code
- generate actionable documentation fixes

Do not use it for freeform research or for writing a new ADR from scratch.

## Inputs

- Optional scope from the user, such as a specific file path
- Current project docs, ADRs, and codebase state

If the user gives a path, validate that it exists before continuing.

## Workflow

### 1. Scan the documentation inventory

Collect:
- ADRs from `docs/adr/` or `docs/decisions/`
- plans from `docs/superpowers/plans/` or `docs/plans/`
- top-level docs such as `README.md` and `CLAUDE.md`
- product and component docs under `docs/` and subdirectories

If no documentation files exist, stop and say there is nothing to audit.

Present a short inventory summary before deeper analysis.

### 2. Build the ADR decision map

Read every ADR you found and extract:
- ADR id and title
- status
- active vs superseded decisions
- key facts that documentation should reflect
- supersession chains

Also run ADR health checks:
- pending or stale proposals
- conflicting accepted ADRs
- broken supersession chains
- missing required sections

If there are no ADRs, continue without a decision map and say so explicitly.

### 3. Cross-check docs against code and ADRs

Look for four outcomes:
- **Stale**: docs describe things that no longer exist
- **Missing**: code or ADR-backed behavior exists but is undocumented
- **Outdated**: docs exist but contain wrong facts
- **Up to date**: accurate docs with no action needed

For every issue, record concrete evidence:
- file path and line numbers for docs
- file paths or config for code evidence
- ADR references when relevant

### 4. Present findings before editing

Show the findings grouped by category. If the user asked about one specific file, only show findings for that file.

Then ask how to apply changes:
- `all`
- `pick`
- `review`
- `none`

Do not edit documentation until the user chooses an apply mode.

### 5. Apply approved documentation fixes

For approved items:
- remove or replace stale references
- draft missing sections where documentation is absent
- correct outdated facts to match code or accepted ADRs

Never delete an entire file without explicit user confirmation.

Show before/after snippets for every applied change.

### 6. Save the report artifact

Always write the audit report to:

`docs/audit/YYYY-MM-DD-docs.md`

The report must include:
- scope
- ADR usage summary
- findings by category
- applied changes
- remaining unchecked action items

### 7. Finish with a useful summary

Summarize:
- files scanned
- issue counts
- files updated
- report path
- remaining action items

If nothing actionable was found, say the documentation is already up to date.

## Output Contract

- Primary artifact: `docs/audit/YYYY-MM-DD-docs.md`
- Optional edited docs, but only after user approval

## Rules

- Use ADRs as the primary source of truth when available.
- Do not invent undocumented facts; ground every finding in code, docs, or ADR evidence.
- Do not skip the apply-choice gate.
- Keep the report persistent and reusable from future sessions.
