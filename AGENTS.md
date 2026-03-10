# AGENTS.md

Agent-facing instructions for the `ago` plugin marketplace repository. Keep this file aligned with `CLAUDE.md` when command inventory, install flow, or update flow changes.

## Install

```text
/plugin marketplace add eyev0/claude-workflow
/plugin install ago@claude-workflow
```

## Updates

This marketplace is resolved from the GitHub repository itself. A GitHub Release is optional and is not required for plugin updates.

Publish flow:

1. Bump `plugins/ago/.claude-plugin/plugin.json` `version`.
2. Push to `master`.

How users receive it:

1. Claude Code refreshes marketplace sources in the background on startup.
2. If Claude Code is already running and the new version must be visible immediately:

```text
/plugin marketplace update claude-workflow
/plugin update ago@claude-workflow
```

`marketplace update` refreshes the marketplace repo cache. `plugin update` updates the installed plugin from that cache.

## Commands

| Command | Description |
|---------|-------------|
| `ago:audit` | Multi-role retrospective review (ARCH/SEC/QAL/PM) from git history + docs |
| `ago:research` | Structured research session with persistent artifact in `docs/research/` |
| `ago:audit-docs` | Audit documentation against ADRs and current code, generate action items |
| `ago:write-adr` | Capture an architectural decision from current conversation as ADR (To Review) |
| `ago:fix-audit` | Parse audit report, plan + execute fixes via parallel agents in worktrees |

All commands are self-contained. No `.workflow/` directory, no agent definitions, no external dependencies. They work with any project that has a `docs/` directory.

## Output

- `docs/audit/YYYY-MM-DD-audit.md` — code/architecture audit report with action items
- `docs/audit/YYYY-MM-DD-docs.md` — documentation audit report with action items
- `docs/research/YYYY-MM-DD-{topic}.md` — research artifact
- `docs/adr/NNN-{title}.md` — ADRs proposed by audit/research/write-adr (written with user approval)
- `docs/.last-audit` — git SHA bookmark for incremental audits
