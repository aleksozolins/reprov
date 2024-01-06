#!/bin/bash

clear
echo "This script will set up your public and private git repositories, populate your home directory with dotfiles, and configure various programs."
echo "It should be run from ~/repos/reprov/"
echo "Logging will be enabled to ~/reprov_log.txt"
echo "Make sure to run as user with sudo privileges and be accurate typing your credentials. You will need to type your git and GPG passphrase multiple times."
read -p "Press Enter to begin..."

# cause the script to exit if there are any errors
set -e

# Create a log file and write all output and errors to it
exec > >(tee ~/reprov_log.txt) 2>&1

# append ips to /etc/hosts
cat ~/repos/reprov/ips | sudo tee -a /etc/hosts

# rebuild the grub config with microcode
sudo grub-mkconfig -o /boot/grub/grub.cfg

# delete files that will interfere with our git repositories
[ -f ~/.bashrc ] && rm ~/.bashrc
[ -f ~/.bash_profile ] && rm ~/.bash_profile

# Clone the private dotfiles repo
git clone https://github.com/aleksozolins/dotfiles_private.git ~/.pdotfiles/

# Clone the dotfiles repo
git clone https://github.com/aleksozolins/dotfiles.git ~/.dotfiles/

# Stow private dotfiles
sudo pacman -S --noconfirm stow
cd ~/.pdotfiles/
stow --no-folding git gpgkeys mbsync ssh

# Stow dotfiles
cd ~/.dotfiles/
stow --no-folding alacritty arch dunst emacs flameshot fontconfig gnupg mac_linux mc mpd ncmpcpp nvim pam-gnupg picom sxhkd tmux transmission w3m youtube-dl zathura

# create .bash_profile symlink
ln -s ~/.profile ~/.bash_profile

# modify /etc/bash.bashrc so that non-login shells will source the custom bashrc location
echo "if [ -s "${XDG_CONFIG_HOME:-$HOME/.config}/bashrc" ]; then" | sudo tee -a /etc/bash.bashrc
echo "   . "${XDG_CONFIG_HOME:-$HOME/.config}/bashrc"" | sudo tee -a /etc/bash.bashrc
echo "fi" | sudo tee -a /etc/bash.bashrc

# fix permissions on ~/.gnupg
chmod -R go-rwx ~/.gnupg

# clone the password store
git clone https://github.com/aleksozolins/password-store.git ~/.local/share/password-store/

# create some necessary directories and symlinks
mkdir $HOME/dls/
ln -s $HOME/Dropbox/desk/ $HOME
ln -s $HOME/Dropbox/docs/ $HOME
ln -s $HOME/Dropbox/pics/ $HOME
ln -s $HOME/Dropbox/vids/ $HOME
ln -s $HOME/Dropbox/mus/ $HOME

#create .dropbox-dist directory as read-only to prevent automatic update startup problem
install -dm0 $HOME/.dropbox-dist

# recreate the top level mail directories
mkdir ~/.local/share/mail && mkdir ~/.local/share/mail/aleks@ozolins.xyz

# Ask about touchpad/trackpoint and install synaptics if needed
echo "Is this a Thinkpad with a trackpoint? Do you need xf86-input-synaptics? yes or no?"
read synaptics
if [[ $synaptics == y* ]]
   then
   sudo pacman -S --noconfirm xf86-input-synaptics
fi

# ask about resolution and stow appropriate gtk configs
echo "Is this a 1080p system? Enter yes for 1080p or no for 720p."
read resi
if [[ $resi == y* ]]
   then
   cd ~/.dotfiles
   stow --no-folding gtk    
   else
   cd ~/.dotfiles
   stow --no-folding gtk_720
fi
   
# ask about and install throttling fix if necessary
echo "Is this your Thinkpad Carbon X1? Do you need to install and enable the throttling fix?? yes or no?"
read throttled
if [[ $throttled == y* ]]
   then
   sudo pacman -S --noconfirm throttled
   sudo systemctl enable --now throttled.service
fi

# ask about and install broadcom-wl if necessary
echo "Do you need broadcom wireless, maybe for the X61? yes or no?"
read broadcom
if [[ $broadcom == y* ]]
   then
   sudo pacman -S --noconfirm broadcom-wl
fi

# ask about and install non-free printer drivers if necessary
echo "Do you need non-free printer drivers from foomatic? (For Brother HL-L2360DW)? yes or no?"
read nonfreeppds
if [[ $nonfreeppds == y* ]]
   then
   sudo pacman -S --noconfirm foomatic-db-nonfree-ppds
fi

# Install all other programs from Arch repo
sudo pacman -S --noconfirm --needed - < ~/repos/reprov/pacman_reprov.txt

