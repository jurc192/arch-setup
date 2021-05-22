#!/bin/bash
# Custom Arch linux system installation script (userspace)
# by Jure Vidmar

# Execute with (needs root privileges):
# $ ./install_userspace.sh <user>

PACKAGES="linux linux-firmware base base-devel sudo man-db man-pages nano openssh parted wpa_supplicant networkmanager xorg xorg-server xfce4 xfce4-screenshooter openbox git firefox code ttf-fira-code xclip tint2 picom xcape network-manager-applet papirus-icon-theme rofi wmctrl gsimplecal"
PACKAGES_AUR="typora"

set -x
[[ $EUID -ne 0 ]] && echo "This script must be run as root." && exit 1
[ -z "$1" ]       && echo "Usage: $0 <user>"                 && exit 1

# Install packages
pacman -S --quiet --noprogressbar --needed $PACKAGES || exit 1

# Install AUR packages
runuser $1 <<- HEREDOC
    mkdir -p /tmp/aur-pkgs
    cd /tmp/aur-pkgs || exit 1
    for pkg in $PACKAGES_AUR; do
        git clone https://aur.archlinux.org/\$pkg.git  &&
        cd \$pkg &&
        sudo -u $1 makepkg --syncdeps --install --noconfirm --noprogressbar --needed || 
        printf "\n\nPackage \$pkg failed to install\n"
    done
HEREDOC

# Enable services
systemctl enable NetworkManager

# Install dotfiles and themes
runuser $1 <<- 'HEREDOC'
    DIR_NAME=.dotfiles_git
    git clone --bare https://github.com/jurc192/dotfiles.git $HOME/$DIR_NAME || exit 1

    function dotfiles {
    /usr/bin/git --git-dir=$HOME/$DIR_NAME --work-tree=$HOME $@
    }
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

    # Install themes
    git clone https://github.com/jurc192/themes.git $HOME/.themes || exit 1
HEREDOC

printf "\nInstallation completed!\n"