# CLAUDE.md

Claude-facing notes for the `ago` plugin marketplace repository.

For canonical install, update, and usage instructions, see `README.md`.
For the minimal cross-agent repository overview, see `AGENTS.md`.

This repository contains the marketplace source and command definitions for the `ago` plugin under `plugins/ago/`.
This plugin is intended for Codex-compatible agent workflows only.

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
