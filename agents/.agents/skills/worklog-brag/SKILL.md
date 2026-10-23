---
name: worklog-brag
description: Generate a monthly brag doc for manager 1:1s — interview rounds to fill gaps before data expires
argument-hint: "[--month 2026-06] [--quick draft-only, skip interview rounds]"
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*), Write(*), Edit(*), AskUserQuestion(*), Task(*)
---

Generate a short monthly brag doc for manager 1:1s. This is **not** a perf review packet — use `/worklog-summary` for that.

**Optional local supplement:** if `~/.agents/skill-overrides/worklog-brag/instructions.md` exists, read it first — it carries the org's repos, team names, channels, career-ladder paths, and config specifics. Without it, this workflow works with `~/.worklog/config.yaml` and user-provided sources.

**Why interview rounds matter:** Platform data disappears. Slack thread context and file URLs expire. Datadog log detail ages out. GitHub review *discussions* get buried. Monthly brag is often the **last chance** to capture recognition quotes, before/after metrics, and invisible work before it's gone. **Do not skip interview rounds** unless the user passes `--quick`.

**Relationship to other worklog commands:**

| Command | Cadence | Audience | Output |
|---------|---------|----------|--------|
| `/worklog-weekly` | Weekly | You | PR entries + optional narratives + weekly summary |
| `/worklog-brag` | Monthly | Manager 1:1 | `~/.worklog/summaries/monthly/YYYY-MM.md` |
| `/worklog-capture` | Ad hoc | You | Narrative from Slack or guided interview |
| `/worklog-summary` | Quarter/half/year | Perf review | Project stories + strengths/growth |

## Input

$ARGUMENTS — examples:
- `--month 2026-06` — June 2026
- `June 2026` / `2026-06` — same
- `--quick` — draft from worklog only, skip interview rounds (not recommended)
- (no args) — **previous calendar month**

## Steps

### Step 1: Parse Month

Resolve to `YYYY-MM`, first day, and last day of that calendar month.

```bash
python3 -c "import calendar; from datetime import date; y,m=2026,6; print(date(y,m,1), date(y,m,calendar.monthrange(y,m)[1]))"
```

If no args, use previous calendar month relative to today.

Set `quick_mode = true` if `--quick` is passed.

### Step 2: Load Data

Read in parallel for `[first_day, last_day]`:

1. **Narratives** — `~/.worklog/narratives/*.md` (frontmatter `date:`)
2. **Entries** — `~/.worklog/entries/*.yaml` (`date:` field)
3. **Weekly summaries** — `~/.worklog/summaries/weekly/*.md` overlapping the month
4. **Prior brag doc** — `~/.worklog/summaries/monthly/<prev-month>.md`
5. **Config** — `~/.worklog/config.yaml`

### Step 3: Extract Brag-Worthy Items

**Priority order:**

1. Narratives: `win`, strong `incident-retro`, `design-decision`
2. Peer quotes from `## Peer Recognition`
3. Entries with substantive `impact:` (metrics, multi-line)
4. Entries tagged `career-growth` or type `doc`
5. High-signal entries without narratives — **flag as thin evidence**

**Exclude:** flag-cleanup PRs, routine opens, duplicates from prior month unless materially progressed.

**Tone:** outcome-first, one line per bullet. Metrics beat PR numbers.

### Step 4: Build Gap Inventory

Before drafting, produce an internal gap list. This drives interview rounds.

| Gap type | How to detect | Retention risk |
|----------|---------------|----------------|
| **Missing week** | ISO week in month with no `summaries/weekly/YYYY-Wnn.md` | Slack search window closing |
| **Missing narrative** | Week has entries but no narrative in that week | Win story + quotes may be lost |
| **Thin highlight** | Tag has ≥3 entries, no narrative, draft bullet has no metric | Impact numbers in Datadog/logs aging out |
| **No recognition** | Zero peer quotes in month | Slack thread replies expire |
| **No career-growth** | Zero `career-growth` tag entries | Mentoring/interviews invisible |
| **Empty impact** | Entry has title but no/minimal `impact:` | User memory fades |
| **Incident without retro** | `incident-response` entries, no matching narrative | Incident channel context lost |
| **Rollout unvalidated** | Entry mentions FF rollout, no follow-up metric | Datadog dashboard snapshots expire |

