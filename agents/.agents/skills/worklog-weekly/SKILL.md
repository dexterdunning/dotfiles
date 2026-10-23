---
name: worklog-weekly
description: Scan recent activity and generate a tagged weekly summary
argument-hint: [W14 | weeks-back (default 1)]
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*), Write(*), Edit(*), WebFetch(*), AskUserQuestion(*), Task(*)
---

Scan recent Slack, Google Drive, and GitHub activity to build a tagged weekly summary.

**Optional local supplement:** if `~/.agents/skill-overrides/worklog-weekly/instructions.md` exists, read it first — it carries the org's repos, team names, pinned channels, and standing filter preferences. Without it, this workflow works with `~/.worklog/config.yaml` and user-provided sources.

The flow is: Slack first (context discovery + incident channels), then Drive + GitHub in parallel, then interactive tagging.

## Input

$ARGUMENTS — accepts either:
- A **week number**: `W14`, `2026-W14`, or `14` → scan that specific ISO week (Mon–Sun)
- A **weeks-back count**: `2` means scan the last 2 weeks ending today (default: 1)

Heuristic: if the argument is `>= 2026` or starts with `W`/`w`, treat as a specific week. Otherwise treat as weeks-back.

## Slack tooling note (read once)

The Slack search/read tools are named differently per harness. Match by suffix, not exact string:
- Claude: `mcp__claude_ai_Slack__slack_search_public_and_private`, `..._read_thread`, `..._read_channel`, `..._search_channels`
- pi / MCP gateway: `slack_slack_search_public_and_private`, `slack_slack_read_thread`, `slack_slack_read_channel`, `slack_slack_search_channels`

When this doc says `slack_search_public_and_private` (etc.), use whichever prefixed name your harness exposes.

**Response shape:** the search tool returns its payload as a JSON *string* nested at `data.content[0].text`. Parse that string; it has a `results` field (a numbered markdown list of `N. <channel> - <user>: <text> <YYYY-MM-DD HH:MM:SS TZ>`) and a `pagination_info` line containing `cursor \`<cursor>\``.

**Pagination + result cap:** `limit` is effectively ignored — the tool returns ~20 results/page and hard-caps around ~350 total per query regardless of paging. For any window longer than ~1 week you **must chunk by date** (e.g. query a week, and when results stop well before `before:`, re-query with `after:` set to the last returned date until you reach the real end). Sort ascending (`sort:"timestamp", sort_dir:"asc"`) so you can tell truncation (tail stops early) from genuine quiet.

**DMs dominate.** A `from:@<user>` query is authorship-scoped and DMs/self-notes often outnumber real channel posts. Since DMs eat the result cap before channels surface, date-chunking matters even for a single busy week. Exclude DMs/group DMs when aggregating (channel starts with `DM with` / `Group DM`, or `D`-prefixed / no `#` name).

## Steps

### Step 1: Load Config

Read `~/.worklog/config.yaml` to get repos, github_user, slack_channels, and tags with hints.

**Detect the catch-up gap.** List `~/.worklog/summaries/weekly/*.md`, find the most recent covered week, and compute weeks-since-last-run. If no argument was given, default to covering the gap (last-covered-week+1 through the current week) rather than assuming 1. Note that a plain weeks-back count silently spans PTO/quiet stretches — that's fine, but surface the true active date range from the Slack scan rather than the nominal window.

### Step 2: Determine Date Range

**If specific week** (e.g., `W14`):
```bash
# Get Monday of ISO week 14, 2026:
python3 -c "from datetime import date; d = date.fromisocalendar(2026, 14, 1); print(d, d + __import__('datetime').timedelta(days=6))"
```
- Start date: Monday of that ISO week
- End date: Sunday of that ISO week

**If weeks-back** (e.g., `2`):
- End date: today
- Start date: today minus (weeks-back * 7) days

Use: `date -v-<days>d +%Y-%m-%d` on macOS.

