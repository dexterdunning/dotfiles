---
name: investigate-write-conflicts
description: Investigate MongoDB write conflicts from Datadog logs. Identifies top conflict sources, drills into specific origins, discovers affected documents, classifies conflict patterns (same-process multifield vs multi-process), and exports results. Use when investigating write contention on time_entry or other collections.
argument-hint: "[collection] [time-range] [--eta_fn=NAME] [--origin=NAME] [--company=ID] [--cluster=NAME] [--broad]"
---

You are investigating MongoDB write conflicts using Datadog slow query logs.

**User request**: $ARGUMENTS

## Background

MongoDB write conflicts occur when WiredTiger detects concurrent modifications to the
same document. These appear in slow query logs as `writeConflicts: N` where N is the
retry count. High values (100+) indicate severe document-level contention.

Write conflict logs are collected by a **shard-d log processor ETA**, not by the
originating worker. Key fields:
- `@attr.writeConflicts` — conflict retry count
- `@attr.durationMillis` — total write duration including retries
- `@attr.ns` — MongoDB namespace (e.g., `core.time_entry`)
- `@q_host` — originating worker pod (from `attr.command.comment`)
- `@eta_fn_name` — ETA function name (from `attr.command.comment`)
- `@origin_uri` — API endpoint or ETA that triggered the write
- `@origin_type` — `api` or `eta`
- `@company_id` — company ID
- `@cluster` — MongoDB cluster name
- `@mongo_log_timestamp` — when MongoDB recorded the operation
- `@attr.command.q._id.$oid` — document ID (often redacted to `XXXXX`)

**Document ID workaround**: The `_id` is typically redacted. Use the validity hash
prefix instead. For `core.time_entry`, deferred field writes include a validity hash
whose first `|`-delimited component is the document ID:
```
validityHash: "69a17dca...|14|2026-03-16 17:34:38...|TimeEntry"
              ^^^^^^^^^^ document ID
```

These are queryable at:
- `@attr.command.u.$set._deferredFields.calculatedAlerts.validityHash`
- `@attr.command.u.$set._deferredFields.segments.validityHash`
- `@attr.command.u.$set._deferredFields.priorEntrySummary.validityHash`
- `@attr.command.u.$set._deferredFields.floatingWorkdayStartTime.validityHash`

**Deduplication**: Each write appears 2-4x in logs due to:
1. Dual-write: mongobetween writes to both `time-entry-cluster` and `time-entry-sharded-cluster`
2. Multi-host logging: multiple shard-d log processor hosts record the same operation

By defaulting to `@cluster:time-entry-cluster`, we eliminate the dual-write duplication
at the query level. The remaining duplicates (multi-host logging, typically 2-3x) are
handled by post-processing deduplication on `(mongo_log_timestamp, durationMillis)`.

## Execution Plan

### Configuration

Parse the user's arguments to determine configuration. Defaults:
- **Collection**: `core.time_entry` (override if user specifies another)
- **Time range**: `now-1d` to `now` (override if user specifies, e.g. `now-6h`, `now-7d`)
- **Cluster**: `time-entry-cluster` (override with `--cluster=<name>` or `--cluster=*` for all clusters)
- **Max documents to examine**: 10 (increase if user requests more)
- **Mode**: interactive (override with `--broad` for non-interactive broad analysis)

**Optional filters** (appended to every Datadog filter query when provided):
- `--eta_fn=<name>` → adds `@eta_fn_name:<name>` to all queries
- `--origin=<name>` → adds `@origin_uri:*<name>*` to all queries
- `--company=<id>` → adds `@company_id:<id>` to all queries
- `--cluster=<name>` → overrides the default cluster filter; use `*` to query all clusters

Build a `BASE_FILTER` string used in every query:
```
@attr.writeConflicts:>0 @attr.ns:<collection> @cluster:<cluster> [optional: @eta_fn_name:X] [optional: @company_id:X]
```

### Phase 1: Overview + Per-Document Summary

Run two queries in parallel:

**1a. Top sources by total conflict count:**
```
Tool: mcp__datadog__analyze_datadog_logs
filter: <BASE_FILTER>
sql: SELECT "@origin_uri" as origin,
            "@origin_type" as origin_type,
            count(*) as log_count,
            avg("@attr.writeConflicts") as avg_conflicts,
            max("@attr.writeConflicts") as max_conflicts,
            sum("@attr.writeConflicts") as total_conflicts
     FROM logs
     GROUP BY "@origin_uri", "@origin_type"
     ORDER BY sum("@attr.writeConflicts") DESC
     LIMIT 20
extra_columns:
  - @origin_uri: string
  - @origin_type: string
  - @attr.writeConflicts: int64
```

