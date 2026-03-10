# Installing ago for Codex

Install `ago` through Codex's native skills ecosystem. Do not use manual local repository wiring.

## Install

Use the preinstalled `$skill-installer` skill to install all of these skill directories from `eyev0/ago`:

- `codex/skills/ago-audit`
- `codex/skills/ago-research`
- `codex/skills/ago-audit-docs`
- `codex/skills/ago-write-adr`
- `codex/skills/ago-fix-audit`

These install the full `ago` working set for Codex.

## Refresh / Update

If you are updating an existing installation and any of these installed directories already exist under `$CODEX_HOME/skills` (usually `~/.codex/skills`), replace only the existing `ago-*` installed copies, then reinstall the same five skill directories from `eyev0/ago`.

After reinstalling, restart Codex if needed so it reloads the updated skills.

## Verify

Confirm that these installed skill directories exist in the Codex skills directory and are available for explicit use:

- `ago-audit`
- `ago-research`
- `ago-audit-docs`
- `ago-write-adr`
- `ago-fix-audit`
