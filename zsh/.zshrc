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


# Use Homebrew curl (required for avante.nvim AWS Bedrock)
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

if [[ -r "$HOME/.config/dotfiles/buildkite.zsh" ]]; then
  source "$HOME/.config/dotfiles/buildkite.zsh"
fi
if [[ -r "$HOME/.config/dotfiles/work.zsh" ]]; then
  source "$HOME/.config/dotfiles/work.zsh"
fi
