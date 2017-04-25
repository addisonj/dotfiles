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
export HISTSIZE=200

# incremental search
bindkey ^R history-incremental-search-backward

# End My options
# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
export ZSH_THEME="flazz"

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

plugins=(deb git ruby npm node knife osx urltools go golang)
source $ZSH/oh-my-zsh.sh

# Set the editor
export EDITOR=vim
