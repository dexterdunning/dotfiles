---
name: worklog-tag
description: Manage worklog tags (create, list, rename, merge, delete)
argument-hint: <create|list|rename|merge|delete> [args]
allowed-tools: Bash(*), Read(*), Grep(*), Glob(*), Write(*), Edit(*), AskUserQuestion(*)
---

Manage tags in the worklog system.

## Input

$ARGUMENTS — subcommand and arguments. Examples:
- `create` — interactive tag creation
- `create my-new-project` — create a tag with this ID
- `list` — list all tags with entry counts
- `rename old-name new-name` — rename a tag across all entries
- `merge source-tag target-tag` — merge source into target, removing source
- `delete tag-name` — remove a tag from config and all entries

## Steps

### Subcommand: `create` (or `create <tag-id>`)

1. If tag ID provided, use it. Otherwise ask the user for one.
   - Validate: lowercase, hyphens and underscores only, no spaces
2. Ask for type: `project` or `career`
3. Ask for description (one line)
4. Ask for hint keywords (comma-separated, optional) — these help auto-tagging
5. Ask for hint paths (glob patterns, optional) — file paths that suggest this tag
6. Ask for hint PR labels (optional) — GitHub labels that suggest this tag
7. Add the tag to `~/.worklog/config.yaml`
8. Confirm creation

### Subcommand: `list`

1. Read `~/.worklog/config.yaml` for tag definitions
2. Count entries per tag by scanning `~/.worklog/entries/*.yaml`
3. Display:

```
Tags (5 total):

  Project Tags:
    platform-migration    12 entries   "On-change to domain events migration"
    frontend-redesign      4 entries   "React component library migration"

  Career Tags:
    career-growth          8 entries   "Mentorship, tech talks, design docs"
    incident-response      3 entries   "Oncall incidents handled"
    code-reviews           6 entries   "Notable code reviews"
```

### Subcommand: `rename <old> <new>`

1. Validate both tag names
2. Read config — find the old tag, update its ID to the new name
3. Scan all entries in `~/.worklog/entries/` — replace old tag name with new in the `tags:` list
4. Update any summaries that reference the old name (or note they'll be stale)
5. Write updated config and entries
6. Report: "Renamed 'old' to 'new' across X entries"

### Subcommand: `merge <source> <target>`

1. Validate both tags exist
2. Scan all entries — for any entry with source tag, add target tag (if not present) and remove source tag
3. Remove source tag from config (keep target)
4. Optionally merge hint keywords from source into target
5. Report: "Merged 'source' into 'target', updated X entries"

### Subcommand: `delete <tag-name>`

1. Confirm with user: "This will remove the tag 'X' from config and Y entries. Continue?"
2. Remove from config
3. Remove from all entries' tag lists
4. Report results

## Validation

- Always back up config before destructive operations (copy to config.yaml.bak)
- Warn if a tag has entries before deleting
- Prevent creating duplicate tag IDs
