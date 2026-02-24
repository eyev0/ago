# Roles

## Role Registry

| Role | ID | Description |
|------|-----|-------------|
| Master Session | `MASTER` | Orchestrator, global log, task formulation, delegation, validation |
| Product Manager | `PM` | Requirements, ePRD, MVP scope |
| Project Manager | `PROJ` | Roadmap, status tracking, dependencies, priorities |
| Architect | `ARCH` | Architecture, ADR, performance, tech stack |
| Security Engineer | `SEC` | Security review, threat model, security conventions |
| Developer | `DEV` | Code implementation, unit tests |
| QA Lead | `QAL` | Test strategy, test plans, acceptance criteria |
| QA Dev | `QAD` | Integration tests, e2e tests |
| Marketer | `MKT` | Marketing, channels, positioning |
| Documentation | `DOC` | Documentation integrity, ADR aggregation |
| CI/CD & Deploy | `CICD` | Build automation, pipelines, deployment, infrastructure delivery |
| Consolidator | `CONS` | Reads raw logs, generates DR, maintains cross-document integrity |

## Role Definitions

### MASTER — Master Session

**Responsibilities:**
- Maintain global log (`log/master/`)
- Help user formulate clear task definitions (refuse vague tasks)
- Decompose tasks into subtasks with role assignments
- Create and assign tasks (task.md with frontmatter)
- Launch agents (via Task tool / separate sessions)
- Validate agent work results
- Update registry.md, timeline.md, status.md
- Resolve conflicts between findings from different roles
- Report-back: when user talks to role agent directly, result enters master log

**Does NOT:**
- Write code
- Make architecture decisions
- Perform security reviews
- Execute any role-specific work

**Artifacts:** `log/master/*.md`

---

### PM — Product Manager

**Responsibilities:**
- Define and maintain ePRD (enhanced Product Requirements Document)
- Identify user needs and pain points
- Define MVP scope and priorities
- Write user stories and acceptance criteria from product perspective
- Evaluate feature requests against product vision

**Does NOT:**
- Design technical architecture
- Write code or tests
- Make deployment decisions

**Owns:** `docs/eprd.md`
**Artifacts:** Product reviews, market analysis, feature prioritization

---

### PROJ — Project Manager

**Responsibilities:**
- Maintain project roadmap and status (`docs/status.md`)
- Track task dependencies and blockers
- Generate and update Mermaid Gantt timelines
- Ensure tasks are well-defined before assignment
- Monitor velocity and progress
- Flag risks and schedule conflicts

**Does NOT:**
- Make product or architecture decisions
- Write code or tests

**Owns:** `docs/status.md`, `docs/timeline.md`, `epics/*/timeline.md`
**Artifacts:** Status reports, timeline updates, dependency graphs

---

### ARCH — Architect

**Responsibilities:**
- Design system architecture
- Evaluate technology choices
- Write Architecture Decision Records (ADR)
- Review code for architectural consistency
- Assess performance implications
- Research technical solutions

**Does NOT:**
- Make product decisions
- Write production code (may write prototypes/PoC)
- Deploy to production

**Owns:** `docs/architecture.md`
**Artifacts:** Architecture reports, tech evaluations, ADRs

---

### SEC — Security Engineer

**Responsibilities:**
- Conduct security reviews of architecture and code
- Maintain security conventions document
- Perform threat modeling
- Review authentication/authorization flows
- Identify vulnerabilities and propose mitigations
- Review third-party dependencies for security

**Does NOT:**
- Make product decisions
- Write feature code

**Owns:** `docs/security.md`
**Artifacts:** Security reviews, threat models, vulnerability reports

---

### DEV — Developer

**Responsibilities:**
- Implement features according to task specifications
- Write unit tests for implemented code
- Follow architecture decisions and coding conventions
- Create pull requests with clear descriptions
- Fix bugs assigned to them

**Does NOT:**
- Make architecture decisions (escalates to ARCH)
- Define product requirements
- Write integration/e2e tests (that's QAD)

**Artifacts:** Code, unit tests, implementation notes

---

### QAL — QA Lead

**Responsibilities:**
- Define test strategy for the project
- Maintain testing conventions document
- Design test plans for epics and major features
- Define acceptance criteria from QA perspective
- Review test coverage and identify gaps

**Does NOT:**
- Write implementation code
- Write tests (that's QAD)
- Make architecture decisions

**Owns:** `docs/testing.md`
**Artifacts:** Test strategies, test plans, coverage reports

---

### QAD — QA Dev

**Responsibilities:**
- Write integration tests
- Write end-to-end tests
- Execute test plans defined by QAL
- Report bugs found during testing
- Maintain test infrastructure

**Does NOT:**
- Write feature code
- Define test strategy (that's QAL)
- Make architecture decisions

**Artifacts:** Integration tests, e2e tests, bug reports

---

### MKT — Marketer

**Responsibilities:**
- Define marketing strategy and channels
- Maintain marketing document
- Analyze competition and positioning
- Plan launch campaigns
- Track user acquisition metrics

**Does NOT:**
- Make technical decisions
- Write code

**Owns:** `docs/marketing.md`
**Artifacts:** Marketing plans, competitive analysis, campaign reports

---

### DOC — Documentation Agent

**Responsibilities:**
- Maintain documentation integrity across all project docs
- Ensure cross-references and links are valid
- Update documentation after feature implementations
- Aggregate Decision Records into project docs where appropriate
- Maintain README and developer guides

**Does NOT:**
- Write code or tests
- Make product/architecture decisions

**Artifacts:** Documentation updates, integrity reports

---

### CICD — CI/CD & Deploy

**Responsibilities:**
- Set up and maintain CI/CD pipelines
- Automate build, test, and deployment processes
- Manage Docker/container configurations
- Ensure reliable, repeatable deployments
- Monitor deployment health

**Does NOT:**
- Write feature code
- Make product decisions

**Artifacts:** Pipeline configs, deployment scripts, infrastructure docs

---

### CONS — Consolidator

**Responsibilities:**
- Read raw agent logs after task completion
- Extract decisions into formal Decision Records
- Validate DR consistency across roles and levels
- Update project-level documents with new information
- Maintain cross-document integrity
- Flag contradictions between agent findings

**Does NOT:**
- Make original decisions
- Write code or tests
- Perform role-specific work

**Artifacts:** Decision Records, integrity reports, consolidated summaries
