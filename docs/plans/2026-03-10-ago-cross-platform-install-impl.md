# ago Cross-Platform Install + Rebrand Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand the repository around `ago`, make the top-level docs platform-neutral, update the Claude marketplace package to `ago@ago`, and add a Codex-native skill distribution with install instructions that avoid `git clone` and symlinks.

**Architecture:** Keep one repository with two platform adapters. Claude continues to use the existing plugin structure under `plugins/ago/`; Codex gets a dedicated `codex/skills/` tree containing one `SKILL.md` per working scenario. Human-facing docs stay in `README.md` and `docs/install/`, while `.codex/INSTALL.md` acts as the agent-facing install entry point.

**Tech Stack:** Markdown documentation, Claude plugin metadata JSON, Codex `SKILL.md` packages, native `$skill-installer` flow.

**Design spec:** `docs/plans/2026-03-10-ago-cross-platform-install-design.md`

---

## File Structure

### Existing files to modify

- `README.md`
- `CLAUDE.md`
- `.claude-plugin/marketplace.json`
- `plugins/ago/.claude-plugin/plugin.json`

### New files to create

- `.codex/INSTALL.md`
- `docs/install/claude.md`
- `docs/install/codex.md`
- `codex/skills/ago-audit/SKILL.md`
- `codex/skills/ago-research/SKILL.md`
- `codex/skills/ago-audit-docs/SKILL.md`
- `codex/skills/ago-write-adr/SKILL.md`
- `codex/skills/ago-fix-audit/SKILL.md`

### Responsibility split

- `README.md` explains the product and routes humans to the right install guide
- `docs/install/*.md` contain detailed per-platform install/update/verify instructions
- `.codex/INSTALL.md` is optimized for agents following fetched instructions
- `codex/skills/*/SKILL.md` map the existing `ago:*` workflows into Codex-native named skills
- marketplace JSON files define the Claude-distribution identity

---

## Chunk 1: Rebrand Product Docs

### Task 1: Rewrite `README.md` as the neutral `ago` entry point

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the opening section**

Rewrite the title and intro so the project is described as `ago`, not as a Claude-only plugin. The first screen should explain:
- `ago` is a lightweight set of agent workflows for audit, research, docs audit, ADR capture, and audit-driven fixes
- it supports multiple agent ecosystems
- platform-specific details live in dedicated install guides

- [ ] **Step 2: Add a neutral scenarios section**

Document these workflows in platform-neutral language:
- `audit`
- `research`
- `audit-docs`
- `write-adr`
- `fix-audit`

Keep the names readable for humans. Claude command and Codex skill spellings can be shown later in platform-specific sections.

- [ ] **Step 3: Rewrite the install section**

Add a short install section with only the official paths:

```text
Claude
/plugin marketplace add eyev0/ago
/plugin install ago@ago

Codex
Fetch and follow instructions from https://raw.githubusercontent.com/eyev0/ago/main/.codex/INSTALL.md
```

Link to:
- `docs/install/claude.md`
- `docs/install/codex.md`

Do not include `git clone`, symlink, or junction instructions.

- [ ] **Step 4: Update update/verification copy**

Describe updates at the product level:
- Claude updates through the plugin system
- Codex refreshes through the documented install/update flow

Avoid claiming marketplace-like auto-update behavior for Codex.

- [ ] **Step 5: Verify README content**

Run:

```bash
rg -n "claude-workflow|git clone|symlink|ln -s|junction" README.md
```

Expected:
- no install instructions using clone/symlink
- no product branding as `claude-workflow`

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README around ago product and install paths"
```

---

### Task 2: Update `CLAUDE.md` product framing

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Rewrite the opening description**

Keep `CLAUDE.md` Claude-specific, but frame it as the Claude adapter for the `ago` product rather than the product itself.

- [ ] **Step 2: Update install commands**

Replace:

```text
/plugin marketplace add eyev0/claude-workflow
/plugin install ago@claude-workflow
```

with:

```text
/plugin marketplace add eyev0/ago
/plugin install ago@ago
```

- [ ] **Step 3: Keep command documentation intact**

Retain the existing `ago:*` command table and output paths. Only adjust surrounding product/install language where needed.

- [ ] **Step 4: Verify**

Run:

```bash
rg -n "claude-workflow|ago@claude-workflow|marketplace add eyev0/claude-workflow" CLAUDE.md
```

Expected: no matches.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: rebrand Claude install instructions to ago"
```

---

## Chunk 2: Claude Marketplace Metadata

### Task 3: Update marketplace source metadata

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Rename the marketplace package**

Update the top-level marketplace identity from `claude-workflow` to `ago`.

Target shape:

```json
{
  "name": "ago",
  "owner": {
    "name": "eyev"
  }
}
```

Preserve the current schema and plugin list structure.

- [ ] **Step 2: Update marketplace descriptions**

Rewrite descriptions so they describe `ago` as a cross-platform agent workflow product, not as a Claude-only workflow repo.

