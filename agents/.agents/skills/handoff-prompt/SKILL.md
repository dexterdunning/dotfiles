---
name: handoff-prompt
argument-hint: [what the prompt should accomplish]
description: Checkpoint or resume work across fresh sessions, or draft a self-contained, copyable handoff prompt for another agent or teammate. Use for checkpoint/save-progress/resume requests. Use whenever the user asks for "a handoff prompt", "a prompt I can paste", "a prompt to give to a new agent", "write me a prompt for X", "draft a prompt so I can spawn an agent", or similar — including when they want to hand off a slice of the current conversation to a fresh context. Trigger eagerly; if someone says anything about generating prompts to run elsewhere, use this skill even if they don't explicitly say "copyable".
---

Draft a prompt the user can copy and paste to hand off a task. Task context: $ARGUMENTS

## Checkpoint and resume modes

Use this skill when Dexter asks to checkpoint, save progress for a fresh chat, or resume from a handoff. These modes override the prompt-output defaults below; do not print the entire checkpoint inline.

### Checkpoint

- Update the existing project handoff instead of creating a competing document. For `incremental-feature-stack`, use its existing `session-handoff.md` and preserve its required fields.
- Otherwise use `~/projects/docs/tmp/handoff-<short-slug>-<YYYYMMDD>.md`; reuse that file on later checkpoints for the same task.
- Aim for 500–1,000 words at most, shorter for simple work. Link large evidence artifacts instead of embedding logs or transcripts. Replace stale state; do not append an endless session diary.
- Include: goal and current phase; settled decisions and rationale; verified evidence with paths/queries/time windows; assumptions and open questions; failed approaches and why they failed; workspace path, branch, PRs and uncommitted work; active agents and their handles/status; one concrete next action, authorization boundaries, and stop conditions.
- Preserve exact commands and test results that matter, distinguishing passed, failed, and not run. Never record a proposed action as completed.
- Return the path and a short kickoff: “Use handoff-prompt resume mode with <path>.” Do not reset the session, commit, push, or launch another agent as part of checkpointing.

### Resume

- Read the checkpoint and applicable guidance first. Verify live workspace/branch/diff and any relevant PR or worker state before relying on recorded state; do not switch branches or overwrite changes automatically.
- Treat settled decisions as settled unless current evidence contradicts them. Read linked evidence selectively, not the entire historical investigation.
- Continue only the stated next action within its recorded authorization. If implementation was not approved, or state/intent conflicts, report the discrepancy and ask before acting.
- Update the same checkpoint at the next handoff. Do not create parallel summaries.

## Where the prompt goes (default: tmp file)

**Default: write the prompt to a tmp markdown file and give the user the path**, so they can open it and copy the whole thing in one action instead of scrolling chat. Use `~/projects/docs/tmp/handoff-<short-slug>-<YYYYMMDD>.md` (create the dir if missing). The file's raw contents are the prompt body — no outer code fence in the file. Then in chat, give the path + a one-line summary, and also print the prompt inline (fenced, below) unless the user asked for file-only.

**Render the inline copy for its destination.** How the inline prompt should be formatted depends on where the user will paste it:

- **Markdown destination** (an AI chat box — the common case): wrap in a four-backtick fence per the rules below, inner code blocks intact.
- **Plain-text destination** (a cloud-agent launcher box, a ticket comment field — anywhere that renders the paste literally): emit the prompt as a **single flowing paragraph** — no fence, no blockquote, no hard line breaks, no leading indentation. Fences and indentation copy as literal garbage there. Skip the tmp file too when the prompt is small and its real payload lives elsewhere (e.g. a spec committed to the branch the agent will check out) — the paragraph is then just the pointer plus first actions.

When handing off, decide which destination applies and follow that mode. (The cloud-agent skill pre-decides this: its kickoff prompts are always plain-text destination.)

Skip the file only if the user explicitly asks for inline-only, or the prompt is a one-liner.

## What "copyable" means (inline rendering)

When showing the prompt inline in chat, wrap the entire prompt in a fenced code block using **four backticks**:

````markdown
<the prompt>
````

