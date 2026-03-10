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

Use this canonical command:

```bash
rm -rf "$HOME/.codex/skills/ago-audit" \
       "$HOME/.codex/skills/ago-research" \
       "$HOME/.codex/skills/ago-audit-docs" \
       "$HOME/.codex/skills/ago-write-adr" \
       "$HOME/.codex/skills/ago-fix-audit" && \
python3 "$HOME/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py" \
  --method download \
  --repo eyev0/ago \
  --path codex/skills/ago-audit \
         codex/skills/ago-research \
         codex/skills/ago-audit-docs \
         codex/skills/ago-write-adr \
         codex/skills/ago-fix-audit
```

This uses the preinstalled Codex installer script and refreshes any older installed copy first.

The skill set being installed is:

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

Codex does not currently provide marketplace-style auto-updates for repo-hosted skills. To refresh `ago`, run the same canonical command again.

The delete step is required because the current installer does not overwrite an existing destination directory.

## Uninstall

Remove the installed `ago-*` skill directories from the Codex skills directory, typically `~/.codex/skills/`.

## Known Limitation

`ago` in Codex is intentionally built on native skills. That keeps installation within the current Codex ecosystem, but updates are a managed reinstall rather than a true plugin-marketplace update.
