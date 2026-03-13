# ago Plan Review Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new standalone `ago` workflow that performs multi-agent review of implementation plans, shipping it as both the Claude command `ago:review-plan` and the Codex skill `ago-review-plan`, with updated product documentation and install metadata.

**Architecture:** Add one workflow concept with two platform adapters. The Claude adapter lives in `plugins/ago/commands/review-plan.md`; the Codex adapter lives in `codex/skills/ago-review-plan/SKILL.md`. Both adapters share the same contract: ensure spec and plan artifacts exist, run four parallel review lenses (`ARCH`, `SEC`, `QAL`, `PM`), write one review document per lens next to the plan, and write a summary index file. Product docs and install instructions are updated to advertise the new workflow and install the new Codex skill.

**Tech Stack:** Markdown workflow definitions, Codex `SKILL.md` packaging, existing `ago` command/skill conventions, git-based verification.

**Design spec:** `docs/plans/2026-03-13-ago-plan-review-design.md`

---

## File Structure

### Existing files to modify

- `README.md`
- `CLAUDE.md`
- `docs/install/claude.md`
- `.codex/INSTALL.md`

### New files to create

- `plugins/ago/commands/review-plan.md`
- `codex/skills/ago-review-plan/SKILL.md`

### Responsibility split

- `plugins/ago/commands/review-plan.md` defines the Claude-native command contract and artifact flow
- `codex/skills/ago-review-plan/SKILL.md` defines the Codex-native skill contract with matching semantics
- `README.md`, `CLAUDE.md`, and `docs/install/claude.md` expose the new workflow to users
- `.codex/INSTALL.md` adds the new Codex skill to the canonical install/update set

---

## Chunk 1: Add The New Workflow Adapters

### Task 1: Create the Claude command `ago:review-plan`

**Files:**
- Create: `plugins/ago/commands/review-plan.md`

- [ ] **Step 1: Draft the command frontmatter and overview**

Write the file with frontmatter matching the existing command pattern:

```md
---
description: Multi-role implementation plan review — ARCH, SEC, QAL, PM review a plan before execution
argument-hint: "[@docs/plans/...-impl.md] [--spec @docs/plans/...-design.md]"
---
```

Then add a short overview that makes these guarantees explicit:
- standalone `ago` workflow
- advisory only
- supports explicit plan path or current session context
- supports optional `--spec` override
- requires persistent plan and spec artifacts before launching agents
- writes review docs next to the plan

- [ ] **Step 2: Define input resolution and artifact materialization**

Add early steps that cover:
- explicit plan path from `$ARGUMENTS`
- explicit spec override from `$ARGUMENTS`
- fallback to current session context when no path is provided
- stop condition when no plan can be resolved
- deterministic spec resolution priority:
  - explicit override
  - `Design spec:` or `Design doc:` header from the plan
  - same-directory `-design.md` sibling
- stop-and-ask behavior when multiple spec candidates exist
- stop-and-ask behavior when zero spec candidates exist and session context is not sufficient to write a reviewable spec
- writing the plan to disk if it only exists in session context
- writing the spec to disk if it only exists in session context
- approval before choosing materialization paths
- no silent overwrite of existing plan/spec/review files
- not proceeding until both artifacts exist as files

The command must tell the operator what paths it resolved before launching agents.

- [ ] **Step 3: Define review context gathering**

Add a section that instructs the command to read:
- plan file
- spec file
- `README.md`
- `CLAUDE.md` if present
- relevant repo instructions if present
- concrete source files or interfaces explicitly referenced by the plan/spec when they can be resolved safely

Assemble those into one shared review context for all review agents.

- [ ] **Step 4: Add a pre-launch confirmation checkpoint**

Before any agents run, require the command to present:
- resolved plan path
- resolved spec path
- any additional source files included in review context
- all output filenames that will be written
- review roles that will run

Then ask for confirmation. Do not launch agents or write review artifacts until the user approves.

