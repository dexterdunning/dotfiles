export EDITOR='nvim'

export ZSH="$HOME/.oh-my-zsh"

# use vim when opening man pages
export MANPAGER='nvim +Man!'

# General Alias
alias zshco="nvim ~/.zshrc"
alias zshso="source ~/.zshrc"
alias gca="git commit --amend"
alias gcan="git commit --amend --no-edit"
alias git-pull-all="find . -type d -depth 1 -exec git --git-dir={}/.git --work-tree=$PWD/{} pull \;  "

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

# CDE CLI zsh configuration
source /Users/dexter/.cde/.venv/lib/python3.11/site-packages/cde_cli/cde_cli_sh_rc.sh

# Rippling Dev-Env Vars
export DEVELOPER_NAME="dexterdunning"
export CDE_SLIM_INIT_ENABLED=true

# Rippling Alias
alias lde="cde local"
export AWS_PROFILE=devexp-playground-claude
