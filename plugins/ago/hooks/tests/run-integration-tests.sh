#!/bin/bash
set -euo pipefail

# Integration test runner for ago: SubagentStop hooks
# Tests verify-and-log.sh and evaluate-and-log.sh against realistic scaffolds
#
# Run from repo root: bash hooks/tests/run-integration-tests.sh
# Or via Makefile:     make test-hooks-integration

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")/scripts"
VERIFY_HOOK="$HOOKS_DIR/verify-and-log.sh"
EVALUATE_HOOK="$HOOKS_DIR/evaluate-and-log.sh"

PASS=0
FAIL=0
TEST_NUM=0
SCAFFOLD=""

# --- Helpers ---

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1 — $2"; FAIL=$((FAIL + 1)); }

cleanup() {
  if [ -n "$SCAFFOLD" ] && [ -d "$SCAFFOLD" ]; then
    rm -rf "$SCAFFOLD"
  fi
}
trap cleanup EXIT

# Create a fresh scaffold directory for a test.
# Sets SCAFFOLD to the new temp directory path.
# Builds a .workflow/ project with task, log, and transcript.
#
# Arguments:
#   $1 - transcript content (optional, defaults to happy-path content)
#   $2 - task status (optional, defaults to "review")
#   $3 - skip log dir if set to "no-log"
setup_scaffold() {
  local transcript_content="${1:-}"
  local task_status="${2:-review}"
  local log_flag="${3:-}"

  SCAFFOLD=$(mktemp -d "${TMPDIR:-/tmp}/ago-hook-test-XXXX")

  # Task directory
  local task_dir="$SCAFFOLD/.workflow/epics/E01/tasks/T001-DEV-test-feature"
  mkdir -p "$task_dir/artifacts"

  # Task file with frontmatter
  cat > "$task_dir/task.md" << 'TASK_FRONTMATTER'
---
id: T001
role: DEV
title: test-feature
epic: E01
status: STATUS_PLACEHOLDER
created: 2026-01-01
updated: 2026-01-01
priority: high
depends_on: []
blocks: []
related_decisions: []
acceptance_criteria:
  - Implement the authentication module
  - Write unit tests for login flow
  - Update API documentation
---

## Description

Implement authentication feature with tests and docs.

## Acceptance Criteria

- [ ] Implement the authentication module
- [ ] Write unit tests for login flow
- [ ] Update API documentation

## Artifacts

(none yet)
TASK_FRONTMATTER

  # Replace the status placeholder
  sed -i.bak "s/STATUS_PLACEHOLDER/$task_status/" "$task_dir/task.md"
  rm -f "$task_dir/task.md.bak"

  # Log directory and entry (unless suppressed)
  if [ "$log_flag" != "no-log" ]; then
    mkdir -p "$SCAFFOLD/.workflow/log/dev"
    cat > "$SCAFFOLD/.workflow/log/dev/2026-01-01.md" << 'LOG_EOF'
## DEV Log — 2026-01-01

### T001 — test-feature

- Implemented authentication module with JWT tokens
- Wrote unit tests covering login, logout, and token refresh
- Updated API documentation for /auth endpoints

**Status:** review
LOG_EOF
  fi

  # Transcript file
  if [ -z "$transcript_content" ]; then
    # Default: happy-path transcript with evidence for all 3 criteria
    transcript_content="Task: T001

I have completed the implementation work for test-feature.

Implement the authentication module — Done. I created auth.js with JWT-based
authentication including login, logout, and token refresh endpoints.

Write unit tests for login flow — Done. Added test/auth.test.js with 12 test
cases covering the login flow including error cases and edge conditions.

Update API documentation — Done. Updated docs/api.md with the new /auth
endpoints, request/response schemas, and example cURL commands."
  fi

  echo "$transcript_content" > "$SCAFFOLD/transcript.txt"

  # Config file (minimal)
  mkdir -p "$SCAFFOLD/.workflow"
  cat > "$SCAFFOLD/.workflow/config.md" << 'CONFIG_EOF'
---
project_name: test-project
task_counter: 1
---
CONFIG_EOF
}

