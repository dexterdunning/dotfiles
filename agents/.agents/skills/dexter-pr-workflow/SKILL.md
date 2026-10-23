---
name: dexter-pr-workflow
description: Use when Dexter asks to create, ship, submit, stack, update, or review a PR across his repos, including repo templates, Jira handling, labels, assignment, rollback plans, stack tooling, and pre-review checks.
---

# Dexter PR Workflow

Use this skill for PR creation, shipping, stack submission, and PR review across Dexter's repos.

> **Local supplement:** If `~/.agents/skill-overrides/dexter-pr-workflow/instructions.md`
> exists, read it for repo-specific PR defaults (templates, labels, helper script, draft rules).
> This skill works without it; the supplement never overrides repository policy or safety rules.

## Core Rules

- Read the repo-local `AGENTS.md` / `CLAUDE.md` first for PR rules.
- Use the repository's PR template when one exists.
- Ask Dexter for a Jira ticket if the repo requires one and none is provided; if proceeding without one, use `no jira`.
- Never add generated-by-agent text to PR descriptions unless Dexter explicitly asks.
- Assign the PR to the current GitHub user when using GitHub:

```bash
gh api user --jq '.login'
gh pr edit <pr-number> --add-assignee <github-username>
```

- Branch names should use hyphens, not slashes.
- Default rollback checkbox: safely revertible, unless migrations, schema changes, data backfills, or breaking API changes make it non-revertible.
- Follow the repo's required PR-creation and validation order; do not run pre-PR checks when the repo requires creating the draft first.

## Repository Defaults

For each repository, read its local `AGENTS.md` / `CLAUDE.md` and PR template first. Typical
defaults (the local supplement records them for these repos):

- Use the repository's `PULL_REQUEST_TEMPLATE.md`.
- Add the current harness label to PRs where the agent contributed code.
- Ask for Jira unless already provided; otherwise use `N/A` when the repo permits no ticket.
- Prefer native GitHub stacks through `gh stack`, not git-spice or the separate `ghstack` tool.
- Where the repository mandates a PR-creation helper script, create new PRs through it and verify
  the required draft state. Preserve existing PR draft/ready states.

## Submitting A PR

1. Gather context:

```bash
git status
git diff --staged
git diff
gh stack view --short  # when a local stack is configured
```

2. Stage only relevant files. Do not include unrelated user changes.
3. Commit with `git commit -m "<message>"`, including the required AI co-author trailer.
4. Use any repo-specific commit prefix only where the repo defines one (the local supplement records them).
5. Restack before submitting when using stacked branches.
6. Submit with an explicit title. Do not rely on auto-filled titles when they are likely to pick the wrong commit.

Shape the PR body from the repo template. For template-style PRs, include:

```markdown
**JIRA**: <jira-or-no-jira>

## Description

<summary of context, changes, and expected behavior>

## Test Plan

- [x] I take full responsibility for this code and its quality, whether written by me or with AI.
- [x] I acknowledge the risks of shipping a PR without a test plan.

<testing performed or why not run>

## Rollback plan

- [x] Check this box if this PR can be safely reverted.
- [ ] Check this box if this PR CANNOT be safely reverted.

<rollback explanation>
```

### Writing the description

The template is a guide, not a strict form. The description must match the scope of the change and be readable by a reviewer with less context.

- Explain why the change is needed and how it behaves, in plain English.
- Don't repeat the diff. Reviewers can read the code; describe what it does instead.
- Use a few simple concrete examples (a small table of input → result works well) rather than dumping raw data or long derivations.
- Keep it proportional: a small config change gets a short description.
- Mention known gaps or out-of-scope follow-ups in a line or two, without the full investigation.

Then assign the PR and report URL, branch, base, stack position, and CI status if checked.

## Native GitHub Stacks

- Use the official `github/gh-stack` extension (`gh stack`). Do not use git-spice, including in repositories with old tracking metadata.
- A branch chain or navigation comment alone is not a native stack. Existing PRs must belong to the same GitHub stack object.
- Inspect `gh stack <command> --help` before using unfamiliar flags. Keep stack branches in the same worktree and do not switch branches checked out elsewhere.
- Adopt existing local branches bottom-to-top with `gh stack init --base <trunk> <bottom-branch> <upper-branch>`, or discover an existing remote stack with `gh stack checkout <PR-URL>` after checking worktrees.
- Create each PR with its required repository helper, explicit title, completed body file, assignment, labels, and required draft state. Then link existing PR URLs:

```bash
gh stack link --base <trunk> <bottom-PR-URL> <upper-PR-URL>
```

- Avoid branch arguments for missing PRs: `link` can auto-create PRs and bypass required creation policies. Do not use `--open`; it changes existing draft states.
- If linking is blocked by individual auto-merge, explain and disable it only as authorized to form the atomic stack. Do not merge any PR or enable stack merging unless Dexter asks.
- For future updates, use `gh stack rebase` to cascade changes, then `gh stack push` or authorized `gh stack sync`. Push uses per-branch leases but is not atomic; sync fetches, rebases, and pushes atomically. Verify every upper branch contains its updated parent and every published head matches.
- Verify actual membership on every PR:

```bash
gh api repos/<owner>/<repo>/pulls/<number> --jq '{number, head: .head.sha, base: .base.ref, draft, stack}'
```

- Require a common non-null `.stack.number`, correct `.stack.position` / `.stack.size`, correct branch bases, and preserved draft states before reporting a native stack complete.
- Merge atomically with `gh stack merge <stack-number>` only on explicit request. A stack does not by itself guarantee one CI run; pipeline configuration controls deduplication.
- When repo policy permits CLI-created PRs, `gh stack submit --auto` can publish them; it is not a substitute for a mandatory repository creation helper.

## Reviewing PRs

When Dexter asks for a review, use code-review stance:

- Lead with findings ordered by severity.
- Ground each finding in specific files/lines.
- Prioritize bugs, deploy risks, data risks, missing tests, rollout issues, and architecture problems.
- Avoid style nitpicks that linters handle.
- Present notes first; ask before posting comments to GitHub.

Review dimensions:

- Architecture and decomposition
- Safety and rollout
- Backward compatibility across deploy windows
- Test behavior and coverage
- Feature flag use when risk warrants it
- Observability and import hygiene
