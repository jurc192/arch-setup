# Arch setup notes

Things I want to do:

- theme installation (icons, gtk)

  - GTK theme: [Fantome](https://github.com/addy-dclxvi/gtk-theme-collections)
  - Openbox theme: [Triste-Crimson](https://github.com/addy-dclxvi/openbox-theme-collections)
  - Icon theme: `papirus-icon-theme` package from community repo
  - TODO add to installation script

  

- [OK] firefox shortcuts

  - fixed by logging in. How to do this from a script?

Manual steps after installation:
- download and install pCloud
- login and sync Firefox

## Openbox theme

Stored in `~/.themes/THEME_NAME/openbox-3/`.
Used theme is specified in `~/.config/openbox/rc.xml` @theme
Wiki: http://openbox.org/wiki/Help:Themes 



### GTK theme

Stored in `~/.themes/THEME_NAME`.
Used theme is specified in ???
Wiki: https://wiki.archlinux.org/title/GTK 

When using xfce4 settings editor, the settings are changed in the GSettings Dconf thingy **database**.
But there's an option of using files in *.config* folder, which looks much nicer. How does all this work?



## Icon theme

Install w/ pacman (papirus-icon-theme). Apply with xfce settings manager, use papirus-dark.
How to do this in a script?

How to make modifying the script easier?

https://gist.github.com/7ec5c3544d9eaf2ace5becb8389402c7.git 
Added this stuff to git repo `arch-setup`: 
https://github.com/jurc192/arch_setup 

Created two files packages.txt and packages_aur.txt
Now figuring out how to get them without pCloud... (avoiding git, to not have everything there but ok)

Wrapping chroot stuff into a function, exporting it. Idea taken from here:
https://stackoverflow.com/questions/30792028/executing-function-inside-chroot-in-bash 



## Application Launcher

Install *rofi* and bind it to WIN key. For this, you need to use **xcape** tool which simulates a big-ass-key-combo on key release.
Added `xcape -e 'Super_L=Control_L|Shift_L|Alt_L|Super_L|D'` to *.xinitrc* file.



OFFTOPIC detour git.

How to combine two commits into one? How to check what's already pushed and what not?
