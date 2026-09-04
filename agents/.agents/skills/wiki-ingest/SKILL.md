---
name: wiki-ingest
description: Ingest a closed investigation from ~/projects/docs into the personal LLM wiki — update entity/concept pages, index, and log. Use when Dexter says wiki-ingest, close investigation into the wiki, or ingest docs/<folder>.
argument-hint: [docs/<folder> | absolute path]
disable-model-invocation: true
---

Ingest a source into `~/projects/wiki/`.

## Input

$ARGUMENTS — path under `~/projects/docs/` (e.g. `deferred-fields` or `docs/deferred-fields`) or an absolute path. If missing, ask once.

## Steps

1. Resolve the source path. Default root: `~/projects/docs/`. Refuse to modify anything under `docs/`.
2. Read `~/projects/wiki/AGENTS.md` and follow the **Ingest** section exactly.
3. Read `~/projects/wiki/index.md` before editing so updates merge with existing pages.
4. Create/update pages under `entities/`, `concepts/` as needed. Prefer editing existing pages over duplicates.
5. Refresh `index.md` and append `log.md`.
6. Report: created pages, updated pages, open tensions / judgment calls for Dexter.

Do not promote to `domain-knowledge` unless asked.
