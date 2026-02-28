# `ago:bootstrap` Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the `ago:bootstrap` command that captures operational context (product brief, decision philosophy, per-role mandates) and produces `brief.md` + `roles/*.md` in target projects.

**Architecture:** A new command (`commands/bootstrap.md`) that reads `.workflow/config.md` for active roles, scans project artifacts, interviews the user, and generates structured markdown files. Two new templates (`templates/brief.md`, `templates/role.md`) provide the structure. Convention docs and all 11 role agent definitions get updated to reference the new files.

**Tech Stack:** Markdown only — no code. All files are Claude Code plugin commands/templates/conventions.

---

### Task 1: Create Templates

**Files:**
- Create: `templates/brief.md`
- Create: `templates/role.md`

**Step 1: Create `templates/brief.md`**

```markdown
---
project: {project-name}
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
---

## Product Vision
{What this product is, who it serves, why it matters}

## Target Users
{Primary personas, their needs, their context}

## Domain Context
{Industry, competitive landscape, market position}

## Operational Constraints
{Tech stack, deployment model, team size, release cadence, compliance requirements}

## Decision Philosophy
{How this project makes decisions — move fast vs careful, consensus vs owner-decides, experimentation tolerance}

## Role Priority Matrix

### Authority Hierarchy
{Which roles can block others, whose reviews are mandatory}

### Engagement Order
{Default sequencing for new work, e.g. PM → ARCH → DEV → QAL/QAD → CICD}

## Goals (Current)
{3-5 concrete near-term goals with owners}
```

**Step 2: Create `templates/role.md`**

```markdown
---
role: {ROLE-ID}
project: {project-name}
focus: {one-line focus for this project}
priority: {1-N, engagement order position}
authority:
  reviews: [{roles this role reviews}]
  reviewed_by: [{roles that review this role}]
---

## First Principles
{2-3 guiding principles for this role on THIS project}

## Focus Areas
{Specific areas this role should prioritize}

## Constraints
{Decisions already made, non-negotiables relevant to this role}

## Key Questions
{Open questions this role should address first}
```

**Step 3: Commit**

```bash
git add templates/brief.md templates/role.md
git commit -m "feat: add brief.md and role.md templates for ago:bootstrap"
```

---

### Task 2: Update Convention Docs

**Files:**
- Modify: `conventions/file-structure.md:8-15` (standard structure diagram)
- Modify: `conventions/naming.md` (add roles section at end)

**Step 1: Update `conventions/file-structure.md`**

Add `brief.md` and `roles/` to the standard structure diagram (lines 8-15). The new structure should be:

```
.workflow/
├── config.md          <- Project configuration
├── brief.md           <- Project brief (product vision, constraints, philosophy)
├── registry.md        <- Index of all entities
├── roles/             <- Per-role mandate documents
├── docs/              <- Living project documents
├── epics/             <- Epic directories with tasks
├── decisions/         <- All Decision Records
└── log/               <- Session and agent logs
```

Add a new section after the `## config.md` section (after line 25):

```markdown
## brief.md

Project-level operational context created by `ago:bootstrap`. Contains:
- Product vision, target users, domain context
- Operational constraints (tech stack, deployment, compliance)
- Decision philosophy
- Role priority matrix (authority hierarchy + engagement order)
- Current goals

Read by all agents as shared context before starting work.

## roles/

One file per active role (excluding MASTER and WFDEV). Each contains the role's project-specific mandate:
- First principles for this project
- Focus areas and constraints
- Key questions to address

Naming: `{role-id-lowercase}.md` (e.g., `arch.md`, `pm.md`, `dev.md`)

Created by `ago:bootstrap`. Read by each agent before starting work.
```

**Step 2: Update `conventions/naming.md`**

Add a new section after "## Project Documents" (after line 71):

```markdown
## Role Mandate Documents

Format: `.workflow/roles/{role-id-lowercase}.md`

Examples:
- `.workflow/roles/pm.md`
- `.workflow/roles/arch.md`
- `.workflow/roles/dev.md`
- `.workflow/roles/sec.md`

Rules:
- Lowercase role ID from `conventions/roles.md`
- One file per active role (excluding MASTER and WFDEV)
- Created by `ago:bootstrap`
```

**Step 3: Commit**

```bash
git add conventions/file-structure.md conventions/naming.md
git commit -m "docs: add brief.md and roles/ directory to conventions"
```

---

### Task 3: Update Registry Template

**Files:**
- Modify: `templates/registry.md:26-34` (Project Documents table)

**Step 1: Update `templates/registry.md`**

Add `[[brief]]` row to the Project Documents table, and add a new Role Mandates table after it.

The Project Documents table (line 26) gets a new first row:

