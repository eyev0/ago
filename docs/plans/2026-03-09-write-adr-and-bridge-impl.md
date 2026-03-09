# write-adr + Bridge + audit-docs ADR Consistency — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `ago:write-adr` command, extend `audit-docs` with ADR consistency checks, and add interactive bridge-to-implementation in all four commands.

**Architecture:** Each command is a self-contained markdown file in `plugins/ago/commands/`. Bridge is a shared pattern copy-pasted (not abstracted) into each command's final step. ADR consistency checks extend existing steps in `audit-docs.md`.

**Tech Stack:** Markdown command definitions (Claude Code plugin format), YAML frontmatter, no runtime code.

**Design doc:** `docs/plans/2026-03-09-write-adr-and-bridge-design.md`

---

### Task 1: Create `ago:write-adr` command

**Files:**
- Create: `plugins/ago/commands/write-adr.md`

**Step 1: Write the command file**

Create `plugins/ago/commands/write-adr.md` with this content:

```markdown
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
```

**Step 2: Verify file exists and is well-formed**

Run: `head -5 plugins/ago/commands/write-adr.md`
Expected: YAML frontmatter with description field

**Step 3: Commit**

```bash
git add plugins/ago/commands/write-adr.md
git commit -m "feat: add ago:write-adr command for mid-conversation ADR capture"
```

---

### Task 2: Register `write-adr` in plugin.json and CLAUDE.md

**Files:**
- Modify: `plugins/ago/.claude-plugin/plugin.json`
- Modify: `CLAUDE.md`

**Step 1: Update plugin.json**

The plugin.json currently has no `commands` array — commands are auto-discovered from the `commands/` directory. Verify this by checking that the file has no explicit command registration.

If auto-discovery is in place, no change to plugin.json is needed.

**Step 2: Update CLAUDE.md commands table**

Add `ago:write-adr` to the commands table:

```markdown
| Command | Description |
|---------|-------------|
| `ago:audit` | Multi-role retrospective review (ARCH/SEC/QAL/PM) from git history + docs |
| `ago:research` | Structured research session with persistent artifact in `docs/research/` |
| `ago:audit-docs` | Audit documentation against ADRs and current code, generate action items |
| `ago:write-adr` | Capture an architectural decision from current conversation as ADR (To Review) |
```

Also add to Output section:

```markdown
- `docs/adr/NNN-{title}.md` — ADRs proposed by audit/research or captured by write-adr (To Review)
```

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: register ago:write-adr in CLAUDE.md"
```

---

### Task 3: Extend `audit-docs` Step 2 — ADR Health table

**Files:**
- Modify: `plugins/ago/commands/audit-docs.md`

**Step 1: Add ADR Health section to Step 2**

After the existing Decision Map output (after the `### Superseded/Deprecated` table and before `If no ADRs exist`), insert:

```markdown
### ADR Health

Perform internal consistency checks on the ADR corpus:

| Check | How |
|-------|-----|
| **Pending review** | ADRs with status "To Review", "Proposed", or "Draft". Flag any older than 4 days as stale proposals. |
| **Conflicting decisions** | Two or more **accepted** ADRs that assert contradictory things (e.g., one says "use SQLite", another says "use PostgreSQL" for the same concern). |
| **Broken supersession chains** | ADR-X says "Supersedes ADR-Y" but ADR-Y does not say "Superseded by ADR-X" (or vice versa). |
| **Missing required sections** | ADR lacks one or more of: Context, Decision, Consequences. |

Present results:

` `` (triple backtick block)
### ADR Health
| Check | Count | Details |
|-------|-------|---------|
| Pending review | {N} | {ADR-NNN, ADR-NNN — awaiting acceptance} |
| Stale proposals (>4 days) | {N} | {ADR-NNN (created YYYY-MM-DD)} |
| Conflicting decisions | {N} | {ADR-NNN vs ADR-NNN — both accepted, contradict on {topic}} |
| Broken supersession chains | {N} | {ADR-NNN supersedes ADR-NNN but back-reference missing} |
| Missing sections | {N} | {ADR-NNN: no Consequences section} |

{If all checks pass: "All ADRs are internally consistent."}
` ``
```

**Step 2: Verify edit is correct**

Read the modified file around Step 2 to confirm the new section is properly placed.

**Step 3: Commit**

```bash
git add plugins/ago/commands/audit-docs.md
git commit -m "feat(audit-docs): add ADR Health checks to decision map"
```

---

### Task 4: Extend `audit-docs` Step 3 — ADR Internal Consistency (Step 3c)

