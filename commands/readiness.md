---
description: Assess project readiness for the workflow system and bootstrap .workflow/ from existing docs
argument-hint: "[--check | --roles]"
---

# ago:readiness

You are executing the `ago:readiness` command. This is the bootstrap command — the FIRST command a user runs to bring a project into the `ago:` workflow system. Your job is to scan the project, assess what exists, and (unless `--check` or `--roles` is passed) create the `.workflow/` directory structure.

Parse `$ARGUMENTS` for flags:
- `--check` — Report only. Do NOT create any files. Stop after the coverage report.
- `--roles` — Show recommended roles only. Do NOT create any files.
- No flags — Full readiness check + interactive bootstrap.

## Step 1 — Check for Existing .workflow/

Check if `.workflow/` already exists at the project root.

**If it exists:**
- Read `.workflow/config.md` and `.workflow/registry.md`
- Report the current state: project name, active roles, epic count, task count
- Ask the user: "A .workflow/ directory already exists. Do you want to re-bootstrap (this will overwrite config and registry)? [y/N]"
- If user says no, stop
- If user says yes, proceed but preserve existing epics, tasks, decisions, and logs

**If it does not exist:** Proceed to Step 2.

## Step 2 — Scan Project for Existing Documentation

Search the project root for these categories of files. Be thorough but don't recurse into `node_modules/`, `.git/`, `vendor/`, `target/`, `dist/`, `build/`, or `__pycache__/`.

### 2a. General Documentation
- `README.md`, `README.rst`, `README.txt`
- `CLAUDE.md`
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`
- `docs/` or `doc/` directory (list contents)
- `wiki/` directory
- `CHANGELOG.md`, `CHANGES.md`, `HISTORY.md`

### 2b. Package Manifests (detect project type)
- `package.json` (Node.js/JavaScript)
- `pyproject.toml`, `setup.py`, `setup.cfg` (Python)
- `Cargo.toml` (Rust)
- `go.mod` (Go)
- `pom.xml`, `build.gradle`, `build.gradle.kts` (Java/Kotlin)
- `Gemfile` (Ruby)
- `composer.json` (PHP)
- `Package.swift` (Swift)
- `*.csproj`, `*.sln` (C#/.NET)
- `CMakeLists.txt`, `Makefile` (C/C++)

Extract from the manifest: project name, description, version, dependencies count.

### 2c. CI/CD Configurations
- `.github/workflows/` (GitHub Actions)
- `.gitlab-ci.yml` (GitLab CI)
- `Jenkinsfile`
- `.circleci/config.yml`
- `Dockerfile`, `docker-compose.yml`
- `.travis.yml`
- `Makefile` (if it has deploy/build targets)

### 2d. Roadmap and Planning
- `TODO.md`, `TODO.txt`, `TODO`
- `ROADMAP.md`
- `BACKLOG.md`
- `.github/ISSUE_TEMPLATE/`
- Any `milestones` or `releases` documentation

### 2e. Testing
- Test directories: `tests/`, `test/`, `__tests__/`, `spec/`
- Test configs: `jest.config.*`, `pytest.ini`, `pyproject.toml [tool.pytest]`, `.mocharc.*`, `vitest.config.*`, `cypress.config.*`
- Coverage configs: `.coveragerc`, `codecov.yml`, `.nycrc`

### 2f. Security
- `SECURITY.md`
- `.snyk`, `.trivyignore`
- Security-related CI steps

## Step 3 — Map Against Workflow Artifacts

Using what you found in Step 2, build a coverage matrix. Map existing documentation to the 7 workflow project documents defined in `@${CLAUDE_PLUGIN_ROOT}/conventions/naming.md`:

| Workflow Document | Maps From | Status |
|-------------------|-----------|--------|
| `eprd.md` (Product Requirements) | README features/goals, specs, PRDs, user stories | Found / Partial / Missing |
| `architecture.md` (Architecture) | docs/architecture, design docs, ADRs, system diagrams | Found / Partial / Missing |
| `security.md` (Security) | SECURITY.md, threat models, security policies | Found / Partial / Missing |
| `testing.md` (Test Strategy) | Test configs, CI test steps, existing test docs | Found / Partial / Missing |
| `marketing.md` (Marketing) | Marketing docs, landing pages, positioning docs | Found / Partial / Missing |
| `status.md` (Status/Roadmap) | TODO.md, ROADMAP.md, CHANGELOG, milestones | Found / Partial / Missing |
| `timeline.md` (Timeline) | Release plans, milestones, sprint docs | Found / Partial / Missing |

For each, note the source files that contribute and any gaps.

## Step 4 — Recommend Roles

Reference the 13 roles from `@${CLAUDE_PLUGIN_ROOT}/conventions/roles.md`.

Recommend roles based on what the project actually needs:

**Always recommended:**
- MASTER (orchestrator — always required)
- PM (product requirements — always relevant)
- PROJ (project management — always relevant)

**Recommended if project has code:**
- ARCH (architecture — any project with code)
- DEV (development — any project with code)

**Conditional — recommend only if relevant signals found:**
- SEC — recommend if: security-sensitive domain, auth/payments, SECURITY.md exists, or >10 dependencies
- QAL — recommend if: test directory exists, CI runs tests, or project is >1000 LOC
- QAD — recommend if: QAL is recommended AND integration/e2e tests exist or are needed
- MKT — recommend if: user-facing product, landing page, or marketing docs exist
- DOC — recommend if: docs/ directory exists with >3 files, or project has API docs
- CICD — recommend if: CI/CD config exists, Dockerfile exists, or deployment pipeline present
- CONS — recommend if: >5 roles are active (consolidation becomes valuable at scale)

**Never recommend for target projects:**
- WFDEV (meta-role for the ago: plugin itself)

Present the recommendation as a table:

| Role | Recommended | Reason |
|------|-------------|--------|
| MASTER | Yes | Always required |
| ... | ... | ... |

## Step 5 — Report

Present the readiness report to the user with these sections:

### Project Summary
- Project name and type (language/framework)
- Description (from manifest or README)
- Git remote URL (if available)

### Documentation Coverage
The coverage matrix from Step 3. Use clear indicators:
- **Found** — existing docs cover this well
- **Partial** — some content exists but needs expansion
- **Missing** — no existing documentation for this area

### Recommended Roles
The role table from Step 4.

### Gaps and Recommendations
Bullet list of specific gaps and what to do about them. Be actionable:
- "No architecture documentation found. The ARCH role will create `.workflow/docs/architecture.md` during the first architecture task."
- "README has product goals but no formal requirements. PM role will formalize into ePRD."

### If `--check` flag: STOP HERE. Do not proceed to Step 6.
### If `--roles` flag: Show ONLY the role table from Step 4 and stop.

## Step 6 — Confirm Before Creating

This is a collaborative command. Always ask the user before creating files.

Present what will be created:

```
The following .workflow/ structure will be created:

  .workflow/
  ├── config.md          (project config with selected roles)
  ├── registry.md        (empty entity index)
  ├── docs/              (project document stubs)
  │   ├── eprd.md
  │   ├── architecture.md
  │   ├── security.md
  │   ├── testing.md
  │   ├── marketing.md    (only if MKT role active)
  │   ├── status.md
  │   └── timeline.md
  ├── epics/             (empty, ready for ago:clarify)
  ├── decisions/         (empty)
  └── log/
      └── master/        (master session log)
