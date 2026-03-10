---
name: ago-write-adr
description: Use when the current conversation has reached a clear architectural, product, or process decision that should be formalized as an ADR
---

# ago-write-adr

## Overview

Capture a decision from the current conversation and write it as an ADR with status `To Review`.

This skill is conversation-first: the ADR comes from what the user and agent decided together, not from git archaeology.

## When to Use

Use this skill when:
- a meaningful decision has been made and should be persisted
- the user wants an ADR written from the current discussion
- a naming, architecture, workflow, or tooling decision now needs a durable record

Do not use it when there is no real decision yet, or when the user only wants general research.

## Inputs

- Optional title or topic hint from the user
- Current conversation context
- Existing ADR files, if any
- Basic project context from `README.md` and `CLAUDE.md`

## Workflow

### 1. Gather context

Read:
- existing ADRs from `docs/adr/` or `docs/decisions/`
- `docs/adr/README.md` if it exists
- `README.md`
- `CLAUDE.md`

Determine the next ADR number from the existing corpus. If there are no ADRs, start at `001`.

### 2. Formulate the ADR draft

Infer the decision from the current conversation. If the user supplied a title or topic, use it as a hint.

Draft:
- title
- context
- decision
- alternatives considered
- consequences with positive, negative, and risk sections

If the conversation does not yet contain a clear decision, stop and ask the user to clarify what was decided and why.

### 3. Approval gate

Present the full ADR draft and ask for:
- `yes`
- `edit`

Do not write any file until the user confirms the draft.

### 4. Write the ADR

After approval, write:

`docs/adr/{NNN}-{kebab-case-title}.md`

Use status `To Review`.

If the project already has an ADR format, match it rather than forcing a new template.

If `docs/adr/README.md` exists, update its index to include the new ADR.

### 5. Offer the planning bridge when relevant

If the decision implies real implementation work, offer a bridge into planning:
- reference the ADR path
- summarize the decision in one line
- list key constraints
- suggest `brainstorming -> writing-plans -> implementation`

If the ADR is informational only, end by suggesting `ago-audit-docs` for consistency checks instead.

## ADR Shape

The draft should contain:

```markdown
# ADR-{NNN}: {Title}

**Status:** To Review
**Date:** {YYYY-MM-DD}

## Context
...

## Decision
...

## Alternatives Considered
...

## Consequences

### Positive
...

### Negative
...

### Risks
...
```

## Output Contract

- Primary artifact: `docs/adr/{NNN}-{kebab-case-title}.md`
- File creation only happens after user approval

## Rules

- Stay conversation-first.
- Never write the ADR without approval.
- Use `To Review` as the status.
- Match existing ADR conventions if the repository already has them.
