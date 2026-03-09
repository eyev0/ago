---
description: Capture an architectural decision from the current conversation as an ADR
argument-hint: "[title or topic]"
---

# ago:write-adr

You are executing the `ago:write-adr` command. This command captures an **architectural decision from the current conversation context** and writes it as an ADR file with status "To Review".

**This command does NOT require `.workflow/` — it works with any project that has a `docs/` directory.**

**Argument:** `$ARGUMENTS` (optional title or topic hint for the ADR).

## Step 1 — Gather Context

### 1a — Existing ADRs

Check for ADR files in these locations:
- `docs/adr/*.md`
- `docs/decisions/*.md`

If ADRs exist, note the **highest ADR number** in use (e.g., if `018-*.md` exists, the next ADR is `019`). If no ADRs exist, the next number is `001`.

Also read `docs/adr/README.md` if it exists to understand the index format.

### 1b — Project context

Read the following if they exist:
- `CLAUDE.md` — project instructions
- `README.md` — project overview

Store a brief summary of the project's purpose and tech stack.

## Step 2 — Formulate ADR

From the current conversation context, identify the decision being made and draft an ADR.

If `$ARGUMENTS` is provided, use it as a hint for the ADR title/topic. If not, infer from the conversation.

If the conversation does not contain a clear decision (no alternatives discussed, no trade-offs weighed), tell the user: "I couldn't identify a clear decision in our conversation. Can you describe what you decided and why?" Wait for their response.

Draft the ADR:

```
# ADR-{NNN}: {Title}

**Status:** To Review
**Date:** {YYYY-MM-DD}

## Context

{Why this decision came up — extracted from the conversation. What problem or question was being discussed.}

## Decision

{What was decided — the specific choice made.}

## Alternatives Considered

{What other options were discussed and why they were rejected. If only one option was discussed, note "No alternatives were explicitly discussed."}

## Consequences

### Positive
- {What becomes easier or better}

### Negative
- {What becomes harder or worse}

### Risks
- {What could go wrong}
```

Present the draft to the user:

> Here's the ADR I formulated from our discussion:
>
> {draft}
>
> **Look good?** (yes / edit)

**Wait for user approval or edits.** If the user provides edits, incorporate them and re-present.

## Step 3 — Write File

Create `docs/adr/` directory if it doesn't exist. Create `docs/` directory if it doesn't exist.

Write the ADR to `docs/adr/{NNN}-{kebab-case-title}.md`.

If `docs/adr/README.md` exists, append the new ADR to its index table, matching the existing format exactly. If it doesn't exist, do NOT create one.

Report:

```
Created: docs/adr/{NNN}-{kebab-case-title}.md (Status: To Review)
```

## Step 4 — Bridge to Implementation

Check whether the decision implies implementation work (code changes, new components, refactoring). If the ADR is purely informational (e.g., a naming convention, a process decision), skip the bridge and end with:

```
ADR saved. Run `ago:audit-docs` to validate consistency with existing documentation.
```

If implementation work is implied, present the bridge:

```
## Ready to plan?

ADR saved: `docs/adr/{NNN}-{title}.md` (To Review)

Based on this decision, here's the context for implementation planning:

**Artifacts:**
- `docs/adr/{NNN}-{title}.md`
{- `docs/research/YYYY-MM-DD-{topic}.md` (if a related research artifact exists)}
{- `docs/audit/YYYY-MM-DD-audit.md` (if a recent audit exists)}

**Decision:** {1-line summary}

**Key constraints:**
- {from Consequences section — most impactful items}

**Suggested pipeline:** brainstorming → writing-plans → implementation

Want to start brainstorming with this context?
[yes / adjust context / not now]
```

- **"yes"** — Invoke `superpowers:brainstorming` skill. Pass the context block above as the starting point. Brainstorming will read the referenced files itself.
- **"adjust context"** — Let the user modify the context, then invoke brainstorming with the adjusted version.
- **"not now"** — End the command. Artifacts are on disk for later use.

## Rules

- **Minimal.** This is the simplest command in the plugin. Do not over-engineer.
- **Conversation-first.** The ADR content comes from the current conversation, not from git history or code analysis.
- **Status: To Review.** Always use "To Review" status. The ADR is not yet accepted — `ago:audit-docs` will flag it for review if it stays unaccepted for >4 days.
- **No `.workflow/` dependency.** Uses only `docs/` and conversation context.
- **Respect existing format.** If the project has existing ADRs with a different format, match that format instead of the template above.
- **User approval required.** Never write the ADR file without the user confirming the draft.
