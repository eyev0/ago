# Quality Gates

## Concept

During consolidation (step 8 of the session lifecycle), decisions and implementations are evaluated for quality, hallucination risk, and adherence to project context. Senior roles review junior roles' work.

## Review Hierarchy

| Senior (Reviewer) | Junior (Reviewed) | What is reviewed |
|---|---|---|
| ARCH (CTO) | DEV | Architecture adherence, code quality, tech decisions |
| QAL | QAD | Test quality, coverage, test design |
| PM | MKT | Product alignment, messaging accuracy |
| SEC | DEV | Security compliance, vulnerability patterns |
| ARCH | CICD | Infrastructure decisions, deployment safety |
| PM + ARCH | DEV (frontend) | UX decisions, design alignment |

## Quality Tiers

Decisions and artifacts are ranked by confidence:

| Tier | Label | Meaning | Action |
|------|-------|---------|--------|
| T1 | **Verified** | Grounded in code/docs, no hallucination risk | Accept |
| T2 | **Probable** | Reasonable inference, minor assumptions | Review by senior |
| T3 | **Speculative** | Assumptions made, needs validation | Must be validated before acceptance |
| T4 | **Ungrounded** | No evidence in codebase/docs, likely hallucination | Reject, redo |

## How It Works

1. Agent completes work and logs it
2. During CONSOLIDATE, CONS (or MASTER) reads the agent's log
3. Each decision/artifact is assigned a quality tier based on:
   - Does it reference existing code/docs? (grounded)
   - Are assumptions stated explicitly?
   - Does it contradict known facts?
4. T3/T4 items are flagged for senior role review
5. Senior role validates or rejects
6. Only T1/T2 items become accepted DRs

## Anti-Hallucination Checks

- **Code reference check:** Does the decision reference real files/functions?
- **Consistency check:** Does it align with existing DRs and project docs?
- **Scope check:** Is the agent operating within their role boundaries?
- **Context check:** Does the agent's output reflect actual project state?

> TODO: Implement quality gate evaluation as a skill (`ago:evaluate-quality-gate`) in Iteration 2.