Print gap summary to user before interview:

```
Gap inventory for June 2026:
- 3 weeks without narrative (W22, W23, W25)
- Heavy PR volume, no story: <project-slug> (9 entries)
- No peer recognition captured
- No career-growth entries (mentoring/interviews?)
- 2 incidents without retro narrative
```

### Step 5: Retention-Aware Recovery Scan (before asking user)

Attempt to **recover expiring data** from platforms while still available. Run what you can; note failures.

#### 5a: Slack (if MCP available)

> Check whether a `slack_search_public_and_private`-suffixed tool is available. If not, note "Slack unavailable" and **elevate interview priority** for recognition quotes.

If available, search the month:
```
from:@<slack_user> after:<first_day> before:<last_day+1>
```

For each gap cluster (incidents, big threads, wins):
- Pull thread replies with leadership recognition
- Extract metrics the user posted in Slack (before/after numbers)
- Save candidate quotes to draft — **do not wait for user** if clearly brag-worthy

Also search incident/project channels the user participated in (from the gap list).

**Slack retention note:** File/image URLs expire; capture quote *text* and attributor name into the brag doc now. Note file IDs in source coverage if charts were attached.

#### 5b: GitHub (Bash + `gh`)

For thin-evidence tags, recover merged PR titles and dates the month may have missed in worklog:

```bash
gh pr list --repo <org>/<repo> --author <github_user> \
  --state merged --search "merged:YYYY-MM-01..YYYY-MM-31" \
  --json number,title,mergedAt --limit 50
```

Union repos from `config.yaml`. Cross-check against logged entry URLs — **unlogged merges are gaps to ask about**.

Do not dump PR lists into brag doc; use only to jog memory in interview rounds.

#### 5c: Datadog / dashboards (optional)

If entries reference dashboard URLs, note them in draft. Do **not** assume metrics are still queryable — ask user for snapshot numbers in interview if missing from narratives.

#### 5d: Recovery report

```
Recovery scan:
- Slack: 2 recognition quotes recovered | unavailable — ask manually
- GitHub: 4 merged PRs not in worklog — will ask about in Round 1
- Datadog: not scanned — ask for metrics in Round 1
```

### Step 6: Draft the Brag Doc

Save to `~/.worklog/summaries/monthly/<YYYY-MM>.md`:

```markdown
# Brag doc — <Month YYYY>
Generated: <today>

> For manager 1:1. Theme: <one sentence if obvious, else TBD after interview>.

## Highlights
- <draft bullets — mark uncertain ones with ⚠️ thin evidence>

## Recognition
- "<quote>" — **Name** (<context>)

## Cross-team / visibility

## Visibility / asks for manager

## Did but didn't brag about

## Backlog / carry forward

---
<details>
<summary>Source coverage</summary>

- Narratives: X
- Entries: Y
- Gap inventory: <bullet list from Step 4>
- Recovery scan: <from Step 5>
- Interview rounds completed: <list>

</details>
```

Mark thin-evidence bullets with `⚠️` until confirmed in interview. Remove `⚠️` after user confirms or supplies metrics.

### Step 7: Interview Rounds (mandatory unless `--quick`)

**Rules:**
- Use **AskUserQuestion** — one round at a time, wait for answers before next round
- **Do not skip rounds** that have open gaps from Step 4
- Preserve user's exact wording for recognition quotes and invisible work
- After each round, update the saved markdown immediately
- If user surfaces a major win, offer `/worklog-capture` before moving on

#### Round 1 — Wins & metrics (required if any thin highlight or missing narrative)

Present each gap cluster:

```
I have PR activity on <tag> but no narrative. Before Datadog detail ages out:

1. <initiative> — what was the outcome? Any before/after numbers?
2. Was this a team goal, incident response, or self-directed platform work?
3. Anything merged this month not in the worklog? (GitHub showed: <list if any>)
```

