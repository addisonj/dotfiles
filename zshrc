# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh

# source aliases
if [ -e "$HOME/.aliases" ]; then
  source "$HOME/.aliases"
fi

# configure apps
if [ -e "$HOME/.app_env" ]; then
  source "$HOME/.app_env"
fi

# env vars, not tracked by source control
if [ -e "$HOME/.env_vars" ]; then
  source "$HOME/.env_vars"
fi

# Stat my options
# ignore duplicate entries in history
setopt histignoredups

# increase history size
export HISTSIZE=2000

# incremental search
bindkey ^R history-incremental-search-backward

# End My options
# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
export ZSH_THEME="powerlevel9k/powerlevel9k"

# Set to this to use case-sensitive completion
# export CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
export DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# export DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# export DISABLE_AUTO_TITLE="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(deb history-substring-search npm node ruby urltools vi-mode z)

# Set the editor
export EDITOR=vim
# set up powerline
#
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_COLOR_SCHEME='light'
POWERLEVEL9K_CUSTOM_VAULTED_ENV='vaultedEnv'
POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=$'\ue0c4'
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=$'\ue0c5'
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir custom_vaulted_env vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(vi_mode status root_indicator background_jobs history time)
source $ZSH/oh-my-zsh.sh

bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