# install paru
git clone https://aur.archlinux.org/paru.git ~/repos/paru && \
cd ~/repos/paru && makepkg -si --noconfirm

# install all other programs from the AUR
paru -S --mflags --skippgpcheck --noconfirm --removemake ttf-symbola dropbox dropbox-cli pam-gnupg-git breeze-default-cursor-theme gtk-theme-arc-gruvbox-git j4-dmenu-desktop pipe-viewer-git mu yt-dlp

# install vundle (nvim package manager)
git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim

# install dmenu, switch to correct branch, and delete install files
git clone https://github.com/aleksozolins/dmenu.git ~/repos/dmenu
cd ~/repos/dmenu
# if resi doesn't start with y, checkout to branch 720
if [[ $resi != y* ]]; then
   git checkout 720
fi
# install and delete install files
sudo make install
rm -f drw.o stest stest.o util.o config.h dmenu dmenu.o

# install dwm, switch to correct branch, and delete install files
git clone https://github.com/aleksozolins/dwm62c.git ~/repos/dwm62c
cd ~/repos/dwm62c
# if resi doesn't start with y, checkout to branch 720
if [[ $resi != y* ]]; then
   git checkout 720
fi
# install and delete install files
sudo make install
rm -f dwm.o config.h dwm

# install dwmblocks_apo
git clone https://github.com/aleksozolins/dwmblocks_apo.git ~/repos/dwmblocks_apo && \
cd ~/repos/dwmblocks_apo && \
sudo make install

# enable trim support for ssds
sudo systemctl enable fstrim.timer

# enable cronie for cron jobs
sudo systemctl enable --now cronie

# enable music player daemon as user
systemctl enable --user mpd.service

# Enable Dropbox as a systemd unit
sudo systemctl enable dropbox@aleksozolins

# Enable lingering for my user so dropbox starts as soon as the system boots
sudo loginctl enable-linger aleksozolins

# install printer support (avahi)
sudo sed -i 's/^hosts: mymachines  resolve \[!UNAVAIL=return\] files myhostname dns/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' /etc/nsswitch.conf
sudo systemctl disable --now systemd-resolved.service
sudo systemctl enable --now avahi-daemon.service
sudo systemctl enable --now cups.service

# import your GPG keys
gpg --import ~/.local/share/gpg/aleks_ozolins_public_gpg_key.txt
gpg --import ~/.local/share/gpg/aleks_ozolins_private_gpg_key.asc

# define the alternate pass directory and initialize the password store
export PASSWORD_STORE_DIR="$HOME/.local/share/password-store/"
pass init aleksozolins

# mail account sync
echo "Would you like to synchronize all your mail accounts? yes or no ?"
read mailsync
if [[ $mailsync == y* ]]
   then
   mbsync -c ~/.config/mbsyncrc -a
fi

# initialuze mu and index mails
mu init --maildir=/home/aleksozolins/.local/share/mail --my-address=aleks@ozolins.xyz --my-address=aleks.admin@ozolins.xyz
mu index

# make changes to /etc/pam.d/system-local-login as root
echo "auth      optional  pam_gnupg.so" | sudo tee -a /etc/pam.d/system-local-login
echo "session   optional  pam_gnupg.so" | sudo tee -a /etc/pam.d/system-local-login

# lets end up in ~
cd

{
echo "#+TITLE: Reprov TODO List"
echo "#+DATE: $(date +[%Y-%m-%d %a])"
echo
echo "* Things you might want to do now:"
echo "- [ ] Run dropbox-cli status to sync and then dropbox-cli exclude to specify dirs to not sync."
echo "- [ ] Configure powertop.service"
echo "- [ ] Login to Firefox and create any additional profiles as necessary (Zapier)."
echo "- [ ] Set your screenlayouts using arandr. default.sh and docked.sh. Remember to set wallpapers there too. Use ~/.config/screenlayout/"
echo "- [ ] If you'd like a non-standard resolution for your main display, remember to generate xorg.conf from the console (sudo X -configure), move that file from /root to /etc/X11/xorg.conf, and add (Option \"PreferredMode\" \"1920x1080\") for instance to the Monitor section of xorg.conf"
echo "- [ ] Run :PluginInstall from within vim"
echo "- [ ] Set up restic for backups if necessary and create the appropriate cron job"
echo "- [ ] Copy ~/Dropbox/archive/mail/<dirs>/ to ~/.local/share/mail/ and re-run 'mu init' and 'mu index' if you want access to old emails"
} > ~/reprov_todos.org

echo "All finished!!!"
echo "Be sure to check ~/reprov_todos.org for some post-reprov tasks."
reap -p "Press Enter to reboot or ctrl-c to exit to shell."
sudo reboot