- [ ] **Step 5: Define the four review agents**

Write the command instructions for parallel agents:
- `ARCH`
- `SEC`
- `QAL`
- `PM`

For each role, specify:
- its review lens on the plan
- the requirement to cite evidence from the plan/spec
- the shared finding schema:
  - `title`
  - `severity`
  - `evidence`
  - `description`
  - `recommendation`
- the shared severity vocabulary:
  - `HIGH`
  - `MEDIUM`
  - `LOW`
  - `INFO`
- the required document title line naming the role, date, reviewed plan, and reviewed spec
- the required output sections:
  - `Executive Summary`
  - `Findings`
  - `Missing Plan Elements`
  - `Questions / Assumptions`
  - `Recommended Edits Before Execution`
  - `Verdict`

Allowed verdicts:
- `Ready`
- `Ready with fixes`
- `Needs rewrite`

- [ ] **Step 6: Define output file naming and review index behavior**

Specify the output naming contract using the plan file stem:

- `{plan-stem}.arch-review.md`
- `{plan-stem}.sec-review.md`
- `{plan-stem}.qal-review.md`
- `{plan-stem}.pm-review.md`
- `{plan-stem}.review-index.md`

The command must write all files in the same directory as the plan. The index file must include:
- plan path
- spec path
- links to the four review docs
- verdict table
- deduplicated top issues
- next-step recommendation

Make the command explicit that agents return structured review output and the orchestrator writes all review files. Define the index recommendation rule:
- any `Needs rewrite` -> `revise plan first`
- else any `Ready with fixes` -> `minor fixes, then execute`
- else -> `safe to execute as-is`

Also define deterministic dedup behavior:
- merge repeated issues when they describe the same plan gap
- preserve contributing roles on the merged entry
- let the merged issue reflect the strongest severity implied by the contributing reviews

Define rerun and partial-failure behavior:
- if any review artifact already exists, prompt to replace, suffix, or stop
- if a role times out or returns malformed output, retry once
- if retry fails, write the successful review files plus an index that marks incomplete coverage and recommends rerunning before execution

- [ ] **Step 7: Verify the command document**

Run:

```bash
rg -n "ago:review-plan|--spec|Design spec:|Design doc:|same-directory|multiple spec|confirm|approval|ARCH|SEC|QAL|PM|title|severity|evidence|description|recommendation|HIGH|MEDIUM|LOW|INFO|reviewed plan|reviewed spec|Executive Summary|Missing Plan Elements|Questions / Assumptions|Recommended Edits Before Execution|Ready with fixes|Needs rewrite|review-index|deduplicated|contributing roles|replace|suffix|retry once|incomplete coverage|revise plan first|minor fixes, then execute|safe to execute as-is|advisory" plugins/ago/commands/review-plan.md
```

Expected:
- matches for the command name
- explicit spec resolution and confirmation wording
- explicit support for `Design spec:` and `Design doc:`
- explicit finding schema and severity vocabulary
- explicit title/section contract for role review docs
- explicit file naming, rerun/failure, and dedup/guidance contract
- explicit advisory wording

- [ ] **Step 8: Commit**

```bash
git add plugins/ago/commands/review-plan.md
git commit -m "feat: add ago review-plan Claude command"
```

---

### Task 2: Create the Codex skill `ago-review-plan`

**Files:**
- Create: `codex/skills/ago-review-plan/SKILL.md`

- [ ] **Step 1: Add skill metadata**

Write frontmatter:

```md
---
name: ago-review-plan
description: Use when the user wants a multi-angle review of an implementation plan before execution, especially between writing-plans and executing-plans
---
```

The description should trigger for:
- reviewing an implementation plan
- running a plan checkpoint before execution
- reviewing a plan created by `writing-plans`

- [ ] **Step 2: Mirror the workflow contract from the Claude command**