Four backticks (not three) because the prompt body will almost certainly contain triple-backtick code blocks of its own. If the outer fence is triple, the copy breaks at the first inner code block. Use more backticks on the outside than anything on the inside — if the prompt contains `````\`\`\`\``````, escalate further.

Nothing else about your reply should be inside the code fence. Any explanation to the user ("I leaned exploratory here because…") belongs outside the fence as normal prose, after the block.

## The core move: brief a cold colleague

The recipient of this prompt does not have the current conversation. They are not you. They do not know what the user is working on, what's been tried, what's been ruled out, or why this matters. Your job is to transplant enough of that context that they can act without asking clarifying questions.

Concretely, good prompts tend to have:

- **What the user wants done**, stated in one or two sentences up top.
- **Why it matters** — what problem this solves, what it unblocks, who cares. One sentence is often enough. This is what lets the recipient make judgment calls instead of following narrow instructions.
- **What's already known** — file paths with line numbers, commands the user has already run, PRs or commits that established the current state, things that were tried and didn't work. Dump the facts; the recipient can filter.
- **Constraints** — conventions to follow, things not to touch, commit message prefixes, branch naming rules, owners to respect. Pull these from the user's AGENTS.md / CLAUDE.md, project conventions, or prior conversation if relevant.
- **What "done" looks like** — verification steps, success criteria, what to report back. If the task is exploration, say so explicitly and say what the exploration should produce.

Prompts without these read like fortune cookies. The recipient has to guess, and that guess is often wrong.

## Prescriptive vs. exploratory

The single biggest variable is how much of the thinking the user has already done. Read the conversation:

- **Prescriptive** — user has diagnosed the problem, knows the fix pattern, wants the prompt to execute a known solution. Write it as: here is the bug, here is the fix, here are the files, here is how to verify. The recipient's job is mechanical.
- **Exploratory** — user has observed something but doesn't yet know the right answer, or the code is someone else's and they want options before committing. Write it as: here is what we see, here is what to investigate, come back with 2-3 candidate approaches and a recommendation. Explicitly say *"do not write the fix yet"* so the recipient doesn't jump ahead.

If you can't tell, ask the user one short question before drafting. Don't guess — a prescriptive prompt on an exploratory task produces a confident wrong patch; an exploratory prompt on a prescriptive task wastes the user's time.

Mixed prompts exist (prescriptive for part A, exploratory for part B). That's fine — just be explicit about which is which.

## Never delegate the understanding

If you find yourself writing phrases like "based on your findings, fix the bug" or "based on the research, implement it" — stop. Those phrases push synthesis onto the recipient instead of doing it yourself. They indicate you skipped a step.

Rewrite to prove you processed the context:
- Not "figure out what's broken" — "the bug is in `file.py:60` where `isinstance(raw, DBRef)` trips the proxy".
- Not "fix the issue" — "replace the check with `type(raw) is DocumentProxy` to avoid triggering `__class__`".

The specifics come from your current conversation. Extract them and plant them in the prompt. The recipient shouldn't have to rediscover what you already know.

## Length and shape

Prompts should be as long as they need to be and no longer. A one-line prompt ("fix the typo in README") is fine. A 60-line prompt with six sections is fine if the task needs it. What's not fine is padding — generic preambles, restated instructions, filler headers.

Organize with headers only when the prompt is long enough that headers help navigation. Short prompts read better as prose paragraphs.

If the prompt has a natural list structure (files to touch, steps to run, options to consider), use lists. Don't force prose where bullets are clearer, and don't force bullets where prose flows better.

## Final-touch conventions

- Include file paths with absolute or repo-relative form — whichever matches the recipient's likely working directory. In this codebase, repo-relative paths like `app/foo/bar.py` usually work.
- Include line numbers when referencing specific code, like `file.py:123`.
- Reference PRs, commits, or JIRA tickets by number when relevant.
- If there's a tracking doc, memo, or spec the recipient should read, name its full path explicitly — don't say "see the doc", say "see `~/projects/docs/foo/bar.md`".
- If the user has conventions in their AGENTS.md / CLAUDE.md (commit prefix, PR template, branch naming), mention the ones relevant to the task.
- Close with one sentence outside the code fence explaining any non-obvious choice you made (why exploratory vs. prescriptive, what you pruned, what you amplified). Keep it short.
