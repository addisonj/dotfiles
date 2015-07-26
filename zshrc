# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh

# source aliases
if [ -e "$HOME/.aliases" ]; then
  source "$HOME/.aliases"
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

#source /usr/local/share/zsh/site-functions
# Uncomment following line if you want to disable colors in ls
# export DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# export DISABLE_AUTO_TITLE="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)

plugins=(deb git ruby npm node knife osx urltools go golang)
source $ZSH/oh-my-zsh.sh

# source rbenv
eval "$(rbenv init -)"


# stuff for nvm
. ~/.nvm/nvm.sh

# Z for moving around
. `brew --prefix`/etc/profile.d/z.sh
function precmd () {
 z --add "$(pwd -P)"
}
#AWS STUFF
if [ -e "$HOME/.aws_env" ]; then
  source "$HOME/.aws_env"
fi

export PLAN9=/usr/local/plan9 export PLAN9
export PATH=/usr/local/bin:/usr/local/sbin:$PATH:$PLAN9/bin

export GOROOT=/usr/local/Cellar/go/1.3.3/libexec
export GOBIN=/usr/local/Cellar/go/1.3.3/bin
export GOPATH=~/go
export PATH=$GOPATH/bin:$GOBIN:$PATH

# put local bin on PATH
if [ -e "$HOME/bin" ]; then
  HB="$HOME/bin"
  export PATH=$HB:$PATH
fi
#java stuff
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

# Set the editor
export EDITOR=vim

# OPAM configuration
. /Users/addisonj/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true
