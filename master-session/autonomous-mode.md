# Autonomous Mode

> TODO: Not yet implemented. This is a stub for future iteration.

## Planned Behavior

In autonomous mode, the master session:

1. Reads backlog from registry.md
2. Picks next unblocked task by priority
3. Launches agents without user approval
4. Consolidates results autonomously
5. Only escalates to user on: conflicts, blockers, major decisions

## Key Differences from Collaborative

| Aspect | Collaborative | Autonomous |
|--------|--------------|------------|
| Task formulation | User + Master | Master reads existing tasks |
| Decomposition approval | Required | Skipped |
| Agent launch | After user OK | Automatic |
| Review | User + Master | Master auto-validates |
| Escalation | Always | Only on conflicts |

## Implementation Notes

- Needs robust validation (CONS must run after every task)
- Needs guardrails: max tasks per session, cost limits, scope limits
- May require different logging level (more detailed for auditability)
