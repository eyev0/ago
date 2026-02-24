---
description: Collect agent results, consolidate logs, create DRs, review with user
---

# /review

> TODO: Full implementation pending

## What This Command Does
1. Reads recent agent logs
2. Invokes `consolidate-logs` skill
3. Presents findings and any conflicts
4. Creates DRs for significant decisions
5. Updates project docs

## Usage
```
/review              — Review all recent agent work
/review T003         — Review specific task results
```
