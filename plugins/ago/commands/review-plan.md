---
description: Multi-role implementation plan review — ARCH, SEC, QAL, PM review a plan before execution
argument-hint: "[@docs/superpowers/plans/...-impl.md] [--spec @docs/superpowers/plans/...-design.md]"
---

# ago:review-plan

You are executing the `ago:review-plan` command. This is a **standalone ago workflow** for reviewing an implementation plan before execution. It is **advisory only**: reviewers recommend plan edits, but they do not change code, execute the plan, or approve implementation on behalf of the user.

This workflow supports:
- an explicit plan path
- the current session context when no plan path is passed
- an optional `--spec` override

It requires persistent plan and spec artifacts on disk before launching review agents, and it writes review docs next to the plan.

**Argument:** `$ARGUMENTS` (optional plan path plus optional `--spec` override).

## Step 1 — Resolve Inputs

Parse `$ARGUMENTS` into:
- optional explicit plan path
- optional explicit `--spec` path

### 1a — Resolve the plan

Resolve the plan using this order:

1. Explicit plan path from `$ARGUMENTS`
2. Current session context, but only if the session already contains a stable implementation plan that can be materialized to disk with user approval

If neither source produces a reviewable plan, stop and tell the user:

> No implementation plan was found. Provide a plan path or establish the plan in the current session first.

If the plan exists only in session context:
- propose a concrete path for writing it to disk
- ask for approval before choosing paths
- do not silently overwrite an existing plan file
- if the proposed plan path already exists, prompt: `replace`, `suffix`, or `stop`
- write the plan only after approval

### 1b — Resolve the spec

Resolve the spec deterministically in this order:

1. explicit `--spec` override
2. a `Design spec:` or `Design doc:` header in the resolved plan
3. a same-directory `-design.md` sibling next to the plan

Rules:
- `--spec` always wins over any in-plan reference or same-directory candidate.
- Treat both `Design spec:` and `Design doc:` as valid headers.
- When scanning for a same-directory sibling, prefer `{plan-stem with -impl removed}-design.md` if applicable, otherwise `{plan-stem}-design.md`.
- If multiple spec candidates are discovered at the same resolution level, stop and present the conflict. Do not guess. Ask the user to choose one path or pass `--spec`.
- If zero-spec resolution occurs and the current session does not contain enough approved context to materialize a reviewable spec, stop.

If the spec exists only in session context:
- propose a concrete path for writing it to disk
- ask for approval before choosing paths
- do not silently overwrite an existing spec file
- if the proposed spec path already exists, prompt: `replace`, `suffix`, or `stop`
- write the spec only after approval

Both artifacts must exist on disk before review. If either artifact is missing after resolution, stop.

## Step 2 — Resolve Review Outputs

Compute output paths next to the resolved plan:

- `{plan-stem}.arch-review.md`
- `{plan-stem}.sec-review.md`
- `{plan-stem}.qal-review.md`
- `{plan-stem}.pm-review.md`
- `{plan-stem}.review-index.md`

If any review artifacts already exist, prompt before proceeding:
- `replace` — overwrite the existing review artifacts
- `suffix` — write new review files with a deterministic suffix such as `.v2`
- `stop` — end without launching reviewers

Do not silently overwrite existing review files.

## Step 3 — Gather Review Context

Read and assemble review context from:
- the resolved plan
- the resolved spec
- `README.md` when present
- `CLAUDE.md` when present
- repo instructions when present, such as `AGENTS.md`
- concrete source files or interfaces referenced by the plan or spec, but only when they are safely resolvable to real repository paths

Rules for additional source-file context:
- Only load files explicitly named or clearly implied by concrete path/interface references in the plan or spec.
- Skip ambiguous references rather than guessing.
- Skip missing files, but note their absence in the orchestrator context.
- Do not expand into a broad repo crawl.

Assemble a single `REVIEW_CONTEXT` block that includes:
- resolved plan path
- resolved spec path
- summaries or excerpts needed from project docs
- additional source files loaded

## Step 4 — Confirmation Checkpoint

Before launching any agents, present a confirmation checkpoint that includes:
- resolved plan path
- resolved spec path
- additional source files
- all output filenames
- review roles: `ARCH`, `SEC`, `QAL`, `PM`

