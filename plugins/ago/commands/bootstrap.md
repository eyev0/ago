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
