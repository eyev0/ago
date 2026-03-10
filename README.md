# ago — Lightweight Audit & Research for Claude Code

Five commands that give your project multi-angle code review, structured research, documentation auditing, ADR capture, and automated fix execution — all working directly with your existing `docs/` directory.

## Install

```
/plugin marketplace add eyev0/claude-workflow
/plugin install ago@claude-workflow
```

## Publishing Updates

Claude Code resolves plugin updates from the marketplace Git repository, not from GitHub Releases.

Author workflow:

1. Update `plugins/ago/.claude-plugin/plugin.json` and bump `version`.
2. Commit and push to `master` in `eyev0/claude-workflow`.
3. Optional: create a GitHub Release or tag for changelog/distribution hygiene. Claude Code does not require it for plugin updates.

User update flow:

1. Claude Code refreshes marketplace sources in the background on startup.
2. After the marketplace refresh sees a newer plugin `version`, Claude Code can update the installed plugin.
3. For an immediate refresh without restarting Claude Code, run:

```
/plugin marketplace update claude-workflow
/plugin update ago@claude-workflow
```

Notes:

- `marketplace update` refreshes the local cached copy of the marketplace repo.
- `plugin update` refreshes the installed plugin from that cached marketplace state.
- Bumping `version` in `plugin.json` is required. If the version does not change, Claude Code will keep the currently installed copy.

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

### `ago:write-adr`

Captures an architectural decision from the current conversation as an ADR with status "To Review".

```
ago:write-adr                    # infer topic from conversation
ago:write-adr Migrate to Rust    # hint for ADR title
```

Output: `docs/adr/NNN-{title}.md`

### `ago:fix-audit`

Parses an audit report, groups action items by dependency, plans fixes via parallel agents, executes in worktrees with ADR generation and draft PRs.

```
ago:fix-audit docs/audit/2026-03-10-audit.md
```

Output: draft PRs, ADRs, updated audit report with resolved items marked.

## No Dependencies

- No `.workflow/` directory
- No agent definitions or role files
- No built-in skills, hooks, or conventions required
- Works with any project that has a `docs/` directory
- Commands are self-contained markdown instructions

## License

MIT
