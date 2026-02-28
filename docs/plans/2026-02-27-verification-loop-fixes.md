# Verification Loop Fixes — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix all issues identified in the Phase 3 design/implementation review before execution: macOS portability (grep -oP), string injection safety, concrete superpowers detection, thin integration details, missing agent description update, and editorial fixes.

**Architecture:** This plan amends the original implementation plan (`docs/plans/2026-02-27-verification-loop-impl.md`). Apply these fixes DURING execution of the original plan — each task here provides corrected content for specific parts. Tasks 1-2 replace shell scripts. Tasks 3-5 replace command/agent markdown. Tasks 6-7 are editorial fixes and test infrastructure.

**Tech Stack:** Bash (corrected hook scripts), Markdown (command/agent/convention files)

---

### Task 1: Replace verify-and-log.sh with portable version

**Files:**
- Create: `hooks/scripts/verify-and-log.sh` (replaces original impl Task 1 Step 2)

**Context:** The original script uses `grep -oP` (Perl regex) which is unavailable on macOS. All instances replaced with POSIX-compatible `grep -oE` and `sed`.

**Changes from original:**
- `grep -oP 'Task:\s*T\d+'` → `grep -oE 'Task:[[:space:]]*T[0-9]+'`
- `grep -oP 'T\d+'` → `grep -oE 'T[0-9]+'`
- `grep -oP 'status:\s*\K\S+'` → `sed -n 's/^status:[[:space:]]*\([^[:space:]]*\).*/\1/p'`
- `grep -oP 'title:\s*\K.*'` → `sed -n 's/^title:[[:space:]]*//p'`
- `grep -qiP` → `grep -qiE`

**Step 1: Create the corrected script**

Write `hooks/scripts/verify-and-log.sh`:

