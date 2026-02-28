## {HH:MM} — {TASK_ID}

**Input:** {What the agent received as task/instruction}

**Actions:**
- {Action 1}
- {Action 2}
- {Action 3}

**Output:** {What was produced — files created, reports written, decisions proposed}

**Decisions made:** {Any local decisions made during execution, or "None"}

**Status:** {New task status: backlog | planned | in_progress | review | blocked}

> Note: Agents cannot set `done` — only MASTER transitions tasks to `done` after validation.
