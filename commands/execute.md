---
description: Launch agents for planned tasks
---

# ago:execute

> TODO: Full implementation pending

## What This Command Does
1. Reads planned (non-blocked) tasks from .workflow/
2. Launches role agents for each task
3. Monitors progress and collects reports
4. Reports back when agents complete

## Usage
```
/ago:execute               — Execute all planned tasks
/ago:execute T001          — Execute specific task
/ago:execute E01           — Execute all tasks in epic
```