```bash
#!/bin/bash
set -euo pipefail

# ago: Verification Hook — SubagentStop
# Runs 3 sequential stages:
#   1. Artifact check — verify required outputs exist
#   2. Criteria check — parse acceptance criteria, check transcript
#   3. Write verification log — mandatory log with evaluation + retry prompt

input=$(cat)

# Extract fields from stdin JSON
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# If no transcript, approve (not an ago: workflow context)
if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Extract task ID from transcript (POSIX-compatible: no grep -P)
task_id=$(grep -oE 'Task:[[:space:]]*T[0-9]+' "$transcript_path" 2>/dev/null | head -1 | grep -oE 'T[0-9]+' || true)

# If no task ID found, this isn't an ago: workflow agent — approve
if [ -z "$task_id" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Find the task directory
task_dir=$(find "$cwd/.workflow/epics" -type d -name "${task_id}-*" 2>/dev/null | head -1)

if [ -z "$task_dir" ] || [ ! -f "$task_dir/task.md" ]; then
  echo '{"decision": "approve", "systemMessage": "ago: verify-and-log: task directory not found for '"$task_id"'"}'
  exit 0
fi

task_file="$task_dir/task.md"

# Extract role from task directory name (T001-DEV-name -> DEV -> dev)
role=$(basename "$task_dir" | sed 's/^T[0-9]*-\([A-Z]*\)-.*/\1/' | tr '[:upper:]' '[:lower:]')

# --- Stage 1: Artifact Check ---

artifacts_ok=true
artifact_results=""

# Check: log entry exists for this role
log_dir="$cwd/.workflow/log/$role"
if [ -d "$log_dir" ] && ls "$log_dir"/*.md >/dev/null 2>&1; then
  artifact_results="${artifact_results}\n- [x] Log entry exists in .workflow/log/$role/"
else
  artifact_results="${artifact_results}\n- [ ] Log entry missing in .workflow/log/$role/"
  artifacts_ok=false
fi

# Check: task status was updated (POSIX-compatible: sed instead of grep -P)
task_status=$(sed -n 's/^status:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$task_file" 2>/dev/null | head -1)
[ -z "$task_status" ] && task_status="unknown"

if [ "$task_status" = "review" ] || [ "$task_status" = "done" ]; then
  artifact_results="${artifact_results}\n- [x] Task status updated to $task_status"
else
  artifact_results="${artifact_results}\n- [ ] Task status is '$task_status' (expected 'review')"
  artifacts_ok=false
fi

# --- Stage 2: Criteria Check ---

# Extract acceptance_criteria from YAML frontmatter
criteria=$(awk '/^---$/{n++; next} n==1 && /acceptance_criteria:/{found=1; next} found && /^  - /{print; next} found && !/^  -/{found=0}' "$task_file")

criteria_total=0
criteria_met=0
criteria_results=""

if [ -n "$criteria" ]; then
  while IFS= read -r criterion; do
    criterion_text=$(echo "$criterion" | sed 's/^  - //')
    criteria_total=$((criteria_total + 1))
    # Search transcript for evidence (fuzzy: first 3 significant words)
    search_words=$(echo "$criterion_text" | tr -cs '[:alnum:]' ' ' | awk '{for(i=1;i<=3&&i<=NF;i++) printf "%s.*", $i}')
    if grep -qiE "$search_words" "$transcript_path" 2>/dev/null; then
      criteria_results="${criteria_results}\n- [x] $criterion_text"
      criteria_met=$((criteria_met + 1))
    else
      criteria_results="${criteria_results}\n- [ ] $criterion_text"
    fi
  done <<< "$criteria"
fi

# Calculate completeness
if [ "$criteria_total" -gt 0 ]; then
  completeness=$(( (criteria_met * 100) / criteria_total ))
else
  completeness=100
fi

# --- Stage 3: Write Verification Log ---

verify_count=$(find "$log_dir" -name "verify-${task_id}-*.md" 2>/dev/null | wc -l | tr -d ' ')
attempt=$((verify_count + 1))
max_retries=3

mkdir -p "$log_dir"

# Extract task title (POSIX-compatible: sed instead of grep -P)
task_title=$(sed -n 's/^title:[[:space:]]*//p' "$task_file" 2>/dev/null | head -1)
[ -z "$task_title" ] && task_title="unknown"

# Determine decision
if [ "$completeness" -ge 80 ] && [ "$artifacts_ok" = true ]; then
  decision="APPROVE"
elif [ "$attempt" -ge "$max_retries" ]; then
  decision="APPROVE (max retries reached)"
else
  decision="BLOCK"
fi

# Build retry prompt (only if blocking)
retry_prompt=""
if [ "$decision" = "BLOCK" ]; then
  retry_prompt="\n### Retry Prompt\nAddress these gaps before completing:\n"
  gap_num=1
  if [ "$artifacts_ok" = false ]; then
    retry_prompt="${retry_prompt}${gap_num}. Fix artifact issues listed above\n"
    gap_num=$((gap_num + 1))
  fi
  if [ -n "$criteria" ]; then
    while IFS= read -r criterion; do
      criterion_text=$(echo "$criterion" | sed 's/^  - //')
      search_words=$(echo "$criterion_text" | tr -cs '[:alnum:]' ' ' | awk '{for(i=1;i<=3&&i<=NF;i++) printf "%s.*", $i}')
      if ! grep -qiE "$search_words" "$transcript_path" 2>/dev/null; then
        retry_prompt="${retry_prompt}${gap_num}. $criterion_text\n"
        gap_num=$((gap_num + 1))
      fi
    done <<< "$criteria"
  fi
fi

# Write the verification log
cat > "$log_dir/verify-${task_id}-${attempt}.md" << VERIFY_EOF
## Verification Report — $task_id — Attempt $attempt

**Timestamp:** $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Task:** $task_id — $task_title
**Role:** $(echo "$role" | tr '[:lower:]' '[:upper:]')
**Attempt:** $attempt of $max_retries

### Artifact Check
$(echo -e "$artifact_results")

### Acceptance Criteria Evaluation
$(echo -e "$criteria_results")

### Completeness: ${completeness}%

### Decision: $decision
$(echo -e "$retry_prompt")
VERIFY_EOF

# --- Return decision to Claude Code ---

if [ "$decision" = "BLOCK" ]; then
  system_msg="ago: Verification failed for $task_id (attempt $attempt/$max_retries, ${completeness}% complete). Address gaps listed in .workflow/log/$role/verify-${task_id}-${attempt}.md before completing."
  echo "{\"decision\": \"block\", \"reason\": \"Verification: ${completeness}% complete (need 80%)\", \"systemMessage\": \"$system_msg\"}" >&2
  exit 2
else
  echo "{\"decision\": \"approve\", \"systemMessage\": \"ago: Verification passed for $task_id (${completeness}% complete, attempt $attempt). Log: .workflow/log/$role/verify-${task_id}-${attempt}.md\"}"
  exit 0
fi
```

