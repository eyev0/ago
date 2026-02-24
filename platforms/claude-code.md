# Claude Code Integration

How to apply agent workflow conventions to a Claude Code project.

## Setup

### 1. Project CLAUDE.md

Add to your project's CLAUDE.md:

```markdown
## Agent Workflow

This project uses the agent workflow system from `~/dev/claude-workflow/`.

When working as a master session:
- Read `~/dev/claude-workflow/master-session/instructions.md`
- Follow the session lifecycle

When working as a role agent:
- Read your role definition from `~/dev/claude-workflow/agents/{role}.md`
- Always invoke `write-raw-log` skill after work

Project workflow files: `.workflow/`
```

### 2. Agent Definitions

Copy or symlink agent files to `.claude/agents/`:
```bash
# Option A: Symlink (always up to date)
ln -s ~/dev/claude-workflow/agents/*.md .claude/agents/

# Option B: Copy (project-independent)
cp ~/dev/claude-workflow/agents/*.md .claude/agents/
```

### 3. Skills

Skills are invoked by agents via instructions (not as separate files in Claude Code).
They are embedded in agent system prompts or as part of commands.

### 4. Commands

Copy command stubs to `.claude/commands/`:
```bash
cp ~/dev/claude-workflow/commands/*.md .claude/commands/workflow.*.md
```

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
| Role | `.claude/agents/{role}.md` |
| Skill | Instructions in agent prompt / command |
| Command | `.claude/commands/{cmd}.md` |
| Master Session | Main conversation with CLAUDE.md context |
| Agent Logs | `.workflow/log/{ROLE}/*.md` |

## Hooks (Future)

Claude Code supports hooks: PreToolUse, PostToolUse, Stop, SessionStart, SessionEnd.
Potential for automated logging via PostToolUse hook.

> TODO: Implement logging hooks in Iteration 3
