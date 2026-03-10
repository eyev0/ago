# Design: ago Cross-Platform Packaging, Installation, and Rebrand

**Date:** 2026-03-10
**Status:** Approved

## Problem

The repository currently presents `ago` as a Claude-centric plugin under the `claude-workflow` product name.

That creates four problems:

1. **The product identity is wrong.** The repository, README, and install copy imply that the project belongs to the Claude ecosystem, even though the workflows themselves are broader.
2. **The install story is inconsistent across agent platforms.** Claude already has a marketplace-based path, while Codex-style distribution is still described in terms of local repository cloning and symlink wiring in comparable projects.
3. **The current docs expose implementation mechanics instead of product UX.** Human-facing docs should describe how to install and use `ago`, not how to manually assemble local filesystem plumbing.
4. **Codex needs a clean "official" path without pretending it has Claude-style plugins.** The design must use native Codex skill mechanisms that exist today, without inventing a marketplace that does not exist.

## Goals

- Rebrand the repository and top-level documentation around the neutral product name `ago`
- Keep one repository for all agent platforms
- Make Claude installation use the marketplace as the primary and only documented path
- Make Codex installation use the native skills ecosystem via `$skill-installer`
- Remove user-facing instructions that require `git clone`, symlinks, or junctions
- Keep all Codex scenarios namespaced under `ago-`
- Preserve one-product semantics even when Codex installs multiple underlying skills

## Non-Goals

- No attempt to invent a Codex plugin marketplace
- No generator system that derives Claude commands and Codex skills from one source format
- No empty bootstrap skill such as `ago` or `ago-help`
- No support for local-clone installation as a recommended or documented path

## Product Model

`ago` is a single product with two platform adapters:

- **Claude adapter:** a marketplace-installed plugin package
- **Codex adapter:** a branded set of installable skills from the same repository

The product name is always `ago`. Platform-specific distribution details only appear in installation documentation and metadata.

## Distribution Model

### Claude

Claude remains the simplest path:

- Marketplace source name becomes `ago`
- Plugin install target becomes `ago@ago`
- The plugin continues to auto-discover commands from `plugins/ago/commands/`

Human-facing install flow:

```text
/plugin marketplace add eyev0/ago
/plugin install ago@ago
```

### Codex

Codex does not get a fake plugin abstraction. It uses native installable skills.

The Codex distribution is a single branded install set made of five working scenario skills:

- `ago-audit`
- `ago-research`
- `ago-audit-docs`
- `ago-write-adr`
- `ago-fix-audit`

There is no standalone `ago` skill because it would be an empty dispatcher with no user value.

Human-facing install flow in docs is one of:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/eyev0/ago/main/.codex/INSTALL.md
```

or the explicit equivalent:

```text
Use $skill-installer to install the ago skill set from github.com/eyev0/ago
```

The agent-facing `.codex/INSTALL.md` is responsible for instructing Codex to install all five skills from this repository in one install action.

## Important Constraint: Codex Updates

Current Codex skill installation does not behave like a true marketplace package manager. The native installer copies skill directories and aborts if the destination already exists.

That means `ago` can be installed through official Codex skill mechanisms, but it cannot truthfully promise automatic marketplace-style updates today.

The clean documented behavior is:

- install the `ago` skill set through `$skill-installer`
- refresh the `ago` skill set by re-running the Codex install/update instructions
- the agent-facing update path may replace the installed `ago-*` skill directories before reinstalling

This is acceptable because it removes cloning and symlinks while staying within the real Codex ecosystem. The docs must be explicit that Codex uses a native skill install flow, not a plugin marketplace.

## Naming

### Product

- Product name: `ago`
- Repository-facing branding: `ago`

### Claude

- Marketplace package: `ago`
- Plugin install target: `ago@ago`
- Existing command names remain:
  - `ago:audit`
  - `ago:research`
  - `ago:audit-docs`
  - `ago:write-adr`
  - `ago:fix-audit`

### Codex

- Skill names:
  - `ago-audit`
  - `ago-research`
  - `ago-audit-docs`
  - `ago-write-adr`
  - `ago-fix-audit`

This keeps the Claude UX idiomatic for plugins and the Codex UX idiomatic for named skills.

## Documentation Design

### Top-Level README

`README.md` becomes the main human entry point and must be understandable without platform-specific background knowledge.

It should include:

- a neutral overview of `ago`
- the workflow/scenario list
- a short "Install" section with:
  - Claude official install path
  - Codex official install path
- links to detailed install guides for each platform
- no mention of manual clone/symlink setup

### Detailed Install Guides

Add platform-specific install docs:

- `docs/install/claude.md`
- `docs/install/codex.md`

Responsibilities:

- `docs/install/claude.md`
  - marketplace install commands
  - verification
  - update/uninstall notes
- `docs/install/codex.md`
  - agent-facing "fetch and follow" flow
  - explicit `$skill-installer` alternative
  - verification
  - refresh/update behavior for installed `ago-*` skills

### Agent-Facing Install Docs

Add:

- `.codex/INSTALL.md`

This file exists specifically so a user can tell Codex to fetch and execute installation instructions without needing to manually translate repo layout into installer arguments.

## Proposed Repository Layout

The repository remains single-source but gets a clearer split between platform adapters.

```text
README.md
CLAUDE.md
.claude-plugin/
  marketplace.json
