# Installing ago for Codex

Install `ago` through Codex's native skills ecosystem. Do not use manual local repository wiring.

## Canonical Command

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

## Install

Use the canonical command above. It removes any installed `ago-*` copy first, then installs the current `main` branch from `eyev0/ago`.

If you need the explicit repo paths, the install target set is:

- `codex/skills/ago-audit`
- `codex/skills/ago-research`
- `codex/skills/ago-audit-docs`
- `codex/skills/ago-write-adr`
- `codex/skills/ago-fix-audit`

These install the full `ago` working set for Codex.

## Refresh / Update

Use the same canonical command again. The delete step is intentional: the current installer aborts if the destination directory already exists.

After reinstalling, restart Codex if needed so it reloads the updated skills.

## Verify

Confirm that these installed skill directories exist in the Codex skills directory and are available for explicit use:

- `ago-audit`
- `ago-research`
- `ago-audit-docs`
- `ago-write-adr`
- `ago-fix-audit`
