---
name: new-skill
argument-hint: "[skill-name] [one-line purpose, or blank to interview]"
description: Create a new personal Dexter skill in the shared ~/.agents/skills home and wire Cursor/Claude/Pi symlinks (and optional Claude /command). Use when the user says /new-skill, asks to add/create a personal skill, or wants to register a skill in the central symlink layout.
---

Create or register a **personal** skill in Dexter's shared skill home. Task: $ARGUMENTS

## Layout (do not reinvent)

The canonical live discovery directory is the composed `~/.agents/skills` tree (public + private source skills linked together).

| Role | Path |
|------|------|
| **Canonical (live)** | `~/.agents/skills/<name>/SKILL.md` |
| Public source | `~/dotfiles/agents/.agents/skills/<name>` |
| Private source | `~/dotfiles-private/agents/skills/<name>` (workflows whose substance is internal) |
| Private supplement | `~/dotfiles-private/agents/skill-overrides/<name>/instructions.md` → `~/.agents/skill-overrides/<name>/instructions.md` |
| Cursor | `~/.cursor/skills/<name>` → **canonical dir** (one hop) |
| Claude skills | `~/.claude/skills/<name>` → **canonical dir** |
| Pi | `~/.pi/agent/skills/<name>` → **canonical dir** |
| Claude `/` command (optional) | `~/.claude/commands/<name>.md` → **canonical `SKILL.md`** |

Rules:
- **Edit only the canonical source** behind `~/.agents/skills/<name>` — never fork content into harness dirs or edit the composed link itself.
- **Personal skills stay out of product repos** (not in a company repo's `.claude/skills` unless intentionally team-shared).
- **Never** put personal skills in `~/.cursor/skills-cursor/` (Cursor-managed).
- Name: lowercase, hyphens, max 64 chars. Match directory name = frontmatter `name` = command basename.
- **Keep reusable workflows public.** Put internal examples, source locations, and company policy in a private supplement, not a duplicate skill body. The public skill must work without that supplement; add an explicit optional-read hook at its start. Local supplements cannot override repository policy or safety requirements.

## Workflow

### 1. Resolve the skill name + purpose

From `$ARGUMENTS`, or ask once if missing:
- `name` (hyphenated)
- one-sentence purpose (feeds `description`)
- whether it should auto-trigger from ambient chat (`disable-model-invocation: true` = slash/explicit only; omit for eager trigger)
- whether to add a Claude `/` command symlink (default **yes** for workflows Dexter will invoke by name)

### 2. Write the skill

Choose the public or private source tree based on audience. Create `<source>/skills/<name>/SKILL.md`, then run `python3 ~/dotfiles/setup-agents.py --private ~/dotfiles-private --omp-profile trial --apply` to expose it through `~/.agents/skills/<name>`. Omit `--private` and choose the appropriate profile on a public-only machine. Do not create a new real directory inside the composed discovery tree.

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
CANON="$HOME/.agents/skills/$NAME"
test -f "$CANON/SKILL.md" || { echo "Install the source skill with setup-agents.py first"; exit 1; }

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
# Expect: .../.agents/skills/$NAME
test -f "$HOME/.agents/skills/$NAME/SKILL.md" && head -6 "$HOME/.agents/skills/$NAME/SKILL.md"
```

Report: canonical path, which harnesses were linked, whether `/<name>` was wired.

## Migrating an existing skill into the layout

If content already lives elsewhere (repo `.claude/skills`, a harness-local copy, a command-only file):

1. Move the skill into the appropriate public/private source tree, then rerun `setup-agents.py` to create its composed discovery entry.
2. Run the symlink block above
3. Delete the old copies so there is one source of truth

## Anti-patterns

- Writing `SKILL.md` only under `~/.cursor/skills` or `~/.claude/skills`
- Copying the same skill into multiple harness dirs
- Writing new sources directly into the composed `~/.agents/skills` directory instead of the public/private source tree
- Explaining this layout from scratch in chat instead of using this skill
