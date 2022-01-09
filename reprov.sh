#!/bin/sh
clear
echo "This script will set up your public and private git repositories, populate your home directory with dotfiles, and configure various programs."
echo "It should be run from ~/repos/reprov_new/"
echo "Make sure to run as user with sudo privileges and be accurate typing your credentials. You will need to type your git and GPG passphrase multiple times."

read -p "Press Enter to begin..."

# make sure we're in ~
cd

# delete files that will interfere with our git repositories
[ -f ~/.bashrc ] && rm ~/.bashrc
[ -f ~/.bash_profile ] && rm ~/.bash_profile

# Clone the dotfiles repo
git clone https://github.com/aleksozolins/dotfiles_stow.git ~/.dotfiles/

# Stow dotfiles
sudo pacman -S --noconfirm stow
cd ~/.dotfiles/
stow arch dosbox dunst flameshot fontconfig git gnupg gpgkeys mc mpd ncmpcpp newsboat nvim pam-gnupg picom qutebrowser sxhkd tmux transmission w3m youtube-dl zathura isync

# create .bash_profile symlink
cd
ln -s ~/.profile ~/.bash_profile

# fix permissions on ~/.gnupg
chmod -R go-rwx ~/.gnupg

# clone the password store
git clone https://github.com/aleksozolins/password-store.git ~/.local/share/password-store/

# create some necessary directories and change owners as necessary
mkdir $HOME/dls/
ln -s $HOME/Dropbox/desk/ $HOME
ln -s $HOME/Dropbox/docs/ $HOME
ln -s $HOME/Dropbox/pics/ $HOME
ln -s $HOME/Dropbox/vids/ $HOME
ln -s $HOME/Dropbox/mus/ $HOME

#create .dropbox-dist directory as read-only to prevent automatic update startup problem
install -dm0 $HOME/.dropbox-dist

echo "If there were no errors, you should now have a home directory full of dotfiles!"

# ask about syncing mail accounts.
# echo "Would you like to synchronize all your mail accounts? yes or no ?"
# read mailsync

# ask about intel video
echo "Would you like to install xf86-video-intel? yes or no (will use modesetting) ?"
read intelvid

# ask about resolution
echo "Is this a 1080p system? yes or no for 720p ?"
read resi

# ask about touchpad/trackpoint
echo "Is this a Thinkpad with a trackpoint? Do you need xf86-input-synaptics? yes or no?"
read synaptics

# ask about throttling fix for x1
echo "Is this your Thinkpad Carbon X1? Do you need to install and enable the throttling fix?? yes or no?"
read throttled

# ask about broadcom-wl
echo "Do you need broadcom wireless, maybe for the X61? yes or no?"
read broadcom

# ask about Dropbox and systemd
echo "Enable Dropbox as a systemd unit? Note, you'll not have access to the tray icon or selective sync."
echo "For server use only... think nzxt. yes or no?"
read dropbox

# Install programs
sudo pacman -S --noconfirm --needed - < ~/repos/reprov_new/pacman_reprov.txt

# enable trim support
sudo systemctl enable fstrim.timer

# install a terminal emulator
cd ~/repos && git clone https://github.com/LukeSmithxyz/st.git && cd ~/repos/st && sudo make install 

# enable cronie for cron jobs
sudo systemctl enable --now cronie 

# recreate the top level mail directories
mkdir ~/.local/share/mail && mkdir ~/.local/share/mail/aleksozolins

# install printer support
sudo sed -i '10s/.*/hosts: files mymachines myhostname mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns/' /etc/nsswitch.conf
sudo systemctl enable --now avahi-daemon.service
sudo systemctl enable --now cups.service

# install synaptics if yes
if [[ $synaptics == y* ]]
   then
   sudo pacman -S --noconfirm xf86-input-synaptics
   else
   echo "moving on..."
fi

# install intel video driver if yes
if [[ $intelvid == y* ]]
   then
   sudo pacman -S --noconfirm xf86-video-intel
   else
   echo "modesetting it is"  
fi

# stow appropriate gtk configs
if [[ $resi == y* ]]
   then
   cd ~/.dotfiles
   stow gtk    
   else
   cd ~/.dotfiles
   stow gtk_720
fi
   
# install throttling fix if yes
if [[ $throttled == y* ]]
   then
   sudo pacman -S --noconfirm throttled
   sudo systemctl enable --now lenovo_fix.service
   else
   echo "alrighty..."
fi

# install broadcom-wl if yes
if [[ $broadcom == y* ]]
   then
   sudo pacman -S --noconfirm broadcom-wl
   else
   echo "let's keep going..."
fi

# change to ~/repos
cd ~/repos

# clone into paru
git clone https://aur.archlinux.org/paru.git