For each incident without retro:
```
INC / incident work around <date> — what did you do, and what was the customer or system impact?
```

#### Round 2 — Recognition (required if no quotes in draft)

```
I don't have peer or manager recognition captured for <month>.

- Any Slack threads, 1:1 feedback, or review comments worth preserving? (exact quotes help)
- Anyone call out your work in incidents or launch channels?
- Any reactions/feedback on the announcements you drove?
```

If user pastes a Slack link → offer inline capture (read thread if MCP available) and add quote to doc.

#### Round 3 — Invisible work (always ask)

```
Worklog won't show these — what happened in <month>?

- Mentoring or pairing?
- Interviews conducted or trained for?
- Substantive code/design reviews that shaped someone else's work?
- Docs, presentations, or design influence outside merged PRs?
- Cross-team unblockings that weren't yours to ship?
```

#### Round 4 — Cross-team & visibility (required if gap inventory shows incidents or multi-repo work)

```
- Which teams did you coordinate with?
- Did you drive any timelines or decisions outside your primary area?
- Anything your manager should know about scope or dependencies?
```

#### Round 5 — Manager asks & carry forward (always ask)

```
- What do you want your manager to know or do something about this month?
- Promotion/ladder framing, goal ownership, workload, career growth?
- What's still in flight that should carry to next month?
```

#### Round 6 — Final confirm

Show cleaned highlights (no ⚠️). AskUserQuestion:

```
Final brag doc for <month>:

1. Cut anything that's too granular for a 1:1?
2. Promote anything to the top?
3. Ready to share as-is, or paste Highlights + Recognition + Asks only?
```

Remove all `⚠️` markers. Update `Interview rounds completed` in source coverage.

### Step 8: Backfill worklog (optional but encouraged)

After interview, for any new win the user described with metrics:

```
You surfaced <X> in the interview but it's not in ~/.worklog/narratives/.
Run /worklog-capture now so next month's brag isn't starting from memory?
```

If user agrees, run capture flow or write a minimal narrative YAML entry.

### Step 9: Report

Show user:
- Path to `~/.worklog/summaries/monthly/<YYYY-MM>.md`
- Gaps found vs gaps resolved in interview
- What was recovered from Slack/GitHub vs asked manually
- Narrative coverage: weeks still without capture (nudge `/worklog-weekly`)
- Copy-paste block: **Highlights + Recognition + Visibility/asks** only (manager-facing)

If `--quick` was used, warn:
```
Draft only — interview rounds skipped. Recognition and metrics may be missing.
Run without --quick before your 1:1.
```

## Platform retention cheat sheet

Tell the user when relevant — this motivates interview rounds:

| Platform | What disappears | Capture now |
|----------|-----------------|-------------|
| **Slack** | File/image URLs; hard to find old threads | Quote text + name + date |
| **Datadog** | Fine-grained log/metric detail (retention varies) | Before/after numbers, dashboard links |
| **GitHub** | PRs persist; review *context* gets buried | Substantive review influence in brag doc |
| **Inc channels** | Channels archive; context scatters | Retro narrative via `/worklog-capture` |
| **Your memory** | Degrades after ~4 weeks | Interview rounds while month is fresh |

## Examples

**Thin evidence → interview → highlight:**

Gap: 9 entries on a project tag, no narrative<br>
Round 1 answer: "saturation at 100%, p95 queue wait 7min → 3min"<br>
→ Highlight: `Rolled out ETA fanout jitter — p95 queue wait ~7 min → ~3 min; eliminated recurring enqueue peak.`

**Recognition recovery from Slack:**

Search finds a peer reply on incident thread<br>
→ Recognition: `"<what the peer said>" — <Peer Name> (<INC-XXXX RCA>)`

## Notes

- Default: **previous month**, run in first week of new month while memory + Slack recovery still work.
- Complements local career-ladder/progression docs, if present — brag doc feeds manager review spreadsheet.
- If month is completely empty, suggest running `/worklog-weekly` for missing weeks **first**, then re-run `/worklog-brag`.
