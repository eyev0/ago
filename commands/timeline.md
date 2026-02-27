---
description: Regenerate Mermaid Gantt timelines from current task state
argument-hint: "[E{NN}]"
---

# ago:timeline

You are executing the `ago:timeline` command. This is a thin wrapper around the `ago:generate-timeline` skill.

## Determine Scope

Check `$ARGUMENTS`:

- **If an epic ID was provided** (e.g., `$1` is `E01`): Set `epic_id` to that value. You will regenerate only that epic's timeline.
- **If no argument was provided**: You will regenerate all epic-level timelines AND the project-level timeline.

## Execute

Read and follow the complete instructions in:

```
@${CLAUDE_PLUGIN_ROOT}/skills/generate-timeline/SKILL.md
```

Pass `epic_id` if one was determined above. Otherwise, regenerate all timelines as described in the skill.

## Report

After generation, display each generated Mermaid Gantt chart to the user by printing the contents of:

- `.workflow/epics/{epic_id}/timeline.md` (for each epic that was regenerated)
- `.workflow/docs/timeline.md` (if the project-level timeline was regenerated)

Confirm which timeline files were created or updated.