- [ ] **Step 3: Keep plugin source path stable**

Do not move `plugins/ago`. The plugin entry in `marketplace.json` should still point at:

```text
./plugins/ago
```

- [ ] **Step 4: Validate JSON**

Run:

```bash
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"
```

Expected: no output, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "chore: rename Claude marketplace package to ago"
```

---

### Task 4: Update the Claude plugin metadata

**Files:**
- Modify: `plugins/ago/.claude-plugin/plugin.json`

- [ ] **Step 1: Keep plugin name `ago`**

Confirm the plugin name remains `ago`.

- [ ] **Step 2: Refresh description and repository metadata**

Update the description so it matches the new README framing. It should still describe the command set accurately, but avoid implying that the repo itself is Claude-specific.

If the repository URL changed with the rebrand, update the `repository` field to the new canonical repo URL.

- [ ] **Step 3: Validate JSON**

Run:

```bash
python3 -c "import json; json.load(open('plugins/ago/.claude-plugin/plugin.json'))"
```

Expected: no output, exit code 0.

- [ ] **Step 4: Commit**

```bash
git add plugins/ago/.claude-plugin/plugin.json
git commit -m "chore: refresh ago plugin metadata for rebrand"
```

---

## Chunk 3: Add Detailed Install Guides

### Task 5: Create `docs/install/claude.md`

**Files:**
- Create: `docs/install/claude.md`

- [ ] **Step 1: Write the guide**

Include these sections:
- what this installs
- install
- verify
- update
- uninstall

Install section:

```text
/plugin marketplace add eyev0/ago
/plugin install ago@ago
```

Verify section should mention the visible commands:
- `ago:audit`
- `ago:research`
- `ago:audit-docs`
- `ago:write-adr`
- `ago:fix-audit`

- [ ] **Step 2: Keep it focused**

Do not duplicate the whole README. This file is only for Claude install and lifecycle operations.

- [ ] **Step 3: Commit**

```bash
git add docs/install/claude.md
git commit -m "docs: add Claude installation guide for ago"
```

---

### Task 6: Create `docs/install/codex.md`

**Files:**
- Create: `docs/install/codex.md`

- [ ] **Step 1: Write the guide**

Include these sections:
- what this installs
- quick install
- explicit install
- verify
- refresh/update
- uninstall
- known limitation

Quick install:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/eyev0/ago/main/.codex/INSTALL.md
```

Explicit install must explain that Codex uses `$skill-installer` to install these repo paths:
- `codex/skills/ago-audit`
- `codex/skills/ago-research`
- `codex/skills/ago-audit-docs`
- `codex/skills/ago-write-adr`
- `codex/skills/ago-fix-audit`

- [ ] **Step 2: Be truthful about updates**

Document that Codex does not currently provide a true marketplace auto-update flow for repo-hosted skills. The supported refresh path is to re-run the documented install/update instructions.

- [ ] **Step 3: Describe verification**

Verification should tell the reader what skills should be available after installation:
- `ago-audit`
- `ago-research`
- `ago-audit-docs`
- `ago-write-adr`
- `ago-fix-audit`

- [ ] **Step 4: Commit**

```bash
git add docs/install/codex.md
git commit -m "docs: add Codex installation guide for ago"
```

---

## Chunk 4: Add Agent-Facing Codex Install Layer

### Task 7: Create `.codex/INSTALL.md`

**Files:**
- Create: `.codex/INSTALL.md`

- [ ] **Step 1: Write the instruction preamble**

The file should explicitly say it is for Codex and that installation must use native skill installation, not local clone/symlink setup.

- [ ] **Step 2: Instruct installation of the full `ago` skill set**

The instructions must tell Codex to use `$skill-installer` and install all five skills from `eyev0/ago` in one action.

The installation target list is:
- `codex/skills/ago-audit`
- `codex/skills/ago-research`
- `codex/skills/ago-audit-docs`
- `codex/skills/ago-write-adr`
- `codex/skills/ago-fix-audit`

- [ ] **Step 3: Include refresh/update behavior**

Because the installer does not overwrite existing destinations, the instructions must define a refresh path. The simplest truthful version:
- remove existing `~/.codex/skills/ago-*` directories if present
- reinstall the five repo paths via `$skill-installer`
- restart Codex if required to pick up changed skills

- [ ] **Step 4: Include verification**

Tell Codex to confirm that the five installed skill directories exist under the Codex skills directory and that the user can invoke them by name.

- [ ] **Step 5: Commit**

```bash
git add .codex/INSTALL.md
git commit -m "docs: add agent-facing Codex install instructions for ago"
```

---

## Chunk 5: Add Codex Skill Set

### Task 8: Create `ago-audit` and `ago-research`

**Files:**
- Create: `codex/skills/ago-audit/SKILL.md`
- Create: `codex/skills/ago-research/SKILL.md`

- [ ] **Step 1: Write `ago-audit`**

