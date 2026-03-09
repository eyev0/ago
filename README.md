# ago — Lightweight Audit & Research for Claude Code

Three commands that give your project multi-angle code review, structured research, and documentation auditing — all working directly with your existing `docs/` directory.

## Install

```
/plugin marketplace add eyev0/claude-workflow
/plugin install ago@claude-workflow
```

## Commands

### `ago:audit`

Multi-role retrospective review. Four agents (ARCH, SEC, QAL, PM) analyze recent git commits from different angles. Produces a consolidated report with action items and proposes ADRs for architectural decisions found in the code.

```
ago:audit              # review since last audit
ago:audit 20           # review last 20 commits
ago:audit abc123..def456  # review specific range
```

Output: `docs/audit/YYYY-MM-DD-audit.md`

### `ago:research`

Structured research session. Formulates questions, researches using code analysis and web search, produces a persistent artifact.

```
ago:research CoreML acceleration for Parakeet TDT
ago:research migrating from SQLite to PostgreSQL
```

Output: `docs/research/YYYY-MM-DD-{topic}.md`

### `ago:audit-docs`

Documentation audit using ADRs as source of truth. Finds stale, missing, and outdated documentation, proposes fixes, and generates a report with action items.

```
ago:audit-docs                    # audit all docs
ago:audit-docs docs/README.md     # audit specific file
```

Output: `docs/audit/YYYY-MM-DD-docs.md`

## No Dependencies

- No `.workflow/` directory
- No agent definitions or role files
- No skills, hooks, or conventions
- Works with any project that has documentation files
- Commands are self-contained markdown instructions

## License

MIT
