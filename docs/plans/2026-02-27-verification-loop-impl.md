# Verification Loop + Superpowers Integration — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add SubagentStop hooks for automatic verification of agent work, and integrate superpowers skills as optional enhancements to ago:clarify and ago:execute.

**Architecture:** Two parallel SubagentStop hooks (command script + prompt) verify agent outputs against acceptance criteria. ago:clarify and ago:execute detect superpowers availability and delegate to brainstorming/writing-plans/subagent-driven-development when present.

**Tech Stack:** Bash (hook script), JSON (hooks.json), Markdown (all commands/conventions/agents)

---

### Task 1: Create hooks directory structure

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/scripts/verify-and-log.sh`

**Step 1: Create hooks.json with SubagentStop configuration**

Create `hooks/hooks.json`:

```json
{
  "description": "ago: workflow verification hooks — check agent work against acceptance criteria",
  "hooks": {
    "SubagentStop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/verify-and-log.sh",
            "timeout": 30
          },
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/evaluate-and-log.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

**Step 2: Create the verify-and-log.sh script**

Create `hooks/scripts/verify-and-log.sh`:

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

# Extract task ID from transcript (look for "Task: T" followed by digits)
task_id=$(grep -oP 'Task:\s*T\d+' "$transcript_path" 2>/dev/null | head -1 | grep -oP 'T\d+' || true)

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

# Extract role from task directory name (T001-DEV-name -> DEV)
role=$(basename "$task_dir" | sed 's/^T[0-9]*-\([A-Z]*\)-.*/\1/' | tr '[:upper:]' '[:lower:]')

# --- Stage 1: Artifact Check ---

artifacts_ok=true
artifact_results=""

# Check: log entry exists for this role
log_dir="$cwd/.workflow/log/$role"
today=$(date +%Y-%m-%d)
if [ -d "$log_dir" ] && ls "$log_dir"/*.md >/dev/null 2>&1; then
  artifact_results="${artifact_results}\n- [x] Log entry exists in .workflow/log/$role/"
else
  artifact_results="${artifact_results}\n- [ ] Log entry missing in .workflow/log/$role/"
  artifacts_ok=false
fi

# Check: task status was updated (look for "review" or "done" in task.md frontmatter)
task_status=$(grep -oP 'status:\s*\K\S+' "$task_file" 2>/dev/null || echo "unknown")
if [ "$task_status" = "review" ] || [ "$task_status" = "done" ]; then
  artifact_results="${artifact_results}\n- [x] Task status updated to $task_status"
else
  artifact_results="${artifact_results}\n- [ ] Task status is '$task_status' (expected 'review')"
  artifacts_ok=false
fi

# --- Stage 2: Criteria Check ---

# Extract acceptance_criteria from YAML frontmatter
# Frontmatter is between first --- and second ---
criteria=$(awk '/^---$/{n++; next} n==1 && /acceptance_criteria:/{found=1; next} found && /^  - /{print; next} found && !/^  -/{found=0}' "$task_file")

criteria_total=0
criteria_met=0
criteria_results=""

if [ -n "$criteria" ]; then
  while IFS= read -r criterion; do
    criterion_text=$(echo "$criterion" | sed 's/^  - //')
    criteria_total=$((criteria_total + 1))
    # Search transcript for evidence of this criterion (fuzzy: first 3 significant words)
    search_words=$(echo "$criterion_text" | tr -cs '[:alnum:]' ' ' | awk '{for(i=1;i<=3&&i<=NF;i++) printf "%s.*", $i}')
    if grep -qiP "$search_words" "$transcript_path" 2>/dev/null; then
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
  # No criteria found — can't evaluate, approve
  completeness=100
fi

# --- Stage 3: Write Verification Log ---

# Count existing verify logs for retry tracking
verify_count=$(find "$log_dir" -name "verify-${task_id}-*.md" 2>/dev/null | wc -l | tr -d ' ')
attempt=$((verify_count + 1))
max_retries=3

# Ensure log directory exists
mkdir -p "$log_dir"

# Extract task title from frontmatter
task_title=$(grep -oP 'title:\s*\K.*' "$task_file" 2>/dev/null | head -1 || echo "unknown")

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
  # Add unmet criteria
  if [ -n "$criteria" ]; then
    while IFS= read -r criterion; do
      criterion_text=$(echo "$criterion" | sed 's/^  - //')
      search_words=$(echo "$criterion_text" | tr -cs '[:alnum:]' ' ' | awk '{for(i=1;i<=3&&i<=NF;i++) printf "%s.*", $i}')
      if ! grep -qiP "$search_words" "$transcript_path" 2>/dev/null; then
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
  # Feed gaps back to Claude so the agent can address them
  system_msg="ago: Verification failed for $task_id (attempt $attempt/$max_retries, ${completeness}% complete). Address gaps listed in .workflow/log/$role/verify-${task_id}-${attempt}.md before completing."
  echo "{\"decision\": \"block\", \"reason\": \"Verification: ${completeness}% complete (need 80%)\", \"systemMessage\": \"$system_msg\"}" >&2
  exit 2
else
  echo "{\"decision\": \"approve\", \"systemMessage\": \"ago: Verification passed for $task_id (${completeness}% complete, attempt $attempt). Log: .workflow/log/$role/verify-${task_id}-${attempt}.md\"}"
  exit 0
fi
```

**Step 3: Create the evaluate-and-log.sh script**

Create `hooks/scripts/evaluate-and-log.sh`:

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

# Extract task ID from transcript (look for "Task: T" followed by digits)
task_id=$(grep -oP 'Task:\s*T\d+' "$transcript_path" 2>/dev/null | head -1 | grep -oP 'T\d+' || true)

# If no task ID found, this isn't an ago: workflow agent — approve
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

# Extract role from task directory name (T001-DEV-name -> DEV)
role=$(basename "$task_dir" | sed 's/^T[0-9]*-\([A-Z]*\)-.*/\1/' | tr '[:upper:]' '[:lower:]')

# Extract task title from frontmatter
task_title=$(grep -oP 'title:\s*\K.*' "$task_file" 2>/dev/null | head -1 || echo "unknown")

# Read acceptance criteria from YAML frontmatter
criteria=$(awk '/^---$/{n++; next} n==1 && /acceptance_criteria:/{found=1; next} found && /^  - /{print; next} found && !/^  -/{found=0}' "$task_file")

# If no criteria, nothing to evaluate — approve
if [ -z "$criteria" ]; then
  echo '{"decision": "approve", "systemMessage": "ago: evaluate-and-log: no acceptance criteria for '"$task_id"'"}'
  exit 0
fi

# Read transcript (truncate to last 4000 chars to stay within prompt limits)
transcript_tail=$(tail -c 4000 "$transcript_path")

# Count existing eval logs for attempt tracking
log_dir="$cwd/.workflow/log/$role"
mkdir -p "$log_dir"
eval_count=$(find "$log_dir" -name "eval-${task_id}-*.md" 2>/dev/null | wc -l | tr -d ' ')
attempt=$((eval_count + 1))
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
role_upper=$(echo "$role" | tr '[:lower:]' '[:upper:]')

# Build LLM prompt with embedded log template
# Uses placeholder substitution to avoid heredoc escaping issues
read -r -d '' llm_prompt << 'PROMPT_EOF' || true
You are a verification evaluator for the ago: workflow system.

A subagent just completed work on task __TASK_ID__: __TASK_TITLE__ (role: __ROLE__).

## Acceptance Criteria
__CRITERIA__

## Subagent Transcript (last 4000 chars)
__TRANSCRIPT__

## Instructions

Evaluate the subagent's work against each acceptance criterion. Output EXACTLY this markdown format:

## LLM Evaluation — __TASK_ID__ — Attempt __ATTEMPT__

**Timestamp:** __TIMESTAMP__
**Task:** __TASK_ID__ — __TASK_TITLE__
**Role:** __ROLE_UPPER__
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
PROMPT_EOF

# Substitute placeholders
llm_prompt="${llm_prompt//__TASK_ID__/$task_id}"
llm_prompt="${llm_prompt//__TASK_TITLE__/$task_title}"
llm_prompt="${llm_prompt//__ROLE__/$role}"
llm_prompt="${llm_prompt//__ROLE_UPPER__/$role_upper}"
llm_prompt="${llm_prompt//__CRITERIA__/$criteria}"
llm_prompt="${llm_prompt//__TRANSCRIPT__/$transcript_tail}"
llm_prompt="${llm_prompt//__ATTEMPT__/$attempt}"
llm_prompt="${llm_prompt//__TIMESTAMP__/$timestamp}"

# Call claude -p with haiku model via stdin
eval_result=$(echo "$llm_prompt" | claude -p --model haiku --output-format text 2>/dev/null || true)

# If claude call failed, approve (don't block on LLM failure)
if [ -z "$eval_result" ]; then
  echo '{"decision": "approve", "systemMessage": "ago: evaluate-and-log: claude -p failed, approving by default"}'
  exit 0
fi

# Write the evaluation log
echo "$eval_result" > "$log_dir/eval-${task_id}-${attempt}.md"

# Parse decision from LLM output
if echo "$eval_result" | grep -qi 'Decision:.*BLOCK'; then
  completeness=$(echo "$eval_result" | grep -oP 'Completeness:\s*\K\d+' || echo "0")
  system_msg="ago: LLM evaluation blocked ${task_id} (attempt ${attempt}, ${completeness}% complete). Details: .workflow/log/${role}/eval-${task_id}-${attempt}.md"
  echo "{\"decision\": \"block\", \"reason\": \"LLM evaluation: ${completeness}% complete (need 80%)\", \"systemMessage\": \"$system_msg\"}" >&2
  exit 2
else
  echo "{\"decision\": \"approve\", \"systemMessage\": \"ago: LLM evaluation passed for ${task_id}. Log: .workflow/log/${role}/eval-${task_id}-${attempt}.md\"}"
  exit 0
fi
```

**Step 4: Make scripts executable**

Run: `chmod +x hooks/scripts/verify-and-log.sh hooks/scripts/evaluate-and-log.sh`

**Step 5: Commit**

```bash
git add hooks/hooks.json hooks/scripts/verify-and-log.sh hooks/scripts/evaluate-and-log.sh
git commit -m "feat: add SubagentStop verification hooks (deterministic + LLM evaluation)"
```

---

### Task 2: Register hooks in plugin.json

**Files:**
- Modify: `.claude-plugin/plugin.json`

**Step 1: Add hooks field to plugin.json**

The plugin manifest needs to declare that hooks exist. Add `"hooks": "hooks/hooks.json"` to the manifest.

Update `.claude-plugin/plugin.json` to:

```json
{
  "name": "ago",
  "version": "0.3.0",
  "description": "Agentic Orchestration — multi-agent workflow system for software development",
  "author": {
    "name": "eyev"
  },
  "keywords": ["orchestration", "agents", "workflow", "multi-agent"],
  "hooks": "hooks/hooks.json"
}
```

**Step 2: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: register verification hooks in plugin manifest, bump to v0.3.0"
```

---

### Task 3: Update conventions/logging.md with verification log format

**Files:**
- Modify: `conventions/logging.md`

**Step 1: Add verification log section**

After the "Agent Log Format" section (line ~39), add a new section documenting the verification log format:

```markdown
## Verification Log Format

Created automatically by the SubagentStop verification hook. One file per verification attempt.

File: `.workflow/log/{role}/verify-{task_id}-{attempt}.md`

Example: `.workflow/log/dev/verify-T001-1.md`

Each verification log contains:
- **Artifact Check** — Required outputs: log entry, task status, referenced files, frontmatter
- **Acceptance Criteria Evaluation** — Each criterion checked against subagent transcript
- **Completeness score** — Percentage of criteria met (threshold: 80%)
- **Decision** — APPROVE or BLOCK
- **Retry Prompt** — (if BLOCK) Specific gaps the agent must address

## LLM Evaluation Log Format

Created automatically by the SubagentStop LLM evaluation hook (`evaluate-and-log.sh`). One file per evaluation attempt.

File: `.workflow/log/{role}/eval-{task_id}-{attempt}.md`

Example: `.workflow/log/dev/eval-T001-1.md`

Each evaluation log contains:
- **Criteria Assessment** — Table with per-criterion Status (MET/GAP/PARTIAL) and Evidence
- **Quality Observations** — What was done well and what is concerning
- **Gaps to Address** — Specific unmet criteria that need work
- **Completeness score** — Percentage of criteria fully MET (threshold: 80%)
- **Decision** — APPROVE or BLOCK

### Graceful Degradation
- If `claude -p` fails, the hook approves by default (no false blocks from LLM failure)
- Deterministic verification log (`verify-*.md`) always exists as fallback

### Retry Rules
- Max 3 attempts per task (configurable in `verify-and-log.sh`)
- After max retries, auto-approve with warnings logged
- Retry count tracked by counting `verify-{task_id}-*.md` files (deterministic) and `eval-{task_id}-*.md` files (LLM)
```

Also update the "Future: Hook-Based Automation" section (line ~49) to reflect that hooks are now implemented:

Replace the TODO block with:

```markdown
## Hook-Based Verification

SubagentStop hooks automatically verify agent work (both command type, run in parallel):
- **Deterministic hook** (`hooks/scripts/verify-and-log.sh`) — artifact check + criteria check + write verification log
- **LLM evaluation hook** (`hooks/scripts/evaluate-and-log.sh`) — independent `claude -p` haiku evaluation + write evaluation log

If either hook returns `block`, the agent continues working. Two log files per attempt:
- `verify-{task_id}-{attempt}.md` — facts (checklist, grep-based criteria)
- `eval-{task_id}-{attempt}.md` — judgment (per-criterion evidence, quality observations, gaps)

See `hooks/hooks.json` for configuration.
```

**Step 2: Commit**

```bash
git add conventions/logging.md
git commit -m "docs: add verification log format and hook documentation to logging conventions"
```

---

### Task 4: Update ago:clarify with optional superpowers integration

**Files:**
- Modify: `commands/clarify.md`

**Step 1: Add superpowers detection after Step 1 (Read Project Config)**

Insert a new Step 1.5 between current Step 1 and Step 2:

```markdown
## Step 1.5: Check for Superpowers Integration

Check if the `superpowers` plugin is available by testing whether the `/brainstorming` and `/writing-plans` skills can be invoked.

**If superpowers IS available:**
- After Step 3 (COLLABORATE), instead of doing your own decomposition, invoke `/brainstorming` with the clarified requirements as context. The brainstorming skill will explore approaches and produce a validated design.
- Then invoke `/writing-plans` to convert the design into tasks. Adapt the writing-plans output to match ago: task format (YAML frontmatter with id, role, epic, priority, depends_on, acceptance_criteria).
- Continue from Step 6 (APPROVE) with the generated task breakdown.

**If superpowers is NOT available:**
- Proceed with Steps 2-5 as written below (existing behavior).

This integration is optional. The command works identically with or without superpowers.
```

**Step 2: Commit**

```bash
git add commands/clarify.md
git commit -m "feat: add optional superpowers integration to ago:clarify (brainstorming + writing-plans)"
```

---

### Task 5: Update ago:execute with optional superpowers integration

**Files:**
- Modify: `commands/execute.md`

**Step 1: Add superpowers detection after Step 2 (Read Project Context)**

Insert a new Step 2.5:

```markdown
## Step 2.5: Check for Superpowers Integration

Check if the `superpowers` plugin is available by testing whether the `/subagent-driven-development` skill can be invoked.

**If superpowers IS available:**
- In Step 7 (Execute each wave), instead of launching all agents in parallel per wave, use the subagent-driven-development pattern:
  - Launch one task at a time within each wave
  - After each task completes, perform a code review checkpoint before launching the next
  - This provides tighter feedback loops at the cost of sequential execution within waves
- The SubagentStop verification hooks still fire for each agent regardless

**If superpowers is NOT available:**
- Proceed with Step 7 as written (parallel launch within waves, sequential between waves).

This integration is optional. The command works identically with or without superpowers.
```

**Step 2: Commit**

```bash
git add commands/execute.md
git commit -m "feat: add optional superpowers integration to ago:execute (subagent-driven-development)"
```

---

### Task 6: Update master-session.md to reference verification hooks

**Files:**
- Modify: `agents/master-session.md`

**Step 1: Add Verification Hooks section after Available Skills table**

After the "Available Skills" table (around line 138), add:

```markdown
## Verification Hooks

SubagentStop hooks automatically verify agent work when they attempt to complete:

- **Command hook** (`hooks/scripts/verify-and-log.sh`) — checks artifacts exist, evaluates acceptance criteria against transcript, writes mandatory verification log to `.workflow/log/{role}/verify-{task_id}-{attempt}.md`
- **LLM evaluation hook** (`hooks/scripts/evaluate-and-log.sh`) — independent LLM evaluation via `claude -p` haiku, writes detailed evaluation log to `.workflow/log/{role}/eval-{task_id}-{attempt}.md`, returns approve/block based on completeness threshold (80%)

Both hooks are command type, run in parallel. Block wins over approve (safety-first). Max 3 attempts per task.

**As MASTER, you should:**
- Check both verification logs after agents complete: `.workflow/log/{role}/verify-*.md` (facts) and `eval-*.md` (judgment)
- If an agent was blocked and retried, review the verification log chain to understand what gaps were found
- Factor verification completeness scores into quality gate evaluation during CONSOLIDATE phase
```

**Step 2: Add note about superpowers to Session Lifecycle section**

In the Session Lifecycle section, add a note after step 3 (COLLABORATE):

```markdown
> **Note:** If the superpowers plugin is available, the COLLABORATE and DECOMPOSE phases can leverage `/brainstorming` and `/writing-plans` skills for richer interactive refinement. See `commands/clarify.md` for details.
```

**Step 3: Commit**

```bash
git add agents/master-session.md
git commit -m "docs: add verification hooks and superpowers references to master-session agent"
```

---

### Task 7: Update file-structure.md with hooks directory

**Files:**
- Modify: `conventions/file-structure.md`

**Step 1: Add hooks to the standard structure tree**

This change is for the plugin structure (this repo), not the target project `.workflow/` structure. However, the verification logs live in `.workflow/log/{role}/` which is already documented.

No changes needed to file-structure.md — the `.workflow/log/{role}/` directory already covers verification logs, and hooks live in the plugin repo (not in target projects).

**Step 1 (actual): Add verification log naming to the log/ section**

In the `## log/` section (line ~65), append:

```markdown
Verification logs (created by SubagentStop hooks):
`verify-{task_id}-{attempt}.md` (e.g., `verify-T001-1.md`)
```

**Step 2: Commit**

```bash
git add conventions/file-structure.md
git commit -m "docs: add verification log naming to file-structure convention"
```

---

### Task 8: Update README.md, CLAUDE.md, MEMORY.md

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `memory/MEMORY.md`

**Step 1: Update README.md Phase 3 roadmap**

In the Phase 3 table, update:

```markdown
### Phase 3: Automation & Hooks

| Item | Status |
|------|--------|
| SubagentStop verification hooks (verify-and-log.sh + prompt) | Done |
| Superpowers integration (clarify + execute) | Done |
| CONS agent as periodic process | TODO |
| Docs integrity CI check | TODO |
```

Also add to the Structure section:

```
hooks/             — SubagentStop verification hooks
```

**Step 2: Update CLAUDE.md**

Add to Architecture section:

```markdown
Verification: SubagentStop hooks auto-check agent work against acceptance criteria (see hooks/hooks.json)
Superpowers: ago:clarify and ago:execute optionally leverage superpowers skills when available
```

**Step 3: Update MEMORY.md**

Add hooks info:

```markdown
## Verification Hooks (Phase 3)
- `hooks/hooks.json` — SubagentStop hook config (command + prompt, parallel)
- `hooks/scripts/verify-and-log.sh` — deterministic 3-stage verification: artifact check, criteria check, write log
- `hooks/scripts/evaluate-and-log.sh` — LLM evaluation via claude -p haiku, writes eval log
- Verification logs: `.workflow/log/{role}/verify-{task_id}-{attempt}.md` (deterministic) + `eval-{task_id}-{attempt}.md` (LLM)
- Max 3 attempts, 80% completeness threshold, block wins over approve
- Superpowers integration: optional, detected at runtime
```

**Step 4: Update AUDIT.md changelog**

Add new entry:

```markdown
### 2026-02-27 — Phase 3: Verification hooks + superpowers integration

**Выполнено:**
1. **Created** `hooks/hooks.json` — SubagentStop verification hooks (two command hooks)
2. **Created** `hooks/scripts/verify-and-log.sh` — deterministic 3-stage artifact/criteria/log verification
3. **Created** `hooks/scripts/evaluate-and-log.sh` — LLM evaluation via claude -p haiku, writes eval log
3. **Updated** `commands/clarify.md` — optional superpowers integration (brainstorming + writing-plans)
4. **Updated** `commands/execute.md` — optional superpowers integration (subagent-driven-development)
5. **Updated** `agents/master-session.md` — verification hooks reference, superpowers note
6. **Updated** `conventions/logging.md` — verification log format documentation
7. **Updated** `conventions/file-structure.md` — verification log naming
8. **Updated** `.claude-plugin/plugin.json` — hooks registration, version bump to 0.3.0
```

**Step 5: Commit**

```bash
git add README.md CLAUDE.md memory/MEMORY.md AUDIT.md
git commit -m "docs: update roadmap and project docs for Phase 3 verification hooks"
```
