# ago

`ago` is a lightweight set of agent workflows for retrospective audit, structured research, documentation review, ADR capture, and audit-driven remediation.

It is designed as one product with platform-specific adapters:
- Claude installs `ago` as a marketplace plugin with `ago:*` commands
- Codex installs `ago` as a native skill set with `ago-*` scenarios

All workflows operate directly on the project you are in. There is no required `.workflow/` directory and no extra runtime service to install.

## Workflows

### Audit

Run a multi-angle retrospective review of recent project work. The workflow inspects git history, recent changes, and documentation context, then produces a consolidated audit report with actionable findings.

Artifact: `docs/audit/YYYY-MM-DD-audit.md`

### Research

Run a structured research session on a technical topic. The workflow combines project context, codebase analysis, and external research, then saves a reusable research artifact.

Artifact: `docs/research/YYYY-MM-DD-{topic}.md`

### Audit Docs

Check project documentation against ADRs and current code. The workflow identifies stale docs, missing docs, outdated statements, and ADR consistency issues.

Artifact: `docs/audit/YYYY-MM-DD-docs.md`

### Write ADR

Capture a decision from the current conversation as an ADR with explicit user approval before writing it.

Artifact: `docs/adr/NNN-{title}.md`

### Fix Audit

Take an existing audit report, group findings by dependency, plan fixes, and execute them through agents with review gates.

Artifacts: draft PRs, ADRs when needed, and an updated audit report

## Install

### Claude

```text
/plugin marketplace add eyev0/ago
/plugin install ago@ago
```

Detailed guide: [docs/install/claude.md](docs/install/claude.md)

### Codex

```text
Fetch and follow instructions from https://raw.githubusercontent.com/eyev0/ago/main/.codex/INSTALL.md
```

Detailed guide: [docs/install/codex.md](docs/install/codex.md)

## Verify

After installation, start a fresh session and invoke one of the platform-native entry points:

- Claude: `ago:audit`, `ago:research`, `ago:audit-docs`, `ago:write-adr`, `ago:fix-audit`
- Codex: `ago-audit`, `ago-research`, `ago-audit-docs`, `ago-write-adr`, `ago-fix-audit`

## Updating

- Claude updates through the plugin marketplace flow
- Codex refreshes through the documented skill install/update flow

Codex currently uses native skill installation rather than a plugin marketplace, so the update path is a managed reinstall of the `ago-*` skills, not a marketplace auto-update.

## License

MIT
