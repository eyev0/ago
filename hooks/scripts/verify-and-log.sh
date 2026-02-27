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

# Check: task status was updated (POSIX-compatible: awk scoped to frontmatter)
task_status=$(awk '/^---$/{n++; next} n==1 && /^status:/{sub(/^status:[[:space:]]*/,""); sub(/[[:space:]]*$/,""); print; exit} n>=2{exit}' "$task_file" 2>/dev/null)
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

# Extract task title (POSIX-compatible: awk scoped to frontmatter)
task_title=$(awk '/^---$/{n++; next} n==1 && /^title:/{sub(/^title:[[:space:]]*/,""); print; exit} n>=2{exit}' "$task_file" 2>/dev/null)
task_title=$(printf '%s' "$task_title" | tr -d '`$\\')
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
  echo "{\"decision\": \"block\", \"reason\": \"Verification: ${completeness}% complete (need 80%)\", \"systemMessage\": \"$system_msg\"}"
  exit 2
else
  echo "{\"decision\": \"approve\", \"systemMessage\": \"ago: Verification passed for $task_id (${completeness}% complete, attempt $attempt). Log: .workflow/log/$role/verify-${task_id}-${attempt}.md\"}"
  exit 0
fi
