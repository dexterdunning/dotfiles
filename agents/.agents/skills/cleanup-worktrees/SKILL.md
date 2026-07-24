---
name: cleanup-worktrees
description: Remove worktrees that no longer have open PRs and clean up git-spice state
allowed-tools: Bash(*), Read(*)
---

Clean up git worktrees whose branches no longer have open PRs, sync git-spice, and delete stale local branches (including branches in the main worktree that have no worktree attached).

## Instructions

### Step 1: Inventory worktrees and local branches

Run in parallel:

```bash
git worktree list
git branch
```

- **Worktree candidates**: non-main, non-master worktrees, plus any `(detached HEAD)` worktree.
- **Local branch candidates**: every branch from `git branch` except `master` and any branch that is already checked out in a worktree (shown in `git worktree list`). These are branches sitting in the main worktree's refs that may be stale.

### Step 2: Check PR status for every candidate

For each worktree branch AND each local branch, check PR status:

```bash
gh pr list --head <branch-name> --state all --json number,state,title --jq '.[0] // "NO_PR"'
```

Loop over all candidates in a single bash call to minimize overhead.

### Step 3: Present a combined findings table

Present ONE unified table covering both worktrees and loose local branches. Columns: Kind (worktree / branch), Path-or-name, Branch, PR status (OPEN #N / MERGED #N / CLOSED #N / No PR), Recommendation (Keep / Remove).

- **Keep**: OPEN PR
- **Remove**: No PR, MERGED, or CLOSED
- **Remove**: detached HEAD worktrees (Cursor artifacts, etc.)

Ask the user to confirm before removing anything. A single confirmation covers both worktrees and loose branches.

### Step 4: Remove confirmed worktrees

```bash
git worktree remove --force <path>
```

If `git worktree remove` hangs or fails on Cursor/IDE-managed worktrees, fall back to:

```bash
rm -rf <path>
```

Then run `git worktree prune` once at the end to clean up stale references.

### Step 5: Sync git-spice

`gs repo sync` pulls latest and auto-deletes merged tracked branches:

```bash
gs repo sync --no-prompt
```

### Step 6: Delete remaining stale local branches

Delete the loose local branches flagged in Step 3 that still exist after `gs repo sync`:

```bash
gs branch delete --no-prompt --force <branch-name>  # preferred; falls back to git if untracked
```

`gs branch delete` handles both tracked and untracked branches. If it fails, fall back to:

```bash
git branch -D <branch-name>
```

### Step 7: Show final state

Run in parallel:

```bash
git worktree list
git branch
```

Report the final count of remaining worktrees and branches.
