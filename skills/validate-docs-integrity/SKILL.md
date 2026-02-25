---
name: ago:validate-docs-integrity
description: Check documentation integrity — wikilinks, references, cross-document consistency. Invoke periodically or after major changes.
version: 0.2.0
---

# ago:validate-docs-integrity

Validate all cross-references and consistency within `.workflow/`.

## When to Use

Periodically, after major changes, or when suspicious inconsistencies are noticed. DOC role scope is limited to `.workflow/docs/` — repo-level docs (README, etc.) are out of scope.

## Input

No parameters required. Scans the entire `.workflow/` directory.

## Checks

### 1. Wikilink Validation
- Find all `[[...]]` patterns in `.workflow/` files
- Wikilinks must use full slug format: `[[T001-DEV-feature/task.md]]`
- Verify each target file exists
- Severity: **Error** if target doesn't exist

### 2. Task Reference Validation
- All task IDs mentioned in any `.workflow/` file must have a corresponding directory
- Pattern: `T{NNN}` should match `.workflow/epics/*/tasks/T{NNN}-*/`
- Severity: **Error** if directory doesn't exist

### 3. DR Reference Validation
- All DR IDs in task frontmatter (`related_decisions`) must exist in `.workflow/decisions/`
- Severity: **Error** if file doesn't exist

### 4. Status Consistency
- For each task in `.workflow/registry.md`, compare status with actual `task.md` frontmatter
- They must match
- Severity: **Error** if mismatch

### 5. Orphan Detection
- Files in `artifacts/` directories not linked from any task.md
- DR files not referenced by any task
- Severity: **Warning**

### 6. Frontmatter Validation
- Entity docs (config, epic, task, decision, project docs, registry) MUST have YAML frontmatter
- Log files are exempt
- Required fields per type:
  - Task: id, role, title, epic, status, created, updated, priority
  - DR: id, role, epic, task, status, date
  - Epic: id, title, status (at minimum)
  - Config: project, task_counter
  - Registry: last_updated
- Severity: **Error** for missing required fields, **Warning** for missing optional fields

### 7. Counter Validation
- `task_counter` in `.workflow/config.md` must be >= the highest task number found
- Severity: **Error** if counter is lower

## Instructions

1. Run all 7 checks in order
2. Collect results into a report

## Output

Generate a report:

```markdown
# Documentation Integrity Report

**Date:** {YYYY-MM-DD}
**Total entities checked:** {count}
**Errors:** {count}
**Warnings:** {count}

## Errors

| # | Check | File | Issue |
|---|-------|------|-------|
| 1 | Wikilink | .workflow/registry.md | [[T001-DEV-foo/task.md]] target not found |

## Warnings

| # | Check | File | Issue |
|---|-------|------|-------|
| 1 | Orphan | .workflow/decisions/ARCH-E01-T003-foo.md | Not referenced by any task |

## Summary

{Brief interpretation of results}
```

3. Output the report to the user (do not write it to a file unless asked)

## Error Handling

- If `.workflow/` doesn't exist: STOP — project not initialized
- If a file can't be parsed: Skip it, add a warning to the report
