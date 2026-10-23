---
name: datadog-investigation
description: Investigate Datadog logs/traces/metrics with the pup CLI, preferring aggregates and local processing over dumping raw logs into chat. Use when querying Datadog, debugging production via logs/APM, using pup, or choosing between pup and Datadog MCP.
---

# Datadog Investigation

If `~/.agents/skill-overrides/datadog-investigation/instructions.md` exists, read it for local storage, tooling, and metric conventions. Otherwise use the workflow below. Local supplements do not override repository policy or safety requirements.

Prefer **`pup`** over Datadog MCP. Aggregate first; never pull raw logs into chat to count/group/scan.

## Tool choice

- **Default:** `pup` — full raw logs, configurable `--limit`, 80+ API domains.
- **Setup:** `brew install datadog-labs/pack/pup` → `pup auth login` → `pup auth status`.
- **Keep it current:** `brew upgrade pup`. Transient mid-session `authentication expired` errors (retry succeeds) were seen on 1.7.0 — fixed by upgrading; check `pup version` before blaming auth. Verify auth with `pup auth status` (should be instant).
- **MCP only** for quick in-chat aggregates when pup is unavailable.

## Decision order

1. **Aggregate in Datadog** — `pup logs aggregate`, `pup ddsql query`, or MCP `analyze_datadog_logs` with tight SQL
2. **Narrow raw fetch** — `--limit=5` after aggregates identify the slice
3. **Local processing** — write to `/tmp`, script with `jq`; return summaries only

## Shell patterns

```bash
# Aggregate → small JSON in chat (choose the storage tier used by the service)
pup logs aggregate --query='status:error service:foo' --from=1h \
  --compute='count' --group-by='@handler' | jq '.data.buckets[:10]'

# Bulk export → local script (agent reads script output, not raw file)
pup --no-agent logs search --query='...' --from=1h --limit=500 \
  > /tmp/dd-logs.json
jq '[.[] | {handler: .attributes.attributes.handler, msg: .attributes.message}] \
  | group_by(.handler) | map({handler: .[0].handler, n: length})' /tmp/dd-logs.json
```

Use `pup --no-agent` when writing scripts/files the user will run outside the agent session.

Gotchas:

- **Time formats:** `--from=1h`, `30m`, `7d`, RFC3339, or unix — NOT `now-1h`.
- **Use a working local runtime for post-processing.** Prefer `jq` for JSON aggregation; check repository guidance before using a Python/package-manager wrapper. Pup itself does not require a repository workspace.

## Query discipline

- **Choose storage for the service and time window.** Use flex when logs are retained there: pup accepts `--storage=flex`; compatible MCP integrations may expose `storage_tier: "flex_and_indexes"`. Use hot storage for fresh indexed logs when appropriate; do not assume every organization mirrors the same retention policy.
- Start `from=1h`; widen only if needed.
- Filter `service:` first; add `@attr:` only after you know the field exists.
- One log with full traceback beats 50 with only `message`.

## Dashboard creation (`pup dashboards create/update`)

When building dashboards via JSON (`--file`):

- **Log-based timeseries widgets** (counts, group-bys over time from flex logs):
  ```json
  {
    "data_source": "logs",
    "storage": "flex_tier",
    "indexes": ["*"],
    "search": { "query": "your search here" },
    "compute": { "aggregation": "count" },
    "group_by": [{"facet": "@field", "limit": 10, "sort": {"aggregation": "count", "order": "desc"}}]
  }
  ```
  Storage value must be `"flex_tier"` (not `"flex"`, not `"online-archives"`).
  The pup CLI uses `--storage=flex`; the dashboard JSON API uses `"flex_tier"` — they differ.
- **Avoid `log_stream` widgets** for flex logs on dashboards — they often show "No matching
  results found" even with correct queries. Use log-count timeseries instead and link to
  the log explorer URL in a note widget for raw log access.
- **Distribution metric gotcha:** a distribution's `sum:` adds measured values; it does not count executions. Use the metric's `count:` aggregation for the number of observed samples, and verify sampling/population alignment before treating those as task counts.
- **Widget titles:** write plain titles a human would use in a retro deck. Avoid
  parenthetical annotations like "(proof that X)" or "(exoneration)" — let the
  data speak. Skip em dashes.

## Return to chat

- Aggregate tables (counts, top-N group-bys)
- 1–3 representative raw logs for a specific failure
- Datadog explorer URLs when useful
- Script conclusions — not intermediate dumps

## MCP fallback (only if pup unavailable)

The `datadog` MCP's `datadog_get_datadog_metric` is a solid metrics fallback — takes the same query strings, returns compact JSON. Search events via `datadog_search_datadog_events`.

Keep calls tight: aggregates first; `max_tokens` 2000–5000; only needed `extra_columns`.

Many tools require telemetry:

```json
"telemetry": { "intent": "short reason for the query" }
```

DDSQL gotchas for `analyze_datadog_logs`:

- `logs` is already time-filtered by `from`/`to` — no timestamp WHERE
- Quote `@`/dotted fields: `"@attr.writeConflicts"`
- Non-aggregated SELECT columns must be in `GROUP BY`; don't reuse SELECT aliases in `GROUP BY`/`WHERE`/`HAVING`
- Avoid `ANY()`, `->>`, `QUALIFY`, `information_schema`, `INTERVAL`, `CURRENT_TIMESTAMP`
