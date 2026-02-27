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

# Extract task title (POSIX-compatible: awk scoped to frontmatter)
task_title=$(awk '/^---$/{n++; next} n==1 && /^title:/{sub(/^title:[[:space:]]*/,""); print; exit} n>=2{exit}' "$task_file" 2>/dev/null)
task_title=$(printf '%s' "$task_title" | tr -d '`$\\')
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
  echo "{\"decision\": \"block\", \"reason\": \"LLM evaluation: ${completeness}% complete (need 80%)\", \"systemMessage\": \"$system_msg\"}"
  exit 2
else
  echo "{\"decision\": \"approve\", \"systemMessage\": \"ago: LLM evaluation passed for ${task_id}. Log: .workflow/log/${role}/eval-${task_id}-${attempt}.md\"}"
  exit 0
fi