### Step 3: Slack Context Discovery

> **Availability check — do this first.** The Slack search tool (see "Slack tooling note" above) can be
> unavailable due to OAuth server downtime or a missing session. Before attempting any Slack
> calls, check whether the `*slack_search_public_and_private` tool is listed as
> an available tool. If it is not, or if any call returns a 503 / auth error:
> - Print: "Slack MCP unavailable — skipping Steps 3 and 4. Proceeding with GitHub + Drive only."
> - Skip the rest of Step 3 and all of Step 4.
> - In the Step 10 summary stats, add a line: `- Slack: unavailable (skipped)`
> - Proceed directly to Step 5.

#### Step 3a: Discover active channels

Before reading any channels, find out which channels the user was actually active in this week. Use the `*slack_search_public_and_private` tool with a query like:

```
from:@<slack_user> after:<start_date> before:<end_date+1day>
```

(`before:` in Slack search is exclusive, so add a day.) Prefer querying by the user's Slack user_id (`from:<@U…>`) over display name. For multi-week windows, chunk by date and page through the cursor as described in the Slack tooling note — do not trust a single call to return the whole window.

From the results:
- Group messages by channel
- **Exclude DMs and group DMs** (channel name starts with `D` or has no `#` name) — only keep public/private channels (`C`-prefixed IDs with a real channel name)
- Count messages per channel, sort descending
- Take the top ~10 channels by message count as the **discovered list**

Union the discovered list with the config's `slack_channels` (pinned channels the user always wants scanned, even with low activity). Dedupe.

The merged list becomes the input to Agent 1 below.

#### Step 3b: Thread drill-down

Before deciding whether to launch Agent 1, automatically drill into threads from the Step 3a search results. This is where the substantive work context lives — a one-line reply in the search results may be the user's contribution to a long design discussion or incident response.

From the Step 3a results, identify every message where the user's message is a **thread reply** (i.e., the message has a `thread_ts` field that differs from its own `ts`, or the API indicates it is a reply rather than a top-level post). For each unique `(channel_id, thread_ts)` pair:

