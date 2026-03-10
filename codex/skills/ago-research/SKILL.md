---
name: ago-research
description: Use when the user wants structured investigation of a technical topic with a reusable artifact and evidence-backed recommendations
---

# ago-research

## Overview

Run a structured research workflow for a user-supplied topic, ground it in the current project, write a reusable research artifact, and optionally propose ADRs from the findings.

Primary artifact: `docs/research/YYYY-MM-DD-{topic}.md`

## When to Use

- The user wants research, comparison, or feasibility analysis
- The user needs a persistent artifact rather than an ad hoc chat answer
- The question should combine project context, codebase evidence, and external sources when available

Do not use for retrospective review of commits. Use `ago-audit` for that.

## Inputs

Require a topic.

If the user did not provide one, ask:

`What topic would you like to research?`

Once provided, derive a kebab-case slug for filenames.

## Process

### 1. Gather project context

Read, when present:

- `README.md`
- `CLAUDE.md`
- top-level architecture docs
- existing ADRs under `docs/adr/` or `docs/decisions/`
- prior research artifacts under `docs/research/`

Capture:

- project purpose and constraints
- existing relevant decisions
- prior work that overlaps the topic

### 2. Formulate research questions

Draft 3 to 5 concrete research questions that are:

- relevant to the project
- non-redundant with existing ADRs and prior research
- diverse enough to cover feasibility, trade-offs, and operational concerns

Present the plan before starting research:

- context
- prior work
- proposed questions

Wait for the user's approval or edits. Do not begin research until the plan is confirmed.

### 3. Conduct the research

For each approved question, combine whatever methods are available:

- codebase inspection
- file search and reading
- shell measurements when useful
- external web research when the environment supports it

For every factual claim, record a source:

- URL
- file path and line reference
- exact command and output

Rate confidence as `HIGH`, `MEDIUM`, or `LOW`.
If something cannot be answered well, record the gap instead of guessing.

### 4. Write the research artifact

Write:

`docs/research/YYYY-MM-DD-{topic-slug}.md`

Include:

- topic, date, author, status
- project context
- questions investigated
- findings by question
- explicit sources
- conclusions
- recommendations
- related ADRs

Set status to:

- `Complete` if all questions were answered with at least medium confidence
- `Partial` otherwise

Write the artifact without asking for another confirmation. This file is the primary output of the skill.

### 5. Propose ADRs

If the research reveals architecture or long-term product decisions that should be formalized, propose ADR candidates to the user.

Only write ADRs after approval.

If approved:

- determine the next ADR number
- write ADRs under `docs/adr/`
- update `docs/adr/README.md` only if it already exists

### 6. Bridge to implementation

If the research produced actionable recommendations, offer a planning handoff that references:

- the research artifact path
- any ADRs created in this run
- the top recommendations

Use the same handoff shape as the Claude workflow:

- artifacts
- key decisions
- top recommendations
- suggested pipeline: brainstorming -> writing-plans -> implementation

If the user declines, stop with artifacts on disk.

## Output Contract

- `docs/research/YYYY-MM-DD-{topic-slug}.md`
- optionally `docs/adr/{NNN}-{title}.md`

## Rules

- Require explicit approval before starting the research questions.
- Require explicit approval before writing ADRs.
- Every factual claim needs a source.
- Do not invent benchmark numbers.
- Be honest when the result is partial.
- Prefer reusable findings over chat-only prose.
