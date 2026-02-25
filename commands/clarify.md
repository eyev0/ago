---
description: Clarify requirements and decompose into tasks with role assignments
---

# ago:clarify

> TODO: Full implementation pending

## What This Command Does
1. Takes a task description or feature request from user
2. Clarifies requirements (scope, motivation, acceptance criteria)
3. Identifies which roles are needed
4. Decomposes into subtasks with role assignments
5. After user approval (APPROVE step), creates task.md files via `ago:create-task`

Does NOT launch agents — use `ago:execute` for that.

## Usage
```
ago:clarify Add VAD support to STT core
ago:clarify               — Interactive mode, asks questions
```
