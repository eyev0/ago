# Documentation Conventions

## Project Documents

Every project maintains living documents in `.workflow/docs/`. Each document has an owner role.

| Document | Owner | Purpose |
|----------|-------|---------|
| `eprd.md` | PM | Product requirements, user stories, MVP scope |
| `architecture.md` | ARCH | System architecture, component overview, ADR links |
| `security.md` | SEC | Security approach, threat model, conventions |
| `testing.md` | QAL | Test strategy, test structure, coverage |
| `marketing.md` | MKT | Marketing strategy, channels, positioning |
| `status.md` | PROJ | Current project status, blockers, velocity |
| `timeline.md` | PROJ | Mermaid Gantt (auto-generated from tasks) |

## Document Update Rules

1. Only the owner role modifies the document directly
2. Other roles propose changes through artifacts or DR
3. After feature implementation, DEV or DOC updates relevant docs
4. CONS validates cross-document consistency

## Cross-References

All documents use wikilinks for internal references:
- `[[T003-DEV-mel-spectrogram]]` — link to task
- `[[ARCH-E01-T003-onnx-vs-tflite]]` — link to DR
- `[[E01-stt-core]]` — link to epic

## ADR (Architecture Decision Records)

ADRs are a subset of Decision Records owned by ARCH.
They follow the standard DR format but focus on:
- Technology choices
- Design patterns
- Performance trade-offs
- Infrastructure decisions

ADRs aggregate into `docs/architecture.md` under a "Decisions" section.

## Documentation Integrity

DOC role periodically checks:
- All wikilinks resolve to existing files
- All tasks referenced in docs exist
- All DRs referenced in docs have correct status
- No orphaned artifacts (artifacts not linked from any task)