**Step 2: Make executable**

Run: `chmod +x hooks/scripts/verify-and-log.sh`

**Step 3: Validate portability**

Run: `grep -n 'grep.*-[^-]*P' hooks/scripts/verify-and-log.sh`

Expected: no output (zero matches — no Perl regex flags remain)

---

### Task 2: Replace evaluate-and-log.sh with portable + injection-safe version

**Files:**
- Create: `hooks/scripts/evaluate-and-log.sh` (replaces original impl Task 1 Step 3)

**Context:** Two fixes: (1) same grep -oP portability fix as Task 1, and (2) replace bash string substitution (`${var//__PLACEHOLDER__/$content}`) with temp-file approach using `printf '%s'`. The original approach was vulnerable to double-substitution if transcript/criteria contained placeholder strings like `__TASK_ID__`.

**Step 1: Create the corrected script**

Write `hooks/scripts/evaluate-and-log.sh`:

```bash
#!/bin/bash
set -euo pipefail

# ago: LLM Evaluation Hook — SubagentStop
# Calls claude -p (Haiku) to independently evaluate subagent work
# Writes detailed evaluation log to .workflow/log/{role}/eval-{task_id}-{attempt}.md

input=$(cat)

# Extract fields from stdin JSON
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# If no transcript, approve (not an ago: workflow context)
if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Extract task ID (POSIX-compatible: no grep -P)
task_id=$(grep -oE 'Task:[[:space:]]*T[0-9]+' "$transcript_path" 2>/dev/null | head -1 | grep -oE 'T[0-9]+' || true)

if [ -z "$task_id" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Find the task directory
task_dir=$(find "$cwd/.workflow/epics" -type d -name "${task_id}-*" 2>/dev/null | head -1)

if [ -z "$task_dir" ] || [ ! -f "$task_dir/task.md" ]; then
  echo '{"decision": "approve", "systemMessage": "ago: evaluate-and-log: task directory not found for '"$task_id"'"}'
  exit 0
fi

task_file="$task_dir/task.md"

# Extract role (T001-DEV-name -> dev)
role=$(basename "$task_dir" | sed 's/^T[0-9]*-\([A-Z]*\)-.*/\1/' | tr '[:upper:]' '[:lower:]')

# Extract task title (POSIX-compatible: sed instead of grep -P)
task_title=$(sed -n 's/^title:[[:space:]]*//p' "$task_file" 2>/dev/null | head -1)
[ -z "$task_title" ] && task_title="unknown"

# Read acceptance criteria from YAML frontmatter
criteria=$(awk '/^---$/{n++; next} n==1 && /acceptance_criteria:/{found=1; next} found && /^  - /{print; next} found && !/^  -/{found=0}' "$task_file")

if [ -z "$criteria" ]; then
  echo '{"decision": "approve", "systemMessage": "ago: evaluate-and-log: no acceptance criteria for '"$task_id"'"}'
  exit 0
fi

# Read transcript (truncate to last 4000 chars for prompt limits)
transcript_tail=$(tail -c 4000 "$transcript_path")

# Attempt tracking
log_dir="$cwd/.workflow/log/$role"
mkdir -p "$log_dir"
eval_count=$(find "$log_dir" -name "eval-${task_id}-*.md" 2>/dev/null | wc -l | tr -d ' ')
attempt=$((eval_count + 1))
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
role_upper=$(echo "$role" | tr '[:lower:]' '[:upper:]')

# --- Build LLM prompt safely using temp file ---
# Uses printf '%s' for user-controlled content (criteria, transcript)
# to prevent string substitution injection.

prompt_file=$(mktemp)
trap 'rm -f "$prompt_file"' EXIT

printf 'You are a verification evaluator for the ago: workflow system.\n\n' > "$prompt_file"
printf 'A subagent just completed work on task %s: %s (role: %s).\n\n' \
  "$task_id" "$task_title" "$role" >> "$prompt_file"
printf '## Acceptance Criteria\n' >> "$prompt_file"
printf '%s\n\n' "$criteria" >> "$prompt_file"
printf '## Subagent Transcript (last 4000 chars)\n' >> "$prompt_file"
printf '%s\n\n' "$transcript_tail" >> "$prompt_file"

# Static instructions — uses heredoc with simple variable expansion
# (task_id, attempt, timestamp are controlled values from our own extraction)
cat >> "$prompt_file" <<INSTRUCTIONS_EOF
## Instructions

Evaluate the subagent's work against each acceptance criterion. Output EXACTLY this markdown format:

## LLM Evaluation — ${task_id} — Attempt ${attempt}

**Timestamp:** ${timestamp}
**Task:** ${task_id} — ${task_title}
**Role:** ${role_upper}
**Evaluator:** LLM (claude -p haiku)

### Criteria Assessment
| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
(one row per criterion: Status = MET / GAP / PARTIAL, Evidence = brief quote or observation from transcript)

### Quality Observations
- (what was done well)
- (what is questionable or concerning)

### Gaps to Address
(numbered list of specific unmet criteria, or "None — all criteria met")

### Completeness: N%
### Decision: APPROVE or BLOCK

Scoring rules:
- MET = clear evidence in transcript that criterion is satisfied
- PARTIAL = some work done but incomplete
- GAP = no evidence found in transcript
- Completeness = percentage of criteria fully MET
- Completeness >= 80% = APPROVE, otherwise = BLOCK
INSTRUCTIONS_EOF

# Call claude -p with haiku model
eval_result=$(claude -p --model haiku --output-format text < "$prompt_file" 2>/dev/null || true)

# If claude call failed, approve (don't block on LLM failure)
if [ -z "$eval_result" ]; then
  echo '{"decision": "approve", "systemMessage": "ago: evaluate-and-log: claude -p failed, approving by default"}'
  exit 0
fi

# Write the evaluation log
echo "$eval_result" > "$log_dir/eval-${task_id}-${attempt}.md"

# Parse decision from LLM output (POSIX-compatible: no grep -P)
if echo "$eval_result" | grep -qi 'Decision:.*BLOCK'; then
  completeness=$(echo "$eval_result" | grep -oE 'Completeness:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' || echo "0")
  system_msg="ago: LLM evaluation blocked ${task_id} (attempt ${attempt}, ${completeness}% complete). Details: .workflow/log/${role}/eval-${task_id}-${attempt}.md"
  echo "{\"decision\": \"block\", \"reason\": \"LLM evaluation: ${completeness}% complete (need 80%)\", \"systemMessage\": \"$system_msg\"}" >&2
  exit 2
else
  echo "{\"decision\": \"approve\", \"systemMessage\": \"ago: LLM evaluation passed for ${task_id}. Log: .workflow/log/${role}/eval-${task_id}-${attempt}.md\"}"
  exit 0
fi
```

