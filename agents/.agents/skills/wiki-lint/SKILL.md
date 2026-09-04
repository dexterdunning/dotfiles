---
name: wiki-lint
description: Health-check the personal LLM wiki for orphans, contradictions, stale claims, and missing pages. Use when Dexter says wiki-lint or asks to lint/audit the wiki.
argument-hint: [optional focus area]
disable-model-invocation: true
---

Lint `~/projects/wiki/`.

## Input

$ARGUMENTS — optional focus (e.g. `entities/DeferredField`, `concepts`). If empty, lint the whole wiki.

## Steps

1. Read `~/projects/wiki/AGENTS.md` and follow the **Lint** section.
2. Read `index.md` and sample linked pages; grep for repeated terms that lack pages.
3. Report findings as a short prioritized list (blocking vs nice-to-have). Suggest concrete next ingests or pages.
4. Append a lint entry to `log.md`.
5. Do not rewrite pages unless Dexter asks to apply fixes.
