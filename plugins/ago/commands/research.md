---
description: Structured research session — deep-research a topic and save findings as a docs artifact
argument-hint: "<topic>"
---

# ago:research

You are executing the `ago:research` command. This command conducts a **structured research session** on a given topic, saves the findings as a reusable docs artifact, and optionally proposes Architecture Decision Records based on the research.

**This command does NOT require `.workflow/` — it works with any project that has a `docs/` directory.**

**Argument:** `$ARGUMENTS` (the research topic).

## Step 1 — Validate Topic

Parse `$ARGUMENTS` as the research topic.

- **If `$ARGUMENTS` is empty or blank:** Ask the user: "What topic would you like to research?" Wait for a response. Do not proceed until a topic is provided.
- **If `$ARGUMENTS` is provided:** Use it as the research topic. Store it as `TOPIC`.

Derive a `TOPIC_SLUG` — a kebab-case version of the topic suitable for filenames (lowercase, hyphens for spaces, strip special characters, max 60 characters).

## Step 2 — Gather Project Context

Collect the following context to inform the research. Each item is optional — skip any that don't exist and note their absence. **Do not fail if any single source is missing.**

### 2a — Project documentation

Read the following if they exist:
- `CLAUDE.md` — project instructions and architecture context
- `README.md` — project overview
- `docs/architecture.md` or similar top-level architecture doc

Store a brief summary of the project's purpose, tech stack, and constraints. This ensures research is grounded in the project's reality.

### 2b — Existing ADRs

Read files in these locations (if they exist):
- `docs/adr/` — Architecture Decision Records
- `docs/decisions/` — alternative ADR location

For existing ADRs, note the **highest ADR number** in use (e.g., if `013-*.md` exists, the next ADR is `014`). Also read `docs/adr/README.md` if it exists to understand the index format.

Store a list of existing ADR titles. These represent **settled decisions** — the research should not re-investigate topics already decided unless the user explicitly wants to revisit them.

### 2c — Existing research artifacts

Check if `docs/research/` exists. If it does, list the files in it and read their titles and status. Store this as `PRIOR_RESEARCH`.

If a prior research artifact covers the same or a closely related topic, note this and inform the user in Step 3. They may want to update the existing artifact instead of creating a new one.

## Step 3 — Formulate Research Questions

Based on the topic, project context, and any prior research, formulate **3–5 specific, targeted research questions**. These should be:

- **Concrete** — answerable with evidence, not open-ended philosophy
- **Relevant** — grounded in the project's context, tech stack, and constraints
- **Non-redundant** — do not re-investigate topics covered by existing ADRs or prior research (unless the user specifically asked to revisit)
- **Diverse** — cover different angles (e.g., technical feasibility, performance, ecosystem maturity, security implications, maintenance burden)

Present the questions to the user:

```
## Research Plan: {TOPIC}

### Context
{1-2 sentences about why this is being researched, based on the topic and project context}

### Prior Work
{List any relevant existing ADRs or prior research artifacts, or "None found."}

### Proposed Questions
1. {question 1}
2. {question 2}
3. {question 3}
4. {question 4} (if applicable)
5. {question 5} (if applicable)
```

Then ask:

> Does this research plan look good? You can:
> - **Approve** — I will begin researching these questions
> - **Modify** — Add, remove, or rephrase questions
> - **Add context** — Tell me more about what you're trying to decide

**Do NOT begin research until the user explicitly confirms.** If the user wants modifications, update the questions and re-present.

## Step 4 — Conduct Research

For each approved question, conduct research using all available tools. The goal is to find **evidence-backed answers**, not opinions.

### Research Methods

Use whichever methods are appropriate for each question. You are expected to use **multiple methods per question** to cross-reference findings.

#### External research

Check whether the `deep-research` skill is available in your skills list (shown in system-reminder messages). Also check for `WebSearch` and `WebFetch` tools.

- **If `deep-research` skill is available:** Prefer it for broad external research. Invoke it with the question as input and the project context as background.
- **If `WebSearch` / `WebFetch` tools are available (but not `deep-research`):** Use WebSearch to find relevant sources, then WebFetch to read the most promising results. Search for:
  - Official documentation
  - Benchmark comparisons
  - GitHub issues and discussions
  - Blog posts from credible authors (library maintainers, core team members)
  - Stack Overflow answers with high vote counts
- **If neither is available:** Skip external research. Note in findings: "External research tools unavailable — findings are limited to codebase analysis and existing knowledge."

#### Codebase analysis

- **Glob** — Find relevant files by pattern (e.g., config files, implementations of the technology in question)
- **Grep** — Search for usage patterns, imports, configuration values
- **Read** — Read specific files for detailed analysis

#### Benchmarks and measurements

- **Bash** — Run commands to gather concrete data (e.g., `wc -l`, `du -sh`, dependency counts, build times, test execution times)
- **CRITICAL:** Only report numbers you actually measured. If you did not run a benchmark, do not report benchmark numbers. State "Not measured" instead.

### Per-Question Research Process

For each question:

1. State the question
2. Research using appropriate methods
3. Record findings with **explicit sources** for every claim:
   - External source: URL, document title, author, date (if available)
   - Codebase source: file path and line numbers
   - Measurement: exact command run and output
   - Existing knowledge: state "Based on general knowledge as of [knowledge cutoff]" — use sparingly and only when external tools are unavailable
4. Assess confidence: **HIGH** (multiple corroborating sources), **MEDIUM** (single credible source or strong inference), **LOW** (limited evidence or conflicting sources)
5. Note any gaps — things you tried to find but could not

### Cross-Reference with ADRs

As you research, check whether any findings confirm, contradict, or extend existing ADRs. Note these connections — they will be surfaced in the artifact.

## Step 5 — Write Research Artifact

