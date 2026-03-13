# Design: `ago` Plan Review Workflow

**Date:** 2026-03-13
**Status:** Approved

## Problem

`ago` currently has strong entry points around retrospective audit, documentation audit, research, and ADR capture, but it does not cover the gap between planning and implementation.

That leaves two practical problems:

1. Implementation plans can go straight from `/writing-plans` to `/executing-plans` without a structured multi-angle review.
2. When a spec exists only in session context and not on disk, there is no persistent artifact for reviewers to validate against.

We want a dedicated `ago` workflow that reviews implementation plans the same way `ago:audit` reviews recent code work: multiple agents, distinct lenses, persistent artifacts, and no hidden state.

## Goals

- Add a new `ago` workflow dedicated to implementation-plan review
- Ship it in both platform adapters:
  - Claude command: `ago:review-plan`
  - Codex skill: `ago-review-plan`
- Keep the workflow advisory rather than blocking
- Reuse the established `ARCH`, `SEC`, `QAL`, and `PM` review lenses
- Produce one persistent review document per review agent
- Keep review artifacts next to the reviewed plan rather than in a separate directory
- Ensure both the plan and the spec exist as files before launching review agents

## Non-Goals

- No hard gate before `/executing-plans`
- No automatic mutation of the plan during review
- No shared consolidated review document replacing individual agent outputs
- No new directory tree just for review artifacts
- No attempt to rewrite `writing-plans` or `executing-plans`

## Product Shape

`ago` gets one new standalone workflow called `review-plan`.

It is a sibling to the existing `audit`, `research`, `audit-docs`, and `write-adr` workflows, not an embedded extension of `writing-plans` or `executing-plans`.

The workflow is invoked explicitly:

- Claude: `ago:review-plan`
- Codex: `ago-review-plan`

This keeps the architecture consistent with the current product model: one workflow concept, two platform-native adapters.

## Workflow Contract

### Inputs

The workflow accepts either:

- a plan file path, optionally with an explicit spec path override, or
- the current session context when the plan has just been discussed but not yet persisted

The preferred input is a plan file path. If a path is provided, the workflow validates that it exists before proceeding.

User-facing input grammar:

- Claude: `ago:review-plan @path/to/plan.md [--spec @path/to/spec.md]`
- Codex: `ago-review-plan <path/to/plan.md> [--spec <path/to/spec.md>]`
- Session-context mode: no path, but only when the current session already contains a reviewable plan draft

When a plan path is available, spec resolution is deterministic and ordered:

1. explicit user override passed to the workflow
2. the `Design spec:` or `Design doc:` line in the plan header, if present
3. a same-directory sibling whose stem matches the plan and ends in `-design.md`

If this process finds zero candidates, the workflow falls back to current session context and offers to write the spec before review.

If session context does not contain enough information to write a reviewable spec, the workflow stops and tells the user that a persistent spec is required before review can begin.

If it finds multiple competing candidates and no explicit override, the workflow stops and asks the user which spec to use.

### Required Persistent Artifacts

Before review agents launch, the orchestrator must ensure there are persistent artifacts for:

- the implementation plan
- the corresponding spec/design document

If the plan exists only in current session context, the workflow first writes the plan to disk.

If the spec exists only in current session context, the workflow first writes the spec to disk.

Review does not start until both artifacts exist as files.

When materializing missing artifacts from session context:

- the workflow proposes the target path before writing
- the user must confirm the path choice
- existing files are never overwritten silently
- if the proposed file already exists, the workflow asks whether to replace it, write a new suffixed file, or stop

Default path rules:

- specs follow the repository's current design pattern: `docs/plans/YYYY-MM-DD-<topic>-design.md`
- implementation plans follow the repository's current plan pattern: `docs/plans/YYYY-MM-DD-<topic>-impl.md`

For reruns, the same overwrite safety applies to review artifacts:

- if `{plan-stem}.*-review.md` or `{plan-stem}.review-index.md` already exists, the workflow asks whether to replace the existing review package, write suffixed review files, or stop

### Advisory Outcome

The workflow is advisory.

Its job is to surface weaknesses, omissions, and risks in the plan before implementation begins. It does not block execution and does not auto-edit the plan. The user may revise the plan based on review output or proceed manually.

## Artifact Model

The plan remains the canonical implementation artifact.

Review outputs are written in the same directory as the plan. If the reviewed plan is:

`docs/plans/2026-03-13-feature-impl.md`

then the workflow writes:

- `docs/plans/2026-03-13-feature-impl.arch-review.md`
- `docs/plans/2026-03-13-feature-impl.sec-review.md`
- `docs/plans/2026-03-13-feature-impl.qal-review.md`
- `docs/plans/2026-03-13-feature-impl.pm-review.md`
- `docs/plans/2026-03-13-feature-impl.review-index.md`

This keeps the review package discoverable from the plan itself and avoids another top-level review directory.

## Runtime Flow

### Step 1: Resolve Input

Resolve one of:

- explicit plan path
- in-session plan context

If neither is available, stop and tell the user there is no plan to review.

### Step 2: Materialize Missing Artifacts

Ensure the plan exists on disk.

Ensure the spec exists on disk.

If either artifact is only implicit in the current conversation, the workflow proposes exact target paths, gets approval, then writes the missing files before continuing.