Then ask:

> Ready to launch 4 plan-review agents. Proceed? (yes / no / adjust paths)

No agent launch before approval.

## Step 5 — Launch Review Agents

Launch 4 review agents in parallel. They review the plan and spec only. They are not implementation agents.

All agents share these rules:
- focus on plan review, not code execution
- require evidence from the plan or spec for every finding
- use this exact finding schema:
  - `title`
  - `severity`
  - `evidence`
  - `description`
  - `recommendation`
- use only these severities:
  - `HIGH`
  - `MEDIUM`
  - `LOW`
  - `INFO`
- return a structured response that the orchestrator can write to disk
- include one verdict using only:
  - `Ready`
  - `Ready with fixes`
  - `Needs rewrite`

### Agent: ARCH

Focus:
- architecture fit
- sequencing and dependency order
- system boundaries and interfaces
- design coherence between plan and spec
- structural risks or missing technical decisions

### Agent: SEC

Focus:
- security assumptions in the plan
- authn/authz and trust-boundary coverage
- sensitive data handling
- rollout, migration, and abuse-case gaps
- security-sensitive dependencies or integrations called out by the plan/spec

### Agent: QAL

Focus:
- test strategy
- validation steps
- edge cases and regression coverage
- rollout verification
- operational readiness and failure handling in the plan

### Agent: PM

Focus:
- scope clarity
- user-facing outcomes
- sequencing against goals
- documentation and acceptance criteria
- plan completeness from a delivery perspective

Each agent must organize its output so the orchestrator can render a review doc with:
- a required title line naming role, date, reviewed plan, and reviewed spec
- `Executive Summary`
- `Findings`
- `Missing Plan Elements`
- `Questions / Assumptions`
- `Recommended Edits Before Execution`
- `Verdict`

Required title line format:

`# {ROLE} Plan Review - {YYYY-MM-DD} - reviewed plan: {plan path} - reviewed spec: {spec path}`

If a section has no items, the agent must say `None.` rather than inventing content.

## Step 6 — Handle Retry and Partial Failure

Agents return structured output; the orchestrator writes all files.

If a role times out or returns malformed output:
- retry once
- if retry succeeds, continue normally
- if retry fails, do not block successful reviewers from being written

In a partial-failure case:
- write all successful review docs
- write the index and mark incomplete coverage
- state which role failed
- recommend rerun before execution

## Step 7 — Write Review Docs

Write one orchestrator-written review doc per role next to the plan:
- `{plan-stem}.arch-review.md`
- `{plan-stem}.sec-review.md`
- `{plan-stem}.qal-review.md`
- `{plan-stem}.pm-review.md`

Every successful review doc must preserve the agent's structured findings and use the required section headings and verdict vocabulary exactly.

## Step 8 — Write the Index

Write `{plan-stem}.review-index.md` next to the plan.

The index must include:
- plan path
- spec path
- links to all available review docs
- a verdict table
- deduplicated top issues
- next-step recommendation

Dedup rules:
- merge repeated issues that describe the same plan gap
- preserve contributing roles
- the merged issue uses the strongest severity from the structured severity fields
- if two issues overlap only loosely, keep them separate

Recommendation rules:
- if any reviewer returns `Needs rewrite`, recommend: `revise plan first`
- else if any reviewer returns `Ready with fixes`, recommend: `minor fixes, then execute`
- else recommend: `safe to execute as-is`

If partial failure occurred, the index must say `incomplete coverage` and recommend rerunning the missing reviewer before execution even if the current recommendation would otherwise be favorable.

## Rules

- Standalone command; do not require `.workflow/`.
- Advisory only.
- Explicit `--spec` override is supported.
- Use deterministic plan/spec resolution.
- Stop on missing plan, missing spec, or unresolved multiple spec conflicts.
- Require path approval before writing plan/spec artifacts from session context.
- No silent overwrite of plan, spec, or review files.
- Load source-file context only when concrete references are safely resolvable.
- No agent launch before approval.
- Reviewers must cite evidence from the plan/spec.
- Orchestrator writes all files, including the review-index artifact.
