---
name: create-task
description: Create a new task with proper frontmatter and directory structure. Use when decomposing work into subtasks.
---

# Create Task

Create a new task directory and task.md file.

## Steps

1. Read `.workflow/config.md` to get the current `task_counter`
2. Increment counter by 1
3. Update `task_counter` in config.md
4. Create directory: `.workflow/epics/{epic-id}/tasks/T{NNN}-{ROLE}-{short-name}/`
5. Create `task.md` from template with filled frontmatter
6. Create empty `artifacts/` directory inside
7. Update `.workflow/registry.md` with new task entry
8. Log the creation in master log

## Required Information
- Epic ID (which epic this belongs to)
- Role (who will execute)
- Title and description
- Priority
- Dependencies (depends_on, blocks)
- Acceptance criteria