```

Ask: "Create this structure? You can also remove roles or skip doc stubs. [Y/n]"

Wait for user confirmation before proceeding.

## Step 7 — Create .workflow/ Structure

Reference `@${CLAUDE_PLUGIN_ROOT}/conventions/file-structure.md` for the directory layout.

### 7a. Create Directories

Create these directories:
- `.workflow/`
- `.workflow/docs/`
- `.workflow/epics/`
- `.workflow/decisions/`
- `.workflow/log/`
- `.workflow/log/master/`

### 7b. Create config.md

Use the template from `@${CLAUDE_PLUGIN_ROOT}/templates/config.md`. Fill in:
- `project`: project name from manifest or directory name
- `description`: from manifest, README first line, or ask user
- `plugin`: `ago`
- `task_counter`: `0`
- Active Epics table: empty
- Active Roles: list the roles the user confirmed
- Project Links: fill git remote if available, leave others as placeholders

### 7c. Create registry.md

Use the template from `@${CLAUDE_PLUGIN_ROOT}/templates/registry.md`. All tables start empty. In the Project Documents table, only list documents for active roles (e.g., omit `[[marketing]]` if MKT is not active).

### 7d. Create Project Document Stubs

For each active role that owns a project document, create the stub in `.workflow/docs/`. Use templates from `@${CLAUDE_PLUGIN_ROOT}/templates/project-docs/`:
- PM active -> `docs/eprd.md`
- ARCH active -> `docs/architecture.md`
- SEC active -> `docs/security.md`
- QAL active -> `docs/testing.md`
- MKT active -> `docs/marketing.md`
- PROJ active -> `docs/status.md`, `docs/timeline.md`

If existing project docs were found in Step 2 that map to these, note the source in the stub so the relevant role knows where to look when populating the document.

### 7e. Optional — Create Initial Epic

If the scan found TODO.md, ROADMAP.md, or clear milestones, ask the user:

"I found roadmap items in {source}. Would you like me to create an initial epic from these? [y/N]"

If yes, use the template from `@${CLAUDE_PLUGIN_ROOT}/templates/epic.md`:
- ID: `E01`
- Title: derived from the roadmap
- Status: `planned`
- Owner: `PROJ`
- Created: today's date
- Create the directory: `.workflow/epics/E01-{kebab-name}/`
- Create `epic.md` inside it
- Update the Active Epics table in `config.md`
- Add the epic row to `registry.md`

## Step 8 — Summary and Next Steps

After creation, show:

### Created
List every file and directory that was created.

### Next Steps
Suggest the logical next actions:

1. **Review config** — "Check `.workflow/config.md` and adjust roles or project links if needed."
2. **Define requirements** — "Run `ago:clarify` with your first feature or goal to create tasks."
3. **Fill gaps** — For each "Missing" item in the coverage matrix, suggest which role will address it and when.

If an initial epic was created:
4. **Decompose epic** — "Run `ago:clarify` to break E01 into tasks with role assignments."
