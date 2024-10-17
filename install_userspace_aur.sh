#!/bin/bash
# Custom Arch linux system installation script (userspace AUR packages)
# by Jure Vidmar

build_dir="/tmp/builds"

packages=(
    pcloud-drive
    typora
)



mkdir -p "$build_dir" || exit 1
printf "AUR package installation script started\n\n"
printf "Temporary build and log files in $build_dir\n\n"

for package in "${packages[@]}"; do
    package_dir="$build_dir/$package"

    printf "Installing $package\t\t"

    # All I/O for this group of commands will be redirected to a file
    {
        # Clone the AUR package repository
        git clone "https://aur.archlinux.org/$package.git" "$package_dir"   &&
        cd "$package_dir"

        # Build and install the package
        makepkg -si --noconfirm &&
        cd -

    } > $build_dir/$package.output 2>&1

    # Check if the package was installed successfully
    if [ $? -eq 0 ]; then
        printf "OK\n"
    else
        printf "FAILED\n"
    fi

done

printf "\n\nAUR package installation script finished.\n\n"
