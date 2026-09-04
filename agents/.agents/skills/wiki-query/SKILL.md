---
name: wiki-query
description: Answer a question from the personal LLM wiki (index first, then cited pages); optionally file synthesis back. Use when Dexter says wiki-query, wiki:, or asks what we know about a topic already in the wiki.
argument-hint: [question]
disable-model-invocation: true
---

Query `~/projects/wiki/`.

## Input

$ARGUMENTS — the question. If missing, ask once.

## Steps

1. Read `~/projects/wiki/AGENTS.md` and follow the **Query** section.
2. Read `~/projects/wiki/index.md`; open only relevant entity/concept/synthesis pages.
3. Answer concisely with citations to wiki paths (and `~/projects/docs/...` only when the wiki is thin).
4. If the answer is reusable synthesis, ask whether to file under `synthesis/`, then update `index.md` + `log.md` if yes.
5. Do not invent facts; say when the wiki has a gap.