**1b. Broad per-document discovery (top conflicted writes with validity hashes):**
```
filter: <BASE_FILTER> (but with writeConflicts:>50)
sql: SELECT "@q_host" as q_host,
            "@attr.writeConflicts" as conflicts,
            "@attr.durationMillis" as duration_ms,
            "@mongo_log_timestamp" as mongo_ts,
            "@origin_uri" as origin,
            "@company_id" as company_id,
            "@eta_fn_name" as eta_fn,
            "@attr.command.u.$set._deferredFields.calculatedAlerts.validityHash" as vh_alerts,
            "@attr.command.u.$set._deferredFields.segments.validityHash" as vh_segments,
            "@attr.command.u.$set._deferredFields.priorEntrySummary.validityHash" as vh_prior,
            "@attr.command.u.$set._deferredFields.floatingWorkdayStartTime.validityHash" as vh_fwst
     FROM logs
     ORDER BY "@attr.writeConflicts" DESC
     LIMIT 500
```

Write the 1b results to a temp file (`/tmp/wc_raw_<timestamp>.tsv`) and run the
**dedup + aggregation script** (see Dedup Script section below) to produce the
per-document summary table immediately.

Present both tables to the user:
1. Top sources overview (from 1a)
2. Per-document summary with pod counts, fields, classification (from 1b, deduped)

**In `--broad` mode**: Skip to Phase 4 (fan-out) for the top 10 documents by max
conflicts. No interactive questions.

**In interactive mode**: Use a single AskUserQuestion to let the user choose:
- Which source to drill into (or "skip to document analysis")
- Which documents to deep-dive (default: top 5 by max conflicts)

### Phase 2: Source drill-down (interactive mode only)

For the selected source, run two SQL aggregates in parallel:

**2a. Top companies:**
```
filter: <BASE_FILTER> @origin_uri:<selected>
sql: SELECT "@company_id" as company_id,
            count(*) as log_count,
            sum("@attr.writeConflicts") as total_conflicts,
            avg("@attr.writeConflicts") as avg_conflicts,
            max("@attr.writeConflicts") as max_conflicts
     FROM logs
     GROUP BY "@company_id"
     ORDER BY sum("@attr.writeConflicts") DESC
     LIMIT 15
```

**2b. Top q_hosts:**
```
filter: <BASE_FILTER> @origin_uri:<selected>
sql: SELECT "@q_host" as q_host,
            "@eta_fn_name" as eta_fn,
            count(*) as log_count,
            sum("@attr.writeConflicts") as total_conflicts
     FROM logs
     GROUP BY "@q_host", "@eta_fn_name"
     ORDER BY sum("@attr.writeConflicts") DESC
     LIMIT 15
```

Present both tables. Continue to Phase 3 without asking — use the top company by default.

### Phase 3: Document discovery (interactive mode only)

For the selected source + company, extract document IDs from validity hashes:

```
filter: <BASE_FILTER> @attr.writeConflicts:>50 @origin_uri:<selected> @company_id:<company>
sql: SELECT "@attr.command.u.$set._deferredFields.calculatedAlerts.validityHash" as vh_alerts,
            "@attr.command.u.$set._deferredFields.segments.validityHash" as vh_segments,
            "@attr.command.u.$set._deferredFields.priorEntrySummary.validityHash" as vh_prior,
            "@attr.command.u.$set._deferredFields.floatingWorkdayStartTime.validityHash" as vh_fwst,
            "@attr.writeConflicts" as conflicts,
            "@company_id" as company_id
     FROM logs
     ORDER BY "@attr.writeConflicts" DESC
     LIMIT 20
```

Parse document IDs by extracting the first `|`-delimited component from any non-null
validity hash column. Collect unique document IDs. Present them and proceed directly
to Phase 4 for the top documents (no confirmation needed).

### Phase 4: Document fan-out analysis

For each document ID (up to MAX_DOCUMENTS), run the fan-out query. **Important**: this
query intentionally omits source/ETA/company filters to capture ALL writers hitting
each document, enabling cross-origin contention detection.

