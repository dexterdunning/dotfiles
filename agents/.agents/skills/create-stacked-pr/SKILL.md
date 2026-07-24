---
name: create-stacked-pr
description: Create a stacked PR using git-spice with proper template
argument-hint: [jira-ticket]
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*)
---

Submit the current branch as a PR using git-spice (`gs`). Assumes the branch already exists and is tracked (use `/new-task` to create branches).

JIRA ticket: $ARGUMENTS (if empty or "no jira", use "no jira")

## Workflow

### Step 1: Gather Information

Run these commands in parallel:
- `git status` - see current changes
- `git diff --staged` - see staged changes
- `git diff` - see unstaged changes
- `gs log short` - see current git-spice branch stack
- `gh api user --jq '.login'` - get GitHub username for assignment

### Step 2: Stage and Commit Changes

If there are uncommitted changes, stage and commit them.

**Commit prefix rule**: Use `[tanda]` prefix only if the changes are in the `time_tracking` module or closely related time tracking code. Otherwise, use a plain commit message.

```bash
git add <relevant-files>
gs commit create -m "<commit message>"
```

### Step 3: Rebase if needed

Check the stack position:
- **If this is the base branch** (bottom of stack or standalone): run `gs rs --restack` to sync with master and restack before submitting.
- **If this is an upper branch** (pr2, pr3, etc.): ask the user whether to rebase off master or just restack onto the immediate base.

### Step 4: Submit PR with git-spice

**IMPORTANT**: Do NOT use `--fill` — it auto-fills the PR title from git history and frequently picks up the wrong commit message. Always provide an explicit `--title`.

```bash
gs branch submit --title "<PR title>" --no-draft --label=claude --body "$(cat <<'EOF'
**JIRA**: <jira-ticket-or-"no jira">

## Description

<1-3 sentence summary of what changed and why>

## Test Plan

- [x] I take full responsibility for this code and its quality, whether written by me or with AI.

<describe testing performed>

## Rollback plan

Refer to [Playbook: Non-Revertible to Revertible Pull Request](https://rippling.atlassian.net/wiki/x/pYBIFgE) to learn which changes are non-revertible.

- [x] Check this box if this PR can be safely reverted.
- [ ] Check this box if this PR CANNOT be safely reverted.

<rollback explanation>
EOF
)"
```

Then assign the PR:
```bash
gh pr edit <pr-number> --add-assignee <github-username>
```

**If submitting a stack**, after all individual branches are submitted, verify the stack from the bottom:
```bash
git checkout <bottom-branch>
gs upstack submit --force
```

### Step 5: Report Results

Report: PR URL, branch name, stack position (if part of a stack).

## Rules

1. **JIRA**: Use provided argument, or "no jira" if empty
2. **Template**: Always use the full PR template from PULL_REQUEST_TEMPLATE.md
3. **Labels**: Always add `claude` label
4. **Assignment**: Always assign to the current user
5. **Rollback**: Default to "can be safely reverted" unless the change involves database migrations, schema changes, data backfills, or breaking API changes
6. **Never** add "Generated with Claude" to PR descriptions
7. **Stack awareness**: When part of a stack, note the base branch relationship