# Build the input JSON for a hook, pointing to the scaffold.
# Arguments:
#   $1 - transcript path (optional, defaults to $SCAFFOLD/transcript.txt)
#   $2 - cwd (optional, defaults to $SCAFFOLD)
make_input_json() {
  local tp="${1:-$SCAFFOLD/transcript.txt}"
  local cwd="${2:-$SCAFFOLD}"
  cat << JSON_EOF
{
  "session_id": "integration-test-$(printf '%04d' $TEST_NUM)",
  "transcript_path": "$tp",
  "cwd": "$cwd",
  "permission_mode": "allow",
  "hook_event_name": "SubagentStop",
  "reason": "Task completed"
}
JSON_EOF
}

# Run a hook and capture stdout, stderr, and exit code.
# Sets: HOOK_STDOUT, HOOK_EXIT
run_hook() {
  local hook_script="$1"
  local input_json="$2"
  HOOK_EXIT=0
  HOOK_STDOUT=$(echo "$input_json" | bash "$hook_script" 2>/dev/null) || HOOK_EXIT=$?
}

# --- Tests for verify-and-log.sh ---

echo "=== Hook Integration Tests ==="
echo ""
echo "--- verify-and-log.sh ---"

# Test 1: Happy path — all criteria met, approve
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — happy path, all criteria met → approve"
setup_scaffold  # defaults: happy-path transcript, status=review, log present
run_hook "$VERIFY_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0"
else
  fail "Exit code" "Expected 0, got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Decision is approve"
else
  fail "Decision" "Expected approve, got: $HOOK_STDOUT"
fi

if [ -f "$SCAFFOLD/.workflow/log/dev/verify-T001-1.md" ]; then
  pass "verify-T001-1.md was written"
else
  fail "Verification log" "verify-T001-1.md not found"
fi
cleanup
SCAFFOLD=""

# Test 2: Block — unmet criteria
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — unmet criteria → block"
transcript_no_match="Task: T001

I started working on the feature but got distracted by refactoring
the database schema. Spent most of the time on unrelated improvements
to the caching layer. No authentication, tests, or docs were touched."

setup_scaffold "$transcript_no_match" "review"
run_hook "$VERIFY_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 2 ]; then
  pass "Exit code is 2 (block)"
else
  fail "Exit code" "Expected 2, got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "block"' >/dev/null 2>&1; then
  pass "Decision is block"
else
  fail "Decision" "Expected block, got: $HOOK_STDOUT"
fi

verify_log="$SCAFFOLD/.workflow/log/dev/verify-T001-1.md"
if [ -f "$verify_log" ]; then
  pass "verify-T001-1.md was written"
  # Check that unmet criteria are listed with unchecked boxes
  if grep -q '\[ \]' "$verify_log"; then
    pass "Unmet criteria listed with unchecked boxes"
  else
    fail "Unmet criteria" "No unchecked boxes found in verification log"
  fi
  # Check that retry prompt exists
  if grep -q 'Retry Prompt' "$verify_log"; then
    pass "Retry prompt present in verification log"
  else
    fail "Retry prompt" "No retry prompt in verification log"
  fi
else
  fail "Verification log" "verify-T001-1.md not found"
fi
cleanup
SCAFFOLD=""

# Test 3: Block — missing log entry
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — missing log entry → block"
setup_scaffold "" "review" "no-log"
run_hook "$VERIFY_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 2 ] || [ "$HOOK_EXIT" -eq 0 ]; then
  # The hook creates the log dir via mkdir -p before writing verify log.
  # With no existing log, artifacts_ok=false, so block unless completeness
  # overrides. Check the actual decision.
  :
fi

verify_log="$SCAFFOLD/.workflow/log/dev/verify-T001-1.md"
if [ -f "$verify_log" ]; then
  pass "Verification log was written"
  if grep -q '\[ \] Log entry missing' "$verify_log"; then
    pass "Log entry flagged as missing"
  else
    fail "Missing log flag" "Expected unchecked log entry in verify log"
  fi
else
  fail "Verification log" "verify-T001-1.md not found"
fi

