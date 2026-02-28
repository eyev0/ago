---
name: ago:evaluate-quality-gate
description: This skill should be used when an agent needs to "evaluate quality", "check for hallucinations", "assign quality tiers", or "run quality gate". Evaluates agent output for quality and hallucination risk, assigns T1-T4 tiers, and triggers senior review during consolidation.
version: 0.2.0
---

# ago:evaluate-quality-gate

Assess agent decisions and artifacts for quality, assign tiers, trigger reviews.

## When to Use

During the CONSOLIDATE step, for each agent output. Called by MASTER or CONS. References `conventions/quality-gates.md` as the canonical source for tier definitions and review hierarchy.

## Input

| Parameter | Required | Description |
|-----------|----------|-------------|
| task_id | Yes | Short task ID (e.g., `T001`) |
| role | Yes | Role that produced the output (e.g., `dev`) |

## Instructions

1. **Read the agent's work:** Find log entries for {task_id} in `.workflow/log/{role}/`
2. **Read artifacts:** Check `.workflow/epics/*/tasks/T{NNN}-*/artifacts/` for deliverables
3. **For each decision or artifact, run these checks:**

### Anti-Hallucination Checks

| Check | Question | Pass | Fail |
|-------|----------|------|------|
| Code reference | Does it reference real files/functions that exist? | +T1 evidence | +T3/T4 evidence |
| Consistency | Does it align with existing DRs and project docs? | +T1 evidence | +T3 evidence |
| Scope | Is the agent operating within role boundaries? | neutral | +T4 evidence |
| Context | Does output reflect actual project state? | +T1 evidence | +T4 evidence |

4. **Assign tier based on evidence:**
   - All checks pass, grounded in code/docs → **T1 (Verified)**
   - Most checks pass, minor assumptions stated → **T2 (Probable)**
   - Some checks fail, assumptions not validated → **T3 (Speculative)**
   - Multiple checks fail, no evidence in codebase → **T4 (Ungrounded)**

5. **Determine reviewer (for T3/T4):** Using the review hierarchy from `conventions/quality-gates.md`:
   - DEV output → reviewed by ARCH
   - QAD output → reviewed by QAL
   - MKT output → reviewed by PM
   - DEV (security) → reviewed by SEC
   - CICD output → reviewed by ARCH
   - DEV (frontend) → reviewed by PM + ARCH

6. **Log the evaluation** in `.workflow/log/master/{date}.md`:

```markdown
## {HH:MM} — Quality Gate: {task_id}

**Role:** {role}
**Items evaluated:** {count}

| Item | Tier | Evidence | Reviewer | Recommendation |
|------|------|----------|----------|----------------|
| {description} | T{n} | {summary} | {reviewer or "—"} | {accept/review/reject/redo} |

**Overall:** {T1/T2 → ready for acceptance | T3/T4 → requires senior review}
```

7. **Actions by tier:**
   - T1: Mark as ready for DR acceptance
   - T2: Mark as ready, flag for optional senior review
   - T3: Flag for mandatory senior review, do NOT accept until reviewed
   - T4: Reject. Flag for redo by the original agent.

## Validation

- Every decision/artifact from the task was evaluated
- T3/T4 items have a designated reviewer
- Evaluation was logged in master log

## Error Handling

- If no log entries found for task: Report "No agent logs found for {task_id}" — cannot evaluate
- If artifacts directory is empty: Evaluate based on log entries only
- If role not in review hierarchy: Default reviewer is MASTER

## References

- `conventions/quality-gates.md` — canonical source for tier definitions and review hierarchy
