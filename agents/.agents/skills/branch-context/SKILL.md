---
name: branch-context
description: Show the current branch's commits and diff against its base (including stacked bases) to provide conversation context. Use when asked for branch context or what changed on this branch.
---

# Branch Context

Show me the changes on the current branch to provide context for our conversation.

## Instructions

1. First, identify the current branch
2. Determine the base branch by finding the merge-base with the main branch (`master` or `main`)
3. If the current branch appears to be based off a non-main branch (e.g., a feature branch off another feature branch), identify and mention this
4. Show the commits on this branch since diverging from the base branch (all the way down to master/main)
5. Explain the diff and any relevant context about the changes by branch

If the branch is based off something other than master/main, clearly indicate what the actual base branch is so I understand the full context of the changes.
