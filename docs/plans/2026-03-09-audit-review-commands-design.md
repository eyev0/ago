# Audit & Review Commands — Design

> **Context:** This is the design doc for the brainstorming session. See companion implementation plan.

**Problem:** The ago framework has full lifecycle commands (clarify→execute→review) that require `.workflow/` setup. Users who already have a working dev flow (brainstorming→writing-plans→executing-plans) want to cherry-pick ago's strengths — multi-role review, ADR consolidation, documentation management — without replacing their existing workflow or maintaining a parallel tracking system.

**Solution:** Three new ago commands that work directly with a project's existing `docs/` directory structure, using git history as the timeline and ADRs as the decision source of truth.

## Design Principles

1. **Single source of truth** — git = timeline, docs/ = knowledge base, ADR = decisions
2. **No new tracking systems** — no .workflow/, no registry, no indexes to maintain
3. **Agents work from artifacts** — git log, plans, code, docs (no session context)
4. **On-demand only** — no hooks into dev flow, manual trigger when ready

## Commands

### ago:audit
Multi-role retrospective review. Spawns 4 agents (ARCH, SEC, QAL, PM) in parallel. Each analyzes recent work from their perspective. Consolidates findings, proposes ADRs.

**Input:** Git range (--since, --commits N, or auto from `.last-audit`)
**Output:** New ADRs in `docs/adr/`, findings summary in chat, `.last-audit` bookmark updated

### ago:research
Structured research session → artifact. Formulates questions, does deep-research/web search, produces structured doc.

**Input:** Topic string
**Output:** `docs/research/YYYY-MM-DD-{topic}.md`, optionally ADRs if architectural decisions found

### ago:sync-docs
Documentation freshness check. ADRs are the primary source of truth. Scans ADRs → code → existing docs → proposes updates.

**Input:** Nothing (or specific doc path)
**Output:** Updated docs in-place, summary of changes

## Roles for Audit (4, no DEV)

| Role | Perspective |
|------|------------|
| ARCH | Architecture decisions, tech debt, system evolution |
| SEC | Security concerns, vulnerabilities, hardening |
| QAL | Test coverage, quality, edge cases |
| PM | Product logic, user impact, scope creep |

## ADR Format (matches shepni convention)

```markdown
# ADR-NNN: Title

**Status:** Proposed | Accepted | Deprecated | Superseded by [ADR-NNN]
**Date:** YYYY-MM-DD

## Context
## Decision
## Consequences
```

## Audit Bookmark

`docs/.last-audit` — single line containing the git SHA of HEAD at last audit completion. Next audit without arguments uses `git log {sha}..HEAD`.

## Future: MCP Server

These commands validate the process. Once proven, wrap the same logic in an MCP server with tools that Claude can invoke autonomously (no slash commands needed).
