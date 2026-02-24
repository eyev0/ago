---
name: validate-docs-integrity
description: Check documentation integrity — links, references, cross-document consistency. Use periodically or after major changes.
---

# Validate Documentation Integrity

Check that all cross-references and links in .workflow/ are valid and consistent.

## Checks

1. **Wikilink validation:** All `[[...]]` links in docs resolve to existing files
2. **Task references:** All task IDs mentioned in docs/DRs exist as task directories
3. **DR references:** All DR IDs in task frontmatter exist in decisions/
4. **Status consistency:** Registry status matches actual task.md status
5. **Orphan detection:** Artifacts not linked from any task
6. **Owner consistency:** Document owner in frontmatter matches conventions/roles.md
7. **Counter check:** task_counter in config.md >= highest existing task number

## Output

Generate a report listing:
- Total entities checked
- Issues found (with severity: error/warning)
- Suggested fixes

## Severity Levels
- **Error:** Broken link, missing file, status mismatch
- **Warning:** Orphaned artifact, missing optional field
