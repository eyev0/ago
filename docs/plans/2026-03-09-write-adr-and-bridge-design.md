# Design: `ago:write-adr` Command + Bridge to Implementation + `audit-docs` ADR Consistency

**Date:** 2026-03-09
**Status:** Approved

## Problem

Three gaps in the current ago plugin:

1. **No way to capture a decision mid-conversation.** `ago:audit` and `ago:research` generate ADRs as a side effect, but there's no standalone command to formalize a decision from the current discussion context.
2. **No transition from findings to development.** After audit/research produces artifacts, the user manually carries context into a new session. There's no proactive handoff to planning and implementation.
3. **No ADR-to-ADR consistency checking.** `audit-docs` checks ADRs against code and docs, but not against each other. "To Review" ADRs go unnoticed.

## Design

### 1. New Command: `ago:write-adr`

Minimal command — the simplest in the plugin. 4 steps.

**Step 1 — Gather context.**
- Read `docs/adr/*.md` for next ADR number
- Read CLAUDE.md/README.md for project context

**Step 2 — Formulate ADR.**
From the current conversation, draft:
- **Context** — why the question arose (what was being discussed)
- **Decision** — what was decided
- **Alternatives Considered** — what was rejected and why
- **Consequences** — positive, negative, risks

Present draft to user. Wait for "ok" or edits.

**Step 3 — Write file.**
Write `docs/adr/NNN-{slug}.md` with status **To Review**.
Create `docs/adr/` if it doesn't exist.

ADR format:
```markdown
# ADR-NNN: {Title}

**Status:** To Review
**Date:** YYYY-MM-DD

## Context
{Why this decision came up}

## Decision
{What we decided}

## Alternatives Considered
{What was rejected and why}

## Consequences

### Positive
{What becomes easier}

### Negative
{What becomes harder}

### Risks
{What could go wrong}
```

**Step 4 — Bridge to implementation.**
Prepare context for brainstorming from the ADR + any related artifacts:

```
## Ready to plan?

ADR saved: `docs/adr/NNN-{title}.md` (To Review)

Based on this decision, here's the context for implementation planning:

**Artifacts:**
- {list of files created/referenced}

**Key decisions:**
- {1-line summary of the ADR}

**Constraints from consequences:**
- {key items from Consequences section}

**Suggested pipeline:** brainstorming → writing-plans → implementation

Want to start brainstorming with this context?
[yes / adjust / not now]
```

- "yes" → invoke `superpowers:brainstorming` with context (references to files, not inline content)
- "adjust" → user edits context, then invoke
- "not now" → end command (artifacts on disk, can return later)

### 2. Extend `ago:audit-docs` — ADR Consistency Checks

Additions to existing steps, not new steps.

**Step 2 (Decision Map) — add ADR Health section:**

After building the decision map, add:

```
### ADR Health
| Check | Count | Details |
|-------|-------|---------|
| To Review / Proposed | {N} | ADR-007, ADR-012 — awaiting acceptance |
| Conflicting decisions | {N} | ADR-003 vs ADR-015 — both accepted, contradict on X |
| Broken supersession chains | {N} | ADR-005 supersedes ADR-003, but ADR-003 missing "Superseded by" |
| Missing sections | {N} | ADR-008 has no Consequences section |
```

**Step 3 — add 3c (ADR Internal Consistency):**

Four checks:
1. **Conflicting ADRs** — Two accepted ADRs assert contradictory things → **Critical** finding
2. **Stale proposals** — ADR with status "To Review" or "Proposed" older than 4 days → finding with action item "accept, reject, or revise"
3. **One-sided supersession chains** — ADR-005 says "Supersedes ADR-003" but ADR-003 lacks "Superseded by ADR-005" → **Outdated** finding (auto-fixable)
4. **Missing required sections** — ADR lacks Context, Decision, or Consequences → **Missing** finding

All findings flow into the existing report (Step 5) and action items (Step 8). No separate display logic needed.

**Final step — conditional bridge:**

| Finding type | Pipeline |
|---|---|
| Architectural (conflicting ADRs, ADR vs code mismatch) | brainstorming → writing-plans → implementation |
| Editorial only (stale/missing/outdated docs) | writing-plans → implementation |
| Both types present | Two separate proposals, each with own context |

Bridge format matches the standard pattern (show context with file references, interactive prompt [yes / adjust / not now]).

### 3. Bridge in `ago:audit` and `ago:research`

Add a final step to both commands — **Bridge to Implementation**.

Common pattern:

1. **Collect BRIDGE_CONTEXT** from the command's artifacts:

| Command | Context source |
|---------|---------------|
| `ago:audit` | Critical/High action items from report + created ADRs |
| `ago:research` | Recommendations section + created ADRs |

2. **Present to user:**

```
## Ready to plan?

Based on this session's output, here's the context for implementation planning:

**Artifacts:**
- {list of files created/referenced}

**Key decisions:**
- {1-2 lines per ADR created}

**Action items to address:**
- {top 3-5 items, prioritized}

**Suggested pipeline:** brainstorming → writing-plans → implementation

Want to start brainstorming with this context?
[yes / adjust / not now]
```

3. On "yes" → invoke `superpowers:brainstorming` with context
4. On "adjust" → user edits, then invoke
5. On "not now" → end command

**Key principle:** Context always references files, never inlines their content. Brainstorming reads the files itself — resilient to context window compaction.

## Files Changed

| File | Change |
|------|--------|
| `plugins/ago/commands/write-adr.md` | **New** — standalone ADR capture command |
| `plugins/ago/commands/audit-docs.md` | **Modify** — add ADR Health to Step 2, add Step 3c, add conditional bridge |
| `plugins/ago/commands/audit.md` | **Modify** — add Bridge step at end |
| `plugins/ago/commands/research.md` | **Modify** — add Bridge step at end |
| `plugins/ago/.claude-plugin/plugin.json` | **Modify** — register `write-adr` command |
| `CLAUDE.md` | **Modify** — add `write-adr` to commands table |

## Non-Goals

- No intermediate "brief" file — artifacts are the persistent context
- No separate `ago:review-adrs` command — consistency checks live in `audit-docs`
- No auto-invocation of brainstorming — always ask user first
