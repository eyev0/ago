---
description: Assess project readiness for the workflow system and bootstrap .workflow/ from existing docs
---

# /agent-readiness

> TODO: Full implementation pending

## What This Command Does

Bootstrap command that bridges a project's existing documentation into the agent workflow system.

### Steps

1. **Scan existing docs** — Find all documentation in the project (README, docs/, wiki, inline comments, CLAUDE.md, etc.)
2. **Assess coverage** — Map existing docs against the workflow system's expected artifacts:
   - ePRD (product requirements)
   - Architecture doc
   - Security doc
   - Testing strategy
   - Marketing plan
   - Status/roadmap
3. **Report gaps** — Show what exists, what's missing, what needs splitting/consolidation
4. **Role mapping** — Identify which roles are relevant for this project (not every project needs MKT or CICD)
5. **Bootstrap .workflow/** — Create the `.workflow/` directory structure:
   - `config.md` with project metadata and active roles
   - `registry.md` initialized with discovered entities
   - `docs/` populated by mapping existing docs to role-owned files
   - Initial epics derived from roadmap/TODO items
6. **Generate roadmap** — Create project-level timeline from discovered milestones and deadlines
7. **Define requirements** — Extract/consolidate product requirements into ePRD format

### Output

A readiness report showing:
- Coverage matrix: which workflow artifacts exist vs. missing
- Active roles for this project
- Proposed epic structure
- Suggested next steps (which gaps to fill first)

## Usage

```
/agent-readiness              — Full readiness check + bootstrap
/agent-readiness --check      — Report only, don't create .workflow/
/agent-readiness --roles      — Show recommended roles for this project
```

## Roles Involved

- **MASTER** — Orchestrates the readiness check
- **PM** — Evaluates product requirements coverage
- **PROJ** — Assesses roadmap and timeline readiness
- **ARCH** — Reviews architecture documentation
- **DOC** — Validates documentation integrity and cross-references
