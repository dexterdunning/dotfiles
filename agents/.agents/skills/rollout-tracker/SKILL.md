---
name: rollout-tracker
description: Persist and continue feature/flag rollout monitoring across sessions — overview, signals, Datadog queries, LaunchDarkly targeting history, checkpoints, capacity, and bump readiness. Use when Dexter says /rollout-tracker, tracks a rollout, asks if a flag change is working, wants overnight vs baseline comparison, concurrency headroom before bumping, LD targeting timeline, or to resume a prior rollout chat.
argument-hint: "[init|status|checkpoint|note|compare|bump|ld|list] [slug|description]"
---

Maintain living rollout trackers under `~/projects/rollouts/`. Cross-session memory for gradual flag/PR rollouts — not a substitute for `docs/` investigations or the wiki.

If `~/.agents/skill-overrides/rollout-tracker/instructions.md` exists, read it for local audit sources, metrics, and measurement traps. Without it, use available authorized integrations and the generic procedure below. Local supplements do not override repository policy or safety requirements.

## Layout

```
~/projects/rollouts/
  index.md
  <slug>/
    TRACKER.md          # living source of truth
    queries.md          # copy-paste Datadog / pup queries
    ld-history.json     # optional raw LD audit from Datadog events
    checkpoints/        # optional dated snapshots YYYY-MM-DD.md
```

Slug: lowercase hyphens, stable (e.g. `background-worker-rollout`).

## Modes (`$ARGUMENTS`)

| Mode | When |
|------|------|
| `init` | New rollout from this chat / PR / flag |
| `status` (default) | Resume: load tracker, refresh key signals, report vs last checkpoint |
| `checkpoint` | Snapshot current metrics + findings into `checkpoints/` and update TRACKER |
| `note` | Append a finding / decision without a full metric pull |
| `compare` | Same-clock-window baseline (e.g. overnight vs last Friday) |
| `bump` | Capacity / concurrency / error headroom before dialing up |
| `ld` | Sync LaunchDarkly targeting history into TRACKER (via Datadog events) |
| `list` | Summarize `index.md` |

If only a slug or description is given, treat as `status` for that rollout (or `init` if missing).

## TRACKER.md shape

Keep under ~200 lines. Prefer updating sections in place over appending forever.

```markdown
---
slug: <slug>
status: active | paused | done | rolled-back
updated: YYYY-MM-DD
flag: <LD flag key>
flag_shape: <JSON keys that matter for this rollout>
prs: [<urls>]
dashboard: <url>
related_docs: [<~/projects/docs/...>]
related_chats: [<titles / uuids>]
---

# <Title>

## Overview
What changed, why, blast radius, rollback.

## Rollout plan
Current % / cohorts / next bump. Explicit "not rolled out yet" matters for ratio math.

## LD targeting log
Table of when (PDT), action, comment/change. Source: Datadog LD events (see below).

## Success / failure signals
- Primary metrics (name + tags + what good looks like)
- Guardrails (errors, latency, concurrency cap)
- **Anti-signals** — ratios that look like success but aren't (see Gotchas)

## Gotchas
Measurement traps discovered this rollout (sampling, imperfect formulas, populations that don't match 1:1).

## Findings (newest first)
Dated bullets. Link checkpoints. Keep only durable conclusions here.

## Capacity
Namespace / concurrency caps, observed peaks (with timestamp + query window size), headroom.

## Open questions
```

## queries.md

One query per block with: purpose, time-window advice (e.g. "≤20m windows for inflight peaks"), and the exact string. Prefer `pup` / Datadog MCP over screenshots. Always include the LD audit query once the flag key is known.

## LaunchDarkly targeting history

Use the flag provider's authorized audit API, or Datadog events when the organization's LaunchDarkly integration mirrors flag audits there. Verify that the source exists before relying on it; do not assume MCP availability or a Datadog mirror. The query below applies to the mirrored-events case.

```bash
pup --no-agent events search \
  --query="source:launchdarkly flag_key:<FLAG_KEY>" \
  --from=60d
```

