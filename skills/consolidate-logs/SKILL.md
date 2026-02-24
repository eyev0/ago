---
name: consolidate-logs
description: Read agent raw logs, extract decisions into DRs, update project docs. Used by CONS or MASTER after task completion.
---

# Consolidate Logs

Read raw agent logs and create Decision Records for any decisions found.

## Steps

1. Read raw logs from `.workflow/log/{ROLE}/` for the specified date/task
2. Identify entries with non-empty "Decisions made" sections
3. For each decision found:
   a. Determine if it warrants a formal DR (significant, affects other tasks/components)
   b. If yes, invoke `ago:create-decision-record` skill
   c. If no, note it in the master log as "minor decision, no DR needed"
4. Check for conflicts between decisions from different roles
5. Flag any contradictions for MASTER review
6. Update relevant project docs (docs/*.md) with new information
7. Log consolidation results in master log
