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
2. **What type?** win / lesson / incident-retro / design-decision / feedback-received
3. **What did you do and why was it hard?** (2-5 sentences)
4. **What was the quantitative impact?** (optional but encouraged — capture the headline
   before/after metric now, e.g. `write_conflicts: 6.8M -> 1.4M (-80%)`, so it doesn't have
   to be re-derived from a dashboard later)
5. **What would you do differently?** (optional — growth signal)
6. **Any supporting links?** (PRs, docs, dashboards)

**Always also prompt for the review-wiring fields** (these are what perf reviews actually
probe, and are cheap to answer at capture time but painful to reconstruct later):

7. **Ownership** — `driver | contributor | enabler | reviewer`. Who else drove/reviewed it?
   Record their name + role if they're a senior/peer whose attribution matters.
8. **Review-worthy?** — is this a story you'd put in a self-review? If yes, note *which
   question shape* it fits (achievement / missed-opportunity / leadership-principle /
   growth) so review time is assembly, not archaeology.
9. **Feedback received** — if this came out of feedback from a manager/peer (esp. critical or
   constructive), capture WHO said it and WHAT they said. Received-feedback is the hardest
   Q2/Q4 material to surface later; record it when it happens.
10. **Incident linkage** — if this resolves or was caused by an incident, record
    `resolves_incidents:` / `caused_incident:` explicitly, plus any leadership-attributed
    impact quote (e.g. "Willy: this caused all 3 DB incidents").

### Step 3: Tag

Present auto-suggested tags and let the user confirm or edit.

### Step 4: Save

Write to `~/.worklog/narratives/<date>_<slug>.md`:

```markdown
---
date: YYYY-MM-DD
tags: [tag1, tag2]
type: win | lesson | incident-retro | design-decision | feedback-received
source: slack | manual
slack_link: <URL if from Slack>
ownership: driver | contributor | enabler | reviewer
review_worthy: achievement | missed-opportunity | leadership-principle | growth | no
metrics:
  - <label>: <before> -> <after> (<delta>)
resolves_incidents: ["#inc-..."]   # if applicable
caused_incident: "#inc-..."        # if applicable
feedback_from: "<name> (<role>): <what they said>"   # if applicable
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
