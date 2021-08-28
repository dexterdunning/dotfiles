# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export EDITOR='nvim'

# Path to your oh-my-zsh installation.
export ZSH="/home/dexter/.oh-my-zsh"


# terminal colors
export TERM="xterm-256color"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

export MANPAGER='nvim +Man!'

# add dart to path
export PATH="$PATH":"$HOME/.pub-cache/bin"

alias python="python2.7"


# -------------------------------
#
#           ALIAS
#
# -------------------------------
alias zshconfig="nvim ~/.zshrc"
alias zshso="source .zshrc"
alias ohmyzsh="nvim ~/.oh-my-zsh"
alias apti="sudo apt install -y "
alias aptup="sudo apt update"
alias aptug="sudo apt upgrade -y"
alias lec="sshpass -p '\$34Erft34' ssh dexterdunning@lectura.cs.arizona.edu"


# -------------------------------
#           SCRIPTS
# -------------------------------
alias startup="~/.scripts/startup.sh"
alias tmuxcwd="~/.scripts/tmux-cwd.sh"
alias gbackup="~/.scripts/google-drive-backup.sh"
alias qute="~/.scripts/qute.sh"
alias zshhistoryfix="~/.scripts/zsh_history_fix.sh"
alias backup_photos="duplicity ~/Pictures/library b2://001e283ebef18180000000002:K001s0O7poKh7SJmt4NL5mP+OyUdAjA@dectura-backup --allow-source-mismatch && touch ~/Desktop/backup.txt"


# -------------------------------
#           NORDVPN
# -------------------------------
alias nords="nordvpn c United_States Phoenix"
alias nordp2p="nordvpn c --group P2P Switzerland"
alias nordd="nordvpn d"

alias pip="pip3"


# -------------------------------
#
#           PLUGINS
#
# -------------------------------
source ~/.zplug/init.zsh

# vi mode
zplug "nyquase/vi-mode"
zplug "b4b4r07/zsh-vimode-visual", defer:3

# # Load theme file
zplug "jenssegers/palenight.zsh-theme", as:theme

# # syntax highlight
zplug "zsh-users/zsh-syntax-highlighting", defer:2

# autocomplete
zplug "zsh-users/zsh-autosuggestions"

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load --verbose

# fzf default command
export FZF_DEFAULT_COMMAND="find . -path '*/\.*' -type d -prune -o -type f -print -o -type l -print 2> /dev/null | sed s/^..//"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
