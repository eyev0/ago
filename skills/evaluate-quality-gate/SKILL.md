---
name: evaluate-quality-gate
description: Evaluate agent output for hallucination risk, assign quality tiers (T1-T4), trigger senior role review for T3/T4 items. Used by CONS or MASTER during consolidation.
---

# Evaluate Quality Gate

Assess the quality and groundedness of agent decisions and artifacts during consolidation (step 8 of session lifecycle). Assigns a quality tier and triggers senior review when needed.

## Quality Tiers

| Tier | Label | Meaning | Action |
|------|-------|---------|--------|
| T1 | **Verified** | Grounded in code/docs, no hallucination risk | Accept |
| T2 | **Probable** | Reasonable inference, minor assumptions | Review by senior |
| T3 | **Speculative** | Assumptions made, needs validation | Must be validated before acceptance |
| T4 | **Ungrounded** | No evidence in codebase/docs, likely hallucination | Reject, redo |

## Steps

1. Read the agent's log entries and artifacts for the completed task
2. For each decision or artifact, run the anti-hallucination checks (see below)
3. Assign a quality tier (T1-T4) based on the check results
4. For T1/T2 items: mark as ready for acceptance (T2 gets optional senior review)
5. For T3/T4 items: flag for mandatory senior role review
6. Identify the correct senior reviewer from the review hierarchy
7. Log the quality evaluation in the master log
8. Only T1/T2 items may become accepted Decision Records

## Anti-Hallucination Checks

- **Code reference check:** Does the decision reference real files/functions that exist in the codebase?
- **Consistency check:** Does it align with existing Decision Records and project docs?
- **Scope check:** Is the agent operating within their role boundaries?
- **Context check:** Does the agent's output reflect the actual project state (not outdated or imagined state)?

## Review Hierarchy

| Senior (Reviewer) | Junior (Reviewed) | What is reviewed |
|---|---|---|
| ARCH (CTO) | DEV | Architecture adherence, code quality, tech decisions |
| QAL | QAD | Test quality, coverage, test design |
| PM | MKT | Product alignment, messaging accuracy |
| SEC | DEV | Security compliance, vulnerability patterns |
| ARCH | CICD | Infrastructure decisions, deployment safety |
| PM + ARCH | DEV (frontend) | UX decisions, design alignment |

## Output

For each evaluated item, record:
- Item description (decision or artifact name)
- Assigned tier (T1/T2/T3/T4)
- Evidence summary (what grounded or ungrounded the item)
- Required reviewer (if T3/T4)
- Recommendation (accept / review / reject / redo)
