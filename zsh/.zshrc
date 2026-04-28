export EDITOR='nvim'

export ZSH="$HOME/.oh-my-zsh"

# use vim when opening man pages
export MANPAGER='nvim +Man!'

# General Alias
alias zshco="nvim ~/.zshrc"
alias zshso="source ~/.zshrc"

# git
alias gca="git commit --amend"
alias gcan="git commit --amend --no-edit"
alias git-pull-all="find . -type d -depth 1 -exec git --git-dir={}/.git --work-tree=$PWD/{} pull \;  "
alias gc="git commit -m"
alias ga="git add ."
alias gl="git log --oneline -10"


# git merge with vim
alias gm="nvim -c \"G mergetool\""

# keybinds for auto complete
bindkey '^h'   backward-word
bindkey '^l'   forward-word

# fzf default command
export FZF_DEFAULT_COMMAND="find . -path '*/\.*' -type d -prune -o -type f -print -o -type l -print 2> /dev/null | sed s/^..//"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH=$HOME/.toolbox/bin:$PATH

# Created by `pipx` on 2024-06-22 15:47:20
export PATH="$PATH:$HOME/.local/bin"
eval "$(pyenv init -)"

# git-spice alias
alias gsdu="gs down && gs up"
alias gsbrbs="gs br && gs bs"
alias gsrc="gs rebase continue"

export AWS_PROFILE=devexp-playground-claude

# Use Homebrew curl (required for avante.nvim AWS Bedrock)
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

export BUILDKITE_API_TOKEN=bkua_af8bada364fb291144960817d6b3e6df9fddb847

# CDE CLI zsh configuration
source /Users/dexter/.cde/.venv/lib/python3.11/site-packages/cde_cli/cde_cli_sh_rc.sh

# Rippling Dev-Env Vars
export DEVELOPER_NAME="dexterdunning"
export CDE_SLIM_INIT_ENABLED=true

# Rippling Alias
alias lde="cde local"
alias lde-type-check="uv run --project=tools/python/lint lint --check incremental_typing --verbose && lde mypy check"
alias lde-mypy="uv run mypy"
alias lde-format="python3 -m ruff check --fix"
alias lde-test-daemon="lde test --daemon --watch time_tracking"
alias lde-hot-test="lde test --hot-reload --watch time_tracking"
alias fix-wcli="rm ~/.npmrc && wcli doctor"
alias run-dev-prod="source config.prod.dev.sh && npm run start"
alias opus="cde claude --model 'opus[1m]'"
alias sonnet="cde claude --model 'sonnet[1m]'"
alias ripm="cd ~/projects/rippling-main/"
alias ripw="cd ~/projects/rippling-webapp/"
alias tt="cd ~/projects/rippling-main/app/time_tracking/"
alias ttw="cd ~/projects/rippling-webapp/app/products/hr/TimeTracking/"
alias ws="cd ~/projects/webscripts/"

# Rippling aws profile
export AWS_PROFILE=developer-cde

# Rippling CDE Setup
eval "$(direnv hook zsh)"
export PATH=$PATH:$NVM_DIR/versions/node/v22.15.0/bin/mobile-cli

# ===== BEGIN MOBILE-CLI MANAGED (DO NOT EDIT) =====
# ===== END MOBILE-CLI MANAGED =====
