# Arch linux installation scripts

This repository contains scripts which install and configure arch linux system.
Once booted into the Arch Linux Live USB:
- install git (`pacman -Sy git`)  
- clone this repo  
- change permissions (`chmod +x *.sh`)  
- install base system (`./install_core.sh`)  
- install userspace
    - move script to new system (e.g. /mnt/home/<USERNAME>/)  
    - execute inside chroot (`arch-chroot /mnt /bin/bash -c "path-to-script.sh <USERNAME>"`)  

