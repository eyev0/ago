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
if grep -rn 'grep.*-[^-]*P' "$HOOKS_DIR"/*.sh | grep -v '^.*:#' >/dev/null 2>&1; then
  fail "Portability" "Found grep -P in non-comment lines of hook scripts"
else
  pass "No grep -P flags in executable lines"
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
