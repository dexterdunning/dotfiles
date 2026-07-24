---
name: checkout-pr
description: Check out a PR branch, finding it in worktrees if it already exists locally
argument-hint: <pr-number-or-url>
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*)
---

Check out a PR branch for local work. Handles worktrees and stacked branches correctly.

PR: $ARGUMENTS

## Instructions

### Step 1: Resolve the PR branch name and base branch

If the argument is a URL, extract the PR number. Then fetch the branch name and base branch:
```bash
gh pr view <number> --json headRefName,baseRefName --jq '{head: .headRefName, base: .baseRefName}'
```

### Step 2: Check if the branch exists in a worktree

```bash
git worktree list
```

Search the output for the branch name. Worktrees show the branch in brackets, e.g. `[dexter-my-branch]`.

### Step 3: Navigate to the right location

**If the branch IS already in a worktree:**
- Identify the worktree path from the output
- Use that path as the working directory for all subsequent commands
- Tell the user: "Branch `<branch>` is already checked out in worktree at `<path>`. Working from there."

**If the branch is NOT in a worktree:**

Check if this PR is part of a **stack** (base branch is NOT `master`/`main`). If stacked, check whether the **base branch** or any other branch in the stack is already in a worktree:

- **If the base branch IS in a worktree** (stacked PR case):
  - Use that worktree — stacked branches must share a worktree so `gs stack restack` can switch between them.
  - Fetch and checkout the target branch within that worktree:
    ```bash
    cd <base-branch-worktree-path>
    git fetch origin <branch>
    git checkout <branch>
    ```
  - Tell the user: "Branch `<branch>` is stacked on `<base>`, which is in worktree at `<path>`. Checked out `<branch>` there to keep the stack together."

- **If the base branch is NOT in a worktree** (standalone PR or stack not yet local):
  - Create a new worktree in the standard location. The worktree name is the branch name with the `dexter-` prefix stripped (e.g. `dexter-fix-bug` → `fix-bug`):
    ```bash
    git fetch origin <branch>
    git worktree add /Users/dexter/projects/rippling-worktrees/<name> origin/<branch>
    ```
  - Then use that worktree path as the working directory.

### Step 4: Show context

Once in the right directory, show the current state:
```bash
git log --oneline -5
git status
gs log short 2>/dev/null || true
```

Report the working directory, branch, and stack position (if any) to the user so they know where they're operating.