Write the skill so it directly states these workflow semantics:
- standalone workflow
- advisory only
- explicit plan path or current session context
- explicit spec override support
- deterministic spec resolution via override, `Design spec:` or `Design doc:` header, then same-directory `-design.md` sibling
- stop-and-ask behavior when multiple spec candidates exist
- stop behavior when no reviewable spec can be materialized from disk or session context
- plan and spec must be persisted before review
- path approval and no silent overwrites when materializing missing files
- supporting source files/interfaces may be loaded when the plan/spec references them concretely
- confirmation before agent launch
- four review roles in parallel
- one orchestrator-written review doc per role next to the plan
- one orchestrator-written index doc next to the plan
- shared finding schema and severity vocabulary
- fixed verdict values and fixed next-step guidance rules
- deterministic dedup behavior in the index
- rerun and partial-failure handling

Keep the skill concise and product-focused, following the style of the existing `ago-*` skills.

- [ ] **Step 3: Adapt wording to Codex skill conventions**

Include:
- overview
- when to use
- inputs
- workflow steps
- output contract
- rules

Make sure the skill explicitly covers:
- candidate-spec conflict handling
- path approval before writing missing artifacts
- source-file context loading when referenced by the plan/spec
- deterministic index guidance rules
- rerun behavior for existing review files
- partial-failure behavior for timed-out or malformed reviewer output

Do not mention Claude-specific plugin behavior.

- [ ] **Step 4: Verify skill metadata and contract**

Run:

```bash
sed -n '1,220p' codex/skills/ago-review-plan/SKILL.md
rg -n "ago-review-plan|--spec|Design spec:|Design doc:|same-directory|multiple spec|confirm|approval|ARCH|SEC|QAL|PM|title|severity|evidence|description|recommendation|HIGH|MEDIUM|LOW|INFO|reviewed plan|reviewed spec|Executive Summary|Missing Plan Elements|Questions / Assumptions|Recommended Edits Before Execution|Ready with fixes|Needs rewrite|review-index|deduplicated|contributing roles|replace|suffix|retry once|incomplete coverage|revise plan first|minor fixes, then execute|safe to execute as-is|advisory" codex/skills/ago-review-plan/SKILL.md
```

Expected:
- valid frontmatter
- workflow name present
- spec resolution and confirmation contract present
- finding schema and severity contract present
- review artifact title/section contract present
- verdict, rerun/failure, and deterministic index contract present

- [ ] **Step 5: Commit**

```bash
git add codex/skills/ago-review-plan/SKILL.md
git commit -m "feat: add ago-review-plan Codex skill"
```

---

## Chunk 2: Update Product Docs And Install Metadata

### Task 3: Add the workflow to user-facing product docs

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `docs/install/claude.md`

- [ ] **Step 1: Update `README.md` workflow inventory**

Add `Review Plan` to the workflow list with a short description such as:
- review an implementation plan through `ARCH`, `SEC`, `QAL`, and `PM` before execution
- writes role-specific review artifacts next to the plan

Add an artifact line for this workflow in the same style as the rest of the workflow inventory:
- `docs/plans/*.{arch,sec,qal,pm}-review.md`
- `docs/plans/*.review-index.md`

Update the verify section so it lists:
- Claude: `ago:review-plan`
- Codex: `ago-review-plan`

- [ ] **Step 2: Update `CLAUDE.md` command table**

Add:

```md
| `ago:review-plan` | Multi-role review of an implementation plan before execution |
```

Also include the review artifact pattern in the output section:
- `docs/plans/*.{arch,sec,qal,pm}-review.md`
- `docs/plans/*.review-index.md`

- [ ] **Step 3: Update `docs/install/claude.md`**

Add `ago:review-plan` to the command list exposed after installation.

Update the verify section so the smoke test explicitly says to invoke `ago:review-plan` with a plan path and confirm the command starts normally.

- [ ] **Step 4: Verify doc references**

Run:

```bash
rg -n "Review Plan|arch-review|sec-review|qal-review|pm-review|review-index|ago:review-plan|ago-review-plan" README.md CLAUDE.md docs/install/claude.md
```

Expected:
- `README.md` includes the workflow entry and artifact pattern
- `CLAUDE.md` includes the command and artifact pattern
- `docs/install/claude.md` includes the command and deterministic smoke test
- Claude and Codex names are spelled consistently

- [ ] **Step 5: Commit**

```bash
git add README.md CLAUDE.md docs/install/claude.md
git commit -m "docs: add ago review-plan workflow references"
```

---

### Task 4: Add the new Codex skill to canonical install/update instructions

**Files:**
- Modify: `.codex/INSTALL.md`

- [ ] **Step 1: Add the new skill to the canonical install command**

Update the delete/install command so it includes:

```bash
"$HOME/.codex/skills/ago-review-plan"
```

and:

```bash
codex/skills/ago-review-plan
```

Keep the formatting consistent with the existing multi-path install command.

- [ ] **Step 2: Update the explicit install target list**

Add:

```text
- codex/skills/ago-review-plan
```

and describe it as part of the full `ago` working set for Codex.

- [ ] **Step 3: Update verify instructions**

Add:

```text
- ago-review-plan
```

to the installed skill directory checklist.

- [ ] **Step 4: Verify install instructions**

Run:

```bash
rg -n "ago-review-plan" .codex/INSTALL.md
```

Expected:
- match in the delete list
- match in the install path list
- match in the verify checklist

- [ ] **Step 5: Commit**

```bash
git add .codex/INSTALL.md
git commit -m "docs: add ago-review-plan to Codex install set"
```

---

## Chunk 3: Final Verification And Wrap-Up

### Task 5: Run final repo-level verification for the new workflow surface

**Files:**
- Verify only

- [ ] **Step 1: Check changed files and whitespace**

Run:

```bash
git diff --check
git status --short
```

Expected:
- no whitespace errors
- only the intended workflow and documentation files changed

- [ ] **Step 2: Check workflow visibility across both adapters**

Run:

```bash
rg -n "ago:review-plan|ago-review-plan" README.md CLAUDE.md docs/install/claude.md .codex/INSTALL.md plugins/ago/commands/review-plan.md codex/skills/ago-review-plan/SKILL.md
```

Expected:
- Claude command appears in the command/docs surface
- Codex skill appears in the skill/install surface

- [ ] **Step 3: Verify the final adapter contracts explicitly**

Run:

```bash
rg -n "Design spec:|Design doc:|explicit spec|multiple spec|confirm|approval|ARCH|SEC|QAL|PM|title|severity|evidence|description|recommendation|HIGH|MEDIUM|LOW|INFO|Executive Summary|Missing Plan Elements|Questions / Assumptions|Recommended Edits Before Execution|Ready with fixes|Needs rewrite|review-index|replace|suffix|retry once|incomplete coverage|revise plan first|minor fixes, then execute|safe to execute as-is" \
  plugins/ago/commands/review-plan.md \
  codex/skills/ago-review-plan/SKILL.md
```

Expected:
- both adapters mention plan/spec persistence before review
- both adapters mention all four roles
- both adapters include the shared finding schema and severity vocabulary
- both adapters include the required review sections
- both adapters include allowed verdicts
- both adapters include rerun/failure handling
- both adapters include review-index guidance rules
- advisory positioning preserved in both adapters

- [ ] **Step 4: Confirm the final commit surface**

Run:

```bash
git status --short
git show --stat --oneline HEAD
```

Expected:
- working tree clean after the final commit
- the final commit only includes the intended workflow and documentation files

- [ ] **Step 5: Commit**

```bash
git add README.md CLAUDE.md docs/install/claude.md .codex/INSTALL.md plugins/ago/commands/review-plan.md codex/skills/ago-review-plan/SKILL.md
git commit -m "feat: add ago plan review workflow"
```