**Step 2: Make executable**

Run: `chmod +x hooks/scripts/evaluate-and-log.sh`

**Step 3: Validate portability**

Run: `grep -n 'grep.*-[^-]*P' hooks/scripts/evaluate-and-log.sh`

Expected: no output (zero Perl regex flags)

**Step 4: Validate no string substitution patterns remain**

Run: `grep -n '__[A-Z_]*__' hooks/scripts/evaluate-and-log.sh`

Expected: no output (no placeholder patterns — all replaced by printf/heredoc approach)

**Step 5: Commit Tasks 1-2 together**

```bash
git add hooks/scripts/verify-and-log.sh hooks/scripts/evaluate-and-log.sh
git commit -m "feat: add SubagentStop verification hooks (portable, injection-safe)"
```

---

### Task 3: Add hook test infrastructure

**Files:**
- Create: `hooks/tests/test-input-ago-task.json`
- Create: `hooks/tests/test-input-non-ago.json`
- Create: `hooks/tests/run-hook-tests.sh`

**Context:** The original impl plan has no test step. Hook scripts should be testable before deployment. These fixtures let you validate both the happy path (ago: task found) and the bypass path (non-ago context).

**Step 1: Create test input for ago: workflow context**

Write `hooks/tests/test-input-ago-task.json`:

```json
{
  "session_id": "test-session-001",
  "transcript_path": "/tmp/ago-test-transcript.txt",
  "cwd": "/tmp/ago-test-project",
  "permission_mode": "allow",
  "hook_event_name": "SubagentStop",
  "reason": "Task completed"
}
```

**Step 2: Create test input for non-ago context**

Write `hooks/tests/test-input-non-ago.json`:

```json
{
  "session_id": "test-session-002",
  "transcript_path": "/tmp/nonexistent-transcript.txt",
  "cwd": "/tmp/some-project",
  "permission_mode": "allow",
  "hook_event_name": "SubagentStop",
  "reason": "Done"
}
```