```
filter: @cluster:<cluster> (@attr.command.u.$set._deferredFields.calculatedAlerts.validityHash:<doc_id>*
         OR @attr.command.u.$set._deferredFields.priorEntrySummary.validityHash:<doc_id>*
         OR @attr.command.u.$set._deferredFields.segments.validityHash:<doc_id>*
         OR @attr.command.u.$set._deferredFields.floatingWorkdayStartTime.validityHash:<doc_id>*)
sql: SELECT "@q_host" as q_host,
            "@attr.writeConflicts" as conflicts,
            "@attr.durationMillis" as duration_ms,
            "@mongo_log_timestamp" as mongo_ts,
            "@eta_fn_name" as eta_fn,
            "@origin_uri" as origin,
            "@company_id" as company_id,
            "@attr.command.u.$set._deferredFields.calculatedAlerts.validityHash" as vh_alerts,
            "@attr.command.u.$set._deferredFields.segments.validityHash" as vh_segments,
            "@attr.command.u.$set._deferredFields.priorEntrySummary.validityHash" as vh_prior,
            "@attr.command.u.$set._deferredFields.floatingWorkdayStartTime.validityHash" as vh_fwst
     FROM logs
     ORDER BY "@mongo_log_timestamp" ASC
```

**Parallelization**: If examining more than 3 documents, spawn parallel Task agents
(subagent_type=general-purpose) to run the fan-out queries concurrently. Each agent
handles a batch of document IDs and returns the raw results. The main agent then
classifies and merges.

Write all fan-out results to temp files and run the dedup script per document.

### Phase 5: Classification

For each document's conflict set, deduplicate and classify:

1. **Deduplicate**: Group rows by `(mongo_ts, duration_ms)`. Rows with identical
   values across these columns are duplicates from multi-host log processors.
   (Since we filter to a single cluster by default, dual-write dupes are already gone.)

2. **Identify deferred fields**: For each unique write, check which `vh_*` column
   is non-null to determine which deferred field was being written.

3. **Count distinct q_hosts**: After deduplication, count unique `q_host` values.

4. **Identify distinct origins**: After deduplication, collect unique `@origin_uri` values.

5. **Classify** (two dimensions — within-filter and cross-origin):

   **Within-filter classification** (based on the filtered dataset):
   - **Same-process, multifield**: 1 distinct q_host, multiple deferred fields written
     within a tight time window (~seconds). This is the multiget pattern — one ETA
     computing multiple deferred fields on the same document via separate `_modify_only` calls.
   - **Multi-process**: Multiple distinct q_hosts writing to the same document. Different
     ETAs or API requests contending on the same document.
   - **Single-field contention**: 1 q_host, 1 deferred field, still high conflicts.
     The document is being contended by OTHER documents' writes (WiredTiger page-level).

   **Cross-origin classification** (from the unfiltered fan-out in Phase 4):
   - **Single-origin**: All writes come from the same `@origin_uri`
   - **Multi-origin**: Writes from multiple origins — report which origins are competing.
     This is critical because a document that looks "same-process" within one ETA may
     actually have severe multi-process contention from other ETAs/APIs.

6. **Summarize per document**:
   - Document ID
   - Company ID
   - Within-filter classification
   - Cross-origin classification (if different origins detected)
   - Distinct q_hosts (list them)
   - Distinct origins (list them)
   - Deferred fields written
   - Total conflict count (sum, deduplicated)
   - Max single-write conflict count
   - Time span of conflict set
   - Max single-write duration

### Phase 6: Export

Write results to `~/write-conflict-investigations/` as both markdown and CSV:

```
~/write-conflict-investigations/<collection>_<YYYY-MM-DD_HHMMSS>.md
~/write-conflict-investigations/<collection>_<YYYY-MM-DD_HHMMSS>.csv
```

**Markdown export** should contain:
1. **Investigation parameters**: collection, time range, cluster, applied filters
2. **Overview table**: top sources (from Phase 1a)
3. **Per-document summary table**: all discovered documents with pod counts, fields,
   max/total conflicts, classification (from Phase 1b)
