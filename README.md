# Claude Workflow

Universal conventions for orchestrating AI agents across software projects.

## What Is This?

A system of rules, templates, and agent definitions that standardize how AI agents (Claude Code, Codex) work together on projects. It defines:

- **Roles** — 12 specialized agent roles (Product Manager, Architect, Developer, etc.)
- **Conventions** — Naming, file structure, task lifecycle, decision records, logging
- **Templates** — Standardized formats for tasks, epics, DRs, project docs
- **Skills** — Shared capabilities any agent can invoke
- **Commands** — User-facing slash commands
- **Master Session** — Orchestrator that coordinates all agent work

## Quick Start

1. Add `.workflow/` directory to your project (copy from `templates/`)
2. Reference this repo in your project's CLAUDE.md
3. Start a master session and use `/status` to begin

## Structure

```
conventions/   — Rules and standards
templates/     — File templates for projects
agents/        — Agent role definitions
skills/        — Shared agent capabilities
commands/      — Slash commands
master-session/ — Master session instructions
platforms/     — Platform-specific adaptations
```

## Applying to a Project

See `conventions/file-structure.md` for the standard `.workflow/` structure.
See `platforms/claude-code.md` for Claude Code integration.
See `platforms/codex.md` for Codex integration.
