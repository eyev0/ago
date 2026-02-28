#!/bin/bash
set -euo pipefail

# Test Module 2: Agent Metadata & Triggering Validation
# Validates frontmatter fields, naming, colors, models, example blocks, and tools

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib/frontmatter.sh"
check_yq

echo "=== Agent Validation Tests ==="

AGENTS_DIR="$REPO_ROOT/agents"
VALID_COLORS="blue|cyan|green|yellow|magenta|red"
VALID_MODELS="inherit|sonnet|opus|haiku"
agent_names=()

for agent_file in "$AGENTS_DIR"/*.md; do
  agent_basename=$(basename "$agent_file")

  echo ""
  echo "--- $agent_basename ---"

  # 1. name field exists, 3-50 chars, kebab-case
  name_val=$(fm_field "$agent_file" '.name')
  if [ -n "$name_val" ] && [ "$name_val" != "null" ]; then
    name_len=${#name_val}
    if [ "$name_len" -ge 3 ] && [ "$name_len" -le 50 ] && echo "$name_val" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$'; then
      pass "name is valid: $name_val ($name_len chars)"
    else
      fail "name format" "'$name_val' — must be 3-50 chars, kebab-case, start/end alphanumeric"
    fi
  else
    fail "name field" "Missing or null"
  fi

  agent_names+=("$name_val")

  # 2. description exists and is non-empty
  desc_val=$(fm_field "$agent_file" '.description')
  if [ -n "$desc_val" ] && [ "$desc_val" != "null" ]; then
    pass "description field exists"
  else
    fail "description field" "Missing or null"
    continue
  fi

  # 3. description contains at least one <example> block
  if echo "$desc_val" | grep -q '<example>'; then
    example_count=$(echo "$desc_val" | grep -c '<example>' || true)
    pass "description has $example_count <example> block(s)"
  else
    fail "example blocks" "No <example> block found in description"
  fi

  # 4. each <example> has user, assistant, commentary
  if echo "$desc_val" | grep -q '<example>'; then
    has_user=$(echo "$desc_val" | grep -c 'user:' || true)
    has_assistant=$(echo "$desc_val" | grep -c 'assistant:' || true)
    has_commentary=$(echo "$desc_val" | grep -c '<commentary>' || true)
    if [ "$has_user" -gt 0 ] && [ "$has_assistant" -gt 0 ] && [ "$has_commentary" -gt 0 ]; then
      pass "examples have user/assistant/commentary structure"
    else
      fail "example structure" "Missing user ($has_user), assistant ($has_assistant), or commentary ($has_commentary)"
    fi
  fi

  # 5. model is valid
  model_val=$(fm_field "$agent_file" '.model')
  if echo "$model_val" | grep -qE "^($VALID_MODELS)$"; then
    pass "model is valid: $model_val"
  else
    fail "model" "Expected one of [$VALID_MODELS], got: $model_val"
  fi

  # 6. color is valid
  color_val=$(fm_field "$agent_file" '.color')
  if echo "$color_val" | grep -qE "^($VALID_COLORS)$"; then
    pass "color is valid: $color_val"
  else
    fail "color" "Expected one of [$VALID_COLORS], got: $color_val"
  fi

  # 7. tools field is non-empty
  tools_val=$(fm_field "$agent_file" '.tools')
  if [ -n "$tools_val" ] && [ "$tools_val" != "null" ]; then
    pass "tools field exists"
  else
    fail "tools field" "Missing or null"
  fi

  # 8. body exists after closing frontmatter
  # Count lines after the second ---
  body_lines=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{count++} END{print count+0}' "$agent_file")
  if [ "$body_lines" -gt 5 ]; then
    pass "body exists ($body_lines lines)"
  else
    fail "body content" "Only $body_lines lines after frontmatter (expected >5)"
  fi
done

# --- Cross-agent checks ---

echo ""
echo "--- Cross-agent checks ---"

# 9. No duplicate agent names
dupes=$(printf '%s\n' "${agent_names[@]}" | sort | uniq -d)
if [ -z "$dupes" ]; then
  pass "No duplicate agent names"
else
  fail "Duplicate names" "$dupes"
fi

# 10. Expected agent count
agent_count=${#agent_names[@]}
if [ "$agent_count" -ge 13 ]; then
  pass "Agent count: $agent_count (expected ≥13)"
else
  fail "Agent count" "Only $agent_count agents found (expected ≥13)"
fi

# 11. Color diversity — at least 4 distinct colors used
colors_used=$(for f in "$AGENTS_DIR"/*.md; do fm_field "$f" '.color'; done | sort -u | wc -l | tr -d ' ')
if [ "$colors_used" -ge 4 ]; then
  pass "Color diversity: $colors_used distinct colors used"
else
  fail "Color diversity" "Only $colors_used colors — agents will look too similar"
fi

summary "Agent Validation"
