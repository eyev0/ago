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
- **Plans:** `docs/plans/*.md` (also check `docs/plan/`)
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

### Applied in This Session

- [x] {Description of change applied} — `{file path}`

### Remaining

- [ ] {Description of remaining issue} — `{file path}`
  - Evidence: {ADR, code file, or other evidence}

{If user chose "none":}
### Not Applied (User Deferred)

- [ ] {Description of deferred issue} — `{file path}`
```

Tell the user: "Report saved to `docs/audit/YYYY-MM-DD-docs.md`."

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

```
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
```

- **"yes"** — Invoke `superpowers:brainstorming` skill with the context above.
- **"adjust context"** — User modifies, then invoke.
- **"not now"** — End the command.

### If only editorial issues remain (no architectural issues, or architectural ones already addressed)

```
## Ready to fix documentation?

This audit found editorial issues that can be planned and fixed:

**Artifacts:**
- `docs/audit/{YYYY-MM-DD}-docs.md` (this session's report)

**Remaining editorial issues:**
- {1-line per remaining editorial issue}

**Suggested pipeline:** writing-plans → implementation (no brainstorming needed for editorial fixes)

Want to create an implementation plan for these fixes?
[yes / adjust context / not now]
```

- **"yes"** — Invoke `superpowers:writing-plans` skill with the context above.
- **"adjust context"** — User modifies, then invoke.
- **"not now"** — End the command.

### If both types exist

Present both bridges separately — architectural first, editorial second. The user can choose to address one, both, or neither.

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