# Even with all criteria met in transcript, missing log makes artifacts_ok=false.
# But completeness can still be 100%. The script checks BOTH completeness >= 80
# AND artifacts_ok. So missing log should block.
if [ "$HOOK_EXIT" -eq 2 ]; then
  pass "Exit code is 2 (block due to missing log)"
else
  fail "Exit code" "Expected 2 (block), got $HOOK_EXIT"
fi
cleanup
SCAFFOLD=""

# Test 4: Block — task status not updated
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — task status in_progress → block"
setup_scaffold "" "in_progress"
run_hook "$VERIFY_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 2 ]; then
  pass "Exit code is 2 (block)"
else
  fail "Exit code" "Expected 2, got $HOOK_EXIT"
fi

verify_log="$SCAFFOLD/.workflow/log/dev/verify-T001-1.md"
if [ -f "$verify_log" ]; then
  if grep -q "Task status is 'in_progress'" "$verify_log"; then
    pass "Status issue recorded in verification log"
  else
    fail "Status check" "Expected in_progress status issue in log"
  fi
else
  fail "Verification log" "verify-T001-1.md not found"
fi
cleanup
SCAFFOLD=""

# Test 5: Approve — max retries reached
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — max retries reached → force approve"

transcript_no_match="Task: T001

Worked on random things, no authentication, no tests, no docs."

setup_scaffold "$transcript_no_match" "review"

# Pre-create two previous verify logs to simulate prior attempts
log_dir="$SCAFFOLD/.workflow/log/dev"
cat > "$log_dir/verify-T001-1.md" << 'EOF'
## Verification Report — T001 — Attempt 1
### Decision: BLOCK
EOF
cat > "$log_dir/verify-T001-2.md" << 'EOF'
## Verification Report — T001 — Attempt 2
### Decision: BLOCK
EOF

run_hook "$VERIFY_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0 (force approve on 3rd attempt)"
else
  fail "Exit code" "Expected 0 (force approve), got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Decision is approve"
else
  fail "Decision" "Expected approve, got: $HOOK_STDOUT"
fi

if [ -f "$log_dir/verify-T001-3.md" ]; then
  pass "verify-T001-3.md was written"
  if grep -q 'max retries reached' "$log_dir/verify-T001-3.md"; then
    pass "Max retries note present in log"
  else
    fail "Max retries note" "Expected 'max retries reached' in verify-T001-3.md"
  fi
else
  fail "Verification log" "verify-T001-3.md not found"
fi
cleanup
SCAFFOLD=""

# Test 6: Approve — no task ID in transcript
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — no task ID in transcript → approve"

transcript_no_task="I did some general cleanup and fixed formatting issues.
No specific task reference here at all."

setup_scaffold "$transcript_no_task" "review"
run_hook "$VERIFY_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0"
else
  fail "Exit code" "Expected 0, got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Decision is approve (not an ago task)"
else
  fail "Decision" "Expected approve, got: $HOOK_STDOUT"
fi

# No verification log should be written — the hook exits before reaching that stage
if ! ls "$SCAFFOLD/.workflow/log/dev/verify-T001"*.md >/dev/null 2>&1; then
  pass "No verification log written (non-ago context)"
else
  fail "Verification log" "Should not write verify log when no task ID found"
fi
cleanup
SCAFFOLD=""

# Test 7: Approve — no .workflow directory
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — no .workflow directory → approve"

SCAFFOLD=$(mktemp -d "${TMPDIR:-/tmp}/ago-hook-test-XXXX")
echo "Task: T001 — just a mention but no .workflow exists" > "$SCAFFOLD/transcript.txt"

run_hook "$VERIFY_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0"
else
  fail "Exit code" "Expected 0, got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Decision is approve (no .workflow)"
else
  fail "Decision" "Expected approve, got: $HOOK_STDOUT"
fi
cleanup
SCAFFOLD=""

# Test 8: Approve — no transcript file
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — nonexistent transcript path → approve"

