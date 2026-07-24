---
name: new-skill
argument-hint: [skill-name] [one-line purpose, or blank to interview]
description: Create a new personal Dexter skill in the shared ~/.agents/skills home and wire Cursor/Claude/Pi symlinks (and optional Claude /command). Use when the user says /new-skill, asks to add/create a personal skill, or wants to register a skill in the central symlink layout.
---

Create or register a **personal** skill in Dexter's shared skill home. Task: $ARGUMENTS

## Layout (do not reinvent)

Canonical tree lives in the dotfiles stow package. `~/.agents` is a stow symlink for home-path compat.

| Role | Path |
|------|------|
| **Canonical** | `~/dotfiles/agents/.agents/skills/<name>/SKILL.md` |
| Compat | `~/.agents` → `dotfiles/agents/.agents` (do not put harness links through this) |
| Cursor | `~/.cursor/skills/<name>` → **canonical dir** (one hop) |
| Claude skills | `~/.claude/skills/<name>` → **canonical dir** |
| Pi | `~/.pi/agent/skills/<name>` → **canonical dir** |
| Claude `/` command (optional) | `~/.claude/commands/<name>.md` → **canonical `SKILL.md`** |

Rules:
- **Edit only the canonical copy.** Never fork content into harness dirs.
- **Harness links target `~/dotfiles/agents/.agents/skills/<name>`, not `~/.agents/skills/<name>`.**
- **Personal skills stay out of product repos** (not in `rippling-main/.claude/skills` unless intentionally team-shared).
- **Never** put personal skills in `~/.cursor/skills-cursor/` (Cursor-managed).
- Name: lowercase, hyphens, max 64 chars. Match directory name = frontmatter `name` = command basename.

## Workflow

### 1. Resolve the skill name + purpose

From `$ARGUMENTS`, or ask once if missing:
- `name` (hyphenated)
- one-sentence purpose (feeds `description`)
- whether it should auto-trigger from ambient chat (`disable-model-invocation: true` = slash/explicit only; omit for eager trigger)
- whether to add a Claude `/` command symlink (default **yes** for workflows Dexter will invoke by name)

### 2. Write the skill

Create `~/dotfiles/agents/.agents/skills/<name>/SKILL.md`:

```markdown
---
name: <name>
description: <what it does>. Use when <trigger phrases>.
argument-hint: [optional]
# disable-model-invocation: true
---

<concise instructions; prefer procedures over prose>
```

Description must include WHAT + WHEN (third person). Keep the body short — only what the agent wouldn't already know.

### 3. Wire symlinks

```bash
NAME=<name>
CANON="$HOME/dotfiles/agents/.agents/skills/$NAME"
mkdir -p "$CANON"
# SKILL.md must already exist at $CANON/SKILL.md

mkdir -p "$HOME/.cursor/skills" "$HOME/.claude/skills" "$HOME/.pi/agent/skills" "$HOME/.claude/commands"
ln -sfn "$CANON" "$HOME/.cursor/skills/$NAME"
ln -sfn "$CANON" "$HOME/.claude/skills/$NAME"
ln -sfn "$CANON" "$HOME/.pi/agent/skills/$NAME"

# Optional Claude slash command
ln -sfn "$CANON/SKILL.md" "$HOME/.claude/commands/$NAME.md"
```

If a harness path already exists as a **real directory** (not a symlink), remove/replace it — do not leave a duplicate copy.

### 4. Verify

```bash
NAME=<name>
readlink "$HOME/.cursor/skills/$NAME"
readlink "$HOME/.claude/skills/$NAME"
readlink "$HOME/.pi/agent/skills/$NAME"
# Expect: .../dotfiles/agents/.agents/skills/$NAME  (not .../.agents/skills/...)
test -f "$HOME/dotfiles/agents/.agents/skills/$NAME/SKILL.md" && head -6 "$HOME/dotfiles/agents/.agents/skills/$NAME/SKILL.md"
```

Report: canonical path, which harnesses were linked, whether `/<name>` was wired.

## Migrating an existing skill into the layout

If content already lives elsewhere (repo `.claude/skills`, a harness-local copy, a command-only file):

1. Move (or copy-then-delete) into `~/dotfiles/agents/.agents/skills/<name>/SKILL.md`
2. Run the symlink block above
3. Delete the old copies so there is one source of truth

## Anti-patterns

- Writing `SKILL.md` only under `~/.cursor/skills` or `~/.claude/skills`
- Copying the same skill into multiple harness dirs
- Harness links through `~/.agents` (extra hop) instead of `~/dotfiles/agents/.agents`
- Committing personal skills into `rippling-main`
- Explaining this layout from scratch in chat instead of using this skill
