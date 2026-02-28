# Claude Code Integration

How to install and use the `ago:` workflow plugin with Claude Code.

## Install

### From GitHub

```
/plugin marketplace add eyev/claude-workflow
/plugin install ago@claude-workflow
```

### From a local clone

```bash
git clone https://github.com/eyev/claude-workflow.git
```

Then in Claude Code:

```
/plugin marketplace add ./path/to/claude-workflow
/plugin install ago@claude-workflow
```

### Installation scopes

When installing via the `/plugin` UI, you can choose:

- **User scope** (default) — available across all projects
- **Project scope** — shared with collaborators (adds to `.claude/settings.json`)
- **Local scope** — only for you in this repo

### Verify

Run `/plugin` and check the **Installed** tab — `ago` should appear.

## First-time setup

In your target project:

```
/ago:readiness          # Scan project, create .workflow/
/ago:bootstrap          # Capture product brief and role mandates
```

### Optional: add to project CLAUDE.md

```markdown
## Agent Workflow

This project uses the `ago:` workflow plugin.
Project workflow files: `.workflow/`
```

## Commands

All commands use the `ago:` prefix:

| Command | Description |
|---------|-------------|
| `ago:readiness` | Scan project, recommend roles, create `.workflow/` |
| `ago:bootstrap` | Capture product brief and role mandates |
| `ago:clarify` | Clarify requirements, decompose into tasks |
| `ago:execute` | Launch agents for planned tasks |
| `ago:review` | Consolidate results, evaluate quality |
| `ago:status` | Show current project state |
| `ago:timeline` | Generate/update Mermaid Gantt timeline |

## Skills

Skills are invoked by agents during execution (not directly by users):

| Skill | Purpose |
|-------|---------|
| `ago:write-raw-log` | Log agent work |
| `ago:create-task` | Create task files |
| `ago:update-task-status` | Transition task status |
| `ago:create-decision-record` | Generate DRs |
| `ago:consolidate-logs` | Merge agent logs |
| `ago:generate-timeline` | Build Mermaid Gantt |
| `ago:update-registry` | Rebuild entity index |
| `ago:validate-docs-integrity` | Check doc references |
| `ago:evaluate-quality-gate` | Assess quality tier |

## Mapping

| Workflow Concept | Claude Code Entity |
|-----------------|-------------------|
| Role | Agent definition (via plugin `agents/` directory) |
| Skill | `ago:{skill-name}` (from `skills/{skill-name}/SKILL.md`) |
| Command | `ago:{command}` (from `commands/{command}.md`) |
| Master Session | Main conversation running `ago:execute` |
| Agent Logs | `.workflow/log/{role}/*.md` |

## Hooks

The plugin includes SubagentStop hooks that automatically verify agent work:

- **verify-and-log.sh** — deterministic check: artifacts exist, acceptance criteria met
- **evaluate-and-log.sh** — LLM evaluation via `claude -p haiku` (80% completeness threshold)

Both run in parallel when any agent subprocess finishes. Failed verification blocks the agent for retry (max 3 attempts). Verification logs are written to `.workflow/log/{role}/`.
