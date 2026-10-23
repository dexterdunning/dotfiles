---
name: dexter-worktree-workflow
description: Use when Dexter asks to start a new task, create a branch or worktree, check out a PR, switch branches, work on a stacked branch, or inspect existing worktrees across his local repos.
---

# Dexter Worktree Workflow

Use this skill for Dexter's branch/worktree setup across local repos.

> **Local supplement:** If `~/.agents/skill-overrides/dexter-worktree-workflow/instructions.md`
> exists, read it for local worktree roots, branch prefixes, and the repo test-runner invocation.
> This skill works without it; the supplement never overrides repository policy or safety rules.

## Defaults

- Prefer existing repo conventions from local `AGENTS.md` / `CLAUDE.md`.
- Default worktree root per repo: use the repo's standard worktree location (the local supplement records it for these repos).
- Default branch prefix: use the repo's or user's preferred prefix, unless the repo or user asks otherwise.
- Branch names should use hyphens, not slashes.
- Before checking out or creating any branch, run `git worktree list`.
- Prefer native GitHub stacks through `gh stack`. Do not initialize or use git-spice, even when old tracking metadata exists.

## New Task Flow

When Dexter asks to create/start a new task:

1. Identify the current repo root and trunk branch.
2. Read repo-local `AGENTS.md` / `CLAUDE.md` for branch naming or worktree rules.
3. Refresh the trunk branch only if that worktree is already on trunk and clean.
4. Parse branch name and optional base branch.
5. Add the required personal/agent prefix only when that matches the repo convention.
6. Validate the local branch, remote branch, and target worktree path do not already exist.
7. Check `git worktree list`.
8. If the base branch is non-trunk and already checked out in a worktree, create the new branch in that same worktree so stacked tooling can manage the stack.
9. Otherwise create a new worktree in the repo's standard location.
10. Initialize/adopt branches with `gh stack`; keep local tracking separate from creating the native stack on GitHub. Use `create-stacked-pr` / `dexter-pr-workflow` for publishing and membership verification.
11. Report the working directory, branch, base branch, and stack status.

For a new task from trunk in a repo with a standard worktree root:

```bash
git fetch origin <trunk-branch>
git worktree add --no-track -b <branch-name> <worktree-root>/<name> origin/<trunk-branch>
cd <worktree-root>/<name>
gh stack init --base <trunk-branch> <branch-name>
```

For a new layer on an existing locally tracked stack, use its worktree, verify the requested parent is the stack's top, then:

```bash
gh stack view --short
gh stack add <branch-name>
```

If the requested parent is in the middle of a stack, confirm insertion/fork intent rather than silently adding above the wrong branch. To adopt an untracked branch chain, create the child explicitly with `git switch --no-track -c <branch-name> <base-branch>`, then `gh stack init --base <trunk> <bottom-branch> ... <branch-name>` in bottom-to-top order. Do not overwrite an existing local stack.

Publish branches with their own upstream (`git push -u origin <branch-name>`), never the parent branch as upstream. These setup commands do not create PRs or native GitHub stack membership.

## PR Checkout Flow

When Dexter asks to check out a PR:

1. Resolve PR number from number or URL.
2. Fetch the PR head/base with the repo's host CLI, usually `gh pr view`.
3. Run `git worktree list`.
4. If the PR branch is already checked out, work there.
5. If the PR is stacked and its base branch is already in a worktree, use that worktree and check out the PR branch there.
6. Otherwise create a worktree in the standard location.
7. For a native remote stack, use `gh stack checkout <PR-URL>` in the selected worktree to discover/adopt its branches; inspect `gh stack view --short`. Do not run sync/rebase merely to inspect or check out a PR.
8. Report the path, branch, base, and stack relationship.

For GitHub:

```bash
gh pr view <number> --json headRefName,baseRefName --jq '{head: .headRefName, base: .baseRefName}'
```

## Confirmation

After changing branch/worktree context, show:

```bash
git log --oneline -5
git status
gh stack view --short  # if a local stack is configured
```

If a command fails because a branch/worktree already exists, stop and tell Dexter the existing path and branch state rather than forcing cleanup.

## Running tests from worktrees

For repos with a bootstrap-heavy test CLI, prefer invoking the already-bootstrapped main
checkout's runner and point it at the worktree (the local supplement records the exact command):

```bash
cd <main-checkout-path>
<repo-test-command> <path-relative-to-app>
```

- Keep any worktree-pointing env var scoped to the command or terminal, not global shell startup.
- If running the repo's test CLI directly inside a fresh worktree tries to bootstrap its
  virtualenv and fails with registry auth errors, retry from the main checkout using the
  documented env var / invocation.
- Do not reuse an already-running hot test daemon for a different worktree; the daemon is
  mounted to the tree it was started with. Restart it pointed at the target worktree first.
