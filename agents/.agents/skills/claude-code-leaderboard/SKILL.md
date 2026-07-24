---
name: claude-code-leaderboard
description: Show Claude Code usage leaderboard from LLM Gateway audit logs
allowed-tools: ToolSearch, mcp__datadog__analyze_datadog_logs, mcp__datadog__search_datadog_logs, Bash
---

# Claude Code Usage Leaderboard

Show a leaderboard of Claude Code usage across Rippling, ranked by request count with cost and token data.

## Team Configuration

**Teammates:** arramesh@rippling.com, vmuttineni@rippling.com, yuwang@rippling.com, wxiao@rippling.com, azeff@rippling.com, mlandry@rippling.com, ashikder@rippling.com, canguyen@rippling.com, rpadia@rippling.com

This list can be updated by editing this file at `/Users/dexter/.claude/commands/claude-code-leaderboard.md`.

## Instructions

1. **Parse the arguments** from `$ARGUMENTS`:
   - Check if "team" is mentioned - if so, enable team comparison mode
   - Extract the time period:
   - If empty or not provided, default to `7d`
   - If `all`, use the period from `2025-03-12` to now (when Claude Code tracking started)
   - Otherwise use the value as-is (e.g., `2w`, `30d`, `1d`)
   - Store the period for display and for the `from`/`to` parameters

2. **Get the current user's email** by running: `git config user.email`

3. **Load the Datadog MCP tools** using `ToolSearch` with query `+datadog logs`

4. **If team mode is enabled**:
   - Parse the teammates list from the Team Configuration section
   - Add the current user to the teammates list if not already present
   - Run a query for each team member's stats in parallel
   - Show a team-only leaderboard ranked by request count
   - Include team rank within the overall leaderboard
   - Calculate team totals (sum of all team members)
   - Skip the global top 25 query

5. **If team mode is NOT enabled, run these 3 queries in parallel** using `mcp__datadog__analyze_datadog_logs`. All queries share these settings:
   - `filter`: `service:llm-gateway "audit trail message" @project_name:"Claude Code"`
   - `storage_tier`: `flex_and_indexes`
   - `from`: `now-{period}` (or `2025-03-12T00:00:00Z` if `all`)
   - `to`: `now`
   - `extra_columns`: `[{"name": "@user_email", "type": "string"}, {"name": "@cost", "type": "float64"}, {"name": "@cost_params.bedrock_cost_params.InputTokens", "type": "int64"}, {"name": "@cost_params.bedrock_cost_params.OutputTokens", "type": "int64"}, {"name": "@cost_params.bedrock_cost_params.CacheCreationInputTokens", "type": "int64"}, {"name": "@cost_params.bedrock_cost_params.CacheReadInputTokens", "type": "int64"}]`

   **Query A — Top 25 by request count:**
   ```
   sql: SELECT "@user_email" as user_email, count(*) as request_count, round(sum("@cost"), 2) as total_cost, sum("@cost_params.bedrock_cost_params.InputTokens") as input_tokens, sum("@cost_params.bedrock_cost_params.OutputTokens") as output_tokens, sum("@cost_params.bedrock_cost_params.CacheCreationInputTokens") as cache_write_tokens, sum("@cost_params.bedrock_cost_params.CacheReadInputTokens") as cache_read_tokens FROM logs GROUP BY "@user_email" ORDER BY request_count DESC LIMIT 25
   ```

   **Query B — Current user's stats:**
   ```
   sql: SELECT "@user_email" as user_email, count(*) as request_count, round(sum("@cost"), 2) as total_cost, sum("@cost_params.bedrock_cost_params.InputTokens") as input_tokens, sum("@cost_params.bedrock_cost_params.OutputTokens") as output_tokens, sum("@cost_params.bedrock_cost_params.CacheCreationInputTokens") as cache_write_tokens, sum("@cost_params.bedrock_cost_params.CacheReadInputTokens") as cache_read_tokens FROM logs WHERE "@user_email" = '{user_email}' GROUP BY "@user_email"
   ```

   **Query C — Total unique users and rank:**
   ```
   sql: SELECT count(DISTINCT "@user_email") as total_users FROM logs
   extra_columns: [{"name": "@user_email", "type": "string"}]
   ```

6. **Calculate the user's rank**: Count how many users in Query A have more requests than the current user (from Query B). If the user isn't in the top 25, run an additional query to find exact rank:
   ```
   sql: SELECT count(DISTINCT "@user_email") as rank_above FROM logs WHERE "@user_email" IN (SELECT "@user_email" FROM logs GROUP BY "@user_email" HAVING count(*) > {user_request_count})
   extra_columns: [{"name": "@user_email", "type": "string"}]
   ```
   The user's rank = rank_above + 1.

7. **Present results**:

   **For team mode:**
   - Show a team leaderboard table with all team members ranked by request count
   - For token columns, use compact format: divide by 1000 and show as `XXXk` (e.g., 1096699 → `1,097k`)
   - Token columns: `Input`, `Output`, `Cache Write`, `Cache Read`
   - Highlight the current user's row with `>>>` markers
   - Include each member's global rank (calculate using the rank query above)
   - Show team totals at the bottom (sum of all members)
   - Include the time period in the header

   **For global mode:**
   - Show rank, email (truncated to username part before @), request count, total cost, and token columns
   - For token columns, use compact format: divide by 1000 and show as `XXXk` (e.g., 1096699 → `1,097k`)
   - Token columns: `Input`, `Output`, `Cache Write`, `Cache Read`
   - Highlight the current user's row with `>>>` markers
   - Show the user's rank and stats summary at the top
   - Include the time period in the header
   - If the user is not in the top 25, show their stats separately below the table
