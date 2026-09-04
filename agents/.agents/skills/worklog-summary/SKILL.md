---
name: worklog-summary
description: Synthesize worklog into perf-review-ready project stories
argument-hint: "[--half H1-2026] [--quarter Q1-2026] [--year 2026] [--tag TAG]"
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*), Write(*), Edit(*), AskUserQuestion(*)
---

Synthesize worklog entries and narratives into perf-review-ready project stories. This is the tool for answering "what was your most impactful project?" and "where do you need to grow?"

## Input

$ARGUMENTS — time period and optional tag filter. Examples:
- `--half H1-2026` — January through June 2026
- `--quarter Q1-2026` — January through March 2026
- `--year 2026` — full year
- `--tag company-sharding` — single project deep-dive
- `--since 2026-01-01 --until 2026-06-30` — custom range
- (no args) — prompt the user

## Steps

### Step 1: Parse Arguments

Map time shortcuts to date ranges:
- `Q1` = Jan 1 – Mar 31, `Q2` = Apr 1 – Jun 30, `Q3` = Jul 1 – Sep 30, `Q4` = Oct 1 – Dec 31
- `H1` = Jan 1 – Jun 30, `H2` = Jul 1 – Dec 31

If no arguments, ask the user what time period they want.

### Step 2: Load All Data

Read in parallel:
1. All YAML entries from `~/.worklog/entries/` within the date range
2. All narratives from `~/.worklog/narratives/` within the date range
3. Weekly summaries from `~/.worklog/summaries/weekly/` within the date range
4. Tag definitions from `~/.worklog/config.yaml`

### Step 3: Build Project Stories

For each tag that has entries in the period, synthesize a **project story**:

**Structure each story as:**

```markdown
### <Project Name> (<tag>)

**Scope**: <one sentence — what was the goal and why did it matter>

**Your role**: <what specifically you drove — designed, implemented, led, responded to>

**Key accomplishments**:
- <accomplishment with metric if available>
- <accomplishment with metric if available>

**What was hard**: <the technical or organizational challenge — this is what distinguishes senior from routine work>

**Impact**: <quantitative where possible — before/after metrics, incidents prevented, performance gains>

**Evidence**: <X PRs merged, Y open, Z narratives>
```

**To build each story:**
- Pull quantitative metrics from narratives (these are the gold — "6.8M → 1.4M write conflicts")
- Pull peer recognition quotes from narratives
- Count PRs as volume evidence
- Connect related incidents, dashboards, and docs
- If a tag has narratives, lead with those. If it only has PRs, note "no narrative captured — consider writing one"

### Step 4: Identify Strengths and Growth Areas

Based on the data, generate two sections:

**What you're doing well** (look for signals):
- Projects with strong quantitative impact
- Narratives with leadership recognition
- Incident responses that show ownership
- Cross-cutting work that affected multiple systems
- Increasing scope/complexity over the period

**Areas to develop** (look for gaps):
- Tags with lots of PRs but no narratives (doing the work but not telling the story)
- Weeks with no narratives captured (potential missed wins)
- Types of work underrepresented (e.g., mentoring, design docs, cross-team collaboration)
- Projects that stalled or have mostly open PRs

Present these as observations, not judgments — the user knows their context better.

### Step 5: Generate the Perf Review Document

Save to `~/.worklog/summaries/<period>.md` (e.g., `H1-2026.md`, `Q1-2026.md`):

```markdown
# Performance Review: <period>
# Generated: <today's date>

## Highlight Reel
Top 3-5 accomplishments, each with a one-line summary and link to the full narrative.

## Project Stories
<all project stories from Step 3, ordered by impact>

## Strengths
<from Step 4>

## Growth Areas
<from Step 4>

## By the Numbers
- Narratives captured: X
- Total PR entries: Y
- PRs merged: Z
- Code reviews: N
- Incidents responded to: M
- Dashboards/tools created: P

## Narrative Coverage
| Week | Narrative? | Notes |
|------|-----------|-------|
| W10  | Yes       | Write conflict reduction win |
| W11  | No        | — |
| W12  | No        | — |
| W13  | Yes       | Disk usage incident response |
| W14  | No        | — |
```

### Step 6: Interactive Review

Present the highlight reel and project stories to the user. Ask:

```
Here's your review draft. A few questions:

1. Do the project stories capture the right emphasis?
   (Sometimes the hardest work isn't the most visible)

2. Any projects or accomplishments missing that aren't in the worklog?
   (Cross-team work, mentoring, design influence often go unlogged)

3. For the growth areas — do these resonate, or am I missing context?
```

Use AskUserQuestion to let the user refine. Update the saved document with their input.
