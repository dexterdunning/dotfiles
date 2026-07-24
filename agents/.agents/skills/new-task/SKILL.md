---
name: new-task
description: Create a new worktree and branch for a task
argument-hint: <branch-name> [--base <branch>]
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*)
---

Create a new git worktree and branch for starting a task.

Arguments: $ARGUMENTS

## Instructions

### Step 0: Refresh master in the main worktree

Pull master in the main worktree so the new branch is based on the latest. Skip cleanly if master isn't checked out or the working tree is dirty — never disturb in-progress work.

```bash
cd /Users/dexter/projects/rippling-main
if [ "$(git rev-parse --abbrev-ref HEAD)" = "master" ] \
    && git diff --quiet && git diff --cached --quiet; then
  git pull --ff-only origin master
else
  echo "Skipping main-worktree master pull: HEAD=$(git rev-parse --abbrev-ref HEAD) or working tree dirty"
fi
```

### Step 1: Parse arguments

Extract:
- **branch name**: required, first argument. Must start with `dexter-`. If the user provides a name without the prefix, add it.
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
   ls /Users/dexter/projects/rippling-worktrees/<name>/
   ```

The worktree `<name>` is the branch name with the `dexter-` prefix stripped. For example, branch `dexter-fix-staleness-bug` gets worktree name `fix-staleness-bug` at `/Users/dexter/projects/rippling-worktrees/fix-staleness-bug`.

If either exists, tell the user and ask how to proceed.

### Step 3: Determine whether to stack or create a new worktree

Check if the base branch is in an existing worktree:
```bash
git worktree list
```

**If `--base` is a non-trunk branch AND it's in an existing worktree** (stacking case):
- The new branch must be created **in that same worktree** so `gs stack restack` and `gs stack submit` can switch between stacked branches.
- Skip to Step 4a (Stack in existing worktree).

**Otherwise** (base is `master`, or base branch isn't in any worktree):
- Create a new worktree. Skip to Step 4b (New worktree).

### Step 4a: Stack in existing worktree

```bash
cd <base-branch-worktree-path>
git fetch origin <base-branch>
git checkout -b <branch-name>
gs branch track --base <base-branch>
```

Report to the user:
- Worktree path: `<base-branch-worktree-path>` (shared with stack)
- Branch: `<branch-name>`
- Based on: `<base-branch>`
- git-spice: tracked, stacked

Then use that worktree path as the working directory for all subsequent commands in the session.

### Step 4b: New worktree

```bash
git fetch origin <base-branch>
git worktree add -b <branch-name> /Users/dexter/projects/rippling-worktrees/<name> origin/<base-branch>
# Clear the auto-set upstream — `git worktree add ... origin/<base>` makes
# the new branch track origin/<base>, which causes `gs branch submit` to
# push to <base> instead of creating its own remote branch.
git -C /Users/dexter/projects/rippling-worktrees/<name> branch --unset-upstream
```

Then initialize git-spice tracking:
```bash
cd /Users/dexter/projects/rippling-worktrees/<name>
gs repo init --trunk=master --remote=origin 2>/dev/null || true
gs branch track --base <base-branch>
```

Report to the user:
- Worktree path: `/Users/dexter/projects/rippling-worktrees/<name>`
- Branch: `<branch-name>`
- Based on: `<base-branch>`
- git-spice: tracked

Then use that worktree path as the working directory for all subsequent commands in the session.

### Step 5: Confirm

Show the current state:
```bash
git log --oneline -5
git status
gs log short 2>/dev/null || true
```
