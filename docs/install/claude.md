# Install ago in Claude

This installs the Claude marketplace adapter for `ago`. After installation, Claude exposes these commands:

- `ago:audit`
- `ago:research`
- `ago:audit-docs`
- `ago:write-adr`
- `ago:fix-audit`

## Install

```text
/plugin marketplace add eyev0/ago
/plugin install ago@ago
```

## Verify

Start a fresh Claude session and confirm the `ago:*` commands are available. A simple smoke test is to invoke `ago:research` with a short topic and confirm the command starts normally.

## Update

```text
/plugin marketplace update ago
/plugin update ago@ago
```

If the marketplace source was already refreshed by Claude, `plugin update` is usually enough.

## Uninstall

```text
/plugin uninstall ago@ago
```
