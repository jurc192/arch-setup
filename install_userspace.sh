#!/bin/bash
# Custom Arch linux system installation script (userspace)
# by Jure Vidmar

PACKAGES="linux linux-firmware base base-devel sudo man-db man-pages nano openssh parted wpa_supplicant networkmanager xorg xorg-server xfce4 openbox git firefox code ttf-fira-code xclip tint2 picom xcape network-manager-applet papirus-icon-theme rofi wmctrl" 
PACKAGES_AUR="pcloud typora"

[[ $EUID -ne 0 ]] && echo "This script must be run as root." && exit 1
[ -z "$1" ]       && echo "Usage: $0 <user>"                 && exit 1

# Install packages
pacman -S --quiet --noprogressbar $PACKAGES || exit 1

# Install AUR packages
mkdir -p /tmp/aur-pkgs
sudo cd /tmp/aur-pkgs || exit 1
for pkg in $PACKAGES_AUR; do
    git clone https://aur.archlinux.org/$pkg.git  &&
    sudo -u $1 makepkg --syncdeps --install --noconfirm --noprogressbar --needed -p $pkg/PKGBUILD || 
    printf "\n\nPackage $pkg failed to install\n"
done

# Enable services
systemctl enable NetworkManager

# Install dotfiles
DIR_NAME=.dotfiles_git
sudo -u $1 git clone --bare https://github.com/jurc192/dotfiles.git $HOME/$DIR_NAME || exit 1

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
sudo -u $1 git clone https://github.com/jurc192/themes.git $HOME/.themes || exit 1

printf "\nInstallation completed!\n"