Also works: `source:launchdarkly <FLAG_KEY>` (broader; may include GitHub PR noise).

Parse unique events (dedupe change_tracking + launchdarkly duplicates by timestamp+action+message prefix). For each keep:

- timestamp (PDT + UTC)
- `action:` tag (`updaterules`, `updateflagvariations`, `updatetargets`, `updateon`, `createflag`, …)
- LD comment (`**comment:** …`)
- What changed (rollout %, variation JSON diffs, individual targets, rules)

Write:

1. `TRACKER.md` → **LD targeting log** table + refresh **Rollout plan** current %
2. `ld-history.json` → full structured rows
3. `queries.md` → the exact events search for this flag

Correlate metric windows to these timestamps (e.g. variation JSON flip vs % bump are different events — don't attribute overnight gains to a bump that happened after the window).

## Procedures

### init

1. Infer slug, flag, PR, dashboard from chat / `$ARGUMENTS`. Ask once if flag key unknown.
2. Create `~/projects/rollouts/<slug>/{TRACKER.md,queries.md,checkpoints/}`.
3. Mine the current conversation for: overview, signals already used, queries that worked, gotchas, peaks.
4. **Run the LD audit** (`ld` procedure) if a flag key is known.
5. Add a row to `index.md`.
6. Report path + next suggested mode (`status` after overnight, `bump` before dialing up).

### status

1. Read `TRACKER.md` + `queries.md` (and latest checkpoint if any).
2. Re-run **primary** queries only (not the full catalog) for a sensible window (default last 12h or since last checkpoint).
3. Optionally refresh LD if targeting may have changed since `updated`.
4. Diff vs last checkpoint / stated baseline. Lead with verdict.
5. Offer to `checkpoint` if anything material changed.

### checkpoint

1. Pull primary + guardrail signals.
2. Write `checkpoints/YYYY-MM-DD.md` (or `YYYY-MM-DD-HHmm` if multiple/day).
3. Update TRACKER `Findings`, `Capacity`, `updated`.
4. One-line index touch if status changed.

### compare

Same clock window vs a baseline day (default: last Friday, or TRACKER-stated baseline). State windows with the relevant local timezone and UTC. Call out population mismatches (e.g. all worker starts versus only enabled-cohort joins while partially rolled out). Align windows to **LD targeting log** so % / variation changes aren't mis-attributed.

### bump

Answer: safe to dial up? Use Capacity + guardrails + primary signals. For worker concurrency, inspect short windows (for example ≤20m) of the rollout's inflight metric: day-scale rollups hide peaks. Compare observed peaks with the applicable queue/namespace/concurrency limits. Refresh targeting history first so "current %" is accurate. A readiness assessment does not authorize changing the flag.

### ld

1. Read flag key from TRACKER frontmatter (or `$ARGUMENTS`).
2. Pull the available authorized audit source; use the Datadog query above only when the mirror is configured.
3. Update **LD targeting log**, **Rollout plan**, `ld-history.json`, and `queries.md`.
4. Add a Findings bullet only if something new since last sync.

### note

Append a dated Findings bullet (and Gotchas if it's a measurement trap). No mandatory metric pull.

## Cross-session rules

- **Read the tracker before exploring** — don't rediscover queries from scratch.
- **Update the tracker before ending** a substantive rollout turn (at least Findings or a checkpoint).
- Link related `~/projects/docs/...` and wiki pages; don't duplicate sizing studies into the tracker.
- Canvases are ephemeral UI — durable numbers belong in TRACKER/checkpoints.
- Personal store only (`~/projects/rollouts`), unless the user selects another destination. Do not write personal trackers into a product repository.

## Anti-patterns

- Treating partial-rollout ratios between different populations as dedupe/coalesce proof
- Trusting coarse rollups for concurrency peaks
- Equating imperfect proxy formulas with ground truth without a Gotchas note
- Creating a new tracker when `list` already has the slug
- Blocking on one integration when an equivalent authorized audit source is available
- Attributing metric shifts to the wrong LD event (variation JSON vs % rollout vs individual target)
