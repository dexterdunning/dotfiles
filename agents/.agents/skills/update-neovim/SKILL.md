---
name: update-neovim
description: Update Neovim (built from source) and all of its plugins/parsers/extensions. Use whenever the user asks to update, upgrade, or refresh Neovim, vim-plug plugins, treesitter parsers, or coc.nvim extensions — even if they only mention one of those pieces, walk through the full sequence so everything stays in sync.
---

# Update Neovim

Bring the user's source-built Neovim and its plugin ecosystem up to date. The user installed Neovim from source at `~/build-from-source/neovim`, manages plugins with vim-plug, and uses both `nvim-treesitter` and `coc.nvim`.

## When to use
- User says "update neovim", "upgrade nvim", "rebuild neovim", or similar.
- User asks to update plugins, treesitter parsers, or coc extensions.
- After a long break from coding when things are likely stale.

## Steps

### 1. Update Neovim from source
Run from the Neovim source repo:

```bash
cd ~/build-from-source/neovim
git fetch --tags --force          # --force so stable/nightly tag moves don't abort the fetch
LATEST_TAG=$(git tag -l 'v[0-9]*' --sort=-v:refname | head -1)
CURRENT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "unknown")
echo "Current: $CURRENT_TAG  Latest: $LATEST_TAG"
```

If `LATEST_TAG` is newer than `CURRENT_TAG`, check it out and rebuild:

```bash
git checkout "$LATEST_TAG"
make distclean
make CMAKE_BUILD_TYPE=Release
sudo make install
nvim --version | head -3
```

Notes:
- The default install prefix is `/usr/local`; `sudo` is required for `make install`.
- `make distclean` is important — it wipes the previous build tree so dependency versions get refreshed.
- If the build fails on missing tooling, install with: `brew install ninja cmake gettext curl`.

### 2. Update vim-plug and its plugins
vim-plug is the user's plugin manager (config lives in `~/.config/nvim/init.vim`). Update headlessly:

```bash
nvim --headless "+PlugUpgrade" "+PlugUpdate --sync" +qall
```

`PlugUpgrade` updates vim-plug itself; `PlugUpdate --sync` updates all plugins synchronously so the headless invocation actually waits for completion.

### 3. Update treesitter parsers and CoC extensions
These plugins typically don't load fully in headless mode, so prompt the user to run them interactively:

```vim
:TSUpdate
:CocUpdate
```

Suggest a one-liner: `nvim -c "TSUpdate | CocUpdate"`.

If the user wants to attempt headless first, try:

```bash
nvim --headless "+TSUpdateSync" +qall
nvim --headless "+CocUpdateSync" +qall
```

If either reports `E492: Not an editor command`, fall back to the interactive instructions.

### 4. Verify
- `nvim --version` reports the new version.
- Open `nvim` and run `:checkhealth` to confirm nothing regressed.

## Important notes
- Never commit anything in `~/build-from-source/neovim` as part of this skill — it's an upstream clone.
- If the user is already on the latest tag, skip the build steps and only refresh plugins/parsers/extensions.
- If `which nvim` reports a path other than `/usr/local/bin/nvim` (e.g., a Homebrew install at `/opt/homebrew/bin/nvim`), stop and confirm with the user before installing — they may have switched install methods.
