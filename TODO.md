# TODO

Patch plan captured from the workspace consistency audit. Do not implement blindly; use this as the execution queue.

## Validation Snapshot (2026-02-25)

- Fixed: `P01`–`P17`

## Patch Queue

- [x] `P01` Add or remove `TODO.md` dependency for workflow-developer role.
  - Files: `agents/workflow-developer.md`, `README.md`
  - Change: Either create and maintain this tracker as canonical, or remove all `TODO.md` references and point to the canonical roadmap file.

- [x] `P02` Add missing project docs timeline template.
  - Files: `platforms/claude-code.md`, `conventions/documentation.md`, `templates/project-docs/timeline.md` (new)
  - Change: Add `timeline.md` template and ensure bootstrap copies it into `.workflow/docs/`.

- [x] `P03` Normalize all project file paths to `.workflow/...`.
  - Files: `agents/master-session.md`, `agents/project-manager.md`, `agents/documentation.md`, `conventions/roles.md`
  - Change: Replace ambiguous `docs/...`, `log/...`, `decisions/...` references with `.workflow/docs/...`, `.workflow/log/...`, `.workflow/decisions/...`.

- [x] `P04` Normalize log directory casing and master role path.
  - Files: `conventions/logging.md`, `conventions/naming.md`, `skills/write-raw-log/SKILL.md`, `memory/AGENTS.md`
  - Change: Pick one canonical convention (`MASTER` vs `master`) and apply everywhere.

- [x] `P05` Unify task ID model (short ID vs full slug).
  - Files: `conventions/naming.md`, `templates/task.md`, `skills/create-task/SKILL.md`, `conventions/documentation.md`, `commands/execute.md`
  - Change: Define canonical `id` format and optional secondary fields, then align examples, filters, and wikilinks.

- [x] `P06` Reconcile lifecycle transitions with status-update skill.
  - Files: `conventions/task-lifecycle.md`, `skills/update-task-status/SKILL.md`
  - Change: Resolve `blocked -> in_progress` contradiction and explicitly encode role permissions for `review -> done`.

- [x] `P07` Resolve documentation ownership conflict.
  - Files: `conventions/documentation.md`
  - Change: Clarify whether only owner can edit directly, or allow DOC/DEV with owner approval workflow.

- [x] `P08` Resolve DR authorship language ambiguity.
  - Files: `conventions/decision-records.md`, `conventions/roles.md`, `agents/architect.md`
  - Change: Distinguish “decision proposal artifacts” vs formal DR creation by CONS/MASTER.

- [x] `P09` Fix global frontmatter rule scope.
  - Files: `CLAUDE.md`, `memory/AGENTS.md`, `templates/registry.md`, `conventions/logging.md`
  - Change: Narrow rule to entity docs (`config`, `epic`, `task`, `decision`, project docs) and exempt logs/registry if intended.

- [x] `P10` Standardize command invocation syntax.
  - Files: `commands/clarify.md`, `commands/execute.md`, `commands/readiness.md`, `commands/status.md`, `commands/review.md`, `commands/timeline.md`
  - Change: Choose one syntax (`/ago:...` or `ago:...`) and enforce across docs.

- [x] `P11` Align readiness messaging with actual implementation status.
  - Files: `README.md`, `commands/*.md`
  - Change: Mark commands as spec-only where applicable and avoid implying they are operational.

- [x] `P12` Correct Codex support claims until integration is complete.
  - Files: `README.md`, `platforms/codex.md`
  - Change: Either expand Codex guide to working level or label as planned/experimental in README.

- [x] `P13` Resolve DOC scope contradiction (`README` ownership vs `.workflow`-only edits).
  - Files: `agents/documentation.md`
  - Change: Align responsibilities and boundaries so DOC either may edit repo-level docs (README/developer guides) or remove that responsibility.

- [x] `P14` Clarify status-change logging ownership for MASTER-driven transitions.
  - Files: `conventions/task-lifecycle.md`, `conventions/logging.md`
  - Change: Define which log receives entries when MASTER performs transitions (especially `review -> done`) and align wording with role-based logging rules.

- [x] `P15` Align `ago:clarify` behavior with lifecycle sequencing.
  - Files: `commands/clarify.md`, `agents/master-session.md`
  - Change: Decide whether `ago:clarify` only decomposes/plans or also creates `task.md`; keep DECOMPOSE/APPROVE/DELEGATE steps consistent.

- [x] `P16` Remove hardcoded local path from config template.
  - Files: `templates/config.md`
  - Change: Replace `conventions_repo: ~/dev/claude-workflow` with a portable placeholder or documented variable.

- [x] `P17` Specify wikilink validation behavior for task links (file vs directory targets).
  - Files: `conventions/documentation.md`, `skills/validate-docs-integrity/SKILL.md`
  - Change: Define canonical task wikilink target (`task.md` or task directory) and make integrity checks enforce that convention unambiguously.
