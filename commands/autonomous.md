---
description: Switch to autonomous mode — master reads backlog and executes independently
---

# /autonomous

> TODO: Full implementation pending (future iteration)

## What This Command Will Do

In autonomous mode:
- Master reads backlog from registry.md
- Picks next unblocked task by priority
- Launches agents without user approval
- User reviews results after completion
- Master can escalate blockers/conflicts to user

## Differences from Collaborative Mode
- No decomposition approval step
- No per-task user confirmation
- Master makes delegation decisions autonomously
- User reviews output, not process