SCAFFOLD=$(mktemp -d "${TMPDIR:-/tmp}/ago-hook-test-XXXX")
input_json=$(cat << JSON_EOF
{
  "session_id": "integration-test-0008",
  "transcript_path": "$SCAFFOLD/does-not-exist.txt",
  "cwd": "$SCAFFOLD",
  "permission_mode": "allow",
  "hook_event_name": "SubagentStop",
  "reason": "Done"
}
JSON_EOF
)
run_hook "$VERIFY_HOOK" "$input_json"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0"
else
  fail "Exit code" "Expected 0, got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Decision is approve (no transcript)"
else
  fail "Decision" "Expected approve, got: $HOOK_STDOUT"
fi
cleanup
SCAFFOLD=""

# --- Tests for evaluate-and-log.sh ---

echo ""
echo "--- evaluate-and-log.sh ---"

# Set up a mock claude command for evaluate tests
MOCK_BIN=$(mktemp -d "${TMPDIR:-/tmp}/ago-mock-bin-XXXX")
cat > "$MOCK_BIN/claude" << 'MOCK_CLAUDE'
#!/bin/bash
# Mock claude CLI — returns a fixed evaluation response
cat << 'EVAL_RESPONSE'
## LLM Evaluation — T001 — Attempt 1

**Timestamp:** 2026-01-01T00:00:00Z
**Task:** T001 — test-feature
**Role:** DEV
**Evaluator:** LLM (claude -p haiku)

### Criteria Assessment
| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Implement the authentication module | MET | Created auth.js with JWT |
| 2 | Write unit tests for login flow | MET | Added test/auth.test.js |
| 3 | Update API documentation | PARTIAL | Some docs updated |

### Quality Observations
- Good implementation of JWT auth
- Test coverage is solid

### Gaps to Address
1. API documentation needs more detail on error responses

### Completeness: 67%
### Decision: APPROVE
EVAL_RESPONSE
MOCK_CLAUDE
chmod +x "$MOCK_BIN/claude"

# Test 9: Evaluate — produces eval log
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: evaluate — produces eval log with mock claude"
setup_scaffold  # happy-path defaults
ORIGINAL_PATH="$PATH"
export PATH="$MOCK_BIN:$PATH"

run_hook "$EVALUATE_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0"
else
  fail "Exit code" "Expected 0, got $HOOK_EXIT"
fi

eval_log="$SCAFFOLD/.workflow/log/dev/eval-T001-1.md"
if [ -f "$eval_log" ]; then
  pass "eval-T001-1.md was written"
  if grep -q 'LLM Evaluation' "$eval_log"; then
    pass "Eval log contains LLM Evaluation header"
  else
    fail "Eval content" "Expected LLM Evaluation header in eval log"
  fi
  if grep -q 'Completeness:' "$eval_log"; then
    pass "Eval log contains Completeness score"
  else
    fail "Eval content" "Expected Completeness score in eval log"
  fi
else
  fail "Eval log" "eval-T001-1.md not found"
fi

export PATH="$ORIGINAL_PATH"
cleanup
SCAFFOLD=""

# Test 10: Evaluate — no task ID → approve
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: evaluate — no task ID in transcript → approve"

transcript_no_task="General cleanup work, no task references."
setup_scaffold "$transcript_no_task" "review"
export PATH="$MOCK_BIN:$PATH"

run_hook "$EVALUATE_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0"
else
  fail "Exit code" "Expected 0, got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Decision is approve (no task ID)"
else
  fail "Decision" "Expected approve, got: $HOOK_STDOUT"
fi

# No eval log should be written
if ! ls "$SCAFFOLD/.workflow/log/dev/eval-T001"*.md >/dev/null 2>&1; then
  pass "No eval log written (non-ago context)"
else
  fail "Eval log" "Should not write eval log when no task ID found"
fi

export PATH="$ORIGINAL_PATH"
cleanup
SCAFFOLD=""

# Test 11: Evaluate — claude command not found → approve gracefully
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: evaluate — claude not in PATH → approve gracefully"

setup_scaffold  # happy-path defaults

# Use a PATH that definitely does not contain claude
# We create a minimal PATH with just essential utilities
RESTRICTED_BIN=$(mktemp -d "${TMPDIR:-/tmp}/ago-restricted-bin-XXXX")

