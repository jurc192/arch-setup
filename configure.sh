#!/bin/bash
# https://git.io/JsOyy

DIR_NAME=.dotfiles_git

function dotfiles {
   /usr/bin/git --git-dir=$HOME/$DIR_NAME --work-tree=$HOME $@
}

printf "\nRunning dotfiles setup script...\n"
git clone --bare https://github.com/jurc192/dotfiles.git $HOME/$DIR_NAME || exit 1

printf "\nChecking out\n"
dotfiles checkout
if [ $? -ne 0 ]; then
    # if checkout fails, remove all files
    printf "Checkout failed: removing conflicting files\n"
    cd $HOME
    dotfiles checkout 2>&1 | egrep "\s+\." | awk '{$1=$1;print}' | xargs -d '\n' rm -rf
    dotfiles checkout || exit 1
fi;

dotfiles config status.showUntrackedFiles no
printf "alias dots='git --git-dir=$HOME/$DIR_NAME/ --work-tree=$HOME'\n" >> $HOME/.bashrc
printf "\nConfiguration files applied successfully\n"