plugins/
  ago/
    .claude-plugin/
      plugin.json
    commands/
      audit.md
      research.md
      audit-docs.md
      write-adr.md
      fix-audit.md
.codex/
  INSTALL.md
codex/
  skills/
    ago-audit/
      SKILL.md
    ago-research/
      SKILL.md
    ago-audit-docs/
      SKILL.md
    ago-write-adr/
      SKILL.md
    ago-fix-audit/
      SKILL.md
docs/
  install/
    claude.md
    codex.md
```

### Rationale For The Codex Layout

`codex/skills/` is intentionally separate from `plugins/ago/commands/`.

Reasons:

- Claude commands and Codex skills are similar in intent but not identical in packaging or invocation semantics
- keeping Codex assets under a dedicated root makes install paths obvious for `$skill-installer`
- the repo stays understandable for both humans and agents
- future Codex-specific assets can live next to the skills without polluting Claude plugin structure

## Codex Installation Semantics

The Codex install instructions should install multiple repo paths in one action from the same repository ref.

Conceptually:

```text
owner/repo: eyev0/ago
paths:
- codex/skills/ago-audit
- codex/skills/ago-research
- codex/skills/ago-audit-docs
- codex/skills/ago-write-adr
- codex/skills/ago-fix-audit
```

This preserves "install ago" as a product concept while remaining faithful to how Codex skills are actually installed.

## Content Strategy For Codex Skills

Each Codex skill should correspond to one working scenario and map cleanly to the existing Claude command semantics.

The expected relationship is:

| Claude command | Codex skill |
|---|---|
| `ago:audit` | `ago-audit` |
| `ago:research` | `ago-research` |
| `ago:audit-docs` | `ago-audit-docs` |
| `ago:write-adr` | `ago-write-adr` |
| `ago:fix-audit` | `ago-fix-audit` |

The first pass should prioritize semantic consistency over perfect source deduplication. Some duplication between Claude markdown commands and Codex `SKILL.md` files is acceptable.

## User Experience

### Human Reader

The user should understand `ago` from the README alone:

- what it does
- what workflows exist
- how to install it in Claude
- how to install it in Codex
- where to go for details

### Agent Reader

The agent should be able to perform Codex installation from `.codex/INSTALL.md` without asking the user to manually clone a repository or create symlinks.

## Migration

The rebrand should remove or rewrite:

- references to `claude-workflow` as the product name
- install examples using `ago@claude-workflow`
- README text that frames the project as Claude-only
- any user-facing clone/symlink instructions

The migration does not require moving the existing Claude plugin command files out of `plugins/ago/`.

## Files Expected To Change

- `README.md`
- `CLAUDE.md`
- `.claude-plugin/marketplace.json`
- `plugins/ago/.claude-plugin/plugin.json`
- `.codex/INSTALL.md`
- `docs/install/claude.md`
- `docs/install/codex.md`
- `codex/skills/ago-audit/SKILL.md`
- `codex/skills/ago-research/SKILL.md`
- `codex/skills/ago-audit-docs/SKILL.md`
- `codex/skills/ago-write-adr/SKILL.md`
- `codex/skills/ago-fix-audit/SKILL.md`

## Recommended Next Step

Create an implementation plan that:

1. rewrites product-facing docs around `ago`
2. updates Claude marketplace metadata to `ago@ago`
3. adds Codex install docs
4. creates the Codex `ago-*` skill set
5. defines a truthful Codex refresh/update path that avoids `git clone` and symlinks
