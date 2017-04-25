#!/bin/bash

set -e
# Credit goes to https://github.com/jferris for this script, slightly tweaked to work better with ubuntu
cutstring="DO NOT EDIT BELOW THIS LINE"

git submodule init && git submodule update || true
for name in *; do
  target="$HOME/.$name"
  if [ -e $target ]; then
    if [ ! -L $target ]; then
      cutline=`grep -n -m1 "$cutstring" "$target" | sed "s/:.*//"`
      if [[ -n $cutline ]]; then
        let "cutline = $cutline - 1"
        echo "Updating $target"
        head -n $cutline "$target" > update_tmp
	platform=`uname`
	if [[ "$platform" == 'Darwin' ]]; then
		startline=`tail -r "$name" | grep -n -m1 "$cutstring" | sed "s/:.*//"`
	else
		startline=`tac "$name" | grep -n -m1 "$cutstring" | sed "s/:.*//"`
	fi
        if [[ -n $startline ]]; then
          tail -n $startline "$name" >> update_tmp
        else
          cat "$name" >> update_tmp
        fi
        mv update_tmp "$target"
      else
        echo "WARNING: $target exists but is not a symlink."
      fi
    fi
  else
    if [[ $name != 'install.sh' && $name != 'README.textile' ]]; then
      echo "Creating $target"
      if [[ -n `grep "$cutstring" "$name"` ]]; then
        cp "$PWD/$name" "$target"
      else
        ln -s "$PWD/$name" "$target"
      fi
    fi
  fi
done

# install vundle and then run it!
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle >/dev/null 2>&1 || true
vim +BundleInstall +qall