### Step 3: Gather Review Context

Read:

- the plan file
- the spec/design file
- `README.md`
- `CLAUDE.md` when present
- any repo-local instructions relevant to implementation behavior
- source files and interfaces explicitly referenced by the plan or spec when those references are concrete enough to resolve

The orchestrator uses this context to build a shared review packet for all review agents.

### Step 4: Launch Four Review Agents

Before dispatching review agents, the orchestrator presents:

- resolved plan path
- resolved spec path
- any source files pulled in as supporting context
- the four review roles that will run
- the exact output filenames that will be written next to the plan

Then it asks for confirmation. No review agents are launched and no review artifacts are written until the user approves.

Launch four agents in parallel with identical context and different lenses:

- `ARCH`
- `SEC`
- `QAL`
- `PM`

Each agent reviews the quality of the plan, not the codebase implementation itself.

### Step 5: Write Individual Review Documents

Each agent returns structured review content to the orchestrator.

The shared finding schema is:

- `title`
- `severity`
- `evidence`
- `description`
- `recommendation`

Shared severity vocabulary:

- `HIGH`
- `MEDIUM`
- `LOW`
- `INFO`

The orchestrator, not the review agents, writes the review documents next to the plan.

This keeps file output deterministic, avoids conflicting parallel writes, and makes it easier to test artifact naming and overwrite behavior.

Those documents are first-class artifacts, not temporary scratch output.

If a review agent times out, errors, or returns malformed output:

- the orchestrator records that role as failed in the index
- the orchestrator does not fabricate a substitute review
- the workflow may retry that role once
- if retry also fails, the workflow writes the successful review artifacts plus an index showing incomplete review coverage and recommends rerunning the workflow before execution

### Step 6: Write Review Index

After all agent reviews complete, the orchestrator writes one index file next to the plan that contains:

- links to all four review docs
- each role's verdict
- a deduplicated list of the most important issues
- a short recommendation for what to do next

The index is a navigation and summary document, not the canonical review source.

## Review Lenses

### `ARCH`

`ARCH` reviews whether the plan is structurally sound.

Focus:

- decomposition quality
- architectural boundaries
- file and module responsibility splits
- hidden refactors or unscoped structural work
- alignment with existing codebase patterns
- whether tasks are grounded in concrete files and interfaces

### `SEC`

`SEC` reviews whether the plan omits security-relevant work.

Focus:

- auth and authorization implications
- secrets and configuration handling
- input validation and trust boundaries
- migration and rollout safety
- dependency risk
- security-sensitive implementation gaps not reflected in the plan

### `QAL`

`QAL` reviews whether the plan is executable and verifiable.

Focus:

- real TDD versus nominal TDD
- test coverage strategy
- edge cases and regression risk
- verification quality
- task granularity
- whether the plan contains enough evidence-producing steps to guide reliable implementation

### `PM`

`PM` reviews whether the plan fully covers the intended outcome.

Focus:

- user-facing completeness
- scope discipline
- documentation and release implications
- mismatches between the plan and the stated goal
- whether the definition of done is clear enough for execution

## Review Document Contract

Every agent review document uses the same high-level structure:

- title with role, date, and reviewed artifacts
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

This keeps the review package easy to scan while still leaving detailed findings in the role-specific files.

## Review Index Contract

The index file written by the orchestrator contains:

- reviewed plan path
- reviewed spec path
- links to the four agent review docs
- verdict table by role
- top deduplicated issues
- short next-step guidance, chosen from:
  - `revise plan first`
  - `minor fixes, then execute`
  - `safe to execute as-is`

The index does not overwrite, inline, or merge away the role-specific reviews.

Issue deduplication is deterministic:

- issues are grouped by the same underlying plan gap or missing artifact
- if multiple roles report the same problem, the index keeps one merged issue entry and records the contributing roles
- severity in the index is the highest severity implied by any contributing role's wording

Next-step guidance is rule-based:

- if any role returns `Needs rewrite`, guidance is `revise plan first`
- else if any role returns `Ready with fixes`, guidance is `minor fixes, then execute`
- else guidance is `safe to execute as-is`

## Platform Adapters

### Claude Adapter

Add a new command:

- `plugins/ago/commands/review-plan.md`

This command should mirror the established `ago:*` command style:

- self-contained workflow contract
- explicit artifact paths
- clear approval boundaries where needed
- persistent outputs

### Codex Adapter

Add a new skill:

- `codex/skills/ago-review-plan/SKILL.md`

The skill should mirror the same workflow semantics as the Claude command while using the repo's Codex skill conventions.

### Product Documentation

The workflow should be added to the user-facing workflow list and installation/verification documentation wherever the rest of the `ago` command and skill set is enumerated.

## Why Standalone Is The Right Shape

We considered making plan review an embedded gate between `writing-plans` and `executing-plans`.

We rejected that shape for three reasons:

1. `writing-plans` and `executing-plans` are existing superpower workflows with their own contracts.
2. A standalone `ago` workflow is easier to expose consistently in both Claude and Codex.
3. Advisory review is more honest when it is explicit and separately invokable.

The result is a simpler and more durable product boundary: planning remains planning, execution remains execution, and `ago` owns the review checkpoint between them.