# change to ~/repos/paru
cd ~/repos/paru

# install paru
makepkg -si --noconfirm

echo "paru installed!"

# install programs
paru -S --mflags --skippgpcheck --noconfirm --removemake ttf-symbola dropbox dropbox-cli pam-gnupg-git breeze-default-cursor-theme gtk-theme-arc-gruvbox-git j4-dmenu-desktop pipe-viewer-git tremc rtv

# install dmenu
cd ~/repos
if [[ $resi == y* ]]
   then
   git clone https://github.com/aleksozolins/dmenu.git
   cd ~/repos/dmenu
   sudo make install
   else
   git clone https://github.com/aleksozolins/dmenu_720.git
   cd ~/repos/dmenu_720
   sudo make install
fi

# delete install files
rm -f dmenu.o config.h dmenu

# install dwm
cd ~/repos
if [[ $resi == y* ]]
   then
   git clone https://github.com/aleksozolins/dwm62c_1080.git
   cd ~/repos/dwm62c_1080
   sudo make install
   else
   git clone https://github.com/aleksozolins/dwm62c_720.git
   cd ~/repos/dwm62c_720
   sudo make install
fi

# delete install files
rm -f dwm.o config.h dwm

# change to ~/repos
cd ~/repos

# clone into dwmblocks_apo
git clone https://github.com/aleksozolins/dwmblocks_apo.git

# change to ~/repos/dwmblocks_apo
cd ~/repos/dwmblocks_apo

# install dwmblocks
sudo make install

# import your GPG keys
gpg --import ~/.local/share/gpg/aleks_ozolins_public_gpg_key.txt
gpg --import ~/.local/share/gpg/aleks_ozolins_private_gpg_key.asc

# define the alternate pass directory and initialize the password store
export PASSWORD_STORE_DIR="$HOME/.local/share/password-store/"
pass init aleksozolins

# make changes to /etc/pam.d/system-local-login as root
echo "auth      optional  pam_gnupg.so" | sudo tee -a /etc/pam.d/system-local-login
echo "session   optional  pam_gnupg.so" | sudo tee -a /etc/pam.d/system-local-login

# enable music player daemon as user
systemctl enable --user mpd.service

# append ips to /etc/hosts
cat ~/repos/reprov_new/ips | sudo tee -a /etc/hosts

# install vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim

# mbsync all accounts if yes
if [[ $mailsync == y* ]]
   then
   mbsync -c ~/.config/mbsyncrc -a
   else
   echo "no mail for you!"
fi

# rebuild the grub config with microcode
sudo grub-mkconfig -o /boot/grub/grub.cfg

# modify /etc/bash.bashrc so that non-login shells will source the custom bashrc location
echo "if [ -s "${XDG_CONFIG_HOME:-$HOME/.config}/bashrc" ]; then" | sudo tee -a /etc/bash.bashrc
echo "   . "${XDG_CONFIG_HOME:-$HOME/.config}/bashrc"" | sudo tee -a /etc/bash.bashrc
echo "fi" | sudo tee -a /etc/bash.bashrc

# enable Dropbox as a systemd unit if yes
if [[ $dropbox == y* ]]
   then
   sudo systemctl enable dropbox@aleksozolins
   echo "Dropbox enabled as a systemd unit."
   else
   echo "Zooming by...."
fi

# lets end up in ~
cd

echo "If you didn't see any errors, you should be all set!!!"
echo "Be sure to check ~/reprov_todo.txt for final configuration tasks."
echo "IT'S A GOOD IDEA TO REBOOT NOW TO ENSURE ENVIRONMENTAL VARIABLES ARE SET CORRECTLY!"
echo "Some things you might want to do now:" >> ~/reprov_todo.txt
echo "-Login to your Dropbox and sync ALL xdg directories. If enabled as a systemd unit run dropbox-cli status to sync." >> ~/reprov_todo.txt 
echo "-Configure powertop.service" >> ~/reprov_todo.txt
echo "-Login to Firefox" >> ~/reprov_todo.txt
echo "-Set your screenlayouts using arandr. default.sh and docked.sh. Remember to set wallpapers there too. Use ~/.config/screenlayout/" >> ~/reprov_todo.txt
echo "-If you'd like a non-standard resolution for your main display, remember to generate xorg.conf from the console (sudo X -configure), move that file from /root to /etc/X11/xorg.conf, and add (Option quotePreferredModequote quote1400x1050quote) or whatever resi to the Monitor secion of xorg.conf" >> ~/reprov_todo.txt
echo "-If your console font is too small, remember to add (for example) FONT=ter-128n to /etc/vconsole.conf" >> ~/reprov_todo.txt
echo "-Run :PluginInstall from within vim" >> ~/reprov_todo.txt
