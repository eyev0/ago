# TODO / Implementation Status

## Iteration 1 — Foundation (DONE)

| Item | Status | Files |
|------|--------|-------|
| Repo + directory structure | done | `.gitignore` |
| Core conventions (9 files) | done | `conventions/*.md` |
| Templates (12 files) | done | `templates/**/*.md` |
| Agent definitions (12 roles) | done | `agents/*.md` |
| Skill definitions (9 skills) | done | `skills/*.md` |
| Command stubs (6 commands) | done | `commands/*.md` |
| Master-session instructions | done | `master-session/*.md` |
| README, CLAUDE.md, AGENTS.md | done | root `*.md` |
| Platform guides | done | `platforms/*.md` |
| Applied to Shepni (.workflow/) | done | `shepni/.workflow/` |
| Symlinks in Shepni .claude/agents/ | done | machine-local, not committed |

## Iteration 2 — Activate on Real Tasks

| Item | Status | Notes |
|------|--------|-------|
| Implement `/status` command | TODO | Read registry + status.md, display summary |
| Implement `/delegate` command | TODO | Clarify task → decompose → create task.md → launch agents |
| Implement `/review` command | TODO | Read agent logs → consolidate → create DR → present |
| Implement `/timeline` command | TODO | Parse task frontmatter → generate Mermaid Gantt |
| Create `write-raw-log` as Claude Code skill | TODO | Convert from doc to executable skill |
| Create `create-task` as Claude Code skill | TODO | Convert from doc to executable skill |
| Create `update-task-status` as Claude Code skill | TODO | Convert from doc to executable skill |
| Create `evaluate-quality-gate` as Claude Code skill | TODO | T1-T4 tier evaluation |
| Test full workflow on Shepni STT Phase 2 (VAD) | TODO | First real end-to-end test |
| Setup script for symlinks after clone | TODO | `scripts/setup.sh` or Makefile target |

## Iteration 3 — Automation & Hooks

| Item | Status | Notes |
|------|--------|-------|
| Claude Code hooks for auto-logging | TODO | PreToolUse/PostToolUse → write to log files |
| Master session as skill/plugin | TODO | Package the orchestration flow |
| Implement `/collaborative` mode switch | TODO | Already default, needs explicit toggle |
| Implement `/autonomous` mode | TODO | Master reads backlog, executes without approval |
| CONS agent as periodic process | TODO | Run after each task batch, validate integrity |
| Validate docs integrity as CI check | TODO | Pre-commit hook or GH Action |

## Iteration 4 — Platform Expansion & Infra

| Item | Status | Notes |
|------|--------|-------|
| Codex (AGENTS.md) full integration | TODO | Map skills/agents to Codex model |
| Self-hosted git (Gitea/Forgejo) | TODO | Spare laptop as personal server |
| VPN/tunnel to hub server | TODO | Access from any device |
| Obsidian vault sync | TODO | Tasks + docs visualization with Dataview/Tasks plugins |
| Cross-project task management | TODO | Tasks spanning multiple repos |

## Open Questions

1. Can Claude Code hooks reliably write to log files during subagent execution?
2. How to map skills/agents to Codex's execution model?
3. Should CONS be periodic (cron) or on-demand (after each task)?
4. Which Obsidian plugins best visualize Gantt + task dependencies?
5. How to handle git symlinks cross-platform (macOS/Linux)?
