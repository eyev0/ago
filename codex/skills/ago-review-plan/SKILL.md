---
name: ago-review-plan
description: Use when the user wants a multi-angle review of an implementation plan before execution, especially between writing-plans and executing-plans
---

# ago-review-plan

## Overview

Run a standalone ago workflow that reviews an implementation plan before execution through four lenses: `ARCH`, `SEC`, `QAL`, and `PM`.

This workflow is advisory only. It supports an explicit plan path, current session context when a plan can be materialized safely, and an explicit `--spec` override. It requires persistent plan and spec artifacts before agent launch, and it writes one review doc per role plus one review-index next to the plan.

## When to Use

- The user wants a plan reviewed before execution starts
- The user wants a multi-angle check between `writing-plans` and `executing-plans`
- The plan and spec may already exist on disk, or can be materialized from the current session
- The user wants evidence-backed feedback rather than immediate implementation

Do not use this skill for retrospective code audits. Use `ago-audit` for that.

## Inputs

Accept:
- an optional explicit implementation plan path
- an optional explicit `--spec` override
- current session context only when it contains enough stable plan/spec content to write durable artifacts with approval

Reviewable artifacts must exist on disk before launching reviewers.

## Workflow

### 1. Resolve the plan

Resolve the implementation plan in this order:

1. explicit plan path
2. current session context, but only if it can be written to disk after approval

If no plan is available, stop and ask for a plan path or a finalized plan in session context.

If the plan must be materialized from session context:
- propose the path first
- get approval before choosing paths
- never silently overwrite an existing plan
- if the target exists, prompt: `replace`, `suffix`, or `stop`

### 2. Resolve the spec

Resolve the spec deterministically in this order:

1. explicit `--spec` override
2. `Design spec:` or `Design doc:` header in the resolved plan
3. same-directory `-design.md` sibling

Rules:
- override wins over all other sources
- support both `Design spec:` and `Design doc:`
- when scanning for a same-directory sibling, prefer `{plan-stem with -impl removed}-design.md` if applicable, otherwise `{plan-stem}-design.md`
- if multiple spec candidates appear at the same priority, stop and ask the user to choose; do not guess
- if no reviewable spec can be materialized, stop

If the spec comes only from session context:
- propose the output path
- require approval
- no silent overwrite
- if the target exists, prompt: `replace`, `suffix`, or `stop`

Both plan and spec must exist before review.

### 3. Resolve review outputs

Create review outputs next to the plan:
- `{plan-stem}.arch-review.md`
- `{plan-stem}.sec-review.md`
- `{plan-stem}.qal-review.md`
- `{plan-stem}.pm-review.md`
- `{plan-stem}.review-index.md`

If review files already exist, ask whether to:
- `replace`
- `suffix`
- `stop`

Do not overwrite review artifacts silently.

### 4. Gather review context

Load:
- the resolved plan
- the resolved spec
- `README.md` when present
- `CLAUDE.md` when present
- repo instructions when present
- concrete source files and interfaces referenced by the plan/spec when safely resolvable

Rules for source-file context:
- load concrete references only
- skip ambiguous references
- skip missing files but note them
- do not broaden into general repo exploration

### 5. Confirmation before launch

Present a checkpoint that includes:
- resolved plan path
- resolved spec path
- additional source files
- all review output filenames
- roles: `ARCH`, `SEC`, `QAL`, `PM`

Require explicit confirm / approval before launching any agent.

### 6. Launch four plan reviewers

Review lenses:
- `ARCH`: architecture fit, sequencing, interfaces, technical coherence
- `SEC`: security assumptions, trust boundaries, sensitive flows, rollout risk
- `QAL`: test strategy, validation depth, edge cases, regression and readiness gaps
- `PM`: scope clarity, user impact, acceptance criteria, delivery completeness

Shared reviewer contract:
- evidence must come from the plan/spec
- every finding uses:
  - `title`
  - `severity`
  - `evidence`
  - `description`
  - `recommendation`
- severity vocabulary is fixed:
  - `HIGH`
  - `MEDIUM`
  - `LOW`
  - `INFO`
- verdict vocabulary is fixed:
  - `Ready`
  - `Ready with fixes`
  - `Needs rewrite`

Each role returns structured output so the orchestrator can write a markdown review doc with:
- a title line naming role, date, reviewed plan, reviewed spec
- `Executive Summary`
- `Findings`
- `Missing Plan Elements`
- `Questions / Assumptions`
- `Recommended Edits Before Execution`
- `Verdict`

Required title line format:

`# {ROLE} Plan Review - {YYYY-MM-DD} - reviewed plan: {plan path} - reviewed spec: {spec path}`

If a section has no items, the reviewer should say `None.` rather than inventing content.

### 7. Write artifacts

The orchestrator writes:
- one review doc per role next to the plan
- one index doc next to the plan

The index must contain:
- plan path
- spec path
- links to all available review docs
- verdict table
- deduplicated top issues
- next-step recommendation

### 8. Deduplicate and recommend

Deduplicated issue behavior:
- merge repeated issues describing the same plan gap
- preserve contributing roles
- strongest severity wins from the structured severity fields
- keep separate issues separate when they are not clearly the same gap

Next-step guidance rules:
- any `Needs rewrite` => `revise plan first`
- else any `Ready with fixes` => `minor fixes, then execute`
- else => `safe to execute as-is`

### 9. Handle reruns and partial failures

Rerun behavior:
- if review artifacts already exist, ask `replace`, `suffix`, or `stop`

Partial-failure behavior:
- if a reviewer times out or returns malformed output, retry once
- if retry still fails, write successful review docs anyway
- write the index with incomplete coverage noted
- recommend rerun before execution

## Output Contract

- `{plan-stem}.arch-review.md`
- `{plan-stem}.sec-review.md`
- `{plan-stem}.qal-review.md`
- `{plan-stem}.pm-review.md`
- `{plan-stem}.review-index.md`

All files are orchestrator-written and live next to the reviewed plan.

## Rules

- Advisory only.
- Standalone workflow semantics; do not depend on `.workflow/`.
- Support explicit `--spec` override.
- Use deterministic spec resolution via override, `Design spec:` or `Design doc:` header, then same-directory sibling.
- Stop when no reviewable spec can be materialized.
- Require path approval and no silent overwrites for plan, spec, or review files.
- Load source-file context only for concretely referenced files/interfaces when safely resolvable.
- Require confirmation before agent launch.
- Use one orchestrator-written review doc per role and one orchestrator-written index doc.
- Keep the shared finding schema, severity vocabulary, verdict values, deduplicated issue behavior, rerun behavior, and partial-failure handling deterministic.
