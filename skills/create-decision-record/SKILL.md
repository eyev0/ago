---
name: create-decision-record
description: Create a formal Decision Record from agent log findings. Used by CONS or MASTER during consolidation.
---

# Create Decision Record

Create a DR file in `.workflow/decisions/`.

## Steps

1. Determine naming: `{ROLE}-{EPIC}-{TASK}-{description}.md`
2. Create file from template with filled frontmatter
3. Fill Context, Options, Decision, Consequences sections
4. Link DR in the originating task's `related_decisions` field
5. Update registry.md with new DR entry
6. Log creation in master log
