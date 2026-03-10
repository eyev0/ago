# Install ago in Codex

Codex installs `ago` as a native skill set, not as a plugin marketplace package. The installed scenarios are:

- `ago-audit`
- `ago-research`
- `ago-audit-docs`
- `ago-write-adr`
- `ago-fix-audit`

## Quick Install

Tell Codex:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/eyev0/ago/main/.codex/INSTALL.md
```

## Explicit Install

Use the preinstalled `$skill-installer` to install these skill directories from `eyev0/ago`:

- `codex/skills/ago-audit`
- `codex/skills/ago-research`
- `codex/skills/ago-audit-docs`
- `codex/skills/ago-write-adr`
- `codex/skills/ago-fix-audit`

The install source is one repository, but Codex receives five working scenario skills.

## Verify

Restart Codex if needed, then confirm these skills are available:

- `ago-audit`
- `ago-research`
- `ago-audit-docs`
- `ago-write-adr`
- `ago-fix-audit`

## Refresh / Update

Codex does not currently provide marketplace-style auto-updates for repo-hosted skills. To refresh `ago`, re-run the documented install/update flow for the same five skill paths.

If the existing installed `ago-*` skill directories block reinstall, remove those installed copies first and then reinstall the same set.

## Uninstall

Remove the installed `ago-*` skill directories from the Codex skills directory, typically `~/.codex/skills/`.

## Known Limitation

`ago` in Codex is intentionally built on native skills. That keeps installation within the current Codex ecosystem, but updates are a managed reinstall rather than a true plugin-marketplace update.
