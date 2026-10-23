---
name: dexter-agent-config-sync
description: Use when Dexter asks to sync, compare, audit, migrate, translate, or keep aligned his Claude Code and Codex personal/repo configuration, including CLAUDE.md, AGENTS.md, slash commands, skills, memories, settings, and workflow drift.
---

# Dexter Agent Config Sync

Use this skill to keep Claude and Codex aligned semantically without forcing one tool to imitate the other.

If `~/.agents/skill-overrides/dexter-agent-config-sync/instructions.md` exists, read it for the machine's source map and integrations. Otherwise use the portable map below. Local supplements do not override repository policy or safety requirements.

## Source Map

Read `references/config-sync.md` first. It defines the current source and target files for each workflow.

## Sync Principle

Sync intent, not syntax.

- Shared repo behavior belongs in repo-local `CLAUDE.md` / `AGENTS.md`.
- Durable personal workflows belong in `~/.codex/skills` and the equivalent Claude location.
- Repo-specific workflows belong in `.agents/skills`.
- Personal preferences should stay short and personal.
- Tool-specific UI, auth, plugin state, logs, sessions, and caches are not drift by default.

## Workflow

1. Read `references/config-sync.md`.
2. Read only the Claude source files and Codex target files relevant to Dexter's request.
3. Classify differences:
   - **Shared intent drift**: same policy should exist in both tools but differs.
   - **Tool-specific mechanics**: different because the products work differently.
   - **Stale instruction**: obsolete, contradictory, or superseded.
   - **Missing workflow**: useful Claude/Codex behavior has no counterpart.
4. Recommend or patch the minimum change.
5. When editing personal config outside the repo, request approval if sandbox rules require it.
6. Report what changed and what was intentionally left unsynced.

## Files To Inspect First

- Repo `AGENTS.md`
- Repo `CLAUDE.md`
- Repo `.agents/skills/*/SKILL.md`
- `~/.claude/CLAUDE.md`
- `~/.claude/commands/*.md`
- `~/.claude/skills/*/SKILL.md`
- `~/.claude/settings.json`
- `~/.codex/config.toml`
- `~/.codex/skills/*/SKILL.md`

## Guardrails

- Do not copy Claude commands verbatim into Codex skills when a broader workflow skill is clearer.
- Do not copy Codex system/plugin/cache/session files into repo config.
- Do not overwrite user-specific settings unless Dexter explicitly asks for that exact change.
- Prefer updating one existing skill over creating a competing skill with overlapping triggers.
- Keep skill bodies concise; move detailed reference material into linked files only when necessary.

## Output Format

For audits, report:

- **In sync**
- **Drift found**
- **Changed**
- **Left tool-native**
- **Recommended next pass**