**Step 3: Create the test runner**

Write `hooks/tests/run-hook-tests.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Hook test runner — validates verify-and-log.sh and evaluate-and-log.sh
# Run from repo root: bash hooks/tests/run-hook-tests.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")/scripts"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1 — $2"; FAIL=$((FAIL + 1)); }

echo "=== Hook Tests ==="

# --- Test 1: Non-ago context should approve ---
echo ""
echo "Test 1: verify-and-log.sh — non-ago context (no transcript)"
result=$(cat "$SCRIPT_DIR/test-input-non-ago.json" | bash "$HOOKS_DIR/verify-and-log.sh" 2>/dev/null)
if echo "$result" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Non-ago context approved"
else
  fail "Non-ago context" "Expected approve, got: $result"
fi

# --- Test 2: Non-ago context for evaluate hook ---
echo ""
echo "Test 2: evaluate-and-log.sh — non-ago context (no transcript)"
result=$(cat "$SCRIPT_DIR/test-input-non-ago.json" | bash "$HOOKS_DIR/evaluate-and-log.sh" 2>/dev/null)
if echo "$result" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Non-ago context approved (evaluate)"
else
  fail "Non-ago context (evaluate)" "Expected approve, got: $result"
fi

# --- Test 3: Portability check — no grep -P in scripts ---
echo ""
echo "Test 3: Portability — no grep -P flags"
if grep -rn 'grep.*-[^-]*P' "$HOOKS_DIR"/*.sh >/dev/null 2>&1; then
  fail "Portability" "Found grep -P in hook scripts"
else
  pass "No grep -P flags found"
fi

# --- Test 4: Scripts are executable ---
echo ""
echo "Test 4: Scripts are executable"
for script in "$HOOKS_DIR"/*.sh; do
  if [ -x "$script" ]; then
    pass "$(basename "$script") is executable"
  else
    fail "$(basename "$script")" "Not executable"
  fi
done

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```

**Step 4: Make test runner executable and run**

Run: `chmod +x hooks/tests/run-hook-tests.sh && bash hooks/tests/run-hook-tests.sh`

Expected: All tests pass (4 PASS, 0 FAIL)

**Step 5: Commit**

```bash
git add hooks/tests/
git commit -m "test: add hook test infrastructure with portability and bypass checks"
```

---

### Task 4: Rewrite ago:clarify superpowers integration

**Files:**
- Modify: `commands/clarify.md` (replaces original impl Task 4)

**Context:** The original impl plan inserted ~15 lines that said "invoke `/brainstorming`" with no detail on context passing, output conversion, or error handling. This version provides full implementation instructions.

**Step 1: Insert Step 1.5 after Step 1 (Read Project Config)**

After the existing Step 1 block (ends at line ~37) and before Step 2, insert:

```markdown
## Step 1.5: Check for Superpowers Integration

Determine whether the `superpowers` plugin is available by checking if the following skills appear in your available skills list (shown in system-reminder messages at the start of this session):

- `superpowers:brainstorming`
- `superpowers:writing-plans`

Both must be present. If only one is available, treat superpowers as unavailable.

**If superpowers IS available — Enhanced Path:**

After completing Step 3 (COLLABORATE), you have clarified requirements with the user. Instead of doing your own decomposition (Steps 4-5), delegate to superpowers:

1. **Invoke the `brainstorming` skill** with the clarified requirements as input. Pass as context:
   - Project name and description (from `.workflow/config.md`)
   - Active roles list
   - Existing epics and their status
   - The full clarified requirements from Step 3
   - Any constraints, dependencies, or out-of-scope items identified during COLLABORATE

   The brainstorming skill will explore the solution space interactively with the user, considering approaches, trade-offs, and constraints. Wait for it to produce a validated design.

2. **Invoke the `writing-plans` skill** to convert the validated design into a structured task breakdown. The writing-plans skill produces bite-sized implementation tasks with steps, tests, and commits — but NOT in ago: format.

3. **Convert the writing-plans output to ago: task format.** For each task in the writing-plans output:
   - **Map to a role:** Choose the appropriate role from the Active Roles list based on the task's nature (code → DEV, architecture → ARCH, tests → QAD, docs → DOC, security → SEC)
   - **Assign a task ID:** Use the next increment from `task_counter` (same as Step 4)
   - **Set priority:** Tasks in earlier dependency waves get higher priority. First wave = `high`, subsequent waves = `medium`, independent nice-to-haves = `low`
   - **Extract acceptance criteria:** Convert the writing-plans verification steps into 2-5 checkable acceptance criteria per task
   - **Set `depends_on`:** Map the writing-plans task dependencies to ago: task IDs
   - **Set status:** All tasks start with `backlog`

4. **Skip Steps 4-5** (DECOMPOSE and Present Decomposition) — the converted output replaces these.

5. **Continue at Step 6** (APPROVE) with the converted task breakdown.

**If superpowers is NOT available — Standard Path:**

Proceed with Steps 2-5 as written below. No changes to existing behavior.

**Error handling:** If either skill invocation fails mid-execution (skill not found, timeout, or error), fall back to the standard path (Steps 4-5). Inform the user: "Superpowers skill failed to load. Falling back to standard decomposition."
```

