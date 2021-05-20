#!/bin/bash
# Custom Arch linux system installation script
# Based on https://disconnected.systems/blog/archlinux-installer/ 
# by Jure Vidmar
#
# Execute with:
#   curl -sL https://git.io/JsIYv | bash

MIRRORLIST_URL="https://archlinux.org/mirrorlist/?country=SI&country=NL&protocol=http&protocol=https&ip_version=4"
PACKAGES="xorg xorg-server xfce4 openbox git firefox code ttf-fira-code xclip tint2 picom xcape network-manager-applet"
AUR_PACKAGES="pcloud typora"

### Update pacman
pacman -Sy --needed --noconfirm pacman-contrib dialog git

### Create pacman repositories mirror list
echo "Updating mirror list"
curl -s "$MIRRORLIST_URL" | \
    sed -e 's/^#Server/Server/' -e '/^#/d' | \
    rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

### User variables, names etc.
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

### Set up logging ###
exec 1> >(tee "jur_script_stdout.log")
exec 2> >(tee "jur_script_stderr.log")

###
timedatectl set-ntp true


### Set up disk partitions and filesystems
###     currently no swap enabled
devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select installtion disk" 0 0 0 ${devicelist}) || exit 1
clear

boot_size=513Mib    # 512 + 1MiB offset. WHy do we need that? MBR?
parted --script "${device}" -- \
  mklabel gpt \
  mkpart ESP fat32 1MiB ${boot_size} \
  set 1 boot on \
  mkpart primary ext4 ${boot_size} 100%

part_boot="$(ls ${device}* | grep -E "^${device}p?1$")"
part_root="$(ls ${device}* | grep -E "^${device}p?2$")"

wipefs "${part_boot}"
wipefs "${part_root}"

mkfs.vfat -F32 "${part_boot}"
mkfs.ext4 "${part_root}"

mount "${part_root}" /mnt
mkdir /mnt/boot
mount "${part_boot}" /mnt/boot

### Install base system
pacstrap /mnt linux linux-firmware base base-devel sudo man-db man-pages nano openssh parted wpa_supplicant networkmanager
genfstab -t PARTUUID /mnt > /mnt/etc/fstab

printf "$hostname\n" > /mnt/etc/hostname

locale="en_US.UTF-8"
printf "LANG=$locale\n" > /mnt/etc/locale.conf
sed -i "/$locale/s/^#//" /mnt/etc/locale.gen            # Uncomment line with sed
arch-chroot /mnt locale-gen

### Create user, enable sudo
arch-chroot /mnt useradd -mU -G wheel,video,audio,storage,lp,optical "$user"
printf "$user:$password\n" | chpasswd --root /mnt
printf "%%wheel ALL=(ALL) ALL\n" > /mnt/etc/sudoers.d/99_wheel
visudo -cf /mnt/etc/sudoers.d/99_wheel

### Install boot manager (systemd-boot)
arch-chroot /mnt bootctl install
printf "default archlinux\n" > /mnt/boot/loader.conf
cat <<EOF > /mnt/boot/loader/entries/archlinux.conf
title    Arch Linux
linux    /vmlinuz-linux
initrd   /initramfs-linux.img
options  root=PARTUUID=$(blkid -s PARTUUID -o value "$part_root") rw
EOF

arch-chroot /mnt pacman -Sy --noconfirm --quiet --noprogressbar $PACKAGES

### Enable services
arch-chroot /mnt systemctl enable NetworkManager

### Install AUR packages
arch-chroot -u $user /mnt /bin/bash -x << END
cd /home/$user
mkdir aur-packages && cd aur-packages || exit 1
for pkg in $AUR_PACKAGES; do
    git clone https://aur.archlinux.org/\$pkg.git  &&
    cd \$pkg &&
    makepkg --syncdeps --install --noconfirm --noprogressbar --needed &&
    cd .. || printf "\n\nPackage \$pkg failed to install\n"
done
cd ..
rm -rf aur-packages
END

### Configure system (install dotfiles)
arch-chroot -u $user /mnt /bin/bash -c 'export HOME=/home/jure && cd $HOME && curl -sL https://git.io/JsOyy | /bin/bash'

echo "FINISHED INSTALLATION!"
