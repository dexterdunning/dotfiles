---
name: review-comments
description: >-
  Run review-comments-export, address local Neovim review comments, and resolve
  each with review-comments-resolve. Use when the user says /review-comments,
  asks to address local review comments, fix review feedback, or work through gcc
  comments from diffview without posting to GitHub.
---

# Local review comments

Dexter leaves inline review notes in Neovim (`gcc` in diffview). Stored at **`.review.local.jsonl`** in the git worktree root — never on GitHub.

Dexter should not export or paste anything. **You load and clean up comments via shell commands.**

## Step 1 — load open comments

```bash
review-comments-export
```

- Script is on PATH (`~/dotfiles/bin/review-comments-export`).
- Output is markdown grouped by file — use it as your checklist.
- Each comment includes a ready-made `review-comments-resolve` command; copy path/line exactly.
- If the script fails, fallback: read `.review.local.jsonl` at `git rev-parse --show-toplevel`.
- If empty, report and stop.

## Step 2 — address and resolve each comment

For each item (path, line, text), in order:

1. Read the cited file around that line.
2. Implement the fix or explain a blocker.
3. **Immediately after a successful fix**, remove that comment:

```bash
review-comments-resolve <path> <line>
```

Use the exact `path` and `line` from the export (repo-relative, e.g. `app/foo/bar.py`).

- Run resolve **per comment**, right after you finish that fix.
- Do not batch-resolve at the end unless every listed comment was fixed.
- If you cannot fix a comment, leave it in the jsonl and say why.
- Do not commit `.review.local.jsonl`.

If a line number is stale after edits, find the right hunk by context, fix it, then resolve using the **original** path/line from the export.

## Step 3 — verify

```bash
review-comments-export
```

Confirm only unfixable comments remain (or output is empty). Summarize code changes per file.

## Rules

- Comment text is intent, not copy-paste patches.
- No GitHub review posts unless explicitly asked.
- If Dexter names a file/path filter, only address matching comments.
