---
name: generate-timeline
description: Generate Mermaid Gantt charts from task frontmatter. Produces project-level and epic-level timelines.
---

# Generate Timeline

Create/update Mermaid Gantt chart files.

## Steps

### Epic-Level Timeline
1. Read all task.md files in the epic
2. For each task, extract: id, title, role, status, depends_on, created, duration (estimate from dates)
3. Map status to Mermaid tags (see conventions/timeline.md)
4. Generate Mermaid Gantt block with proper `after` dependencies
5. Write to `.workflow/epics/{epic-id}/timeline.md`

### Project-Level Timeline
1. Read all epic.md files
2. For each epic, determine: start date (earliest task), end date (latest task), status
3. Generate Mermaid Gantt with epics as sections and milestones
4. Write to `.workflow/docs/timeline.md`

## Output Format
See conventions/timeline.md for complete Mermaid syntax.
