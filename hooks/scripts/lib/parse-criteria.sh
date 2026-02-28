#!/bin/bash
# ago: Shared criteria-parsing functions for hook scripts
#
# Source this file from hook scripts:
#   source "$(dirname "$0")/lib/parse-criteria.sh"
#
# Functions:
#   parse_criteria <task_file>  — extract acceptance criteria lines
#   strip_criterion <line>      — normalize a criterion line to plain text

# parse_criteria — extract acceptance criteria from a task.md file
#
# Strategy: try YAML frontmatter first, fall back to markdown body.
# This is needed because ago:create-task writes criteria as checkboxes
# in the markdown body (per templates/task.md), not in YAML frontmatter.
#
# Outputs one criterion per line to stdout. Empty output = no criteria found.
#
# Source 1: YAML frontmatter list items
#   Matches lines like "  - Implement the auth module" inside the
#   acceptance_criteria: block between the first pair of "---" fences.
#   Regex: /^  - / (two-space indent, dash, space)
#   Stops when a line doesn't match the indent pattern (end of list).
#
# Source 2: Markdown body checkboxes
#   Matches lines like "- [ ] Implement the auth module" or "- [x] Done"
#   under the "## Acceptance Criteria" heading, stopping at the next heading.
#   Regex: /^- \[.\] / (dash, space, bracket, any char, bracket, space)
#   The dot in \[.\] matches any checkbox state: space (unchecked), x (checked),
#   or any other single character. This is intentional — we evaluate all criteria
#   regardless of their checked/unchecked visual state.
#
parse_criteria() {
  local task_file="$1"

  # Try YAML frontmatter first
  local criteria
  criteria=$(awk '
    /^---$/ { n++; next }
    n==1 && /acceptance_criteria:/ { found=1; next }
    found && /^  - / { print; next }
    found && !/^  -/ { found=0 }
  ' "$task_file")

  # Fallback: parse "## Acceptance Criteria" section checkboxes
  if [ -z "$criteria" ]; then
    criteria=$(awk '
      /^## Acceptance Criteria/ { found=1; next }
      found && /^## /           { exit }
      found && /^- \[.\] /      { print }
    ' "$task_file")
  fi

  printf '%s' "$criteria"
}

# strip_criterion — normalize a criterion line to plain text
#
# Strips both formats:
#   YAML frontmatter: "  - Implement auth"  →  "Implement auth"
#   Markdown body:    "- [ ] Implement auth" →  "Implement auth"
#                     "- [x] Done item"      →  "Done item"
#
# The sed expression chains two substitutions:
#   s/^  - //       — strip leading "  - " (frontmatter format)
#   s/^- \[.\] //   — strip leading "- [.] " (body checkbox, any state)
# Only one will match per line; the other is a no-op.
#
strip_criterion() {
  echo "$1" | sed 's/^  - //; s/^- \[.\] //'
}
