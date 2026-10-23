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

Check the requested PR's remote stack metadata, not the stack of the current checkout:

```bash
gh api repos/<owner>/<repo>/pulls/<number> --jq '.stack'
```

A non-trunk base alone is not proof of a native stack. If `.stack` is present, identify its members and check whether any member is already in a worktree:

- **If a stack member IS in a worktree:**
  - Use that worktree — stack branches stay together in one worktree.
  - Discover the remote stack and check out its target there:
    ```bash
    cd <stack-worktree-path>
    gh stack checkout <PR-URL-or-stack-number>
    ```
  - Tell the user which shared stack worktree is active.

- **If no stack member is in a worktree** (standalone PR or stack not yet local):
  - Create one worktree in the standard location. The worktree name is the branch
    name with its repository-required personal/agent prefix stripped:
    ```bash
    git fetch origin <branch>
    git worktree add "$HOME/projects/worktrees/<name>" origin/<branch>
    ```
  - For a native stack, run `gh stack checkout <PR-URL-or-stack-number>` in that
    worktree so the CLI discovers and tracks the stack branches locally. Do not
    create one worktree per member.
  - Then use that worktree path as the working directory.

Do not run `gh stack sync` or `gh stack rebase` merely to check out or inspect a PR;
those commands mutate branch state.

### Step 4: Show context

Once in the right directory, show the current state:
```bash
git log --oneline -5
git status
gh stack view --short 2>/dev/null || true
```

Report the working directory, branch, and stack position (if any) to the user so they know where they're operating.
