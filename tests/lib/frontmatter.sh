#!/bin/bash
# Shared frontmatter extraction utilities using yq
# Source this file: source "$(dirname "$0")/lib/frontmatter.sh"

# Check yq dependency — graceful skip
check_yq() {
  command -v yq >/dev/null 2>&1 || {
    echo "SKIP: yq not installed (brew install yq)"
    exit 0
  }
}

# Extract YAML frontmatter from a markdown file, pipe to yq
# Only extracts between the FIRST two --- delimiters (lines 1 and closing)
# Usage: fm_field "file.md" ".name"
fm_field() {
  local file="$1" expr="$2"
  awk 'BEGIN{n=0} /^---$/{n++; if(n==2) exit; next} n==1{print}' "$file" | yq eval "$expr" -
}

# Extract raw frontmatter as a string (no yq)
# Usage: fm_raw "file.md"
fm_raw() {
  awk 'BEGIN{n=0} /^---$/{n++; if(n==2) exit; next} n==1{print}' "$1"
}

# Check if a frontmatter field exists and is non-null
# Usage: fm_exists "file.md" ".name"
fm_exists() {
  local val
  val=$(fm_field "$1" "$2")
  [ -n "$val" ] && [ "$val" != "null" ]
}

# Test pass/fail helpers (match existing hook test style)
PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "  PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "  FAIL: $1 — $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

# Print summary and exit with appropriate code
summary() {
  local label="${1:-Results}"
  echo ""
  echo "=== $label: $PASS_COUNT passed, $FAIL_COUNT failed ==="
  [ "$FAIL_COUNT" -eq 0 ] && exit 0 || exit 1
}
