---
name: datadog-notebook
description: Create or update a shareable Datadog notebook (narrative + graphs) from metric queries via the pup CLI, for presenting an investigation's findings. Use when asked for a "Datadog notebook", a presentable/shareable writeup of metrics, a deck-ready set of Datadog graphs, or to turn an investigation into something to show others.
argument-hint: "[title / topic, or blank to infer from current investigation]"
---

Build a Datadog **notebook** (markdown narrative interleaved with graphs) and POST it via `pup`. The output is one shareable URL: `https://app.datadoghq.com/notebook/<id>`.

**Optional local supplement:** if `~/.agents/skill-overrides/datadog-notebook/instructions.md` exists, read it first — it carries local metric names, team queries, and org conventions. Without it, this workflow works standalone with user-provided metrics.

Prereq: `pup auth status` returns OK (see the datadog-investigation skill). Graph queries are normal Datadog metric strings. Run each one through `pup metrics query` first so the notebook renders real data.

## Workflow

1. **Gather the queries.** Reuse the exact query strings you already validated during the investigation. For trend graphs, add `.rollup(sum, 604800)` for weekly buckets or `86400` for daily. For cost graphs, query the raw metric and apply the multiplier in a formula (for example `some.billable_action ... × price / 1e6`).
2. **Write the JSON** to a temp file (see template). Alternate `markdown` cells for narrative with `timeseries` cells for graphs. Use the `queries`+`formulas` request shape with `response_format`, `alias`, and a unit override. Open with a TL;DR markdown cell.
3. **Create:** `pup --no-agent notebooks create --file /tmp/nb.json -y`
4. **Report** the id and URL. To make changes, edit the file and run `pup --no-agent notebooks update <id> --file /tmp/nb.json -y`.

## Template (create)

```json
{
  "data": {
    "type": "notebooks",
    "attributes": {
      "name": "<title>",
      "time": { "live_span": "1mo" },
      "cells": [
        { "type": "notebook_cells", "attributes": { "definition": {
          "type": "markdown", "text": "# <title>\n\n**TL;DR:** <one-paragraph verdict>." } } },
        { "type": "notebook_cells", "attributes": { "definition": {
          "type": "markdown", "text": "## 1. <section>\n<one-line takeaway>" } } },
        { "type": "notebook_cells", "attributes": {
          "definition": {
            "type": "timeseries",
            "requests": [
              { "display_type": "line", "response_format": "timeseries",
                "queries": [{"name":"a","data_source":"metrics","query":"<query A>.rollup(sum,604800)"}],
                "formulas": [{"formula":"a","alias":"<hover label>","number_format":{"unit":{"type":"custom_unit_label","label":"<unit>"}}}],
                "style": {"palette":"cool"} }
            ],
            "yaxis": { "scale": "linear", "include_zero": true },
            "title": "<graph title>"
          },
          "graph_size": "l" } }
      ]
    }
  }
}
```

## Cell notes

- Wrap every cell as `{ "type": "notebook_cells", "attributes": { "definition": {...} } }`. Graph cells also take `"graph_size": "l"` alongside `definition`.
- `definition.type` is `markdown` (with `text`) or `timeseries` (with `requests[]` and `title`). Other valid types: `toplist`, `heatmap`, `note`, `log_stream`.
- Use the `queries`+`formulas` request shape so you can set aliases and unit overrides. The bare `q` shape does not support them. Every `queries`+`formulas` request needs `"response_format": "timeseries"`, otherwise the API returns a 400 (`is not valid under any of the given schemas`).
- `formulas[].alias` sets the hover and legend name. Leave it out and the hover shows the raw query string, so set one per series.
- `formulas[].number_format.unit` controls the y-axis. Metrics carrying time-unit metadata render as a duration ("115d 9h" is 9.97M seconds with the wrong label). Override it with `{"type":"custom_unit_label","label":"<unit>"}`. For money, use `{"type":"canonical_unit","unit_name":"dollar"}` and do the arithmetic in the formula (for example `"formula":"a * <price> / 1000000"`).
- `requests[].display_type` is `line`, `bars`, or `area`. `style.palette` is `cool`, `warm`, `purple`, `grey`, or `orange`.
- For relative time, use `{"live_span":"1h"|"4h"|"1d"|"1w"|"1mo"|"3mo"}`. For a fixed window, put `{"start":"<ISO>","end":"<ISO>","live":false}` directly under `time` (do not nest it under `notebook_absolute_time`). Reach for a fixed window when the narrative names a specific range, so the graphs line up with the title.
- Keep markdown takeaways to 1-3 lines and let the graph carry the evidence.

## Also produce a paste-ready md

Alongside the notebook, write `/tmp/<topic>-writeup.md` with a TL;DR, a key-numbers table, and the raw query strings under each section, so the user can paste them into Metrics Explorer without opening the notebook. The notebook is for presenting; the md is for iterating and pasting.

## Anti-patterns

- Adding queries to the notebook before running them (leads to blank graphs).
- Cramming all the graphs into one markdown cell as text. Interleave real graph cells.
- Hand-encoding multi-query Metrics Explorer URLs. They break easily, so lean on the notebook as the stable shareable artifact.
