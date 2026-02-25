# Naming Conventions

## Epics

Format: `E{NN}-{short-kebab-name}`

Examples:
- `E01-stt-core`
- `E02-ios-keyboard`
- `E03-chrome-extension-polish`

Rules:
- Two-digit zero-padded number
- Short kebab-case name (2-4 words)
- Numbers are sequential, never reused

## Tasks

Format: `T{NNN}-{ROLE}-{short-kebab-name}`

Examples:
- `T001-ARCH-research-models`
- `T002-DEV-mel-spectrogram`
- `T015-SEC-jwt-rotation-review`

Rules:
- Three-digit zero-padded number
- Global increment — task numbers NEVER repeat across epics
- Role ID identifies the assignee
- Short kebab-case name (2-5 words)

The canonical task identifier is the short numeric ID (T001). The full directory slug (T001-DEV-feature-name) is derived. In frontmatter, use id: T001. In wikilinks, use the full slug: [[T001-DEV-feature-name/task.md]].

Directory: `.workflow/epics/{epic-id}/tasks/{task-id}/`

## Decision Records

Format: `{ROLE}-{EPIC}-{TASK}-{short-description}.md`

Examples:
- `ARCH-E01-T003-onnx-vs-tflite.md`
- `SEC-E02-T015-jwt-rotation-strategy.md`
- `PM-E01-T001-mvp-scope-definition.md`

Rules:
- Role ID first (who generated the decision)
- Epic ID second
- Task ID third
- Short description last
- All kebab-case

## Agent Log Files

Format: `.workflow/log/{role}/{YYYY-MM-DD}.md`

Examples:
- `.workflow/log/master/2026-02-20.md`
- `.workflow/log/arch/2026-02-20.md`
- `.workflow/log/dev/2026-02-21.md`

## Project Documents

Fixed names in `.workflow/docs/`:
- `eprd.md` — Product requirements
- `architecture.md` — Architecture overview + ADR links
- `security.md` — Security approach
- `testing.md` — Test strategy
- `marketing.md` — Marketing strategy
- `status.md` — Project status tracker
- `timeline.md` — Mermaid Gantt (project-level)
