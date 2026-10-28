# Dotfiles

Portable preferences live here. Company-specific workflows and model/MCP setup belong in a separate private checkout; credentials and runtime state stay local.

## Editor and shell symlinks

Requires GNU Stow:

```sh
./stow-all.sh
```

This stows only the editor, terminal, window-manager, tmux, and shell packages. It does **not** stow `agents`, `pi`, or `omp`. For a disposable destination, set `DOTFILES_TARGET=/path/to/empty/home`.

The shell optionally sources `~/.config/dotfiles/work.zsh` for private work setup and `~/.config/dotfiles/buildkite.zsh` for a local credential. Neither file belongs in this repository. The agent installer can link the work setup, but never installs credentials.

## Pi and OMP

Requires Python 3.11+; the installer uses only the standard library. Preview first:

```sh
python3 setup-agents.py
python3 setup-agents.py --apply
```

Add private sources explicitly when needed:

```sh
python3 setup-agents.py --private ~/dotfiles-private --omp-profile work
python3 setup-agents.py --private ~/dotfiles-private --omp-profile work --apply
```

`--omp-profile work` writes `~/.omp/profiles/work/agent/`; omit it for `~/.omp/agent/`. The private directory must exist outside this repository. It is never inferred from your machine.

Choose a provider/model and authenticate separately in each harness. The public sources do not require an internal gateway. Public OMP setup explicitly uses `always-ask` tool approvals; Pi retains its built-in `ask` project-trust default. Private overrides may choose different policies.

Install the packages listed in Pi's generated settings using your Pi version's package commands. The Python-refactor extension also needs:

```sh
(cd ~/.pi/agent/extensions/python-refactor && npm ci)
```

`open-in-nvim` requires macOS, Warp, and Neovim. `pi-vimmode.config.js` is optional configuration for the separate `pi-vimmode` package; it does not install that package. The installer does not install packages, patch dependencies, fetch gateways, or migrate authentication.

`omp/extensions/vim-jj.ts` maps `jj` within 300 ms to exit OMP's Vim insert mode. A lone `j` appears immediately; pasted text and normal-mode movement are unchanged. The installer symlinks this user-owned extension into the selected profile, outside Homebrew and managed plugin installations.

### Sources and generated files

| Public source | Optional private source | Live destination |
|---|---|---|
| `agents/.agents/AGENTS.md` | `agents/AGENTS.md` | `~/.agents/AGENTS.md` |
| Shared instructions above | `pi/AGENTS.md` | `~/.pi/agent/AGENTS.md` |
| `agents/.agents/skills/<name>` | `agents/skills/<name>` | `~/.agents/skills/<name>` symlink |
| — | `agents/skill-overrides/<name>/` | `~/.agents/skill-overrides/<name>` symlink |
| `pi/.pi/agent/settings.json` | `pi/settings.json` | `~/.pi/agent/settings.json` |
| `pi/.pi/agent/title-renamer.json` | `pi/title-renamer.json` | `~/.pi/agent/title-renamer.json` |
| `pi/.pi/agent/context-prune/settings.json` | `pi/context-prune/settings.json` | Same path under `~/.pi/agent/` |
| `pi/.pi/agent/extensions/` | `pi/extensions/` | Per-extension links under `~/.pi/agent/extensions/` |
| `omp/config.json` | `omp/config.json` | OMP `config.yml` |
| `omp/APPEND_SYSTEM.md` | `omp/APPEND_SYSTEM.md` | OMP `APPEND_SYSTEM.md` |
| `omp/extensions/`, if present | `omp/extensions/` | OMP extension links |
| — | `pi/files/` | Additional Pi support-file links |
| — | `zsh/work.zsh` | `~/.config/dotfiles/work.zsh` |

Private paths in this table are relative to `--private`. JSON objects merge recursively; private arrays and scalar values **replace**, not append to, public values. Instructions are concatenated public first, private second. OMP accepts the generated JSON syntax in its YAML configuration file.

Edit source files, then rerun setup. Live settings are independent generated files so a harness cannot write through a symlink into the public sources. Harness-side preference changes must be moved back into the appropriate source before reinstalling.

Reusable skill implementations stay public, including feature-stack planning, PR/worktree mechanics, TDD, slides, feedback, worklogs, Datadog, and rollout tracking. Only workflows whose substance is internal remain in the private `agents/skills/` tree. Each skill has one implementation; public/private full skill names must be distinct.

Optional local policy, data sources, and real project examples live under private `agents/skill-overrides/<name>/instructions.md` with any supporting files beside it. The installer links these directories into `~/.agents/skill-overrides/<name>`. Public skills explicitly read their matching supplement when present and work without it. Supplements do not override repository policy or safety requirements; they are not separate skills or duplicate bodies.

The installer composes `~/.agents/skills` and repairs existing Pi/Claude/Cursor/Codex skill links and Claude command links that point into these trees. It leaves unrelated resources and harness-local copies alone; it does not enable every skill in every harness.

Existing managed paths are preserved under numbered entries in `~/.local/state/dotfiles/backups/<timestamp>/`. Stowed directory roots are detached without modifying their sources. Unmanaged files are retained. Omitting `--private` is **not** a private-resource removal command; use a fresh home to exercise a public-only setup.

Auth, live MCP configuration, sessions, caches, and databases are not imported. Do not put them in `pi/files/` or any source tree. `.gitignore` is a guardrail, not a secret scanner, and does not remove tracked files or historical exposure. Review Git history before sharing; exposed credentials must be revoked, not merely deleted from the latest version.

### Verification

Disposable install (no model calls or package installation):

```sh
HOME_DIR=$(mktemp -d)
python3 setup-agents.py --home "$HOME_DIR" --apply
```

Migration regression test:

```sh
python3 -m unittest discover -s tests -v
```
