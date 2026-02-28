#!/bin/bash
set -euo pipefail

# Unit tests for hooks/scripts/lib/parse-criteria.sh
# Run from repo root: bash hooks/tests/test-parse-criteria.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB="$(dirname "$SCRIPT_DIR")/scripts/lib/parse-criteria.sh"

source "$LIB"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1 — $2"; FAIL=$((FAIL + 1)); }

TMPFILE=""
cleanup() { [ -n "$TMPFILE" ] && rm -f "$TMPFILE"; true; }
trap cleanup EXIT

make_task() {
  TMPFILE=$(mktemp "${TMPDIR:-/tmp}/ago-parse-test-XXXX.md")
  cat > "$TMPFILE"
}

echo "=== parse-criteria unit tests ==="

# --- parse_criteria tests ---

echo ""
echo "--- parse_criteria ---"

# Test 1: YAML frontmatter criteria
echo ""
echo "Test 1: Parses YAML frontmatter acceptance_criteria"
make_task << 'EOF'
---
id: T001
acceptance_criteria:
  - Implement auth module
  - Write unit tests
  - Update docs
status: backlog
---

## Description

Some description.
EOF

result=$(parse_criteria "$TMPFILE")
count=$(echo "$result" | grep -c '  - ' || true)
if [ "$count" -eq 3 ]; then
  pass "Found 3 criteria from frontmatter"
else
  fail "Frontmatter parse" "Expected 3 criteria, got $count. Output: $result"
fi
cleanup; TMPFILE=""

# Test 2: Markdown body checkboxes (no frontmatter criteria)
echo ""
echo "Test 2: Falls back to markdown body checkboxes"
make_task << 'EOF'
---
id: T001
status: backlog
---

## Description

Some description.

## Acceptance Criteria

- [ ] Implement auth module
- [ ] Write unit tests
- [ ] Update docs

## Artifacts

None yet.
EOF

result=$(parse_criteria "$TMPFILE")
count=$(echo "$result" | grep -c '\[.\]' || true)
if [ "$count" -eq 3 ]; then
  pass "Found 3 criteria from markdown body"
else
  fail "Body parse" "Expected 3 criteria, got $count. Output: $result"
fi
cleanup; TMPFILE=""

# Test 3: Frontmatter takes priority over body
echo ""
echo "Test 3: Frontmatter takes priority when both present"
make_task << 'EOF'
---
id: T001
acceptance_criteria:
  - Frontmatter criterion A
  - Frontmatter criterion B
status: backlog
---

## Acceptance Criteria

- [ ] Body criterion X
- [ ] Body criterion Y
- [ ] Body criterion Z
EOF

result=$(parse_criteria "$TMPFILE")
if echo "$result" | grep -q "Frontmatter criterion A"; then
  pass "Frontmatter criteria returned (not body)"
else
  fail "Priority" "Expected frontmatter criteria, got: $result"
fi
count=$(echo "$result" | grep -c '.' || true)
if [ "$count" -eq 2 ]; then
  pass "Got 2 criteria (frontmatter count, not body count)"
else
  fail "Priority count" "Expected 2 (frontmatter), got $count"
fi
cleanup; TMPFILE=""

# Test 4: No criteria anywhere
echo ""
echo "Test 4: No criteria in frontmatter or body → empty"
make_task << 'EOF'
---
id: T001
status: backlog
---

## Description

Just a description, no acceptance criteria section.

## Artifacts

None.
EOF

result=$(parse_criteria "$TMPFILE")
if [ -z "$result" ]; then
  pass "Empty output when no criteria found"
else
  fail "No criteria" "Expected empty, got: $result"
fi
cleanup; TMPFILE=""

# Test 5: Checked checkboxes are also captured
echo ""
echo "Test 5: Captures checked [x] checkboxes too"
make_task << 'EOF'
---
id: T001
status: review
---

## Acceptance Criteria

- [x] Already done item
- [ ] Still pending item
EOF

result=$(parse_criteria "$TMPFILE")
count=$(echo "$result" | grep -c '\[.\]' || true)
if [ "$count" -eq 2 ]; then
  pass "Both checked and unchecked captured"
else
  fail "Checkbox states" "Expected 2 criteria, got $count. Output: $result"
fi
cleanup; TMPFILE=""

# Test 6: Stops at next heading
echo ""
echo "Test 6: Body parsing stops at next ## heading"
make_task << 'EOF'
---
id: T001
status: backlog
---

## Acceptance Criteria

- [ ] Real criterion 1
- [ ] Real criterion 2

## Artifacts

- [ ] This is NOT a criterion, it's in a different section
EOF

result=$(parse_criteria "$TMPFILE")
count=$(echo "$result" | grep -c '\[.\]' || true)
if [ "$count" -eq 2 ]; then
  pass "Stopped at ## Artifacts heading"
else
  fail "Heading boundary" "Expected 2 criteria, got $count. Output: $result"
fi
cleanup; TMPFILE=""

# Test 7: Frontmatter list ends at non-indented line
echo ""
echo "Test 7: Frontmatter parsing stops at non-list line"
make_task << 'EOF'
---
id: T001
acceptance_criteria:
  - First criterion
  - Second criterion
status: backlog
depends_on: []
---

## Description

Some description.
EOF

result=$(parse_criteria "$TMPFILE")
count=$(echo "$result" | grep -c '  - ' || true)
if [ "$count" -eq 2 ]; then
  pass "Stopped before status: line"
else
  fail "Frontmatter boundary" "Expected 2, got $count. Output: $result"
fi
if ! echo "$result" | grep -q "status"; then
  pass "Did not capture 'status' field as criterion"
else
  fail "Frontmatter boundary" "Incorrectly captured non-criterion YAML field"
fi
cleanup; TMPFILE=""

# --- strip_criterion tests ---

echo ""
echo "--- strip_criterion ---"

# Test 8: Strip frontmatter format
echo ""
echo "Test 8: Strips '  - ' prefix (frontmatter format)"
result=$(strip_criterion "  - Implement auth module")
if [ "$result" = "Implement auth module" ]; then
  pass "Frontmatter prefix stripped"
else
  fail "Strip frontmatter" "Expected 'Implement auth module', got '$result'"
fi

# Test 9: Strip body unchecked format
echo ""
echo "Test 9: Strips '- [ ] ' prefix (body unchecked)"
result=$(strip_criterion "- [ ] Write unit tests")
if [ "$result" = "Write unit tests" ]; then
  pass "Body unchecked prefix stripped"
else
  fail "Strip body unchecked" "Expected 'Write unit tests', got '$result'"
fi

# Test 10: Strip body checked format
echo ""
echo "Test 10: Strips '- [x] ' prefix (body checked)"
result=$(strip_criterion "- [x] Already done")
if [ "$result" = "Already done" ]; then
  pass "Body checked prefix stripped"
else
  fail "Strip body checked" "Expected 'Already done', got '$result'"
fi

# Test 11: Plain text passes through unchanged
echo ""
echo "Test 11: Plain text without prefix passes through"
result=$(strip_criterion "Just plain text")
if [ "$result" = "Just plain text" ]; then
  pass "Plain text unchanged"
else
  fail "Strip passthrough" "Expected 'Just plain text', got '$result'"
fi

# --- Summary ---
echo ""
echo "=== Parse-criteria results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