Create a proper Codex skill with frontmatter:

```yaml
---
name: ago-audit
description: Use when the user wants a multi-angle retrospective audit of recent project work
---
```

The body should adapt the existing Claude command semantics from `plugins/ago/commands/audit.md` into skill form:
- determine audit scope
- gather git/docs context
- present scope
- wait for confirmation before launching parallel review agents
- consolidate findings into `docs/audit/YYYY-MM-DD-audit.md`

- [ ] **Step 2: Write `ago-research`**

Create:

```yaml
---
name: ago-research
description: Use when the user wants structured code and web research captured in a persistent artifact
---
```

Adapt the current `ago:research` semantics into skill form and preserve artifact output in `docs/research/`.

- [ ] **Step 3: Verify both files**

Run:

```bash
head -5 codex/skills/ago-audit/SKILL.md
head -5 codex/skills/ago-research/SKILL.md
```

Expected: valid frontmatter with `name` and `description`.

- [ ] **Step 4: Commit**

```bash
git add codex/skills/ago-audit/SKILL.md codex/skills/ago-research/SKILL.md
git commit -m "feat(codex): add ago-audit and ago-research skills"
```

---

### Task 9: Create `ago-audit-docs` and `ago-write-adr`

**Files:**
- Create: `codex/skills/ago-audit-docs/SKILL.md`
- Create: `codex/skills/ago-write-adr/SKILL.md`

- [ ] **Step 1: Write `ago-audit-docs`**

Map the existing `ago:audit-docs` behavior into a Codex skill that:
- audits docs against ADRs and current code
- produces `docs/audit/YYYY-MM-DD-docs.md`
- preserves the current action-item/report behavior

- [ ] **Step 2: Write `ago-write-adr`**

Map the existing `ago:write-adr` behavior into a Codex skill that:
- formulates an ADR from current conversation context
- requires user confirmation before writing
- writes `docs/adr/NNN-{title}.md`

- [ ] **Step 3: Verify both files**

Run:

```bash
head -5 codex/skills/ago-audit-docs/SKILL.md
head -5 codex/skills/ago-write-adr/SKILL.md
```

Expected: valid frontmatter with `name` and `description`.

- [ ] **Step 4: Commit**

```bash
git add codex/skills/ago-audit-docs/SKILL.md codex/skills/ago-write-adr/SKILL.md
git commit -m "feat(codex): add ago-audit-docs and ago-write-adr skills"
```

---

### Task 10: Create `ago-fix-audit`

**Files:**
- Create: `codex/skills/ago-fix-audit/SKILL.md`

- [ ] **Step 1: Write the skill**

Map the existing `ago:fix-audit` behavior into Codex skill form:
- parse audit report
- group items by dependency
- present execution plan
- require user approval
- execute fixes via agents/worktrees as supported by the harness

Artifact expectations should stay aligned with the Claude command.

- [ ] **Step 2: Verify**

Run:

```bash
head -5 codex/skills/ago-fix-audit/SKILL.md
```

Expected: valid frontmatter with `name` and `description`.

- [ ] **Step 3: Commit**

```bash
git add codex/skills/ago-fix-audit/SKILL.md
git commit -m "feat(codex): add ago-fix-audit skill"
```

---

## Chunk 6: Final Verification

### Task 11: Verify cross-platform install surface

**Files:**
- Read: `README.md`
- Read: `CLAUDE.md`
- Read: `.claude-plugin/marketplace.json`
- Read: `plugins/ago/.claude-plugin/plugin.json`
- Read: `.codex/INSTALL.md`
- Read: `docs/install/claude.md`
- Read: `docs/install/codex.md`
- Read: `codex/skills/*/SKILL.md`

- [ ] **Step 1: Validate JSON files**

Run:

```bash
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('plugins/ago/.claude-plugin/plugin.json'))"
```

Expected: no output, exit code 0.

- [ ] **Step 2: Validate skill inventory**

Run:

```bash
find codex/skills -maxdepth 2 -name SKILL.md | sort
```

Expected: exactly five `SKILL.md` files under `codex/skills/`.

- [ ] **Step 3: Validate product naming**

Run:

```bash
rg -n "claude-workflow|ago@claude-workflow" README.md CLAUDE.md .claude-plugin/marketplace.json plugins/ago/.claude-plugin/plugin.json docs/install .codex codex/skills
```

Expected: no matches, unless a historical reference is intentionally preserved in migration notes.

- [ ] **Step 4: Review install promises**

Read the docs and confirm:
- Claude is described as marketplace install
- Codex is described as native skill install
- no file claims that Codex has marketplace auto-update
- no file recommends clone/symlink setup

- [ ] **Step 5: Commit final integration**

```bash
git add README.md CLAUDE.md .claude-plugin/marketplace.json plugins/ago/.claude-plugin/plugin.json .codex/INSTALL.md docs/install codex/skills
git commit -m "feat: add ago cross-platform install and Codex skills"
```
