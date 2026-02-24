# Claude Code Integration

How to apply agent workflow conventions to a Claude Code project.

## Setup

### 1. Install the Plugin

The `claude-workflow` repo is a Claude Code plugin with `.claude-plugin/plugin.json`.

```bash
# From your project directory, add as a plugin:
claude plugin add ~/dev/claude-workflow
```

This makes all `ago:` prefixed commands and skills available in your project.

### 2. Project CLAUDE.md

Add to your project's CLAUDE.md:

```markdown
## Agent Workflow

This project uses the agent workflow plugin (`ago:`).

When working as a master session:
- Read the master-session instructions via the plugin
- Follow the session lifecycle

When working as a role agent:
- Read your role definition from the plugin agents
- Always invoke `ago:write-raw-log` skill after work

Project workflow files: `.workflow/`
```

### 3. Skills

Skills live in subdirectories: `skills/skill-name/SKILL.md`

They are invoked with the `ago:` prefix (e.g., `ago:write-raw-log`, `ago:evaluate-quality-gate`).

### 4. Commands

Available commands (all prefixed with `ago:`):

| Command | Description |
|---------|-------------|
| `ago:status` | Show project status |
| `ago:readiness` | Check agent readiness |
| `ago:clarify` | Clarify and formulate a task |
| `ago:execute` | Execute a formulated task |
| `ago:review` | Review agent work results |
| `ago:timeline` | Generate/update timeline |

### 5. Initialize .workflow/

```bash
mkdir -p .workflow/{docs,epics,decisions,log/master}
cp ~/dev/claude-workflow/templates/config.md .workflow/config.md
cp ~/dev/claude-workflow/templates/registry.md .workflow/registry.md
cp ~/dev/claude-workflow/templates/project-docs/*.md .workflow/docs/
```

## Mapping

| Workflow Entity | Claude Code Entity |
|----------------|-------------------|
| Role | Agent definition via plugin |
| Skill | `ago:{skill-name}` (from `skills/{skill-name}/SKILL.md`) |
| Command | `ago:{command}` (from plugin commands) |
| Master Session | Main conversation with CLAUDE.md context |
| Agent Logs | `.workflow/log/{ROLE}/*.md` |

## Hooks (Future)

Claude Code supports hooks: PreToolUse, PostToolUse, Stop, SessionStart, SessionEnd.
Potential for automated logging via PostToolUse hook.

> TODO: Implement logging hooks in Iteration 3
