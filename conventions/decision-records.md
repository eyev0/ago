# Decision Records

## What is a Decision Record?

A DR captures a significant technical, product, or process decision with its context and consequences.

## When to Create a DR

- Architecture choice (framework, pattern, library)
- Product scope decision (what's in/out of MVP)
- Security approach (auth method, encryption)
- Any decision that affects multiple tasks or has long-term impact

## How DRs Are Generated

DRs are NOT written by agents during their work. Instead:

1. Agent works on task, logs actions in raw log (`.workflow/log/{role}/`)
2. Agent notes decisions in log entry under "Decisions made" section
3. After task completion, MASTER or CONS reads the raw log
4. CONS extracts decisions into formal DR files in `.workflow/decisions/`
5. DR is linked to the originating task and relevant project docs

## DR Statuses

| Status | Meaning |
|--------|---------|
| `proposed` | Decision drafted, not yet accepted |
| `accepted` | Decision approved by MASTER/user |
| `rejected` | Decision considered and rejected |
| `superseded` | Replaced by a newer DR (link in `supersedes` field) |

## DR Naming

See `conventions/naming.md` for format: `{ROLE}-{EPIC}-{TASK}-{description}.md`

## Aggregation

- Role-level DRs aggregate into project-level documents
- ARCH DRs feed into `.workflow/docs/architecture.md`
- SEC DRs feed into `.workflow/docs/security.md`
- PM DRs feed into `.workflow/docs/eprd.md`
- DOC or CONS role maintains these aggregation links
