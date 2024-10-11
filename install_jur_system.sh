#!/bin/bash
# Custom Arch linux system installation script (core system)
# Based on https://disconnected.systems/blog/archlinux-installer/ 
#
#   pacman -Sy git && git clone https://github.com/jurc192/arch_setup
#   
#   (if needed, first run pacman -S archlinux-keyring)
#
# by Jure Vidmar

# Bash flags (https://bash-prompt.net/guides/bash-set-options/)
set -xeuo pipefail

# Update pacman + choose fastest pacman mirrors
echo "Updating pacman's mirror list"
reflector --country Slovenia,Netherlands --score 5 --save /etc/pacman.d/mirrorlist

# Install utils needed for running this script
pacman -S --needed --noconfirm pacman-contrib dialog git

# Get user input: hostname, username, password
hostname=$(dialog --stdout --inputbox "Enter hostname" 0 0) || exit 1
clear
: ${hostname:?"hostname cannot be empty"}

user=$(dialog --stdout --inputbox "Enter admin username" 0 0) || exit 1
clear
: ${user:?"user cannot be empty"}

password=$(dialog --stdout --passwordbox "Enter admin password" 0 0) || exit 1
clear
: ${password:?"password cannot be empty"}
password2=$(dialog --stdout --passwordbox "Enter admin password again" 0 0) || exit 1
clear
[[ "$password" == "$password2" ]] || ( echo "Passwords did not match"; exit 1; )


# setup logging
exec 1> >(tee "install_script_stdout.log")
exec 2> >(tee "install_script_stderr.log")

# Disk partitioning and filesystems
devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select installtion disk" 0 0 0 ${devicelist}) || exit 1
clear

boot_size=512Mib    # 512 + 1MiB offset. WHy do we need that? MBR?
parted --script "${device}" -- \
  mklabel gpt \
  mkpart ESP fat32 0% ${boot_size} \
  set 1 boot on \
  mkpart primary ext4 ${boot_size} 100%

part_boot="$(ls ${device}* | grep -E "^${device}p?1$")"
part_root="$(ls ${device}* | grep -E "^${device}p?2$")"

wipefs "${part_boot}" && mkfs.vfat -F32 "${part_boot}"
wipefs "${part_root}" && mkfs.ext4 "${part_root}"

mount "${part_root}" /mnt
mkdir /mnt/boot
mount "${part_boot}" /mnt/boot


# Install base system
pacstrap /mnt linux linux-firmware base base-devel sudo man-db man-pages nano openssh parted wpa_supplicant networkmanager git

# Post-installation stuff
genfstab -t PARTUUID /mnt > /mnt/etc/fstab

arch-chroot /mnt /bin/bash -x <<- CHROOT
    
    # Hostname
    printf "$hostname\n" > /etc/hostname

    # Locale
    locale="en_US.UTF-8"
    printf "LANG=\$locale\n" > /etc/locale.conf
    sed -i "/\$locale/s/^#//" /etc/locale.gen
    locale-gen

    # Timezone
    ln -sf /usr/share/zoneinfo/Europe/Ljubljana /etc/localtime

    # Create user account
    useradd -mU -G wheel,video,audio,storage,lp,optical,uucp "$user"
    printf "$user:$password\n" | chpasswd
    printf "%%wheel ALL=(ALL) ALL\n" > /etc/sudoers.d/99_wheel
    visudo -cf /etc/sudoers.d/99_wheel

    # Free access to dmesg
    printf "kernel.dmesg_restrict=0\n" > /etc/sysctl.d/99-dmesg.conf

    # Boot manager (systemd-boot)
    bootctl install
    printf "default archlinux\n" > /boot/loader.conf
    cat <<- INNER > /boot/loader/entries/archlinux.conf
        title    Arch Linux
        linux    /vmlinuz-linux
        initrd   /initramfs-linux.img
        options  root=PARTUUID=$(blkid -s PARTUUID -o value "$part_root") rw
    
INNER
CHROOT

printf "\n\nCore system installed successfully\n\n"

# Install userspace
arch-chroot /mnt /bin/bash <<EOF

    echo "Bulding and installing jur-userspace"
    runuser "$user" git clone https://github.com/jurc192/arch-packages && cd arch-packages/jur-userspace && makepkg -si

    runuser $user <<- 'HEREDOC2'
        cd /home/$user/

        DIR_NAME=.dotfiles_git
        git clone --bare https://github.com/jurc192/dotfiles.git $HOME/$DIR_NAME || exit 1

        function dotfiles {
        /usr/bin/git --git-dir=$HOME/$DIR_NAME --work-tree=$HOME $@
        }
        dotfiles checkout
        if [ $? -ne 0 ]; then
            # if checkout fails, remove all files
            printf "Removing conflicting files due to failed checkout\n"
            cd $HOME
            dotfiles checkout 2>&1 | grep -E "\s+\." | awk '{$1=$1;print}' | xargs -d '\n' rm -rf
            dotfiles checkout || exit 1
            printf "Dotfiles checkout succeeded\n"
        fi;

        dotfiles config status.showUntrackedFiles no
        
        printf "\nConfiguration files applied successfully\n"

        # Install themes
        git clone https://github.com/jurc192/themes.git $HOME/.themes || exit 1
    HEREDOC2

EOF

printf "\n\nUserspace installed successfully\n\n"