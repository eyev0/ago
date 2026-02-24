# Codex Integration

How to apply agent workflow conventions to an OpenAI Codex project.

> TODO: Detailed integration pending. This is a stub for Iteration 4.

## Setup

### 1. AGENTS.md

Codex reads `AGENTS.md` at the project root. Include workflow instructions there.

### 2. Role Prompts

Codex uses system prompts for agent roles. Adapt agent definitions from `agents/` as system prompts.

### 3. Task Management

Codex works with files directly. The .workflow/ structure works as-is.

## Key Differences from Claude Code

| Aspect | Claude Code | Codex |
|--------|------------|-------|
| Config file | CLAUDE.md | AGENTS.md |
| Agent definitions | .claude/agents/ | System prompts |
| Slash commands | .claude/commands/ | Not supported natively |
| Hooks | PreToolUse/PostToolUse | Not available |
| Skills | Via instructions | Via system prompt |
