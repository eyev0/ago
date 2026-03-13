# CLAUDE.md

Claude-facing notes for the `ago` marketplace package.

For the canonical product overview and cross-platform install paths, see `README.md`.

This repository contains the Claude marketplace source and command definitions for the `ago` plugin under `plugins/ago/`.

## Install

```text
/plugin marketplace add eyev0/ago
/plugin install ago@ago
```

## Commands

| Command | Description |
|---------|-------------|
| `ago:audit` | Multi-role retrospective review (ARCH/SEC/QAL/PM) from git history + docs |
| `ago:research` | Structured research session with persistent artifact in `docs/research/` |
| `ago:audit-docs` | Audit documentation against ADRs and current code, generate action items |
| `ago:write-adr` | Capture an architectural decision from current conversation as ADR (To Review) |
| `ago:review-plan` | Multi-role review of an implementation plan before execution |
All commands are self-contained. No `.workflow/` directory, no agent definitions, and no external runtime dependencies. They work with any project that has a `docs/` directory.

## Output

- `docs/audit/YYYY-MM-DD-audit.md` — code/architecture audit report with action items
- `docs/audit/YYYY-MM-DD-docs.md` — documentation audit report with action items
- `docs/research/YYYY-MM-DD-{topic}.md` — research artifact
- `docs/adr/NNN-{title}.md` — ADRs proposed by audit/research/write-adr (written with user approval)
- `docs/plans/*.{arch,sec,qal,pm}-review.md` — per-role implementation plan review artifacts
- `docs/plans/*.review-index.md` — consolidated review summary index
- `docs/.last-audit` — git SHA bookmark for incremental audits
