---
name: worklog-capture
description: Capture a project narrative from a Slack link or free-form
argument-hint: [slack-link | description]
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*), Write(*), Edit(*), AskUserQuestion(*)
---

Capture a project narrative to `~/.worklog/narratives/`. This is for wins, lessons, incident retros, and design decisions — the artifacts that matter for perf reviews.

## Input

$ARGUMENTS — a Slack message link, or a short description to start a guided narrative.

## Steps

### Step 1: Load Config

Read `~/.worklog/config.yaml` to get tags and their hints.

### Step 2: Determine Capture Mode

**If a Slack link was provided** (contains `slack.com`):

1. Parse the channel ID and message timestamp from the URL.
2. Use `mcp__claude_ai_Slack__slack_read_thread` to get the full message + all thread replies.
3. Extract:
   - **Full message text** (preserving formatting)
   - **Key thread replies** — prioritize leadership/peer recognition, skip one-liners like "nice!"
   - **Reaction summary** — emoji types and counts
   - **Attached file names and IDs** — note these for reference (Slack image URLs expire)
4. Auto-detect type: if message contains metrics/numbers → `win`, if mentions incident → `incident-retro`
5. Auto-suggest tags by matching message content against config tag hints.

**If a description was provided** (or empty):

Guide the user through a narrative with these questions (use AskUserQuestion):

1. **What project or accomplishment?** (title)
2. **What type?** win / lesson / incident-retro / design-decision
3. **What did you do and why was it hard?** (2-5 sentences)
4. **What was the quantitative impact?** (optional but encouraged)
5. **What would you do differently?** (optional — growth signal)
6. **Any supporting links?** (PRs, docs, dashboards)

### Step 3: Tag

Present auto-suggested tags and let the user confirm or edit.

### Step 4: Save

Write to `~/.worklog/narratives/<date>_<slug>.md`:

```markdown
---
date: YYYY-MM-DD
tags: [tag1, tag2]
type: win | lesson | incident-retro | design-decision
source: slack | manual
slack_link: <URL if from Slack>
---

# <Title>

## What I did
<narrative text>

## Peer Recognition (if from Slack with replies)
> **Name**: "quote"

## Engagement (if from Slack)
- X :rocket:, Y :tada:

## Supporting Evidence
- PR #123: description
- Dashboard: URL
```

### Step 5: Confirm

Show the user the saved file path and a preview of the narrative.
