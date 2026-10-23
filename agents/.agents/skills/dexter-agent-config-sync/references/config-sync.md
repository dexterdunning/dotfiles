# Agent configuration source map

Sync intent, not product syntax. Inventory actual files and links before choosing a source of truth; paths below are conventions, not a claim that every harness uses them.

## Repository guidance

- Start with repository `AGENTS.md` / `CLAUDE.md` and the relevant module guidance already provided by the harness.
- Keep repository behavior, test commands, PR policy, architectural rules, and gotchas in repository-owned guidance.
- Repository-specific workflows belong in the repository's skill/command directories. Do not publish internal examples or policies merely to synchronize tools.

## Personal instructions

- In this dotfiles layout, portable source preferences are `~/dotfiles/agents/.agents/AGENTS.md`; optional private supplements are supplied explicitly to `setup-agents.py`.
- `~/.agents/AGENTS.md` is generated. Pi's instructions are generated from shared instructions plus its optional private supplement. OMP links to the shared generated file.
- Edit sources and rerun the installer; do not maintain parallel full preference copies or assume a harness loads another product's instructions.
- Claude, Codex, and Cursor may retain separate native instruction files. Inspect their actual references and align shared preferences deliberately without overwriting tool-specific additions.

## Personal workflows

- Public skill sources: `~/dotfiles/agents/.agents/skills/<name>`.
- Optional private skill sources: `<private-root>/agents/skills/<name>`.
- Live discovery: `~/.agents/skills/<name>` links to exactly one source.
- Optional private workflow details: `<private-root>/agents/skill-overrides/<name>/instructions.md`, exposed through `~/.agents/skill-overrides/<name>`.
- Edit the resolved source, not generated files or harness-local copies. Existing harness/command links can point through the live discovery entries.

Translate capabilities rather than copying commands literally: worktree setup, PR shipping/review, tests, and visual verification should preserve their approval and safety constraints while using the destination harness's real tools. Do not assume that an MCP endpoint, managed browser, credential store, or extension API exists elsewhere.

## Native GitHub stacks

Keep stack-related skills aligned on native `gh stack`, explicit GitHub membership verification, preserved draft state, and explicit merge authorization. A local branch chain alone is not a native GitHub stack; do not promise CI deduplication without checking the pipeline.

## Leave native state alone

Do not synchronize auth, tokens, sessions, databases, logs, caches, plugin/marketplace state, or tool-specific UI settings by default. Provider configuration examples must contain no live credentials. Audit instruction drift separately from operational state.

For a machine-specific source map, follow the optional local supplement for this skill. Without one, identify the existing sources for the requested workflow and report missing integrations instead of inventing them.
