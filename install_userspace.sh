#!/bin/bash
set -xeuo pipefail

if [ -z "$?" ]; then
    printf "Run script with: ./install_userspace.sh <username>\n\tusername - username of the chroot's systems user"
    exit 1
fi;
user=$1

# Install userspace
printf "\n\nCore system installed successfully\n\n"

# Install userspace
arch-chroot /mnt /bin/bash <<EOF

    echo "Building and installing jur-userspace"
    git clone https://github.com/jurc192/arch-packages /home/$user/arch-packages
    cd /home/$user/arch-packages/jur-userspace
    makepkg -si

    # Run all user-specific commands using runuser -c ""
    runuser "$user" -c "
        cd /home/$user/

        DIR_NAME='.dotfiles_git'
        git clone --bare https://github.com/jurc192/dotfiles.git \$HOME/\$DIR_NAME || exit 1

        function dotfiles {
            /usr/bin/git --git-dir=\$HOME/\$DIR_NAME --work-tree=\$HOME \"\$@\"
        }

        dotfiles checkout
        if [ \$? -ne 0 ]; then
            # If checkout fails, remove all conflicting files
            printf 'Removing conflicting files due to failed checkout\n'
            cd \$HOME
            dotfiles checkout 2>&1 | grep -E '\s+\.' | awk '{\$1=\$1;print}' | xargs -d '\n' rm -rf
            dotfiles checkout || exit 1
            printf 'Dotfiles checkout succeeded\n'
        fi

        dotfiles config status.showUntrackedFiles no
        printf '\nConfiguration files applied successfully\n'

        # Install themes
        git clone https://github.com/jurc192/themes.git \$HOME/.themes || exit 1
    "

EOF

printf "\n\nUserspace installed successfully\n\n"
