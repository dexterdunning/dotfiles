---
name: dexter-review-comments
description: >-
  Run review-comments-export, fix local Neovim review comments, and resolve each
  with review-comments-resolve. Use when Dexter says /review-comments.
---

# Local review comments

1. `review-comments-export` — checklist
2. Per comment: fix code, then `review-comments-resolve <path> <line>`
3. `review-comments-export` again — verify empty
4. Summarize; never commit `.review.local.jsonl`

Full workflow: `~/.cursor/skills/review-comments/SKILL.md`
