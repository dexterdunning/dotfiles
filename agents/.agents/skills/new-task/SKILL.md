---
name: new-task
description: Create a new worktree and branch for a task
argument-hint: <branch-name> [--base <branch>]
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*)
---

Create a new git worktree and branch for starting a task.

> **Local supplement:** If `~/.agents/skill-overrides/new-task/instructions.md` exists, read
> it for the local main-checkout path, worktree root, trunk branch, and branch prefixes.
> This skill works without it; the supplement never overrides repository policy or safety rules.

Arguments: $ARGUMENTS

## Instructions

### Step 0: Refresh the trunk branch in the main worktree
Pull the trunk branch in the main checkout so the new branch is based on the latest. Skip cleanly if the trunk isn't checked out or the working tree is dirty — never disturb in-progress work.


```bash
cd <main-checkout-path>
if [ "$(git rev-parse --abbrev-ref HEAD)" = "<trunk-branch>" ] \
    && git diff --quiet && git diff --cached --quiet; then
  git pull --ff-only origin <trunk-branch>
else
  echo "Skipping main-worktree trunk pull: HEAD=$(git rev-parse --abbrev-ref HEAD) or working tree dirty"
fi
```

### Step 1: Parse arguments

Extract:
- **branch name**: required, first argument. Read the repository's branch rules first and follow its required personal/agent prefix.
- **base branch**: optional `--base <branch>`, defaults to `master`.

If no arguments were provided, ask the user for a branch name.

### Step 2: Validate

1. Check the branch doesn't already exist:
   ```bash
   git branch --list <branch-name>
   git ls-remote --heads origin <branch-name>
   ```
2. Check no worktree already exists at the target path:
   ```bash
   ls <worktree-root>/<name>/
   ```

The worktree `<name>` is the branch name with its required personal/agent prefix stripped. The local supplement names the worktree root and prefixes for this machine.

If either exists, tell the user and ask how to proceed.

### Step 3: Determine whether to stack or create a new worktree

Check if the base branch is in an existing worktree:
```bash
git worktree list
```

**If `--base` is a non-trunk branch AND it's in an existing worktree** (stacking case):
- The new branch must be created **in that same worktree**. Native GitHub stack branches stay together in one worktree.
- Skip to Step 4a (Stack in existing worktree).

**Otherwise** (base is `master`, or base branch isn't in any worktree):
- Create a new worktree. Skip to Step 4b (New worktree).

### Step 4a: Stack in existing worktree

Inspect the existing stack in that worktree. If it is remote-only, discover it with `gh stack checkout <base-PR-URL>` first. Verify the requested parent is the stack's top before adding:

```bash
cd <base-branch-worktree-path>
gh stack view --short
gh stack add <branch-name>
```

Do not silently append above a different parent. If the parent is in the middle of a stack, ask about insertion/fork intent. For an unpublished untracked chain, create the child with `git switch --no-track -c <branch-name> <base-branch>`, then adopt the intended bottom-to-top branches with `gh stack init --base <trunk> <bottom> ... <branch-name>`.

Report to the user:
- Worktree path: `<base-branch-worktree-path>` (shared with stack)
- Branch: `<branch-name>`
- Based on: `<base-branch>`
- Local stack: layer added; native GitHub membership is created/verified during PR publication

Then use that worktree path as the working directory for all subsequent commands in the session.

### Step 4b: New worktree

```bash
git fetch origin <base-branch>
git worktree add --detach <worktree-root>/<name> origin/<base-branch>
git -C <worktree-root>/<name> switch --no-track -c <branch-name>
```

Do not set the base as the branch's upstream. When the branch is ready to publish,
push its own remote branch with `git push -u origin <branch-name>`. If this becomes
a multi-branch stack, use `gh stack init --base master <bottom> <upper> [...]` or
`gh stack add <branch>`; see `create-stacked-pr` for the repository-safe PR flow.

Report to the user:
- Worktree path: `<worktree-root>/<name>`
- Branch: `<branch-name>`
- Based on: `<base-branch>`
- Upstream: none until the branch is pushed to its own remote name

Then use that worktree path as the working directory for all subsequent commands in the session.

### Step 5: Confirm

Show the current state:
```bash
git log --oneline -5
git status
gh stack view --short 2>/dev/null || true
```