1. Call the `*slack_read_thread` tool with the channel ID and thread timestamp.
2. From the thread, extract:
   - The **parent message** (full text — this is what the user was responding to)
   - **All replies**, filtered to those from the user (by display name from config's `slack_user`)
   - Replies from others that directly respond to the user's messages (for context)
   - Any links, PR URLs, doc URLs, or ticket references in the full thread
3. Summarize each thread as: `[channel] [date] Topic: <derived from parent> — User's contribution: <what user said>`

Deduplicate against threads already fully captured in the Step 3a top-level messages. Add the thread summaries to the channel groupings before deciding on Agent 1.

**When to skip thread drill-down:** If the Step 3a results show the user's messages are all top-level posts (no `thread_ts` field, or `thread_ts == ts`), skip this step.

#### Step 3c: Parallel deep-read

**Shortcut: skip Agent 1 when the concise search + thread drill-down is enough.** The `slack_search_public_and_private` call from Step 3a (with `response_format: "concise"` and `include_context: false`) plus the thread drill-down from Step 3b already returns full message bodies, thread context, links, channel names, and timestamps for every matching message. If the user's week is dominated by short status posts and PR/dashboard link shares (no long threads worth mining), you have everything you need — synthesize directly.

Launch sub-agents in parallel only as needed:

#### Agent 1: Regular channels (optional — skip if Step 3a + 3b results are enough)

subagent_type: `general-purpose`
model: `haiku`

Only launch when channels from config's `slack_channels` had no user activity in the Step 3a search results but may still contain relevant discussion. Prompt the agent with those specific channels, start_date, and end_date. It should:

1. For each channel, use the `*slack_read_channel` tool to read recent messages. If that tool requires a channel ID, first use `*slack_search_channels` to resolve the channel name to an ID.

2. Filter to messages sent by the user (match on display name from config's `slack_user`). Skip channels where the user posted nothing — do not summarize other people's activity.

3. For each channel with user messages, extract:
   - Message text (full content, not truncated)
   - Timestamp / date
   - Any links mentioned (Google Docs URLs, Jira tickets, PR links, dashboard URLs, etc.)
   - Note any thread replies — these will have been captured in Step 3b already, so just flag them rather than re-fetching

4. Group by channel and produce a summary per channel:
   - What topics/projects were discussed
   - Key decisions or updates shared
   - Any documents, tickets, or PRs linked

5. Separately collect any PR links the user shared or discussed — these are candidates for "substantive review" entries.

6. Return results as JSON:
```json
{
  "channels": [
    {
      "name": "#channel-name",
      "message_count": 5,
      "date_range": "2026-03-01 to 2026-03-05",
      "summary": "2-3 bullet point summary",
      "linked_documents": ["https://docs.google.com/..."],
      "linked_dashboards": ["https://app.datadoghq.com/..."],
      "linked_tickets": ["ABC-1234"],
      "linked_prs": ["https://github.com/..."]
    }
  ],
  "work_categories": [
    "Short description of a category of work identified from messages"
  ],
  "pr_reviews_discussed": [
    {
      "url": "https://github.com/...",
      "context": "Brief description of what was discussed about this PR in Slack"
    }
  ]
}
```

#### Agent 2: Incident channel discovery

subagent_type: `general-purpose`
model: `haiku`

Search for incident channels the user participated in during the date range:

1. Use the `*slack_search_channels` tool to search for channels matching the org's incident-channel prefix (e.g. `inc-`) within the date range.
2. For each matching channel, use `*slack_read_channel` and check if the user (by display name) posted messages or was mentioned.
3. For channels with user involvement, extract:
   - Channel name and incident topic
   - User's messages and actions taken
   - Any PRs, dashboards, or docs linked
   - Incident ticket IDs

Return results as JSON:
```json
{
  "incident_channels": [
    {
      "name": "#inc-2026-04-01-...",
      "incident_summary": "What the incident was about",
      "user_involvement": "What the user did",
      "linked_prs": [],
      "linked_dashboards": [],
      "linked_tickets": ["INC-1234"]
    }
  ]
}
```

If no incident channels are found, return `{"incident_channels": []}`.

### Step 4: Confirm Work Categories

Present the Slack-derived work categories to the user:

```
Based on your Slack messages this week, here's what I found:

### #<channel-a> (12 messages)
- Shared updates on refactor progress
- Discussed rollout plan
- Linked: <design doc>, ABC-5678

### #<channel-b> (4 messages)
- Discussed migration approach
- Reviewed logging results

Work categories identified:
1. <category 1>
2. <category 2>
3. <category 3>

Does this look right? Any categories to add, rename, or remove?
```

Use AskUserQuestion to let the user confirm, edit, or add categories.

If the Slack scan found PRs the user discussed (not authored), present those too:

```
PRs you discussed in Slack (potential reviews to log):
- PR #12345 "<title>" — discussed architecture approach
- PR #12346 "<title>" — discussed scoping

Log any of these as substantive reviews?
```

Use AskUserQuestion to let the user select which (if any) to log.

**Also ask about non-code artifacts.** Dashboards, internal scripts, warehouse queries, and other artifacts often don't surface from GitHub or Slack alone. Present whatever Slack/incident scanning found (dashboard links, etc.) and ask:

```
Did you create any dashboards, scripts, warehouse queries, or other artifacts this week
that aren't covered above?
```

Use AskUserQuestion to let the user add any.

### Step 5: Google Drive + GitHub (Parallel)

Launch these two sub-agents **in parallel** (in a single message with multiple Task calls). They don't depend on each other.

#### Agent A: Google Drive Document Search (Conditional)

**Only launch this agent if** the Slack scan surfaced document links or references. Otherwise skip.

subagent_type: `general-purpose`
model: `haiku`

The agent should:
1. For any Google Docs/Sheets/Slides URLs found in Slack messages, extract the file ID and use the Drive MCP tool to get the title and metadata.
2. For any document references by name (e.g., "the storage design doc"), use the Drive search tool with the name as the query, filtered by `modifiedAfter: <start_date>`.
3. For any ticket references, note them for the user (we won't fetch them, just list them).

Return results as JSON:
```json
{
  "documents": [
    {
      "title": "Document Name",
      "file_type": "document",
      "url": "https://docs.google.com/...",
      "date_modified": "2026-03-05"
    }
  ],
  "tickets": ["ABC-1234", "ABC-5678"]
}
```

#### GitHub Authored PRs (use Bash directly — do NOT delegate to a sub-agent)

Run `gh` commands directly via Bash. Sub-agents tend to truncate large JSON output.

**Discover additional repos from Slack.** Before running `gh pr list`, scan the Slack search results from Step 3a for any URLs matching `github.com/<org>/<repo>/pull/<number>`. Extract the distinct `<repo>` set and union with config's `repos` plus the org's auxiliary event repos (if configured in the supplement). Skipping this step misses cross-repo PRs (mobile fixes, rules updates, etc.).

**Use a single `--state all` query with `created:<start>..<end>`.** Beats the separate merged/open queries — surfaces PRs created in the week regardless of current state (open, merged-later, closed/abandoned). Also run a separate `--state merged --search "merged:<start>..<end>"` query to catch PRs created *earlier* but merged in this week (worth flagging for dedup against prior weeks).

For each repo in the unioned set, run:

1. **Merged PRs:**
   ```bash
   gh pr list --repo <repo> --author <github_user> --state merged --search "merged:>=$start_date" --json number,title,url,mergedAt --limit 50 | python3 -c "import json,sys; prs=json.load(sys.stdin); [print(f'{p[\"mergedAt\"][:10]} #{p[\"number\"]} {p[\"title\"]} {p[\"url\"]}') for p in sorted(prs, key=lambda x: x['mergedAt'])]"
   ```

2. **Open PRs (created in date range):**
   ```bash
   gh pr list --repo <repo> --author <github_user> --state open --json number,title,url,createdAt --limit 50 | python3 -c "import json,sys; prs=json.load(sys.stdin); [print(f'{p[\"createdAt\"][:10]} #{p[\"number\"]} {p[\"title\"]} {p[\"url\"]}') for p in sorted(prs, key=lambda x: x['createdAt'], reverse=True) if p['createdAt'][:10] >= '$start_date']"
   ```

Also check the org's auxiliary repos configured for event/tooling PRs, if any:
```bash
gh pr list --repo <org>/<aux-repo> --author <github_user> --state all --search "created:>=$start_date" --json number,title,url,createdAt,mergedAt,state --limit 50
```

**Note:** PR reviews are NOT fetched from GitHub API. Instead, reviews worth logging are identified from Slack discussion in Step 3 and confirmed by the user in Step 4.

### Step 6: Deduplicate Against Existing Entries

1. List all files in `~/.worklog/entries/` whose filenames start with dates in the range.
2. `cat` all matching files and extract every URL from `links:` / `url:` fields.
3. Build a set of already-logged URLs (GitHub PR URLs, doc URLs, etc.).
4. Filter the PR list and artifact list against this set — only present NEW items to the user.
5. Briefly note how many items were skipped as duplicates (e.g., "Skipped 8 already-logged PRs from W13").

**Apply built-in filters before presenting items to the user:**

- **Routine flag-removal PRs** — Drop any PR whose sole purpose is removing a fully rolled-out feature flag. Title patterns: starts with "Remove" and mentions a flag name, or contains phrases like "Remove rolled-out" / "cleanup FF". These carry no perf-review signal — the engineering judgment is captured by the rollout itself, not the cleanup commit. Apply silently.

**Also apply persistent worklog filters from memory.** Read any worklog-specific filters from the user's agent memory directory (files matching `feedback_worklog_*.md`), when present. These encode the user's standing preferences for what to silently drop beyond the built-in rules above. Apply them quietly; do not present filtered items for tagging. Note the combined count of filtered items (built-in + memory rules) in the final summary so the user can audit.

### Step 7: Interactive Tagging

Now present all items (PRs + confirmed docs + confirmed reviews) to the user for tagging. Use the work categories from Step 4 to auto-suggest tags:

- Match PR titles, file paths, and labels against:
  1. The work categories confirmed by the user
  2. The tag hints from config.yaml
- For documents, use the category they were discovered under

Present items grouped by work category (not by source):

```
=== <Category A> (3 items) ===

[1/15] PR #12345 "<title>" (open, 2026-03-05)
  Auto-tag: [category-a]
[2/15] PR #12346 "<title>" (open, 2026-03-07)
  Auto-tag: [category-a]
[3/15] Doc: "<doc title>" (2026-03-03)
  Auto-tag: [category-a]

Accept all with [category-a]? (y) / Edit / Skip some

=== <Category B> (8 items) ===
...

=== Uncategorized (2 items) ===
[14/15] PR #12347 "<title>"
  No auto-tag — assign a tag or skip?
```

If the user wants to add a tag that doesn't exist, offer to create it (ask for type and description, add to config.yaml).

### Step 8: Save Entries

For each accepted item, write a YAML entry to `~/.worklog/entries/<date>_<id>.yaml`.

Group related PRs into batch entries where it makes sense (e.g., a 3-step migration = 1 entry with 3 links).

**Review-wiring fields (add when known — cheap now, expensive to reconstruct later):**
For any entry that could end up in a perf review, capture these at save time. Don't block on
them; fill what's known.
- `ownership: driver | contributor | enabler | reviewer` — your role, plus who else
  drove/reviewed if a senior/peer's attribution matters.
- `metrics:` — the headline before/after, e.g. `- write_conflicts: 6.8M -> 1.4M (-80%)`.
- `review_worthy: achievement | missed-opportunity | leadership-principle | growth | no` —
  which review-question shape this fits, so review time is assembly not archaeology.
- `resolves_incidents:` / `caused_incident:` — explicit incident linkage, plus any
  leadership-attributed impact quote.

**Entry templates by type:**

PR entry (single):
```yaml
title: "<PR title cleaned up>"
type: pr
date: YYYY-MM-DD
tags: [tag-id]
ownership: driver
review_worthy: achievement
metrics:
  - <label>: <before> -> <after>
links:
  - https://github.com/<org>/<repo>/pull/<number>
impact: "1–3 sentence why/what."
```

PR batch (multiple related PRs):
```yaml
title: "<batch title>"
type: pr-batch
date: YYYY-MM-DD
tags: [tag-id, optional-second-tag]
links:
  - https://github.com/<org>/<repo>/pull/<n1>
  - https://github.com/<org>/<repo>/pull/<n2>
impact: |
  Multi-line description of the cluster of work.
```

Doc entry (wiki pages, tech specs, design docs — even outside Google Drive):
```yaml
title: "<doc title or topic>"
type: doc
date: YYYY-MM-DD
tags: [tag-id]
links:
  - https://<org>.atlassian.net/wiki/...
impact: "Why the doc was written and what it covers."
```

Incident-tied entries (PR or batch) — add `incident:` field and optionally a `narrative:` field for short lessons:
```yaml
incident: "#inc-YYYY-MM-DD-..."
narrative: |
  Short lesson worth remembering for future perf reviews.
```

### Step 9: Project Narratives (the main event)

**This is the most important step.** PRs are evidence; narratives are what matter for perf reviews.

After saving PR entries, prompt the user for narratives. Present context from the week's activity to jog their memory:

```
This week you worked on: [<category-a> (8 PRs), incident-response (3 PRs + dashboard), ...]

Any project wins, lessons, or reflections you want to capture?

Options:
1. Share a Slack link → I'll do a deep capture (full text, images, thread replies)
2. Write a fresh narrative → I'll guide you through it
3. Skip → just the PR log this week
```

Use AskUserQuestion to let the user choose.

#### Option 1: Deep Slack Capture

If the user shares a Slack link:

1. Use the `*slack_read_thread` tool to get the full message + all replies.
2. Extract:
   - **Full message text** (preserving formatting, bullet points, bold)
   - **Key thread replies** — especially from leadership, skip "nice!" one-liners
   - **Reaction summary** — total count and notable emoji types
   - **Attached file names and IDs** — note: Slack image URLs expire, so record file IDs for reference
3. Save as `~/.worklog/narratives/<date>_<slug>.md`:

```markdown
---
date: YYYY-MM-DD
tags: [tag1, tag2]
type: win | lesson | incident-retro | design-decision
source: slack
slack_link: <original URL>
---

# <Title derived from message>

## What I posted

<Full message text, cleaned up for markdown>

## Peer Recognition

> **<Name>**: "<exact quote>"

> **<Name>**: "<exact quote>"

## Engagement
- 10 :rocket:, 9 :tada:, 1 :raised_hands:
- 4 thread replies from leadership and peers

## Supporting Evidence
- PR #<n>: <one-line summary>
- PR #<n>: <one-line summary>
- Incidents resolved: #inc-2026-01-28, #inc-2026-02-09
```

#### Option 2: Guided Narrative

If the user wants to write a fresh narrative, ask these questions one at a time via AskUserQuestion:

1. **What project or accomplishment?** (free text — title)
2. **What type?** (win / lesson / incident-retro / design-decision)
3. **What did you do and why was it hard?** (the core narrative — 2-5 sentences)
4. **What was the quantitative impact?** (metrics, before/after, scope — optional but encouraged)
5. **What would you do differently?** (growth signal — optional)
6. **Any supporting links?** (PRs, docs, dashboards — auto-suggest from this week's entries)

Save as `~/.worklog/narratives/<date>_<slug>.md` with similar frontmatter.

#### Option 3: Skip

Move on to the weekly summary. Gently note: "No narrative this week — consider capturing one next time if there's a win or lesson worth preserving."

**The user can add multiple narratives** — after each one, ask "Any more?" until they say no.

### Step 10: Generate Weekly Summary

Generate a markdown summary at `~/.worklog/summaries/weekly/<year>-W<week>.md`.

**Multi-week / catch-up runs:** when the window spans more than one ISO week (weeks-back ≥ 2, or a gap since the last run), write a single combined file named `<year>-W<start>-W<end>.md` (e.g. `2026-W28-W32.md`) and **group by theme/tag, not by week** — projects usually span multiple weeks, so a per-week split fragments them. Open the file noting the true active date range (from the Slack scan) and call out any weeks that were quiet/PTO.

Single-week template:

```markdown
# Week of <start-date> to <end-date>

## Narratives
- [Win: 80% Reduction in Time Entry Write Conflicts](../../narratives/2026-03-27_write_conflict_reduction.md)

## By Tag

### <category-a>
- PR #12345: <title> (open, 2026-03-05)
- PR #12346: <title> (open, 2026-03-07)
- Doc: <doc title> (2026-03-03)

### <category-b>
- PR #12347: <title> (2026-03-06)
- ...

## Untagged
- (any items the user accepted without tags)

## Stats
- Narratives captured: 1
- New PR entries: 15
- PRs merged: 10
- PRs open: 3
- PRs reviewed (substantive): 1
- Google Drive docs: 2
- Skipped (already logged): N
- Skipped (filter rules from memory): N
- Closed/abandoned: N
```

### Step 11: Report

Show the user:
- How many items were found per source vs. already logged vs. newly added
- How many narratives were captured this week
- Path to the weekly summary file
- Path(s) to any new narrative files