4. **Source drill-down** (if interactive): top companies and q_hosts (from Phase 2)
5. **Document deep-dive**: for each examined document (from Phase 4):
   - Document ID, Company ID
   - Within-filter and cross-origin classification
   - Conflict summary table (deduplicated writes with fields, q_hosts, conflicts, timestamps)
   - All origins that touched this document
   - Interpretation (what's causing the contention)
6. **Recommendations**: based on patterns observed

**CSV export** should contain one row per deduplicated write with columns:
`doc_id, company_id, q_host, eta_fn, origin, field, conflicts, duration_ms, mongo_ts`

This enables loading into spreadsheets or notebooks for further analysis.

## Dedup Script

After every query that returns raw rows with validity hashes, write results to a temp
file and run this Python script to deduplicate and aggregate per document. This avoids
manual dedup in every phase.

```python
#!/usr/bin/env python3
"""Deduplicate write conflict logs and produce per-document summary."""
import csv
from collections import defaultdict

def extract_doc_id(vh):
    """Extract document ID from validity hash (first pipe-delimited component)."""
    if vh and '|' in vh:
        return vh.split('|')[0]
    return None

def process_write_conflict_data(input_path, output_summary_path=None, output_csv_path=None):
    rows = []
    with open(input_path, 'r') as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            rows.append(row)

    # Dedup by (mongo_ts, duration_ms) — removes multi-host log processor dupes
    seen = set()
    deduped = []
    for row in rows:
        key = (row.get('mongo_ts', ''), row.get('duration_ms', ''))
        if key not in seen:
            seen.add(key)
            deduped.append(row)

    # Aggregate per document
    doc_info = defaultdict(lambda: {
        'pods': set(), 'fields': set(), 'origins': set(), 'eta_fns': set(),
        'max_conflicts': 0, 'total_conflicts': 0, 'write_count': 0,
        'company_id': '', 'max_duration_ms': 0, 'writes': [],
    })

    field_map = {
        'vh_alerts': 'alerts', 'vh_segments': 'segments',
        'vh_prior': 'prior', 'vh_fwst': 'fwst',
    }

    for row in deduped:
        conflicts = int(row.get('conflicts', 0) or 0)
        duration = int(row.get('duration_ms', 0) or 0)

        doc_ids_fields = {}
        for col, fname in field_map.items():
            did = extract_doc_id(row.get(col, ''))
            if did:
                doc_ids_fields.setdefault(did, set()).add(fname)

        if not doc_ids_fields:
            continue

        for did, fields in doc_ids_fields.items():
            info = doc_info[did]
            info['pods'].add(row.get('q_host', ''))
            info['fields'].update(fields)
            info['origins'].add(row.get('origin', ''))
            if row.get('eta_fn'):
                info['eta_fns'].add(row['eta_fn'])
            info['max_conflicts'] = max(info['max_conflicts'], conflicts)
            info['total_conflicts'] += conflicts
            info['write_count'] += 1
            if row.get('company_id'):
                info['company_id'] = row['company_id']
            info['max_duration_ms'] = max(info['max_duration_ms'], duration)
            info['writes'].append(row)

    # Sort by max_conflicts descending
    sorted_docs = sorted(doc_info.items(), key=lambda x: x[1]['max_conflicts'], reverse=True)
    return sorted_docs
```

Run this script after Phase 1b and Phase 4 queries. The output drives the per-document
summary table and classification.

## Query Reference

### Datadog MCP tools to use
- `mcp__datadog__analyze_datadog_logs` — for all SQL aggregates (all phases)
- `mcp__datadog__search_datadog_logs` — only if raw log inspection is needed

### Common extra_columns declaration
```json
[
  {"name": "@origin_uri", "type": "string"},
  {"name": "@origin_type", "type": "string"},
  {"name": "@attr.writeConflicts", "type": "int64"},
  {"name": "@attr.durationMillis", "type": "int64"},
  {"name": "@q_host", "type": "string"},
  {"name": "@eta_fn_name", "type": "string"},
  {"name": "@company_id", "type": "string"},
  {"name": "@cluster", "type": "string"},
  {"name": "@mongo_log_timestamp", "type": "string"},
  {"name": "@attr.command.u.$set._deferredFields.calculatedAlerts.validityHash", "type": "string"},
  {"name": "@attr.command.u.$set._deferredFields.segments.validityHash", "type": "string"},
  {"name": "@attr.command.u.$set._deferredFields.priorEntrySummary.validityHash", "type": "string"},
  {"name": "@attr.command.u.$set._deferredFields.floatingWorkdayStartTime.validityHash", "type": "string"}
]
```

### Token budget guidelines
- Phase 1a: ~500 tokens (20-row aggregate)
- Phase 1b: ~3,000 tokens (500-row raw, paginated if needed)
- Phase 2: ~600 tokens (two 15-row aggregates)
- Phase 3: ~400 tokens (20-row discovery)
- Phase 4: ~500 tokens per document (fan-out)
- Total for 10 documents: ~8,000 tokens of Datadog data

Prefer `analyze_datadog_logs` (SQL) over `search_datadog_logs` (raw) in all phases.
Raw logs are 500+ tokens each due to nested `dependentQueries` blobs.
