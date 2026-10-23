---
name: cleanup-worktrees
description: Safely remove worktrees and local branches after verifying their PR and native GitHub stack state
allowed-tools: Bash(*), Read(*)
---

Clean up git worktrees and stale local branches without mutating unrelated native GitHub stacks. Never use stack sync/rebase as a read-only cleanup step.

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

Present ONE unified table covering worktrees and loose local branches. Columns:
Kind, Path-or-name, Branch, PR status, Unique local commits, Active work, Recommendation.

- **Keep**: OPEN PR or active work
- **Remove**: MERGED, only after verifying no active work and no unique local commits
- **Review**: No PR or CLOSED; closed-unmerged branches may contain unique work
- **Review**: detached HEAD worktrees; verify they are disposable before removal

Ask the user to confirm before removing anything. Explicitly call out every branch
that needs force deletion or has unique commits.

### Step 4: Remove confirmed worktrees

```bash
git worktree remove <path>
```

Use `--force` or direct filesystem removal only after explicit confirmation that the
worktree has no active or unique work. If an IDE-managed worktree cannot be removed:

```bash
rm -rf <path>
```

Then run `git worktree prune` once to clean stale references.

### Step 5: Refresh remote refs without mutating stacks

```bash
git fetch --prune origin
```

Do not blindly run `gh stack sync` or `gh stack rebase`: both can rewrite/push active
branches, and `gh stack sync --prune` can delete merged local branches. Inspect with
`gh stack view --short` / `--json` only when stack context is needed.

### Step 6: Delete confirmed stale local branches

```bash
git branch -d <branch-name>
```

If `-d` refuses because commits are unique, stop and ask. Use `git branch -D` only
after the user explicitly authorizes discarding those commits. Never quietly merge them.

### Step 7: Show final state

Run in parallel:

```bash
git worktree list
git branch
```

Report the final count of remaining worktrees and branches.
