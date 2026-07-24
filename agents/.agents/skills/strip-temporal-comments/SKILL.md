---
name: strip-temporal-comments
description: Find and remove temporal asides in code comments and docstrings — phrases that describe how the code *used to* behave or what *just changed* ("matches the prior X", "was previously Y", "replaces the old Z", "address review feedback", "renamed from"). These pollute long-term readability and are a common LLM-generated diff smell. Use when the user asks to "clean up comments", "strip LLM artifacts", "remove temporal asides", "find before/after comments", reviews a PR with `/strip-temporal-comments`, or you notice these patterns yourself in a diff you're about to ship.
---

# Strip temporal comments

LLM-assisted PRs often leave behind comments and docstrings that talk *about the change* — "matches the prior inline-metric behavior", "(was: X)", "Replaces the old Y". They make sense for one review pass and become noise immediately after. This skill finds them so they can be removed or rewritten.

## When to scan

Default to the current branch's diff vs `master`. The skill accepts:

- **A PR number** → `gh pr diff <num>`
- **A git range** → `git diff <base>..<head>` (e.g. `master..HEAD`, `origin/master...`)
- **A list of files** → scan only added/changed comment lines in those files
- **No arg** → `git diff $(git merge-base HEAD master)..HEAD` from the current worktree

Only scan **added** lines (those prefixed `+` in the diff). Unchanged comments are not your business.

## What to flag

The signal is: *the comment's subject is the change itself, not the current behavior*. A reader six months from now, with no access to the prior version, gets nothing from the sentence.

High-signal phrases to match (case-insensitive, allow loose word order and punctuation):

- "matches the prior / previous / old <X>"
- "mirrors the prior / old <X>"
- "(was: ...)", "(previously ...)", "(used to ...)", "(formerly ...)"
- "replaces the old ...", "supersedes the previous ..."
- "renamed from ...", "renamed: ...", "moved from ..."
- "this used to ...", "previously this ...", "this was ..."
- "on-path / off-path is the prior ..."
- "address review feedback", "address codex review", "per review", "per <reviewer>'s comment"
- Bare time-comparisons in comments: "old behavior", "new behavior", "before this change", "after this change"

These are seeds, not an exhaustive regex. Treat them as a fast pre-filter, then judge each hit against the rule above. Read enough surrounding lines to know what the sentence is actually doing.

## What NOT to flag

- Comments that explain *current* behavior plainly, even using past tense — "this is load-bearing because the migration left the legacy column populated" is fine; the past-tense reference is the *cause* of the current state, not narration about a prior code version.
- TODOs, FIXMEs, deprecation notices, JIRA/PR/Linear links.
- Migration helpers and temporary shims that *explicitly* exist for a migration — temporal context is the whole point.
- Changelog files, release notes, ADRs.
- Test names and assertions describing scenarios ("test_does_not_emit_when_value_unchanged").
- Type-stub style annotations and version-gate comments (`# py3.10+ only`).

When unsure, prefer to flag and let the user decide. A false positive costs one keystroke; a missed aside lives in the codebase forever.

## Workflow

1. **Gather the diff.** Pick the right source based on the arg. Save added lines + their file:line locations.
2. **Pre-filter.** Cheap pass: scan added comment/docstring lines for the seed phrases above. Drop everything else.
3. **Judge.** For each survivor, look at the surrounding 3–5 lines of file context (read the file, not just the diff hunk) and decide: is the sentence's subject the *change*, or the *current behavior*? Drop false positives quietly.
4. **Present findings.** One block per file. For each finding, show:
   - `path:line` (markdown-linked so it's clickable)
   - The offending text (one line, quoted)
   - A one-line proposed rewrite — usually: strip the aside, keep the current-behavior sentence. If the whole comment is an aside, propose deletion.
5. **Offer interactive cleanup.** Ask the user: accept all, reject all, or step through. Do not auto-rewrite without confirmation. On accept, edit the file; preserve indentation and surrounding structure.

## Output format

```
Found N temporal asides in M files.

[app/foo/bar.py:435](app/foo/bar.py:435)
  Current:  "Bumps DEFERRED_FIELD_UPDATED only when the value actually changed (matches the prior inline-metric behavior)."
  Rewrite:  "Bumps DEFERRED_FIELD_UPDATED only when the value actually changed."

[app/foo/baz.py:299](app/foo/baz.py:299)
  Current:  "Off path is the prior `getattr(self, 'timecardSummary', None)`."
  Rewrite:  (delete — describes the alternative branch only in terms of what it used to be)

Apply all / step through / cancel?
```

Keep the prose tight. The user is scanning for hits, not reading a report.

## Rewrite heuristics

- If the sentence has the structure "<current behavior> (<aside>)", drop the parenthetical.
- If the sentence is purely "this is the prior X" or "replaces the old Y", delete the whole sentence — and the whole comment if it becomes empty.
- If a docstring's only content is temporal narration, delete the docstring (don't leave a stub).
- Never rewrite to introduce *new* current-behavior claims you can't verify from the code. When in doubt, just delete the aside and stop.

## Why this matters

These asides accumulate. Each one looked harmless in its review, but six months later the file reads like a changelog stapled to the code. Reviewers (Vihari called this out on PR #487170, and the same pattern has shown up across multiple LLM-assisted PRs in this repo) find them especially annoying because they're an unforced error — the diff already shows what changed, so the comment is doubling up on something git already tracks better.
