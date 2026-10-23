---
name: create-stacked-pr
description: Create and manage native GitHub stacked PRs with the installed github/gh-stack CLI and the repository's PR workflow
argument-hint: [jira-ticket]
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*)
---

Create PRs for the current branch or branch series, then register them as a **native GitHub stack** with the installed `github/gh-stack` CLI (`gh stack`). A chain of Git branch bases or navigation comments alone is not a stack. Do not use git-spice, `gs`, or the unrelated `ghstack` tool.

> **Local supplement:** If `~/.agents/skill-overrides/create-stacked-pr/instructions.md` exists,
> read it for repo-specific PR creation, label, draft-state, and commit-prefix conventions.
> This skill works without it; the supplement never overrides repository policy or safety rules.

JIRA ticket: $ARGUMENTS (if empty or "no jira", use `N/A`)

## Workflow

### Step 1: Read repository rules and inspect state

Read the repository's nearest `AGENTS.md` / `CLAUDE.md` and PR template before acting. Repository instructions override generic commands below. Gather in parallel:

```bash
git status
git diff --staged
git diff
git branch --show-current
gh stack view --short
gh api user --jq '.login'
```

Use `gh stack view --json` when machine-readable stack details are needed. Determine the trunk branch and the intended bottom-to-top branch order. Keep all branches in one worktree. Branches must follow repository naming rules; read the local supplement for any organization-specific prefix or naming constraints.

### Step 2: Commit coherently

If there are relevant uncommitted changes, stage only those files and commit with Git:

```bash
git add <relevant-files>
git commit -m "<commit message>" -m "Co-Authored-By: <agent-name> <agent-email>"
```

Follow the repository's commit-prefix and attribution rules, including any required `Co-Authored-By` trailer. Do not use a stack tool as a commit wrapper.

For a new layer on a locally tracked stack, first verify the requested parent is its top, then create the layer without setting the parent as an upstream:

```bash
gh stack view --short
gh stack add <new-branch>
```

Do not silently add above a different top or initialize a second stack from an untracked child. Discover existing remote stacks with `gh stack checkout <PR-URL>` in the correct worktree. If the branches already exist but have no local stack, adopt the entire intended chain as below.

If branches already exist, adopt them in bottom-to-top order:

```bash
gh stack init --base <trunk> <bottom-branch> <upper-branch> [...]
```

`gh stack init` may switch branches and creates missing branches, so verify branch names/order first. The default relationship is trunk → bottom branch → each preceding stack branch.

### Step 3: Rebase the stack only with approval

Fetch and cascade the stack with:

```bash
gh stack rebase
```

Useful scoped/recovery forms are `--upstack`, `--downstack`, `--no-trunk`, `--continue`, and `--abort`. Rebasing can rewrite every published branch above the changed layer. Do not rebase or force-push a published stack without the user's approval.

For existing PRs, push stack branches explicitly with the command below. For new PRs, follow Step 4's per-branch push/immediate-create sequence instead of bulk-pushing ahead of required creation:


```bash
gh stack push
```

This uses per-branch force-with-lease behavior, skips merged/queued members, and is **not atomic**. For a brand-new branch pushed outside this command, push the branch to its own remote name—not its base:

```bash
git push -u origin <own-branch>
```

Never leave a new branch tracking its base branch.

### Step 4: Create or preserve the individual PRs

Use the repository's required PR creation flow before linking the stack. Preserve existing PR numbers and draft/ready state. Never use `--open` on an existing normal PR because it can change ready state.

#### A repository with a mandatory PR-creation helper

When the repository requires creating PRs through a helper script or workflow (its `AGENTS.md`
names one), for each branch bottom-up:

1. Complete the repository-level PR template in a file. Use `N/A` for JIRA when there is no ticket.
2. Push the coherent initial commit and immediately create the PR with the required helper,
   following its interface. Do not run repo-required pre-PR checks before this initial creation.
3. Use the correct base: trunk for the bottom PR and the preceding branch for each upper PR.
4. Assign the current GitHub user, add the required labels, and follow repository Code Owner
   requirements.
5. Verify the newly created PR's URL and required draft/ready state. Preserve the current draft
   state of pre-existing PRs; never convert an existing PR merely because work resumed.
6. After the PR exists, run the repository-required checks and push follow-up fixes as instructed.

The local supplement records this repo's helper script, harness label set, commit prefixes, and
draft-state rules.

Do not replace the repository helper with generic stack submission: native auto-creation would
bypass draft enforcement, template content, assignment, labels, and state verification.

#### Other repositories

Follow their local creation rules. Only when a repository explicitly permits the CLI to create PRs may you use:

```bash
gh stack submit --auto
```

Do not use it where creation must go through a wrapper or custom workflow. Do not use `--open` to alter existing PR state.

### Step 5: Link existing PRs into the native GitHub stack

After every member has a PR URL, create the actual native stack object:

```bash
gh stack link --base <trunk> <bottom-PR-URL> <upper-PR-URL> [...]
```

Pass PR URLs, not branch names. Passing branches that lack PRs auto-creates PRs and can bypass repository requirements. If extending an existing native stack, put its stack number first and append the new existing PR URLs as supported by the CLI.

If linking fails because an individual PR has auto-merge enabled, explain the conflict. Disable individual auto-merge only when the user authorizes converting the PRs to an atomic stack; do not merge or silently change settings. Preserve all existing PR numbers.

`gh stack sync` fetches, rebases, pushes atomically, synchronizes PR state, and links existing members; it does not create PRs. Because it mutates branches, use it only when those combined effects are intended and approved—not as a read-only inspection command. `--prune` also deletes merged local branches.

### Step 6: Verify the native stack and PR state

Inspect both CLI and REST state:

```bash
gh stack view --short
gh stack view --json
gh api <PR-REST-path> --jq '{number, head: .head.ref, base: .base.ref, draft, stack: .stack}'
```

For every member verify:

- `.stack.number` is present and identical across members
- `.stack.position` is correct and unique in bottom-to-top order
- `.stack.size` equals the member count on every PR
- head/base relationships are correct
- each PR retained its expected draft/ready state
- PR number, assignment, labels, template, and repository-required checks are correct

A base-branch chain without matching native `.stack` metadata is incomplete.

### Step 7: Report

Report the stack number, ordered PR URLs, branches and positions, draft/ready states, and validation results. Note any checks still running or any user action required.

## Merge safety

Native atomic stack merge is:

```bash
gh stack merge <stack-number>
```

Run it **only** when the user explicitly asks to merge. Never bypass required checks. Do not promise CI runs only once; each PR may run CI unless that repository's pipeline is specifically optimized for stacks.

## Rules

1. Always prefer native `gh stack`; never use git-spice, `gs`, or `ghstack`.
2. A stack is complete only when the native GitHub stack object exists and REST stack metadata verifies it.
3. Keep all branches in one worktree and never track a base branch as the new branch's upstream.
4. Preserve repository branch, commit attribution, PR template, draft, label, assignment, Code Owner, test, and rollback rules.
5. Never add generated-by-agent boilerplate to PR descriptions.
6. Never auto-create PRs through stack linking/submission when repository rules require a separate creation flow.
7. Never merge, enable/disable auto-merge, rewrite published branches, or change ready state without the required explicit authorization.