**Files:**
- Modify: `plugins/ago/commands/audit-docs.md`

**Step 1: Add Step 3c after Step 3b**

After the existing `### 3b — Superseded ADR Remnants in Docs` section, insert:

```markdown
### 3c — ADR Internal Consistency

For each issue detected in the ADR Health check (Step 2), create a finding in the appropriate category:

1. **Conflicting ADRs** — Two accepted ADRs contradict each other.
   - Category: **Outdated** (one of them must be wrong)
   - Record both ADRs, the contradiction, and suggest the user resolve by superseding one
   - Severity: **Critical** — conflicting truth sources undermine all documentation

2. **Stale proposals** — ADR with status "To Review" or "Proposed" created more than 4 days ago.
   - Category: **Outdated** (the proposal is aging without resolution)
   - Record the ADR, its creation date, and days since creation
   - Action item: "Accept, reject, or revise ADR-{NNN}"

3. **Broken supersession chains** — One-sided supersession reference.
   - Category: **Outdated** (metadata is inconsistent)
   - This is **auto-fixable**: add the missing "Superseded by ADR-{NNN}" or "Supersedes ADR-{NNN}" field
   - Record both ADRs and which direction is missing

4. **Missing required sections** — ADR lacks Context, Decision, or Consequences.
   - Category: **Missing**
   - Record the ADR and which section(s) are absent
   - Action item: "Add missing {section} to ADR-{NNN}"

These findings flow into Step 4's classification and are presented alongside documentation findings in Step 5. They are actioned in Step 7 like any other finding (auto-fix for broken chains, user action for conflicts and stale proposals).
```

**Step 2: Verify edit is correct**

Read the modified file around Step 3 to confirm 3c follows 3b naturally.

**Step 3: Commit**

```bash
git add plugins/ago/commands/audit-docs.md
git commit -m "feat(audit-docs): add ADR internal consistency checks (Step 3c)"
```

---

### Task 5: Add conditional bridge to `audit-docs`

**Files:**
- Modify: `plugins/ago/commands/audit-docs.md`

**Step 1: Add bridge as final step**

After Step 9 (Final Summary) and before the `## Rules` section, insert a new Step 10:

```markdown
## Step 10 — Bridge to Implementation

If the audit found **zero actionable issues**, skip this step.

Classify the findings from this session into two categories:

### Architectural issues
Findings that require design decisions or code changes:
- Conflicting ADRs (from Step 3c)
- ADR vs Code mismatches (from Step 3a)
- Major missing documentation that implies missing features

### Editorial issues
Findings that require only documentation edits:
- Stale references, outdated text, missing sections
- Broken supersession chains
- Minor documentation gaps

Present the appropriate bridge based on what was found:

### If architectural issues exist

` ``
## Ready to plan?

This audit found architectural issues that need design decisions:

**Artifacts:**
- `docs/audit/{YYYY-MM-DD}-docs.md` (this session's report)
{- list any ADRs flagged as conflicting or mismatched}

**Architectural issues:**
- {1-line per architectural issue found}

**Suggested pipeline:** brainstorming → writing-plans → implementation

Want to start brainstorming with this context?
[yes / adjust context / not now]
` ``

- **"yes"** — Invoke `superpowers:brainstorming` skill with the context above.
- **"adjust context"** — User modifies, then invoke.
- **"not now"** — End the command.

### If only editorial issues remain (no architectural issues, or architectural ones already addressed)

` ``
## Ready to fix documentation?

This audit found editorial issues that can be planned and fixed:

**Artifacts:**
- `docs/audit/{YYYY-MM-DD}-docs.md` (this session's report)

**Remaining editorial issues:**
- {1-line per remaining editorial issue}

**Suggested pipeline:** writing-plans → implementation (no brainstorming needed for editorial fixes)

Want to create an implementation plan for these fixes?
[yes / adjust context / not now]
` ``

- **"yes"** — Invoke `superpowers:writing-plans` skill with the context above.
- **"adjust context"** — User modifies, then invoke.
- **"not now"** — End the command.

### If both types exist

Present both bridges separately — architectural first, editorial second. The user can choose to address one, both, or neither.
```

**Step 2: Verify edit is correct**

Read the end of the modified file to confirm Step 10 is before Rules and flows naturally from Step 9.

**Step 3: Commit**

```bash
git add plugins/ago/commands/audit-docs.md
git commit -m "feat(audit-docs): add conditional bridge to brainstorming/writing-plans"
```

---

### Task 6: Add bridge to `ago:audit`

**Files:**
- Modify: `plugins/ago/commands/audit.md`

**Step 1: Replace "Next Steps" in Step 10 with interactive bridge**

In Step 10 (Final Summary), replace the `### Next Steps` section content:

```markdown
### Next Steps
- Open a new session and run: "Fix critical issues from docs/audit/{date}-audit.md"
- Or use /writing-plans with the report as input
- Run `ago:audit` again after fixes to verify
```

With:

```markdown
### Bridge to Implementation

If the audit found zero action items, skip this section and end.

Prepare the bridge context from this session's output:

` ``
## Ready to plan?

Based on this audit's findings, here's the context for implementation planning:

**Artifacts:**
- `docs/audit/{YYYY-MM-DD}-audit.md` (this session's report)
{- `docs/adr/{NNN}-{title}.md` (for each ADR created this session)}

**Key decisions:**
{- 1-line per ADR created}

**Top action items:**
{- Top 3-5 Critical/High items from the report}

**Suggested pipeline:** brainstorming → writing-plans → implementation

Want to start brainstorming with this context?
[yes / adjust context / not now]
` ``

- **"yes"** — Invoke `superpowers:brainstorming` skill. Pass the context above — brainstorming will read the referenced artifact files for full details.
- **"adjust context"** — Let the user modify the context block, then invoke brainstorming with the adjusted version.
- **"not now"** — End the command. All artifacts are on disk for later use. Suggest: "Run `ago:audit` again after fixes to verify resolution."
```

**Step 2: Verify edit is correct**

Read the end of audit.md to confirm the bridge replaces the old Next Steps section.

**Step 3: Commit**

```bash
git add plugins/ago/commands/audit.md
git commit -m "feat(audit): add interactive bridge to brainstorming pipeline"
```

---

### Task 7: Add bridge to `ago:research`

**Files:**
- Modify: `plugins/ago/commands/research.md`

**Step 1: Replace "Next Steps" in Step 7 with interactive bridge**

In Step 7 (Final Summary), replace the `### Next Steps` section content:

```markdown
### Next Steps
{Same as Recommendations from the artifact, for quick reference}
```

With:

```markdown
### Bridge to Implementation

If the research produced no actionable recommendations, skip this section and end.

Prepare the bridge context from this session's output:

` ``
## Ready to plan?

Based on this research, here's the context for implementation planning:

**Artifacts:**
- `docs/research/{YYYY-MM-DD}-{slug}.md` (this session's research)
{- `docs/adr/{NNN}-{title}.md` (for each ADR created this session)}

**Key decisions:**
{- 1-line per ADR created, or "No ADRs created"}

**Top recommendations:**
{- Top 3-5 recommendations from the research artifact}

**Suggested pipeline:** brainstorming → writing-plans → implementation

Want to start brainstorming with this context?
[yes / adjust context / not now]
` ``

- **"yes"** — Invoke `superpowers:brainstorming` skill. Pass the context above — brainstorming will read the referenced artifact files for full details.
- **"adjust context"** — Let the user modify the context block, then invoke brainstorming with the adjusted version.
- **"not now"** — End the command. All artifacts are on disk for later use.

**Step 2: Verify edit is correct**

Read the end of research.md to confirm the bridge replaces the old Next Steps placeholder.

**Step 3: Commit**

```bash
git add plugins/ago/commands/research.md
git commit -m "feat(research): add interactive bridge to brainstorming pipeline"
```

---

### Task 8: Update MEMORY.md

**Files:**
- Modify: `/Users/eyev/.claude/projects/-Users-eyev-dev-claude-workflow/memory/MEMORY.md`

**Step 1: Update the Lightweight Commands section**

Update the section about lightweight commands to reflect the new `write-adr` command and the bridge pattern. Update the command count in Key Structure.

**Step 2: Commit**

No commit needed — memory files are outside the repo.

---

### Task 9: Smoke test all commands

**Step 1: Verify all command files parse correctly**

Run: `head -3 plugins/ago/commands/*.md`
Expected: Each file starts with `---` (YAML frontmatter)

**Step 2: Verify plugin.json is valid JSON**

Run: `python3 -c "import json; json.load(open('plugins/ago/.claude-plugin/plugin.json'))"`
Expected: No error

**Step 3: Verify no broken markdown**

Run: Visually scan each modified command file for unclosed code blocks or broken formatting.

**Step 4: Commit (if any fixes needed)**

Only if issues were found in steps 1-3.