```markdown
## Project Documents

| Document | Owner | Last Updated |
|----------|-------|-------------|
| [[brief]] | MASTER | |
| [[eprd]] | PM | |
| [[architecture]] | ARCH | |
| [[security]] | SEC | |
| [[testing]] | QAL | |
| [[marketing]] | MKT | |
| [[status]] | PROJ | |
| [[timeline]] | PROJ | |

## Role Mandates

| Role | Focus | Priority |
|------|-------|----------|
| | | |
```

**Step 2: Commit**

```bash
git add templates/registry.md
git commit -m "docs: add brief and role mandates to registry template"
```

---

### Task 4: Update `memory/AGENTS.md`

**Files:**
- Modify: `memory/AGENTS.md:11-14` (For Role Agents section)

**Step 1: Update the "For Role Agents" section**

Replace lines 11-14:

```markdown
## For Role Agents

Each agent role is defined in `agents/{role-name}.md`. Follow your role definition strictly.
Always invoke the `ago:write-raw-log` skill after completing work.
```

With:

```markdown
## For Role Agents

Before starting any work:
0. Read `.workflow/brief.md` for project context, decision philosophy, and role priorities (if it exists)
1. Read `.workflow/roles/{your-role}.md` for your project-specific mandate and focus areas (if it exists)
2. Follow your role definition in `agents/{your-role}.md`

Always invoke the `ago:write-raw-log` skill after completing work.
```

**Step 2: Add `ago:bootstrap` to the Commands list (line 51)**

Add after the `ago:readiness` line:

```markdown
- `ago:bootstrap` — Capture operational context: product brief, role mandates, decision philosophy
```

**Step 3: Commit**

```bash
git add memory/AGENTS.md
git commit -m "docs: add brief.md and role doc reads to AGENTS.md"
```

---

### Task 5: Update All Role Agent Definitions

**Files:**
- Modify: `agents/architect.md:39-44`
- Modify: `agents/product-manager.md:38-42`
- Modify: `agents/developer.md:36-40`
- Modify: `agents/security-engineer.md:39-44`
- Modify: `agents/qa-lead.md:38-43`
- Modify: `agents/qa-dev.md:37-42`
- Modify: `agents/project-manager.md:38-43`
- Modify: `agents/marketer.md:38-43`
- Modify: `agents/documentation.md:37-42`
- Modify: `agents/cicd.md:38-43`
- Modify: `agents/consolidator.md:39-44`
- Modify: `agents/master-session.md:91-95`

For each role agent (NOT master-session, NOT workflow-developer), prepend two lines to the "Before Starting Work" numbered list:

```markdown
## Before Starting Work
1. Read `.workflow/brief.md` for project context and priorities (if it exists)
2. Read `.workflow/roles/{role}.md` for your specific mandate (if it exists)
3. {previous step 1 — e.g., "Read the task.md for your assigned task"}
4. {previous step 2}
...
```

Replace `{role}` with the actual lowercase role ID for each agent:
- `agents/architect.md` → `roles/arch.md`
- `agents/product-manager.md` → `roles/pm.md`
- `agents/developer.md` → `roles/dev.md`
- `agents/security-engineer.md` → `roles/sec.md`
- `agents/qa-lead.md` → `roles/qal.md`
- `agents/qa-dev.md` → `roles/qad.md`
- `agents/project-manager.md` → `roles/proj.md`
- `agents/marketer.md` → `roles/mkt.md`
- `agents/documentation.md` → `roles/doc.md`
- `agents/cicd.md` → `roles/cicd.md`
- `agents/consolidator.md` → `roles/cons.md`

For `agents/master-session.md`, prepend only ONE line (MASTER reads brief.md, no role doc):

```markdown
## Before Starting Work
1. Read `.workflow/brief.md` for project context and priorities (if it exists)
2. {previous step 1 — "Read `.workflow/registry.md`..."}
...
```

Do NOT modify `agents/workflow-developer.md` — WFDEV is a meta-role.

**Step: Commit**

```bash
git add agents/*.md
git commit -m "feat: add brief.md and role doc reads to all agent definitions"
```

---

### Task 6: Create the `commands/bootstrap.md` Command

**Files:**
- Create: `commands/bootstrap.md`

**Step 1: Write the command**

