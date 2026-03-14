---
description: Audit project documentation against ADRs and current code state, generate action items
argument-hint: "[docs/path/to/specific-file.md]"
---

# ago:audit-docs

You are executing the `ago:audit-docs` command. This command audits project documentation against the current code state and produces a report with action items. It treats **ADRs as the primary source of truth** — when a doc contradicts an accepted ADR, the doc is wrong.

**This command does NOT require `.workflow/` — it works with any project that has documentation files.**

**Argument:** `$ARGUMENTS` (optional path to a specific file to focus on — see Step 1).

## Step 1 — Scan Documentation Inventory

Scan the project for all documentation files. Collect them into these categories:

- **ADRs:** `docs/adr/*.md` (also check `docs/decisions/`)
- **Plans:** `docs/superpowers/plans/*.md` (also check `docs/plan/`)
- **Product docs:** `docs/**/*.md` (excluding ADRs and plans)
- **Top-level docs:** `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and similar at the project root
- **Component docs:** `*/README.md`, `*/docs/*.md` — documentation inside subdirectories that describes specific components

If `$ARGUMENTS` contains a file path, validate that the file exists. If it does, note that you will focus analysis on that specific file (but still build the full decision map in Step 2, since ADRs provide the ground truth). If the file does not exist, tell the user and stop.

If no documentation files are found at all, tell the user: "No documentation files found in this project. Nothing to synchronize." and stop.

Present the inventory:

```
## Documentation Inventory

| Category | Count | Latest Update |
|----------|-------|---------------|
| ADRs | {N} | {YYYY-MM-DD} |
| Plans | {N} | {YYYY-MM-DD} |
| Product docs | {N} | {YYYY-MM-DD} |
| Top-level docs | {N} | {YYYY-MM-DD} |
| Component docs | {N} | {YYYY-MM-DD} |
| **Total** | **{N}** | |

{If $ARGUMENTS specified a file:}
**Focus:** Analysis will target `{path}` specifically.
```

## Step 2 — Build Decision Map from ADRs

Read every ADR file found in Step 1. For each ADR, extract:

- **ID and title** (from filename and/or heading)
- **Status** (Accepted, Superseded, Deprecated, Proposed, Rejected — from frontmatter or body)
- **Key facts** — the concrete decisions recorded: technology choices, architecture patterns, components added or removed, behavioral changes, naming conventions, any specific factual claim
- **Supersession chain** — which ADRs this one supersedes, and which supersede it (from "Superseded by" or "Supersedes" fields)
- **Date** — when the decision was made

Assemble these into a structured `DECISION_MAP`:

```
## Decision Map

{N} ADRs found. {N} accepted, {N} superseded, {N} other.

### Active Decisions (Accepted, not superseded)
| ADR | Title | Key Facts |
|-----|-------|-----------|
| ADR-001 | {title} | {comma-separated key facts} |
| ... | ... | ... |

### Supersession Chains
- ADR-001 -> superseded by ADR-005 -> superseded by ADR-012
- ...

### Superseded/Deprecated (should NOT appear in current docs)
| ADR | Title | Superseded By | Facts That Changed |
|-----|-------|---------------|--------------------|
| ADR-001 | {title} | ADR-005 | {old fact} -> {new fact} |
| ... | ... | ... | ... |
```

### ADR Health

Perform internal consistency checks on the ADR corpus:

| Check | How |
|-------|-----|
| **Pending review** | ADRs with status "To Review", "Proposed", or "Draft". Flag any older than 4 days as stale proposals. |
| **Conflicting decisions** | Two or more **accepted** ADRs that assert contradictory things (e.g., one says "use SQLite", another says "use PostgreSQL" for the same concern). |
| **Broken supersession chains** | ADR-X says "Supersedes ADR-Y" but ADR-Y does not say "Superseded by ADR-X" (or vice versa). |
| **Missing required sections** | ADR lacks one or more of: Context, Decision, Consequences. |

Present results:

```
### ADR Health
| Check | Count | Details |
|-------|-------|---------|
| Pending review | {N} | {ADR-NNN, ADR-NNN — awaiting acceptance} |
| Stale proposals (>4 days) | {N} | {ADR-NNN (created YYYY-MM-DD)} |
| Conflicting decisions | {N} | {ADR-NNN vs ADR-NNN — both accepted, contradict on {topic}} |
| Broken supersession chains | {N} | {ADR-NNN supersedes ADR-NNN but back-reference missing} |
| Missing sections | {N} | {ADR-NNN: no Consequences section} |

{If all checks pass: "All ADRs are internally consistent."}
```

If no ADRs exist, note "No ADRs found. Analysis will rely on code-to-documentation comparison only." and proceed to Step 3 without a decision map. The command is still useful for finding stale, missing, and outdated documentation even without ADRs.

## Step 3 — Cross-Reference ADRs with Code and Documentation

For each **active (accepted, not superseded) ADR**, perform two checks:

### 3a — ADR vs. Code

Verify that the technology, pattern, or component described in the ADR actually exists in the codebase:

- If an ADR says "We use SQLite for local storage," check that SQLite-related code, dependencies, or config exists.
- If an ADR says "We adopted the repository pattern," check that the pattern appears in the code.
- If the ADR's claims cannot be verified in code, flag it as a **potentially outdated ADR** (the code may have evolved beyond the ADR).

### 3b — Superseded ADR Remnants in Docs

For each **superseded** ADR, check whether documentation still references the old decision:

- If ADR-003 switched the app from Tauri to native Swift, search docs for references to "Tauri" that are not historical (i.e., not in the ADR itself or in a changelog).
- If ADR-005 removed a component called "DataSync," search docs for references to "DataSync" outside of ADRs.

Record all findings with file paths and line numbers.

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

## Step 4 — Find Documentation Gaps

Analyze each documentation file (or just the target file if `$ARGUMENTS` specified one) against the codebase and the decision map. Classify every finding into one of four categories:

### Stale

Documentation describes something that **no longer exists** in the codebase:

- References to removed files, components, or directories
- Instructions for features that were deleted
- Links to files or URLs that no longer resolve
- References to superseded ADR decisions as if they were current
- Dead internal cross-references (wikilinks or relative paths that point to nothing)

For each stale item, record:
- **File:** `{path}`
- **Line(s):** `{line number or range}`
- **Issue:** `{what is stale and why}`
- **Evidence:** `{what code/file is missing, or which ADR supersedes this}`

### Missing

Code or decisions exist but **are not documented**:

- New components, modules, or packages with no documentation
- Significant features without any mention in README or docs
- API endpoints or public interfaces without usage docs
- ADR decisions that should be reflected in architecture docs, READMEs, or guides but are not
- Configuration options that exist in code but not in docs

For each missing item, record:
- **What exists:** `{component, feature, or decision}`
- **Where:** `{file path(s) in codebase}`
- **Expected doc location:** `{where this should be documented}`
- **Evidence:** `{the code or ADR that proves this should be documented}`

### Outdated

Documentation exists but contains **incorrect facts** given current state:

- Version numbers that don't match `package.json`, `Cargo.toml`, etc.
- Architecture descriptions that don't match current code structure
- Status or progress claims that are no longer accurate
- Tech stack descriptions contradicted by ADRs or current dependencies
- Setup instructions that reference old tools, old paths, or removed steps
- Feature lists that are incomplete or include removed features

For each outdated item, record:
- **File:** `{path}`
- **Line(s):** `{line number or range}`
- **Current doc says:** `{the outdated claim}`
- **Actual state:** `{what is actually true now}`
- **Evidence:** `{ADR, code file, config, or dependency that proves the correct state}`

### Up to Date

Documentation that is **accurate** — no action needed. Count these but do not list individual items.

## Step 5 — Present Findings

Present all findings organized by category. If `$ARGUMENTS` specified a file, only show findings for that file.

```
## Documentation Sync Findings

{If a decision map was built:}
**Decision map:** {N} active ADRs, {N} superseded
**ADR-code mismatches:** {N}
**Superseded remnants in docs:** {N}

### Stale ({N} issues)

| # | File | Line(s) | Issue |
|---|------|---------|-------|
| 1 | `{path}` | {lines} | {description} |
| ... | ... | ... | ... |

{If none: "No stale documentation found."}

### Missing ({N} issues)

| # | What | Expected Location | Evidence |
|---|------|-------------------|----------|
| 1 | {component/feature} | `{path}` | {evidence} |
| ... | ... | ... | ... |

{If none: "No documentation gaps found."}

### Outdated ({N} issues)

| # | File | Line(s) | Says | Should Say |
|---|------|---------|------|------------|
| 1 | `{path}` | {lines} | {current text} | {correct text} |
| ... | ... | ... | ... | ... |

{If none: "No outdated documentation found."}

### Up to Date

{N} documentation files are current and accurate.
```

If zero issues were found across all categories, say: "All documentation is up to date. No changes needed." and skip to Step 8.

## Step 6 — Ask User How to Apply

Present the user with options:

> **How would you like to apply these changes?**
>
> - **all** — Apply all proposed fixes
> - **pick** — Enter numbers to select (e.g., "S1, M2, O3" for Stale #1, Missing #2, Outdated #3)
> - **none** — Skip all changes, keep the report only
> - **review** — Walk through each change one at a time, approve/reject individually

**Wait for the user's response. Do not proceed until they answer.**

If the user says "none," skip to Step 8.

## Step 7 — Apply Updates

For each approved change, apply it according to its category:

### Stale items

- **Remove** references to things that no longer exist.
- **Replace** dead links or cross-references with correct ones if a replacement is obvious.
- When removing a reference to a superseded ADR decision, replace it with a reference to the current ADR. For example: replace "Uses Tauri for desktop" with "Uses native Swift for desktop (see ADR-005)."
- **Never delete an entire documentation file** without explicit user confirmation — even if the file is entirely stale, ask first.

### Missing items

- **Draft new sections** or paragraphs in the expected documentation location.
- When the missing documentation relates to an ADR, reference the ADR in the new text.
- For new components without any docs, draft a minimal description: what it is, what it does, where it lives.
- Mark drafted content with a comment if appropriate (e.g., `<!-- Generated by ago:audit-docs — review for accuracy -->`) to signal it may need human refinement.

### Outdated items

- **Update the incorrect facts** to match current state.
- When the correct state comes from an ADR, add a parenthetical reference: e.g., "(see ADR-007)".
- For version number updates, update to the actual value from the source of truth (package.json, Cargo.toml, etc.).
- For architecture or feature list updates, rewrite the relevant section to match reality.

### Show before/after

For every change applied, show the user what was modified:

```
### Applied: {category} #{number} — {short description}

**File:** `{path}`

**Before:**
{the old text, with line numbers}

**After:**
{the new text}
```

If applying changes to a file with multiple findings, batch them together and show the combined before/after for that file.

## Step 8 — Save Report File

Save the audit report to `docs/audit/YYYY-MM-DD-docs.md` (using today's date). Create the `docs/audit/` directory if it doesn't exist.

The report file is a persistent artifact that can be referenced from any future session. It captures findings and action items in checkbox format.

Write the report with this structure:

```markdown
# Documentation Audit Report — {YYYY-MM-DD}

**Scope:** {N} documentation files scanned
**ADRs referenced:** {N} active ADRs used as source of truth
**Issues found:** {stale} stale, {missing} missing, {outdated} outdated

## Summary

{2-3 sentence summary of the documentation health and most significant findings}

## Findings

### Stale ({N})

| # | File | Line(s) | Issue |
|---|------|---------|-------|
| 1 | `{path}` | {lines} | {description} |

### Missing ({N})

| # | What | Expected Location | Evidence |
|---|------|-------------------|----------|
| 1 | {component/feature} | `{path}` | {evidence} |

### Outdated ({N})

| # | File | Line(s) | Says | Should Say |
|---|------|---------|------|------------|
| 1 | `{path}` | {lines} | {current text} | {correct text} |

## Action Items

**IMPORTANT:** This section MUST include an action item for EVERY finding from the audit — stale, missing, outdated, and ADR health issues. Mark applied items as `[x]`, remaining as `[ ]`.

### Applied in This Session

- [x] **{title}** — {description}
  - Category: {Stale Reference | Missing Documentation | Outdated Documentation | ADR Maintenance}
  - Files: `{file path}`

### Remaining

{For EVERY finding not yet resolved — this MUST be exhaustive:}
- [ ] **{title}** — {description}
  - Acceptance: {how to verify this is fixed}
  - Category: {Stale Reference | Missing Documentation | Outdated Documentation | ADR Maintenance}
  - Evidence: {ADR, code file, or other evidence}
  - Files: `{file path}`

{If user chose "none" — ALL items go here as unchecked:}
```

Tell the user: "Report saved to `docs/audit/YYYY-MM-DD-docs.md`."

## Step 8b — Save Action Items File

If there are **remaining (unchecked) action items**, generate a standalone action items file at `docs/audit/{YYYY-MM-DD}-docs-action-items.md`. This is a focused extract for parallel processing.

```markdown
# Audit Report — Documentation Action Items ({YYYY-MM-DD})

**Source:** docs/audit/{YYYY-MM-DD}-docs.md
**Total items:** {N} ({breakdown by category})

## Category Overview

| Category | Count | Details |
|----------|-------|---------|
| Stale Reference | {N} | Dead links, removed components, superseded decisions |
| Missing Documentation | {N} | Undocumented features, components, configs |
| Outdated Documentation | {N} | Incorrect facts, version mismatches |
| ADR Maintenance | {N} | Stale proposals, conflicts, broken chains |

(Omit categories with zero items.)

## Action Items

{All remaining (unchecked) items, organized by category:}

### Stale Reference
- [ ] **{title}** — {description}
  - Acceptance: {criteria}
  - Category: Stale Reference
  - Evidence: {evidence}
  - Files: `{file path}`

### Missing Documentation
{same format}

### Outdated Documentation
{same format}

### ADR Maintenance
{same format}
```

**Do not ask permission to write this file** — it is a companion output to the doc audit report.

If there are **zero remaining items** (all were applied in Step 7), skip this step.

## Step 9 — Final Summary

Present the final summary:

```
## Documentation Audit Complete

**Files scanned:** {N}
**Issues found:** {stale} stale, {missing} missing, {outdated} outdated
**Files updated:** {N}
**Files unchanged:** {N}
**Report saved:** `docs/audit/YYYY-MM-DD-docs.md`

{If ADRs were used:}
**ADRs referenced:** {N} active ADRs used as source of truth

### Changes Applied
| File | Changes |
|------|---------|
| `{path}` | {brief description of what changed} |
| ... | ... |

{If no changes were applied:}
No changes were applied. Run `ago:audit-docs` again to re-evaluate.

### Remaining Action Items
{List any issues the user chose not to fix, or that require manual attention:}
- [ ] {file}: {issue description} (skipped / needs manual review)

{If no remaining issues:}
All detected issues have been addressed.
```

## Step 10 — Bridge to Next Steps

If the audit found **zero remaining action items**, end with: "All documentation issues resolved. Run `ago:audit-docs` again after code changes to verify." Skip this step.

Classify remaining findings into:

- **Architectural issues** — conflicting ADRs, ADR-code mismatches, major missing docs that imply missing features
- **Editorial issues** — stale references, outdated text, missing sections, broken chains

Present options based on remaining item count:

```
### What's Next?

{N} remaining documentation action items across {M} categories.

1. **Fix now** — Launch parallel agents to fix remaining items
   - Groups items by category, one agent per group
   - Each agent works on documentation files only (no code changes)
   - Best for: editorial fixes (stale refs, missing sections, outdated text)

2. **Brainstorm first** — For architectural issues that need design discussion
   - Best for: conflicting ADRs, ADR-code mismatches, structural gaps
   - Pipeline: brainstorming → writing-plans → implementation

3. **Not now** — All artifacts saved to disk for later
   - Report: docs/audit/{YYYY-MM-DD}-docs.md
   - Action items: docs/audit/{YYYY-MM-DD}-docs-action-items.md

[1 / 2 / 3]
```

- **"1" (Fix now)** — Proceed to Step 11 (Parallel Doc Fix).
- **"2" (Brainstorm)** — Invoke `superpowers:brainstorming` skill with context referencing the report and action items files.
- **"3" (Not now)** — End the command.

**Do NOT proceed to Step 11 unless the user explicitly chooses option 1.**

## Step 11 — Group & Approve Doc Fix Plan

Group remaining action items by **category** (Stale Reference, Missing Documentation, Outdated Documentation, ADR Maintenance). Each category becomes one agent group.

If a category has only 1-2 items, batch it with the nearest small category into a "Mixed Batch" group.

### File conflict check

For each pair of groups, check if they modify the same file. If so, merge those groups.

Present the fix plan:

```
## Doc Fix Plan

**Items:** {N} remaining ({breakdown by category})
**Agent groups:** {M} parallel

### Agent 1 — {category} [{file list}]
  {title}
  {title}

### Agent 2 — {category} [{file list}]
  {title}

Proceed? [yes / adjust / cancel]
```

**Do NOT proceed until the user confirms.**

## Step 12 — Dispatch Doc Fix Agents

Launch agents **in parallel** using the Agent tool. Each agent runs in an isolated worktree (`isolation: "worktree"`).

For each agent group, use the Agent tool with `isolation: "worktree"` and this prompt:

```
You are fixing documentation issues. You ONLY modify documentation files (.md, .txt, .rst) — never source code.

## Your Items

{For each item in this group:}

### Item: {title}
- **Category:** {category}
- **Description:** {description}
- **Acceptance criteria:** {acceptance}
- **Evidence:** {evidence}
- **Files:** {files}

{Repeat for each item}

## Instructions

For each item:

1. **Read the referenced file(s)** to understand current state
2. **Apply the fix** — match the existing doc style and tone
3. **Verify** — re-read the changed section and confirm the acceptance criteria are met
4. When fixing stale references to superseded ADRs, replace with current ADR reference
5. When writing missing documentation, keep it minimal and accurate — don't over-elaborate

After all items:

6. **Self-review:** `git diff` all changes. Check for consistency.
7. **Commit:**
   ```
   docs: {summary of documentation fixes}

   Refs: ago:audit-docs {date}
   ```

## Output

Report back with:
- List of items: title, category, status (fixed/failed)
- Files changed
- Any issues encountered
```

## Step 13 — Collect Results

After all doc fix agents complete, present results:

```
## Doc Fix Results

**Items fixed:** {X}/{Y}
**Agents:** {N} dispatched, {M} completed

### Results

| # | Item | Category | Status |
|---|------|----------|--------|
| 1 | {title} | Stale Reference | fixed |
| 2 | {title} | Missing Documentation | fixed |

### Branches Created
- `{branch-name}` — {summary}

{If any items failed: list with failure reason.}
```

After presenting results:

1. **Update action items** — Change `- [ ]` to `- [x]` for fixed items in both report and action items files.
2. Suggest: "Review the branches, then run `ago:audit-docs` again to verify."

## Rules

- **ADRs are truth.** If documentation contradicts an accepted, non-superseded ADR, the documentation is wrong. Do not question the ADR — update the doc.
- **No `.workflow/` dependency.** This command does not read from or write to `.workflow/`. It uses `docs/`, source code, project config files, and git metadata only.
- **Collaborative.** Always present findings and proposed changes before applying them. Never silently modify documentation. Show before/after for every change.
- **Conservative.** When uncertain whether something is stale, missing, or outdated, flag it for review rather than auto-applying a fix. Err on the side of asking.
- **Referential.** When updating documentation because of an ADR, always add a reference to the relevant ADR so readers can trace the decision.
- **Non-destructive on code.** Only modify documentation files (`.md`, `.txt`, `.rst`, and similar). Never modify source code, configuration, or build files.
- **Never delete doc files silently.** Even if a documentation file is entirely stale, ask the user before deleting it. Prefer emptying/rewriting over deletion.
- **Respect existing style.** When drafting new documentation sections, match the tone, formatting, and conventions of the existing docs in the project.
- **Graceful degradation.** If no ADRs exist, the command still works — it compares docs against code directly. If `docs/` does not exist, scan for top-level and component docs only. Only hard-fail if zero documentation files are found anywhere.
- **Idempotent.** Running `ago:audit-docs` twice in a row should produce no changes on the second run if all issues were addressed in the first.
- **Focused mode.** When `$ARGUMENTS` specifies a file, still build the full decision map (ADR truth is global) but only report and fix issues in that file.