# Symlink only the utilities the hook script needs (no claude)
for cmd in bash jq grep head find tail date mktemp cat awk sed wc tr mkdir rm printf dirname basename; do
  cmd_path=$(command -v "$cmd" 2>/dev/null || true)
  if [ -n "$cmd_path" ]; then
    ln -sf "$cmd_path" "$RESTRICTED_BIN/$cmd"
  fi
done

export PATH="$RESTRICTED_BIN"
run_hook "$EVALUATE_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0 (graceful degradation)"
else
  fail "Exit code" "Expected 0 (graceful), got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Decision is approve (claude not available)"
else
  fail "Decision" "Expected approve, got: $HOOK_STDOUT"
fi

export PATH="$ORIGINAL_PATH"
rm -rf "$RESTRICTED_BIN"
cleanup
SCAFFOLD=""

# --- Cleanup mock bin ---
rm -rf "$MOCK_BIN"

# --- Tests for body-only criteria parsing (no frontmatter criteria) ---

echo ""
echo "--- Body-only criteria fallback ---"

# Helper: creates a scaffold where acceptance_criteria is ONLY in the markdown
# body (as checkboxes), not in YAML frontmatter. This matches what
# ago:create-task actually produces via templates/task.md.
setup_scaffold_body_only() {
  local transcript_content="${1:-}"
  local task_status="${2:-review}"
  local log_flag="${3:-}"

  SCAFFOLD=$(mktemp -d "${TMPDIR:-/tmp}/ago-hook-test-XXXX")

  local task_dir="$SCAFFOLD/.workflow/epics/E01/tasks/T001-DEV-test-feature"
  mkdir -p "$task_dir/artifacts"

  # Task file — NO acceptance_criteria in frontmatter
  cat > "$task_dir/task.md" << 'TASK_BODY_ONLY'
---
id: T001
role: DEV
title: test-feature
epic: E01
status: STATUS_PLACEHOLDER
created: 2026-01-01
updated: 2026-01-01
priority: high
depends_on: []
blocks: []
related_decisions: []
---

## Description

Implement authentication feature with tests and docs.

## Acceptance Criteria

- [ ] Implement the authentication module
- [ ] Write unit tests for login flow
- [ ] Update API documentation

## Artifacts

(none yet)
TASK_BODY_ONLY

  sed -i.bak "s/STATUS_PLACEHOLDER/$task_status/" "$task_dir/task.md"
  rm -f "$task_dir/task.md.bak"

  if [ "$log_flag" != "no-log" ]; then
    mkdir -p "$SCAFFOLD/.workflow/log/dev"
    cat > "$SCAFFOLD/.workflow/log/dev/2026-01-01.md" << 'LOG_EOF'
## DEV Log — 2026-01-01

### T001 — test-feature

- Implemented authentication module with JWT tokens
- Wrote unit tests covering login, logout, and token refresh
- Updated API documentation for /auth endpoints

**Status:** review
LOG_EOF
  fi

  if [ -z "$transcript_content" ]; then
    transcript_content="Task: T001

I have completed the implementation work for test-feature.

Implement the authentication module — Done. I created auth.js with JWT-based
authentication including login, logout, and token refresh endpoints.

Write unit tests for login flow — Done. Added test/auth.test.js with 12 test
cases covering the login flow including error cases and edge conditions.

Update API documentation — Done. Updated docs/api.md with the new /auth
endpoints, request/response schemas, and example cURL commands."
  fi

  echo "$transcript_content" > "$SCAFFOLD/transcript.txt"

  mkdir -p "$SCAFFOLD/.workflow"
  cat > "$SCAFFOLD/.workflow/config.md" << 'CONFIG_EOF'
---
project_name: test-project
task_counter: 1
---
CONFIG_EOF
}

# Test 12: verify — body-only criteria, all met → approve
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — body-only criteria, all met → approve"
setup_scaffold_body_only
run_hook "$VERIFY_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0"
else
  fail "Exit code" "Expected 0, got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "approve"' >/dev/null 2>&1; then
  pass "Decision is approve"
