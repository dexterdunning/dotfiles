---
name: cloud-agent-handoff
description: Draft a fully-specified, copyable handoff prompt for a CLOUD AGENT running a less-capable/cheaper model (Ripples pods, background agents, cheap Claude/GPT tiers). Use when the user wants to "hand this off to a cloud agent", "give this to a Ripples pod", "spawn a background agent", "write a prompt for a cheaper model", or is delegating an implementation task to an autonomous agent rather than a capable interactive one. Prefer this over handoff-prompt whenever the recipient is a cloud/background agent.
argument-hint: [what the cloud agent should build]
---

Draft a handoff prompt for a **cloud agent on a less-capable model**. Task context: $ARGUMENTS

> **Local supplement:** If `~/.agents/skill-overrides/cloud-agent-handoff/instructions.md`
> exists, read it for repo-specific flag/layering/verification/convention examples to reuse.
> This skill works without it; the supplement never overrides repository policy or safety rules.

## The one assumption that changes everything

**Assume the recipient is a weak model with no judgment.** It will not infer conventions, will not generalize from one example to the pattern, will not "do the right thing" when the prompt is ambiguous. It copies the most literal reading of what you wrote and executes it. Every gap you leave becomes a wrong guess. Every judgment call you delegate becomes a coin flip.

So the base skill's "brief a cold colleague" becomes "brief a literal-minded junior who will do *exactly* what you write and nothing you didn't." You do the thinking; the prompt encodes the answer, not the question.

## Pre-handoff checklist — satisfy ALL before emitting the prompt

Each item below maps to a real way cheap models fail. If you can't satisfy one, resolve it in *this* chat first; do not paper over it in the prompt.

1. **Resolve every open fork first.** If the plan or conversation has an unresolved decision (which flag key, which of two approaches, shared vs separate), *decide it now with the user* before writing the handoff. Never hand a cheap model a design choice — it will pick wrong. A handoff prompt should contain zero "decide whether…" instructions.

2. **Name the exact flag / config shape — never a type or enum.** Give the literal key string, where it lives, its default, and the in-repo precedent to mirror (e.g. "add `pilot_key = "<literal-key>"` next to `<EXISTING_KEY>` in `<file>:<line>`; do NOT use a `<TypeEnum>` value"). Cheap models default to the most obvious literal (the model/enum name) unless told otherwise.

3. **Specify layering as "X calls Y, not Z."** Name the calling site, the method it must call, the owning service, and the forbidden shortcut (e.g. "the scheduler in `<file>` calls `<OwningService>.schedule_*`, which owns the funnel call — the service must NOT call `<OtherService>.<method>` directly"). A cheap model will inline the shortest path unless the layer boundary is stated as a rule.

4. **Cite a repo precedent for every new method.** Cheap models copy far better than they design. For each new function say "mirror `<existing_method>` at `<file>:<line>`." Point at a concrete sibling, not a description of one.

5. **Name the stacking tool explicitly if multiple PRs.** Not "make a stack" — say "use the installed native GitHub stack CLI (`gh stack`); see the `create-stacked-pr` skill; keep one branch per PR in one worktree; create PRs through repository-required flows before linking their URLs into the native stack." Reference `create-stacked-pr` / `new-task` by name. Never use git-spice, `gs`, or `ghstack`.

6. **Give a hard `## Do NOT` list.** Cheap models wander and over-reach. Bound the scope: what not to touch, not to flip, not to delete, not to refactor. Include the "another agent owns X" boundaries.

7. **Give a runnable verification command, not "add tests."** Exact command, what should pass, and the mock helper to use. Cheap models write tests that assert the mock; tell them what behavior to assert.

8. **Include a stop-and-ask clause.** The single highest-leverage line: *"If any step is ambiguous, a named file/line doesn't match what you find, or a precedent doesn't exist, STOP and report back — do not guess or improvise."* This catches the divergences item 1 couldn't predict.

9. **Restate the PR/branch conventions inline.** Don't assume the agent reads AGENTS.md. Spell out the repo's branch prefix rules; any commit prefix + `Co-Authored-By`; the repo's PR-creation helper or flow and its required draft state; the full PR template (responsibility checkbox, rollback box); required labels; and assignment via `gh api user --jq '.login'`. The local supplement records the concrete values for these repos.

## Tension by design (keep both)

Item 1 (resolve every fork up front) and item 8 (stop rather than guess) look contradictory but aren't. Item 1 eliminates *predictable* guesses; item 8 catches *unpredictable* reality-divergence (a line number moved, a method was renamed). A good cloud handoff has zero open decisions AND an explicit stop-clause.

## Handoff mechanics for cloud agents (branch + spec + prompt rendering)

Cloud agents don't share your filesystem — they clone from origin. Every handoff decision follows from that. These are session-tested rules; each one is here because its absence caused a real failure.

1. **Remote-first, always.** Never put a local workstation path in the prompt or spec. The handoff artifact is a **branch on origin**: the agent checks out the branch, and the spec rides on it. The kickoff prompt names the branch and repo-relative spec paths only; local workstation paths are not available in the remote runtime.

2. **Spec-on-branch + drop-first pattern.** Commit the spec to the handoff branch so the agent receives it with the checkout (no copy-paste). Then the prompt's stated FIRST ACTION is to drop that commit so the PR diff stays clean:

   ```
   git reset --soft HEAD~1
   ```

   The spec file remains on disk (untracked) as the working reference; the prompt must say "do not commit the spec at any point." This only works on a clean-cut branch (item 3).

3. **Verify branch contents before declaring handoff-ready.** Run `git log origin/<branch> --oneline` and confirm every commit is either the spec or master ancestry. An unrelated commit riding along (a prototype, a lockfile bump) pollutes the PR or misleads the agent about scope. Cut the branch fresh from master; never reuse a dirty exploration branch as a handoff branch.

4. **Require incremental pushes — this is recoverability, not etiquette.** A cloud agent that works an hour without pushing loses everything if killed, and `git ls-remote` will confirm nothing was saved. (This happened: a completed Task 1+2 was unrecoverable because origin still pointed at the spec commit; the redo was cheaper than the salvage.) For multi-task specs, the prompt says "push after each commit/task", not just "push when done."

5. **Kickoff-prompt rendering: plain-text destination.** The user pastes the kickoff prompt into the cloud launcher box, which renders the paste literally — so per the base skill's "render for the destination" rule, emit it as a single flowing paragraph: no fence, no blockquote, no newlines, no leading indentation. The base skill's tmp-file default also doesn't apply: the prompt is a short pointer (branch + spec path + first actions) and its real payload is the spec committed to the branch (item 2).

6. **When an in-flight agent goes sideways, default to fresh relaunch over salvage.** An agent that worked from a wrong scope (e.g. was told to tag callsites in PR 1 when the PR plan moved tagging to PR 2) has the wrong plan baked into its context. Walking it back reliably costs more than the redo when the work is mechanical. Salvage only if the work is expensive *and* pushed. Also: if the PR plan changes mid-flight, fix the spec on the branch and relaunch — don't reprompt around a stale spec.

## Shape of the emitted prompt

Point the agent at the plan doc first (full path), then inline the essentials — never rely on "see the doc" alone for a cheap model; the doc may have nuance it can't parse, so restate the concrete steps in the prompt body. Sections that tend to appear: task + why (1-2 sentences) · settled design decisions (do NOT re-litigate) · the change, step by step with file:line + precedent · Do NOT list · tests + command · conventions · report-back.

Default to the tmp-file output (see base skill). Close, outside the fence, with one line on any non-obvious choice.
