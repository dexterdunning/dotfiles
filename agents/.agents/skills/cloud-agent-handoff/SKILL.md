---
name: cloud-agent-handoff
description: Draft a fully-specified, copyable handoff prompt for a CLOUD AGENT running a less-capable/cheaper model (Ripples pods, background agents, cheap Claude/GPT tiers). Use when the user wants to "hand this off to a cloud agent", "give this to a Ripples pod", "spawn a background agent", "write a prompt for a cheaper model", or is delegating an implementation task to an autonomous agent rather than a capable interactive one. Prefer this over handoff-prompt whenever the recipient is a cloud/background agent.
argument-hint: [what the cloud agent should build]
---

Draft a handoff prompt for a **cloud agent on a less-capable model**. Task context: $ARGUMENTS

This is a fork of `handoff-prompt`. Read that skill for the shared mechanics — **copyable rendering (four-backtick fence), tmp-file default, prescriptive-vs-exploratory, never-delegate-understanding, length/shape.** All of that still applies. This skill only adds what a cheap cloud recipient needs on top.

## The one assumption that changes everything

**Assume the recipient is a weak model with no judgment.** It will not infer conventions, will not generalize from one example to the pattern, will not "do the right thing" when the prompt is ambiguous. It copies the most literal reading of what you wrote and executes it. Every gap you leave becomes a wrong guess. Every judgment call you delegate becomes a coin flip.

So the base skill's "brief a cold colleague" becomes "brief a literal-minded junior who will do *exactly* what you write and nothing you didn't." You do the thinking; the prompt encodes the answer, not the question.

## Pre-handoff checklist — satisfy ALL before emitting the prompt

Each item below maps to a real way cheap models fail. If you can't satisfy one, resolve it in *this* chat first; do not paper over it in the prompt.

1. **Resolve every open fork first.** If the plan or conversation has an unresolved decision (which flag key, which of two approaches, shared vs separate), *decide it now with the user* before writing the handoff. Never hand a cheap model a design choice — it will pick wrong. A handoff prompt should contain zero "decide whether…" instructions.

2. **Name the exact flag / config shape — never a type or enum.** Give the literal key string, where it lives, its default, and the in-repo precedent to mirror. E.g. "add `pilot_key = "time_entry_segments_refresh"` next to `TIME_ENTRY_BACKGROUND_REFRESH_FUNNEL_PILOT` in `feature_flag_utils.py:802`; do NOT use a `FunnelDocumentType` value." Cheap models default to the most obvious literal (the model/enum name) unless told otherwise.

3. **Specify layering as "X calls Y, not Z."** Name the calling site, the method it must call, the owning service, and the forbidden shortcut. E.g. "the scheduler in `time_entry_service.py` calls `TimeEntryDeferredFieldService.schedule_*`, which owns the funnel call — the service must NOT call `DeferredFieldFunnelService.request_compute_batch` directly." A cheap model will inline the shortest path unless the layer boundary is stated as a rule.

4. **Cite a repo precedent for every new method.** Cheap models copy far better than they design. For each new function say "mirror `<existing_method>` at `<file>:<line>`." Point at a concrete sibling, not a description of one.

5. **Name the stacking tool explicitly if multiple PRs.** Not "make a stack" — say "use git-spice (`gs`); see the `create-stacked-pr` skill; one branch per PR; PR2 bases on PR1's branch." Reference `create-stacked-pr` / `new-task` by name.

6. **Give a hard `## Do NOT` list.** Cheap models wander and over-reach. Bound the scope: what not to touch, not to flip, not to delete, not to refactor. Include the "another agent owns X" boundaries.

7. **Give a runnable verification command, not "add tests."** Exact command (e.g. `cde local test time_tracking/... -- -v`), what should pass, and the mock helper to use (`@mock_feature_flag`, `mocker`). Cheap models write tests that assert the mock; tell them what behavior to assert.

8. **Include a stop-and-ask clause.** The single highest-leverage line: *"If any step is ambiguous, a named file/line doesn't match what you find, or a precedent doesn't exist, STOP and report back — do not guess or improvise."* This catches the divergences item 1 couldn't predict.

9. **Restate the PR/branch conventions inline.** Don't assume the agent reads AGENTS.md. Spell out: `agent-` branch, no slashes; `[tanda]` commit prefix + `Co-Authored-By`; draft PR via `scripts/create-draft-pr.sh` + verify `isDraft: true`; full PR template with the responsibility checkbox + rollback box; `pi` label; assign to `gh api user --jq '.login'`.

## Tension by design (keep both)

Item 1 (resolve every fork up front) and item 8 (stop rather than guess) look contradictory but aren't. Item 1 eliminates *predictable* guesses; item 8 catches *unpredictable* reality-divergence (a line number moved, a method was renamed). A good cloud handoff has zero open decisions AND an explicit stop-clause.

## Shape of the emitted prompt

Point the agent at the plan doc first (full path), then inline the essentials — never rely on "see the doc" alone for a cheap model; the doc may have nuance it can't parse, so restate the concrete steps in the prompt body. Sections that tend to appear: task + why (1-2 sentences) · settled design decisions (do NOT re-litigate) · the change, step by step with file:line + precedent · Do NOT list · tests + command · conventions · report-back.

Default to the tmp-file output (see base skill). Close, outside the fence, with one line on any non-obvious choice.
