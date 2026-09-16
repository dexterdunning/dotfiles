### Setup Symlinks

```
chmod +x stow-all.sh
./stow-all.sh
```

### Pi (coding agent)

`pi/.pi/agent/` stows `settings.json`, `title-renamer.json`, and custom extensions into `~/.pi/agent/` (file-level symlinks; pi's sessions/auth/npm caches stay local). After stowing on a fresh machine:

```
(cd ~/.pi/agent/extensions/python-refactor && npm install)
```

### Agents (personal skills)

Canonical tree: `agents/.agents/` (stowed to `~/.agents`).

Harness skill links point **directly** at `~/dotfiles/agents/.agents/skills/<name>` (not via `~/.agents`). Use `/new-skill` to add skills.
