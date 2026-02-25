---
name: ago:create-decision-record
description: Create a formal Decision Record from agent log findings. Invoke during consolidation when a significant decision is found.
version: 0.2.0
---

# ago:create-decision-record

Create a DR file in `.workflow/decisions/` and link it to the originating task.

## When to Use

During consolidation (CONSOLIDATE step), when `ago:consolidate-logs` finds a significant decision in an agent's log that warrants formal documentation.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| role | Yes | Role that made the decision (uppercase, e.g., `ARCH`) |
| epic_id | Yes | Epic ID (e.g., `E01`) |
| task_id | Yes | Short task ID (e.g., `T003`) |
| description | Yes | Short kebab-case description (e.g., `onnx-vs-tflite`) |
| context | Yes | Why this decision needed to be made |
| options | Yes | List of options considered, each with pros/cons |
| decision | Yes | What was decided and why |
| consequences | Yes | Impact on the project |

## Instructions

1. **Build filename:** `{ROLE}-{EPIC}-{TASK}-{description}.md`
   - Example: `ARCH-E01-T003-onnx-vs-tflite.md`
2. **Create file** at `.workflow/decisions/{filename}` with this content:

```markdown
---
id: {ROLE}-{EPIC}-{TASK}-{description}
role: {ROLE}
epic: {EPIC}
task: {TASK}
status: proposed
date: {YYYY-MM-DD}
supersedes:
---

## Context

{context}

## Options Considered

### Option 1: {name}
- Pros: {advantages}
- Cons: {disadvantages}

### Option 2: {name}
- Pros: {advantages}
- Cons: {disadvantages}

## Decision

{decision}

## Consequences

{consequences}
```

3. **Link to task:** Find the task.md for {task_id}, add the DR id to the `related_decisions` list in frontmatter
4. **Update registry:** Add a row to the Decision Records table in `.workflow/registry.md`:
   `| {id} | proposed | {ROLE} | {EPIC} | {TASK} | {YYYY-MM-DD} |`

## Validation

- DR file exists at `.workflow/decisions/{filename}`
- DR has valid YAML frontmatter with `status: proposed`
- Task.md `related_decisions` includes the DR id
- Registry has a new row

## Error Handling

- If `.workflow/decisions/` doesn't exist: Create it
- If task.md not found: Create the DR anyway, log a warning about missing task link
- If a DR with the same filename already exists: Append a numeric suffix (e.g., `-2`)
