# AGENTS.md — For Codex and Non-Claude AI Systems

This file provides equivalent instructions to CLAUDE.md for OpenAI Codex and other AI systems.

## Overview

This repository defines an agent workflow system. You may be operating as one of 12 roles
(see `agents/` directory) or as a master session (see `master-session/`).

## Key Rules

1. Follow your role definition in `agents/{your-role}.md`
2. Log all work to `.workflow/log/{ROLE}/{YYYY-MM-DD}.md`
3. Use templates from `templates/` when creating new files
4. Follow naming conventions from `conventions/naming.md`
5. Never modify files outside your role's scope

## Conventions

Read these files for the full rule set:
- `conventions/roles.md` — Role definitions and boundaries
- `conventions/task-lifecycle.md` — Task statuses and transitions
- `conventions/naming.md` — File and entity naming
- `conventions/file-structure.md` — Project .workflow/ structure
- `conventions/logging.md` — Logging format and rules
