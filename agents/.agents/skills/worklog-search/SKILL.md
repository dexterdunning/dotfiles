---
name: worklog-search
description: Search worklog entries by keyword, tag, type, or date
argument-hint: [search query or flags]
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*), AskUserQuestion(*)
---

Search worklog entries by various criteria.

## Input

$ARGUMENTS — search query or flags. Examples:
- `migration` — search titles and impact for "migration"
- `--tag career-growth` — all entries with this tag
- `--type pr` — all PR entries
- `--since 2025-01-01` — entries since this date
- `--type design-doc --tag career-growth` — combined filters
- (no args) — ask the user what they're looking for

## Steps

### Step 1: Parse Query

Parse $ARGUMENTS into filters:
- Plain text → keyword search (matches against title, impact, links)
- `--tag <name>` → filter by tag
- `--type <type>` → filter by type (pr, commit, design-doc, review, mentoring, incident, talk, code-review, other)
- `--since <date>` → entries on or after date
- `--until <date>` → entries on or before date
- `--quarter Q1-2025` / `--half H1-2025` — time shortcuts (same parsing as worklog-summary)

Multiple filters are AND-ed together.

If no arguments, ask the user what they want to search for.

### Step 2: Load and Filter Entries

Read all YAML files from `~/.worklog/entries/`.
Apply all filters.

### Step 3: Display Results

Show matching entries in a concise format:

```
Found 5 entries matching: tag=career-growth, since=2025-01-01

  2025-02-25  [design-doc]  New provisioning architecture
              Tags: career-growth, platform-migration
              Impact: Defined technical direction for Q2
              Links: https://docs.google.com/...

  2025-02-20  [mentoring]   Onboarded new hire to platform team
              Tags: career-growth
              Impact: Accelerated ramp-up by 2 weeks

  2025-01-15  [talk]        Presented domain events migration at eng all-hands
              Tags: career-growth, platform-migration
              Impact: Drove adoption across 3 teams

  ... (2 more)
```

If no results, suggest broadening the search or list available tags/types.

### Step 4: Offer Actions

After showing results, ask if the user wants to:
- Edit any entry (open the YAML file path for them)
- Re-tag entries (bulk add/remove a tag)
- Generate a summary from these results