Create the research artifact at:

```
docs/research/YYYY-MM-DD-{TOPIC_SLUG}.md
```

Use today's date. Create the `docs/research/` directory if it does not exist. Create the `docs/` directory if it does not exist.

### Determine Status

- **Complete** — all questions were answered with at least MEDIUM confidence
- **Partial** — one or more questions could not be fully answered (mark which ones and explain why)

### Artifact Format

```markdown
# Research: {TOPIC}

**Date:** {YYYY-MM-DD}
**Author:** ago:research
**Status:** {Complete | Partial}

## Context

{Why this was researched — 2-4 sentences. What decision or problem motivated the research. Reference the project context.}

## Questions Investigated

1. {question 1}
2. {question 2}
3. {question 3}
...

## Findings

### Q1: {question 1}

{Detailed findings — paragraphs, bullet points, tables, or code snippets as appropriate. Every factual claim must have a source reference.}

**Confidence:** {HIGH | MEDIUM | LOW}

**Sources:**
- {source 1 — URL, file path, or measurement description}
- {source 2}
- ...

{If the question could not be fully answered:}
**Gaps:** {What could not be determined and why.}

---

### Q2: {question 2}

{Same structure as Q1}

---

{...repeat for each question...}

## Conclusions

{Numbered list of key takeaways — the most important things learned from this research. Each conclusion should be supported by findings above.}

1. {takeaway 1}
2. {takeaway 2}
3. {takeaway 3}
...

## Recommendations

{Actionable next steps based on the research. Be specific — what should be done, by whom (if obvious), and in what order.}

1. {recommendation 1}
2. {recommendation 2}
...

## Related ADRs

{List any existing ADRs that are relevant to this research, with a note on how they relate (confirms, extends, potentially conflicts). If none are relevant, write "None."}

- **ADR-{NNN}: {title}** — {relationship description}
```

Write the file. Do not ask permission — the research artifact is the primary output of this command and is always written.

## Step 6 — Propose ADRs

Review the research findings and conclusions. If any findings point to **architectural decisions that should be formalized** (e.g., technology choices, architectural patterns, trade-offs with long-term implications), propose them as ADRs.

If there are no candidate decisions, skip to Step 7.

Present the candidates to the user:

```
## Proposed ADRs

The research surfaced the following potential architectural decisions. Would you like to formalize any as ADRs?

| # | Title | Based On | Confidence |
|---|-------|----------|------------|
| 1 | {title} | Q{N} findings | {HIGH/MEDIUM} |
| 2 | {title} | Q{N} findings | {HIGH/MEDIUM} |
```

Then ask:

> **Which decisions should become ADRs?**
> Enter numbers (e.g., "1, 3"), "all", or "none".

**Wait for the user's response. Do not proceed until they answer.**

### Write Approved ADRs

For each decision the user approved, create an ADR file in `docs/adr/`.

**Determine next ADR number:** From Step 2b, you know the highest existing ADR number. Increment from there. If no ADRs exist yet, start at `001`.

**Filename:** `docs/adr/{NNN}-{kebab-case-title}.md`

**Content:**

```markdown
# ADR-{NNN}: {Title}

**Status:** Accepted
**Date:** {YYYY-MM-DD}

## Context

{Context from the research findings — what motivated this decision. Reference the research artifact.}

## Decision

{The decision — what approach was chosen and why, based on the research evidence.}

## Consequences

{What becomes easier or more difficult because of this decision. Include both positive and negative consequences.}
```

**Create `docs/adr/` directory if needed.**

**Update ADR index:** If `docs/adr/README.md` exists, read it to understand its format, then append the new ADR(s) to its index table or list, matching the existing format exactly. If `docs/adr/README.md` does not exist, do NOT create one.

Report each ADR created:

```
Created: docs/adr/{NNN}-{kebab-case-title}.md
```

## Step 7 — Final Summary

Present the closing summary:

```
## Research Complete

**Topic:** {TOPIC}
**Artifact:** docs/research/{filename}
**Status:** {Complete | Partial}
**Questions investigated:** {N}
**Sources cited:** {total unique sources across all findings}
**ADRs created:** {count} ({list filenames if any, or "none"})

### Key Takeaways
{Numbered list — same as Conclusions from the artifact, for quick reference}

### Next Steps
{Same as Recommendations from the artifact, for quick reference}
```

## Rules

- **Every claim needs a source.** Do not write unsourced assertions in the research artifact. If you cannot find a source for a claim, either drop it or explicitly mark it as "Based on general knowledge" with a LOW confidence rating.
- **No hallucinated benchmarks.** If you did not run a measurement or find a published benchmark with a URL, do not report numbers. Write "Not measured" or "No published benchmarks found."
- **Honest about gaps.** If a question cannot be fully answered, mark the research as Partial and explain what could not be determined. Partial research is more valuable than fabricated complete research.
- **Collaborative.** Ask before writing ADRs. The research artifact itself is always written — that is the point of the command. But ADRs are formal project decisions and require user approval.
- **No `.workflow/` dependency.** This command does not read from or write to `.workflow/`. It uses only `docs/`, project files, and external sources.
- **Respect existing ADRs.** Do not propose ADRs that contradict settled decisions unless the user explicitly asked to revisit them. If research findings conflict with an existing ADR, note the conflict in the artifact and let the user decide.
- **ADR format:** Match the style of existing ADRs in the project if any exist. The format in Step 6 is the default — adapt it if the project uses a different ADR format.
- **Graceful degradation.** If external research tools are unavailable, work with codebase analysis and existing knowledge. If `docs/` doesn't exist, create it. Only hard-fail if no topic is provided.
- **Reusable artifact.** The research artifact should be useful to anyone reading it later — not just the person who requested it. Write for a future reader who has no context beyond what's in the document.