```markdown
---
description: Capture operational context — product brief, role mandates, decision philosophy
argument-hint: "[--check | --role ROLE]"
---

# ago:bootstrap

You are executing the `ago:bootstrap` command. This command runs AFTER `ago:readiness` to capture operational context that makes agents effective from day one. Your job is to interview the user, scan existing docs, and generate `brief.md` + per-role mandate documents.

Parse `$ARGUMENTS` for flags:
- `--check` — Show what would be generated without creating files. Stop after the preview.
- `--role {ROLE}` — Regenerate a single role doc only (re-interview for that role).
- No flags — Full hybrid scan + interview.

## Step 1 — Prerequisites

Check that `.workflow/config.md` exists. If it does not:
- Tell the user: "Run `ago:readiness` first to create the `.workflow/` scaffold."
- Stop.

Read `.workflow/config.md` and extract:
- Project name
- Active roles list
- Project description

If `.workflow/brief.md` already exists:
- Show current brief summary (vision + goals)
- Ask: "A project brief already exists. Regenerate it? Existing role docs will also be regenerated. [y/N]"
- If no, stop (unless `--role` flag targets a specific role)

If `--role {ROLE}` flag is set:
- Verify the role is in the active roles list
- Skip to Step 5 for that single role only
- Read existing `.workflow/brief.md` for context (do not regenerate it)

## Step 2 — Scan & Pre-fill

Search the project for existing context. Be thorough but skip `node_modules/`, `.git/`, `vendor/`, `target/`, `dist/`, `build/`, `__pycache__/`.

Scan these sources:
- `README.md` — extract project vision, description, goals
- `CLAUDE.md` — extract conventions, preferences, constraints
- `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` — tech stack, dependencies
- `.workflow/docs/eprd.md` — product requirements (if populated beyond stub)
- `.workflow/docs/architecture.md` — tech decisions (if populated beyond stub)
- `.workflow/docs/security.md` — security posture (if populated beyond stub)
- `.workflow/docs/testing.md` — test strategy (if populated beyond stub)
- `.workflow/docs/status.md` — current roadmap/status (if populated beyond stub)
- `SECURITY.md`, `CONTRIBUTING.md` — operational signals
- `.github/workflows/`, `Dockerfile`, `docker-compose.yml` — deployment model

Build a pre-filled draft from what you find. Note what you could and couldn't infer.

## Step 3 — Product Brief Interview

Present what you found and ask targeted questions for gaps. Use `AskUserQuestion` with multiple-choice options where possible. Use open-ended questions for vision, philosophy, and goals where the user's own words matter.

### 3a. Product Vision
If scanned from README/ePRD, present it:
"Here's what I found for the product vision: {scanned text}. Is this accurate, or would you adjust it?"

If not found, ask:
"What is this product? Who does it serve? Why does it matter? (2-3 sentences)"

### 3b. Target Users
Ask: "Who are the primary users? Describe 1-3 personas or user types."

### 3c. Domain Context
Ask: "What's the industry or domain context? Any competitive landscape worth noting?"

If the project is clearly technical infrastructure (library, CLI tool, framework), pre-fill:
"This appears to be a {type} — domain context is developer tooling."
Ask for confirmation.

### 3d. Operational Constraints
Present what you inferred from the scan:
"Based on the project, I see: {tech stack}, {deployment signals}, {team signals}."

Ask: "Any additional operational constraints? (compliance, team size, release cadence, budget)"

### 3e. Decision Philosophy
Always ask — this cannot be scanned:
"How does this project make decisions?"

Offer choices:
- **Move fast** — ship quickly, iterate, accept some tech debt
- **Careful & deliberate** — thorough review, minimal debt, slower pace
- **Balanced** — fast for small changes, careful for architecture
- **Other** — describe your approach

### 3f. Goals
Ask: "What are the 3-5 current goals for this project? What should be accomplished next?"

## Step 4 — Role Priority Matrix

### 4a. Engagement Order
Based on the active roles and project type, propose a default engagement order:

For code-heavy projects: `PM → ARCH → DEV → QAL/QAD → SEC → CICD`
For content/docs projects: `PM → DOC → MKT → PROJ`
For infrastructure projects: `ARCH → DEV → CICD → SEC → QAL/QAD`

Present the default: "Proposed engagement order for new work: {order}. Adjust?"

### 4b. Authority Hierarchy
Use the review hierarchy from `@${CLAUDE_PLUGIN_ROOT}/conventions/quality-gates.md` as the default:
- ARCH reviews DEV
- QAL reviews QAD
- PM reviews MKT
- SEC reviews DEV

Present it and ask: "Any additional mandatory review gates? (e.g., SEC must approve before deployment)"

## Step 5 — Per-Role Mandates

For each active role (excluding MASTER and WFDEV), generate a role mandate doc.

Group roles into two tiers:

**Core roles (detailed interview — 2-3 questions each):**
- PM, ARCH, DEV

**Conditional roles (lighter interview — 1-2 questions each, only if active):**
- SEC, QAL, QAD, PROJ, MKT, DOC, CICD, CONS

For each role:
1. Pre-fill focus from scanned context and the brief interview answers
2. Pre-fill authority from the review hierarchy
3. Ask: "What should {ROLE full name} focus on specifically for this project?"
   - Offer 2-3 suggested focus areas based on what you know + an "Other" option
4. For core roles only, also ask: "Any first principles or constraints for {ROLE}?"
5. For conditional roles, present the pre-filled version: "Here's what I have for {ROLE}: {summary}. Adjust or confirm?"

## Step 6 — Preview & Confirm

### If `--check` flag: Show the preview and STOP.

Present what will be created:

```
The following files will be created:

  .workflow/brief.md           (project brief — vision, constraints, philosophy)
  .workflow/roles/             (per-role mandate directory)
  .workflow/roles/pm.md        (Product Manager mandate)
  .workflow/roles/arch.md      (Architect mandate)
  .workflow/roles/dev.md       (Developer mandate)
  ...                          (one per active role)

  registry.md will be updated with brief and role mandate references.