**Step 2: Commit**

```bash
git add commands/clarify.md
git commit -m "feat: add concrete superpowers integration to ago:clarify (brainstorming + writing-plans)"
```

---

### Task 5: Rewrite ago:execute superpowers integration

**Files:**
- Modify: `commands/execute.md` (replaces original impl Task 5)

**Context:** The original impl plan inserted ~12 lines saying "use the subagent-driven-development pattern" with no detail on how wave-based execution adapts. This version provides full implementation instructions.

**Step 1: Insert Step 2.5 after Step 2 (Read Project Context)**

After the existing Step 2 block and before Step 3, insert:

```markdown
## Step 2.5: Check for Superpowers Integration

Determine whether the `superpowers` plugin is available by checking if the following skill appears in your available skills list (shown in system-reminder messages):

- `superpowers:subagent-driven-development`

**If superpowers IS available — Enhanced Execution:**

In Step 7 (Execute each wave), replace the default parallel-within-wave execution with the subagent-driven-development pattern:

1. **Within each wave, execute tasks sequentially** (not in parallel):
   - Launch a fresh subagent for the first task in the wave
   - Wait for the subagent to complete
   - Perform a code review checkpoint (see below)
   - If the checkpoint passes, launch the next task's subagent
   - Continue until all tasks in the wave are complete

2. **Code review checkpoint after each task:**
   - Read the agent's raw log entry (`.workflow/log/{role}/{date}.md`)
   - Check for verification logs from SubagentStop hooks: `.workflow/log/{role}/verify-{task_id}-*.md` and `eval-{task_id}-*.md`
   - If the verification hook blocked the agent and it retried, review whether the retry addressed the gaps
   - Summarize the result to the user: what was done, what the verification found, and whether to proceed

3. **Between waves** remains sequential (same as standard path).

4. **Inform the user about the trade-off** at the start of execution:

   > Using superpowers mode: tasks within each wave will execute sequentially with code review checkpoints between tasks. This provides tighter feedback loops at the cost of longer total execution time.

**If superpowers is NOT available — Standard Execution:**

Proceed with Step 7 as written (parallel launch within waves, sequential between waves). No changes to existing behavior.

**Error handling:** If the subagent-driven-development skill fails to load, fall back to standard parallel execution and notify the user: "Superpowers skill unavailable. Using standard parallel execution."

**Note:** SubagentStop verification hooks fire regardless of execution path (superpowers or standard). The hooks are orthogonal to the execution strategy.
```

**Step 2: Commit**

```bash
git add commands/execute.md
git commit -m "feat: add concrete superpowers integration to ago:execute (subagent-driven-development)"
```

---

### Task 6: Enhance master-session.md updates

**Files:**
- Modify: `agents/master-session.md` (amends original impl Task 6)

**Context:** The original impl plan adds a "Verification Hooks" section but misses two things: (1) updating the agent's `description` field in frontmatter to reflect verification capabilities, and (2) edge case guidance for when the two hooks disagree.

**Step 1: Update the frontmatter description**

In `agents/master-session.md`, update the `description` field:

Old:
```
description: Orchestrates the workflow — formulates tasks, delegates to agents, validates results, maintains the global log. Use as the primary entry point for any project work session.
```

New:
```
description: Orchestrates the workflow — formulates tasks, delegates to agents, validates results (including automated verification hook logs), maintains the global log. Use as the primary entry point for any project work session.
```

**Step 2: Add the Verification Hooks section (from original impl Task 6 Step 1)**

