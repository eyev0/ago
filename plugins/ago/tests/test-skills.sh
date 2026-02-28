#!/bin/bash
set -euo pipefail

# Test Module 1: Skill Validation
# Validates YAML frontmatter, naming conventions, trigger phrases, and cross-references

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib/frontmatter.sh"
check_yq

echo "=== Skill Validation Tests ==="

SKILLS_DIR="$REPO_ROOT/skills"
skill_names=()

# --- Per-skill checks ---

for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"

  echo ""
  echo "--- $skill_name ---"

  # 1. SKILL.md exists
  if [ -f "$skill_file" ]; then
    pass "SKILL.md exists"
  else
    fail "SKILL.md exists" "File not found: $skill_file"
    continue  # skip remaining checks for this skill
  fi

  # 2. name field exists and is a string
  name_val=$(fm_field "$skill_file" '.name')
  if [ -n "$name_val" ] && [ "$name_val" != "null" ]; then
    pass "name field exists: $name_val"
  else
    fail "name field" "Missing or null"
  fi

  # 3. name matches ago:* pattern
  if echo "$name_val" | grep -qE '^ago:'; then
    pass "name matches ago:* pattern"
  else
    fail "name pattern" "Expected ago:*, got: $name_val"
  fi

  # Collect for duplicate check
  skill_names+=("$name_val")

  # 4. description exists and is a string
  desc_val=$(fm_field "$skill_file" '.description')
  if [ -n "$desc_val" ] && [ "$desc_val" != "null" ]; then
    pass "description field exists"
  else
    fail "description field" "Missing or null"
    continue
  fi

  # 5. description starts with third-person format
  if echo "$desc_val" | grep -qi '^This skill should be used when'; then
    pass "description uses third-person format"
  else
    fail "description format" "Should start with 'This skill should be used when'"
  fi

  # 6. description contains quoted trigger phrases
  if echo "$desc_val" | grep -qE '"[^"]+"'; then
    pass "description contains quoted trigger phrases"
  else
    fail "trigger phrases" "No quoted phrases found in description"
  fi

  # 7. version exists and is semver
  version_val=$(fm_field "$skill_file" '.version')
  if echo "$version_val" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    pass "version is valid semver: $version_val"
  else
    fail "version" "Expected semver, got: $version_val"
  fi

  # 8. Referenced convention files in ## References exist
  if grep -q '^## References' "$skill_file"; then
    while IFS= read -r ref_line; do
      ref_path=$(echo "$ref_line" | grep -oE 'conventions/[a-z-]+\.md' || true)
      if [ -n "$ref_path" ] && [ -f "$REPO_ROOT/$ref_path" ]; then
        pass "Reference exists: $ref_path"
      elif [ -n "$ref_path" ]; then
        fail "Reference" "File not found: $ref_path"
      fi
    done < <(grep -A 20 '^## References' "$skill_file" | grep 'conventions/')
  fi
done

# --- Cross-skill checks ---

echo ""
echo "--- Cross-skill checks ---"

# 9. No duplicate skill names
dupes=$(printf '%s\n' "${skill_names[@]}" | sort | uniq -d)
if [ -z "$dupes" ]; then
  pass "No duplicate skill names"
else
  fail "Duplicate names" "$dupes"
fi

# 10. Expected skill count
skill_count=${#skill_names[@]}
if [ "$skill_count" -ge 9 ]; then
  pass "Skill count: $skill_count (expected ≥9)"
else
  fail "Skill count" "Only $skill_count skills found (expected ≥9)"
fi

summary "Skill Validation"