else
  fail "Decision" "Expected approve, got: $HOOK_STDOUT"
fi

# Verify the log contains actual criteria evaluations (not empty)
verify_log="$SCAFFOLD/.workflow/log/dev/verify-T001-1.md"
if [ -f "$verify_log" ]; then
  pass "verify-T001-1.md was written"
  if grep -q '\[x\] Implement the authentication module' "$verify_log"; then
    pass "Body criteria evaluated — auth module marked met"
  else
    fail "Body criteria" "Expected evaluated criterion in verify log"
  fi
  if grep -q 'Completeness: 100%' "$verify_log"; then
    pass "Completeness is 100%"
  else
    fail "Completeness" "Expected 100%, check verify log"
  fi
else
  fail "Verification log" "verify-T001-1.md not found"
fi
cleanup
SCAFFOLD=""

# Test 13: verify — body-only criteria, unmet → block
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: verify — body-only criteria, unmet → block"

transcript_no_match="Task: T001

Spent the session refactoring database code. No authentication, tests, or docs."

setup_scaffold_body_only "$transcript_no_match" "review"
run_hook "$VERIFY_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 2 ]; then
  pass "Exit code is 2 (block)"
else
  fail "Exit code" "Expected 2, got $HOOK_EXIT"
fi

if echo "$HOOK_STDOUT" | jq -e '.decision == "block"' >/dev/null 2>&1; then
  pass "Decision is block"
else
  fail "Decision" "Expected block, got: $HOOK_STDOUT"
fi

verify_log="$SCAFFOLD/.workflow/log/dev/verify-T001-1.md"
if [ -f "$verify_log" ]; then
  if grep -q 'Retry Prompt' "$verify_log"; then
    pass "Retry prompt present for body-only criteria"
  else
    fail "Retry prompt" "Expected retry prompt in verify log"
  fi
fi
cleanup
SCAFFOLD=""

# Test 14: evaluate — body-only criteria, produces eval log
echo ""
TEST_NUM=$((TEST_NUM + 1))
echo "Test $TEST_NUM: evaluate — body-only criteria, produces eval log"

# Recreate mock for evaluate tests
MOCK_BIN=$(mktemp -d "${TMPDIR:-/tmp}/ago-mock-bin-XXXX")
cat > "$MOCK_BIN/claude" << 'MOCK_CLAUDE'
#!/bin/bash
cat << 'EVAL_RESPONSE'
## LLM Evaluation — T001 — Attempt 1

**Timestamp:** 2026-01-01T00:00:00Z
**Task:** T001 — test-feature
**Role:** DEV
**Evaluator:** LLM (claude -p haiku)

### Criteria Assessment
| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Implement the authentication module | MET | Created auth.js |
| 2 | Write unit tests for login flow | MET | Added tests |
| 3 | Update API documentation | MET | Updated docs |

### Quality Observations
- All criteria addressed

### Gaps to Address
None — all criteria met

### Completeness: 100%
### Decision: APPROVE
EVAL_RESPONSE
MOCK_CLAUDE
chmod +x "$MOCK_BIN/claude"

setup_scaffold_body_only
ORIGINAL_PATH="$PATH"
export PATH="$MOCK_BIN:$PATH"

run_hook "$EVALUATE_HOOK" "$(make_input_json)"

if [ "$HOOK_EXIT" -eq 0 ]; then
  pass "Exit code is 0"
else
  fail "Exit code" "Expected 0, got $HOOK_EXIT"
fi

eval_log="$SCAFFOLD/.workflow/log/dev/eval-T001-1.md"
if [ -f "$eval_log" ]; then
  pass "eval-T001-1.md was written"
  if grep -q 'LLM Evaluation' "$eval_log"; then
    pass "Eval log contains evaluation (body-only criteria parsed)"
  else
    fail "Eval content" "Expected LLM Evaluation in eval log"
  fi
else
  fail "Eval log" "eval-T001-1.md not found"
fi

export PATH="$ORIGINAL_PATH"
rm -rf "$MOCK_BIN"
cleanup
SCAFFOLD=""

# --- Summary ---
echo ""
echo "=== Integration Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
