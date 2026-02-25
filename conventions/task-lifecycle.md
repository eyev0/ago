# Task Lifecycle

## Statuses

```
backlog -> planned -> in_progress -> review -> done
                   \-> blocked (can return to planned or in_progress)
```

| Status | Meaning |
|--------|---------|
| `backlog` | Identified but not scheduled |
| `planned` | Scheduled, dependencies clear, ready to start |
| `in_progress` | Actively being worked on |
| `review` | Work complete, awaiting validation |
| `done` | Validated and accepted |
| `blocked` | Cannot proceed, dependency or issue |

## Transitions

| From | To | Who | When |
|------|-----|-----|------|
| backlog | planned | MASTER, PROJ | Task is decomposed, dependencies set |
| planned | in_progress | Agent (assignee) | Agent starts work |
| in_progress | review | Agent (assignee) | Work complete |
| in_progress | blocked | Agent (assignee) | Dependency discovered |
| review | done | MASTER | Validation passed |
| review | in_progress | MASTER | Revision needed |
| blocked | planned | MASTER, PROJ | Blocker resolved |
| blocked | in_progress | MASTER, PROJ | Blocker resolved, work can resume immediately |

## Rules

1. Every status change MUST be logged in the agent's raw log
2. `depends_on` tasks must be `done` before a task can move to `in_progress`
3. Only MASTER can move a task to `done` (validation gate). Only MASTER can transition review → done.
4. A task in `review` must have all artifacts present
5. `blocked` tasks must reference the blocker in task.md

## Task Creation Rules

1. MASTER creates tasks during DECOMPOSE phase
2. Every task has exactly one `role` (assignee)
3. Task ID is globally unique (next increment from config.md counter)
4. Task MUST have: description, acceptance criteria, priority
5. Task SHOULD have: depends_on, blocks, estimated duration
