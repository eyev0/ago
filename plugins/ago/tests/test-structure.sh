#!/bin/bash
set -euo pipefail

# Test Module 3: Plugin Structure & Cross-Reference Integrity
# Validates manifest, command metadata, role→agent mappings, skill references, and portability

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib/frontmatter.sh"
check_yq

echo "=== Plugin Structure Tests ==="

# --- Manifest checks ---

echo ""
echo "--- Manifest ---"

MANIFEST="$REPO_ROOT/.claude-plugin/plugin.json"

# 1. plugin.json exists and is valid JSON
if [ -f "$MANIFEST" ] && jq . "$MANIFEST" >/dev/null 2>&1; then
  pass "plugin.json exists and is valid JSON"
else
  fail "plugin.json" "Missing or invalid JSON"
fi

# 2. name field exists
manifest_name=$(jq -r '.name // empty' "$MANIFEST")
if [ -n "$manifest_name" ]; then
  pass "manifest has name: $manifest_name"
else
  fail "manifest name" "Missing name field"
fi

# 3. version field exists
manifest_version=$(jq -r '.version // empty' "$MANIFEST")
if [ -n "$manifest_version" ]; then
  pass "manifest has version: $manifest_version"
else
  fail "manifest version" "Missing version field"
fi

# 4. hooks path points to real file
hooks_path=$(jq -r '.hooks // empty' "$MANIFEST")
if [ -n "$hooks_path" ] && [ -f "$REPO_ROOT/$hooks_path" ]; then
  pass "hooks path resolves: $hooks_path"
else
  fail "hooks path" "File not found: $hooks_path"
fi

# 5. hooks.json is valid JSON
if jq . "$REPO_ROOT/$hooks_path" >/dev/null 2>&1; then
  pass "hooks.json is valid JSON"
else
  fail "hooks.json" "Invalid JSON"
fi

# --- Command checks ---

echo ""
echo "--- Commands ---"

for cmd_file in "$REPO_ROOT"/commands/*.md; do
  cmd_name=$(basename "$cmd_file" .md)

  # 6. Each command has description in frontmatter
  desc_val=$(fm_field "$cmd_file" '.description')
  if [ -n "$desc_val" ] && [ "$desc_val" != "null" ]; then
    pass "command $cmd_name has description"
  else
    fail "command $cmd_name" "Missing description in frontmatter"
  fi
done

# --- Role → Agent mapping ---

echo ""
echo "--- Role → Agent mapping ---"

EXECUTE_CMD="$REPO_ROOT/commands/execute.md"

if [ -f "$EXECUTE_CMD" ]; then
  # Extract agent file references from the role mapping table
  while IFS= read -r line; do
    # Match lines like: | ARCH | `@${CLAUDE_PLUGIN_ROOT}/agents/architect.md` |
    agent_filename=$(echo "$line" | grep -oE 'agents/[a-z-]+\.md' || true)
    role_id=$(echo "$line" | grep -oE '\| [A-Z]+ \|' | head -1 | tr -d '| ' || true)
    if [ -n "$agent_filename" ]; then
      if [ -f "$REPO_ROOT/$agent_filename" ]; then
        pass "Role $role_id → $agent_filename exists"
      else
        fail "Role mapping" "$role_id → $agent_filename not found"
      fi
    fi
  done < <(grep 'agents/' "$EXECUTE_CMD" || true)
else
  fail "execute.md" "Command file not found"
fi

# --- Skill references in master-session ---

echo ""
echo "--- Skill references in master-session ---"

MASTER_AGENT="$REPO_ROOT/agents/master-session.md"

if [ -f "$MASTER_AGENT" ]; then
  while IFS= read -r skill_ref; do
    # Extract skill name like ago:write-raw-log
    skill_name=$(echo "$skill_ref" | grep -oE 'ago:[a-z-]+' || true)
    if [ -n "$skill_name" ]; then
      # Convert ago:write-raw-log → skills/write-raw-log/
      skill_dir_name="${skill_name#ago:}"
      if [ -d "$REPO_ROOT/skills/$skill_dir_name" ] && [ -f "$REPO_ROOT/skills/$skill_dir_name/SKILL.md" ]; then
        pass "Skill $skill_name → skills/$skill_dir_name/SKILL.md exists"
      else
        fail "Skill reference" "$skill_name → skills/$skill_dir_name/ not found"
      fi
    fi
  done < <(grep -oE '`ago:[a-z-]+`' "$MASTER_AGENT" | sort -u || true)
else
  fail "master-session.md" "Agent file not found"
fi

# --- Portability checks ---

echo ""
echo "--- Portability ---"

# 7. No hardcoded absolute paths (except in comments and plan docs)
hardcoded=$(grep -rn '/Users/' "$REPO_ROOT"/{agents,commands,skills,hooks}/ \
  --include='*.md' --include='*.sh' --include='*.json' \
  2>/dev/null | grep -v '^\s*#' | grep -v 'docs/plans/' || true)

if [ -z "$hardcoded" ]; then
  pass "No hardcoded absolute paths in plugin components"
else
  fail "Hardcoded paths" "Found absolute paths: $(echo "$hardcoded" | head -3)"
fi

# 8. All hook scripts use ${CLAUDE_PLUGIN_ROOT} not relative paths
hooks_json="$REPO_ROOT/$hooks_path"
if grep -q 'CLAUDE_PLUGIN_ROOT' "$hooks_json"; then
  pass "hooks.json uses \${CLAUDE_PLUGIN_ROOT}"
else
  fail "hooks.json portability" "Should use \${CLAUDE_PLUGIN_ROOT} for script paths"
fi

# --- Directory structure ---

echo ""
echo "--- Directory structure ---"

# 9. Required directories exist
for dir in .claude-plugin agents commands skills hooks; do
  if [ -d "$REPO_ROOT/$dir" ]; then
    pass "Directory exists: $dir/"
  else
    fail "Directory" "Missing: $dir/"
  fi
done

# 10. No orphan .md files in commands/ without frontmatter
for cmd_file in "$REPO_ROOT"/commands/*.md; do
  if ! head -1 "$cmd_file" | grep -q '^---$'; then
    fail "Orphan command" "$(basename "$cmd_file") has no YAML frontmatter"
  fi
done

summary "Plugin Structure"
