---
name: datadog-investigation
description: Investigate Datadog logs/traces/metrics with the pup CLI, preferring aggregates and local processing over dumping raw logs into chat. Use when querying Datadog, debugging production via logs/APM, using pup, or choosing between pup and Datadog MCP.
---

# Datadog Investigation

Prefer **`pup`** over Datadog MCP. Aggregate first; never pull raw logs into chat to count/group/scan.

## Tool choice

- **Default:** `pup` — full raw logs, configurable `--limit`, 80+ API domains.
- **Setup:** `brew install datadog-labs/pack/pup` → `pup auth login` → `pup auth status`.
- **MCP only** for quick in-chat aggregates when pup is unavailable.

## Decision order

1. **Aggregate in Datadog** — `pup logs aggregate`, `pup ddsql query`, or MCP `analyze_datadog_logs` with tight SQL
2. **Narrow raw fetch** — `--limit=5` after aggregates identify the slice
3. **Local processing** — write to `/tmp`, script with `jq`; return summaries only

## Shell patterns

```bash
# Aggregate → small JSON in chat (flex tier default)
pup logs aggregate --query='status:error service:foo' --from=1h --storage=flex \
  --compute='count' --group-by='@handler' | jq '.data.buckets[:10]'

# Bulk export → local script (agent reads script output, not raw file)
pup --no-agent logs search --query='...' --from=1h --storage=flex --limit=500 \
  > /tmp/dd-logs.json
jq '[.[] | {handler: .attributes.attributes.handler, msg: .attributes.message}] \
  | group_by(.handler) | map({handler: .[0].handler, n: length})' /tmp/dd-logs.json
```

Use `pup --no-agent` when writing scripts/files the user will run outside the agent session.

## Query discipline

- **Default storage: flex** — Rippling logs mostly live here.
  - pup: `--storage=flex` on `logs search` / `logs aggregate` / `logs query`
  - MCP: `storage_tier: "flex_and_indexes"`
- **Hot only** for live incidents (sub-hour freshness); omit `--storage` / `storage_tier`.
- Start `from=1h`; widen only if needed.
- Filter `service:` first; add `@attr:` only after you know the field exists.
- One log with full traceback beats 50 with only `message`.

## Return to chat

- Aggregate tables (counts, top-N group-bys)
- 1–3 representative raw logs for a specific failure
- Datadog explorer URLs when useful
- Script conclusions — not intermediate dumps

## MCP fallback (only if pup unavailable)

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
