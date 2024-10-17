#!/bin/bash
set -xeuo pipefail

if [ -z "$?" ]; then
    printf "Run script with: ./install_userspace.sh <username>\n\tusername - username of the chroot's systems user"
    exit 1
fi;
user=$1

# Install userspace
arch-chroot /mnt /bin/bash <<EOF

    echo "Bulding and installing jur-userspace"
    runuser "$user" git clone https://github.com/jurc192/arch-packages
    cd arch-packages/jur-userspace
    makepkg -si

    runuser $user <<- 'HEREDOC2'
        cd /home/"$user"/

        DIR_NAME=".dotfiles_git"
        git clone --bare https://github.com/jurc192/dotfiles.git \$HOME/\$DIR_NAME || exit 1

        function dotfiles {
        /usr/bin/git --git-dir=\$HOME/\$DIR_NAME --work-tree=\$HOME \$@
        }
        dotfiles checkout
        if [ \$? -ne 0 ]; then
            # if checkout fails, remove all files
            printf "Removing conflicting files due to failed checkout\n"
            cd \$HOME
            dotfiles checkout 2>&1 | grep -E "\s+\." | awk '{\$1=\$1;print}' | xargs -d '\n' rm -rf
            dotfiles checkout || exit 1
            printf "Dotfiles checkout succeeded\n"
        fi;

        dotfiles config status.showUntrackedFiles no
        
        printf "\nConfiguration files applied successfully\n"

        # Install themes
        git clone https://github.com/jurc192/themes.git \$HOME/.themes || exit 1
    HEREDOC2


    printf "\n\nUserspace installed successfully\n\n"
EOF