After the Available Skills table (around line 138), add the section from the original impl plan, PLUS this additional guidance at the end:

```markdown
## Verification Hooks

SubagentStop hooks automatically verify agent work when they attempt to complete:

- **Deterministic hook** (`hooks/scripts/verify-and-log.sh`) — checks artifacts exist, evaluates acceptance criteria against transcript, writes mandatory verification log to `.workflow/log/{role}/verify-{task_id}-{attempt}.md`
- **LLM evaluation hook** (`hooks/scripts/evaluate-and-log.sh`) — independent LLM evaluation via `claude -p` haiku, writes detailed evaluation log to `.workflow/log/{role}/eval-{task_id}-{attempt}.md`

Both hooks run in parallel. Block wins over approve (safety-first). Max 3 attempts per task.

**As MASTER, you should:**
- Check both verification logs after agents complete: `verify-*.md` (artifact checklist, grep-based criteria) and `eval-*.md` (per-criterion evidence, quality observations)
- If an agent was blocked and retried, review the verification log chain to understand what gaps were found and whether retries addressed them
- Factor verification completeness scores into quality gate evaluation during the CONSOLIDATE phase

**When hooks disagree:** If the deterministic hook approves but the LLM hook blocks (or vice versa), the block wins and the agent retries. During CONSOLIDATE, compare both logs to understand why they disagreed — the deterministic hook checks structural artifacts while the LLM hook evaluates semantic completeness. A mismatch often means the agent produced required files but with incomplete content.
```

**Step 3: Add superpowers note in Session Lifecycle**

In the Session Lifecycle section, after step 3 (COLLABORATE), add:

```markdown
> **Note:** If the superpowers plugin is available, the COLLABORATE and DECOMPOSE phases leverage `brainstorming` and `writing-plans` skills for richer interactive refinement. See `commands/clarify.md` Step 1.5 for details.
```

**Step 4: Commit**

```bash
git add agents/master-session.md
git commit -m "docs: enhance master-session with verification hooks, edge cases, superpowers note"
```

---

### Task 7: Fix editorial issues in both plan documents and downstream files

**Files:**
- Modify: `docs/plans/2026-02-27-verification-loop-design.md`
- Modify: `docs/plans/2026-02-27-verification-loop-impl.md`

**Context:** Minor fixes: timeout justification in design doc, AUDIT.md duplicate numbering in impl doc, hooks.json format clarification.

**Step 1: Add timeout justification to design doc**

In `docs/plans/2026-02-27-verification-loop-design.md`, in the "Key Constraints" section (around line 168), change:

Old:
```
- Max script timeout: 30s for deterministic hook, 60s for LLM evaluation hook
```

New:
```
- Max script timeout: 30s for deterministic hook (shell-only, no network), 120s for LLM evaluation hook (includes cold-start latency for `claude -p`; original 60s was insufficient)
```

**Step 2: Add hooks.json format note to design doc**

In the design doc, after the hooks.json reference in Part A (around line 16), add a note:

```markdown
> **Format note:** Plugin hooks.json uses the wrapper format: `{"hooks": {"SubagentStop": [...]}}`. This differs from the settings.json direct format where events are top-level keys. See the hook-development skill for details.
```

**Step 3: Fix AUDIT.md entry in impl doc**

In `docs/plans/2026-02-27-verification-loop-impl.md`, in Task 8 Step 4, the AUDIT.md entry has duplicate numbering. Change:

Old:
```
3. **Created** `hooks/scripts/evaluate-and-log.sh` — LLM evaluation via claude -p haiku, writes eval log
3. **Updated** `commands/clarify.md` — optional superpowers integration (brainstorming + writing-plans)
```

New:
```
3. **Created** `hooks/scripts/evaluate-and-log.sh` — LLM evaluation via claude -p haiku, writes eval log
4. **Updated** `commands/clarify.md` — optional superpowers integration (brainstorming + writing-plans)
```

And renumber the remaining entries (4→5, 5→6, 6→7, 7→8, 8→9).

**Step 4: Update impl doc timeout in hooks.json**

In the impl doc Task 1 Step 1, update the evaluate-and-log.sh timeout:

Old:
```json
"timeout": 60
```

New:
```json
"timeout": 120
```

**Step 5: Commit**

```bash
git add docs/plans/
git commit -m "docs: fix editorial issues in verification loop plans (timeouts, numbering, format notes)"
```