```

Ask: "Create these files? [Y/n]"

Wait for user confirmation before proceeding.

## Step 7 — Generate Files

### 7a. Create `roles/` Directory

Create `.workflow/roles/` if it doesn't exist.

### 7b. Create `brief.md`

Use the template from `@${CLAUDE_PLUGIN_ROOT}/templates/brief.md`. Fill in all sections from the interview answers. Do not leave placeholders — every section should have real content from the interview.

### 7c. Create Role Docs

For each active role (excluding MASTER and WFDEV), use the template from `@${CLAUDE_PLUGIN_ROOT}/templates/role.md`. Fill in:
- `role`: uppercase role ID
- `project`: project name from config
- `focus`: one-line focus from interview
- `priority`: engagement order position (1-based)
- `authority.reviews`: from review hierarchy
- `authority.reviewed_by`: from review hierarchy
- First Principles, Focus Areas, Constraints, Key Questions: from interview answers

### 7d. Update `registry.md`

Add `[[brief]]` to the Project Documents table (first row, owner: MASTER).

Add a new "Role Mandates" section after Project Documents:

```markdown
## Role Mandates

| Role | Focus | Priority |
|------|-------|----------|
| PM | {focus} | {N} |
| ARCH | {focus} | {N} |
| DEV | {focus} | {N} |
...
```

## Step 8 — Summary & Next Steps

After creation, show:

### Created
List every file created.

### Summary
Brief recap: "{N} role mandates generated. Decision philosophy: {philosophy}. Engagement order: {order}."

### Next Steps
1. **Review brief** — "Check `.workflow/brief.md` and adjust any answers."
2. **Review role mandates** — "Spot-check `.workflow/roles/*.md` — these shape how each agent approaches your project."
3. **Start working** — "Run `ago:clarify` with your first feature or goal."
4. **Update later** — "Run `ago:bootstrap --role {ROLE}` to regenerate a specific role's mandate."
```

**Step 2: Commit**

```bash
git add commands/bootstrap.md
git commit -m "feat: add ago:bootstrap command for operational context capture"
```

---

### Task 7: Update Plugin References

**Files:**
- Modify: `CLAUDE.md` (add ago:bootstrap to key commands if listed)
- Modify: `README.md` (add ago:bootstrap to command list if present)

**Step 1: Check CLAUDE.md for command references**

If CLAUDE.md lists commands, add `ago:bootstrap` after `ago:readiness`:
```
- `ago:bootstrap` — Capture operational context: product brief, role mandates, decision philosophy
```

**Step 2: Check README.md for command list**

If README.md has a commands section, add the same line.

**Step 3: Commit**

```bash
git add CLAUDE.md README.md
git commit -m "docs: add ago:bootstrap to plugin documentation"
```

---

### Task 8: Update Project Memory

**Files:**
- Modify: `/Users/eyev/.claude/projects/-Users-eyev-dev-claude-workflow/memory/MEMORY.md`

**Step 1: Update MEMORY.md**

Add `ago:bootstrap` to the Commands section. Update the file structure section to mention `brief.md` and `roles/`. Update the Roadmap Status to note bootstrap command is done.

**Step 2: Commit** (not applicable — memory is outside the repo)

---

### Task 9: Final Verification

**Step 1: Verify all files exist**

Run:
```bash
ls -la commands/bootstrap.md templates/brief.md templates/role.md
```
Expected: All three files exist.

**Step 2: Verify convention updates**

Run:
```bash
grep -c "brief.md" conventions/file-structure.md
grep -c "roles/" conventions/file-structure.md
grep -c "roles/" conventions/naming.md
```
Expected: At least 1 match each.

**Step 3: Verify agent updates**

Run:
```bash
grep -l "brief.md" agents/*.md | wc -l
```
Expected: 12 (all agents except workflow-developer.md).

**Step 4: Verify AGENTS.md**

Run:
```bash
grep "brief.md" memory/AGENTS.md
grep "ago:bootstrap" memory/AGENTS.md
```
Expected: Both match.

**Step 5: Verify registry template**

Run:
```bash
grep "brief" templates/registry.md
grep "Role Mandates" templates/registry.md
```
Expected: Both match.
