#!/bin/bash
# Custom Arch linux system installation script (userspace AUR packages)
# by Jure Vidmar

build_dir="/tmp/builds"

packages=(
    pcloud-drive
    typora
)



mkdir -p "$build_dir"

for package in "${packages[@]}"; do
    package_dir="$build_dir/$package"

    # All I/O for this group of commands will be redirected to a file
    {
        # Clone the AUR package repository
        git clone "https://aur.archlinux.org/$package.git" "$package_dir"   &&
        cd "$package_dir"

        # Build and install the package
        makepkg -si --noconfirm

    } > $build_dir/$package.output 2>&1

    # Check if the package was installed successfully
    if [ $? -eq 0 ]; then
        echo "$package successfully installed."
    else
        echo "Failed to install $package."
    fi

    # Return to the original directory
    cd -
done

printf "\n\nAUR packages have been installed.\n\n"
