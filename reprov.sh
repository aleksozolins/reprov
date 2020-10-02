#!/bin/sh
clear
echo "This script will set up your public and private git repositories, populate your home directory with dotfiles, and configure various programs."
echo "It should be run from ~/repos/reprov"
echo "Make sure to run as user with sudo privileges and be accurate typing your credentials. You will need to type your git and GPG passphrase multiple times."

read -p "Press Enter to begin..."

# make sure we're in ~
cd

# delete files that will interfere with our git repositories
[ -f ~/.bashrc ] && rm ~/.bashrc
[ -f ~/.bash_profile ] && rm ~/.bash_profile

# configure the cfg alias in the current shell scope
alias cfg='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# eliminate recursion problems
echo ".cfg" >> .gitignore

# clone the repo
git clone --bare https://github.com/aleksozolins/dotfiles.git $HOME/.cfg

# checkout
cfg checkout

# set the UntrackedFiles flag
cfg config --local status.showUntrackedFiles no

# set upstream
cfg push --set-upstream origin master

# make sure we're in ~
cd

# configure the cfgp alias in the current shell scope
alias cfgp='/usr/bin/git --git-dir=$HOME/.cfgp/ --work-tree=$HOME'

# eliminate recursion problems
echo ".cfgp" >> .gitignore

# clone the repo
git clone --bare https://github.com/aleksozolins/dotfiles_private.git $HOME/.cfgp

# checkout
cfgp checkout

# set the UntrackedFiles flag
cfgp config --local status.showUntrackedFiles no

# set upstream
cfgp push --set-upstream origin master

# fix permissions on ~/.gnupg
chmod -R go-rwx ~/.gnupg

# clone the password store
git clone https://github.com/aleksozolins/password-store.git ~/.local/share/password-store/

# create some necessary directories and change owners as necessary
mkdir $HOME/desk/
mkdir $HOME/dls/
sudo mkdir /mnt/4TBext4
sudo chown aleksozolins:aleksozolins /mnt/4TBext4
ln -s $HOME/Dropbox/xdg/docs/ $HOME
ln -s $HOME/Dropbox/xdg/pics/ $HOME
ln -s $HOME/Dropbox/xdg/vids/ $HOME
ln -s $HOME/Dropbox/xdg/mus/ $HOME
mkdir $HOME/.config/gtk-2.0/

#create .dropbox-dist directory as read-only to prevent automatic update startup problem
install -dm0 $HOME/.dropbox-dist

echo "If there were no errors, you should now have a home directory full of dotfiles!"

# ask about trim support?
echo "Would you like to enable trim support for SSDs? yes or no ?"
read trim

# ask about st
echo "Would you like to install Luke Smith's build of st? NOTE: You may have to adjust the config.h file afterwords and reinstall. yes or no?"
read te

# ask about cron jobs
echo "Would you like to enable the cronie service for cron jobs? yes or no?"
read cronie

# ask about creating the maildirs
echo "Would you like to create the top level mail directories in ~/.local/share/mail/? yes or no ?"
read maildirs

# ask about syncing mail accounts.
echo "Would you like to synchronize all your mail accounts? yes or no ?"
read mailsync

# ask about printer support
echo "Would you like to install/enable printer/network printing support? yes or no ?"
read printer

# ask about touchpad/trackpoint
echo "Is this a Thinkpad with a trackpoint? Do you need xf86-input-synaptics? yes or no?"
read synaptics

# ask about throttling fix for x1
echo "Is this your Thinkpad Carbon X1? Do you need to install and enable the throttling fix?? yes or no?"
read throttled

# ask about broadcom-wl
echo "Do you need broadcom wireless, maybe for the X61? yes or no?"
read broadcom

# ask about Nvidia
echo "Do you need that evil Nvidia driver? yes or no?"
read nvidia

# ask about Dropbox and systemd
echo "Enable Dropbox as a systemd unit? Note, you'll not have access to the tray icon or selective sync."
echo "For server use only... think nzxt. yes or no?"
read dropbox

sudo pacman -S --noconfirm --needed - < ~/repos/reprov/pacman_reprov.txt

# does ~/repos exist?
if [ ! -d ~/repos ]
  then
  mkdir ~/repos
  else
  echo "~/repos already exists!"
fi

# enable trim support if yes
if [[ $trim == y* ]]
  then
  sudo systemctl enable fstrim.timer
  else
  echo "moving on..."
fi

# install a terminal emulator if yes
if [[ $te == y* ]]
  then
  cd ~/repos && git clone https://github.com/LukeSmithxyz/st.git && cd ~/repos/st && sudo make install 
  else
  echo "OK, but don't blame me when you can't get a prompt..."
fi

# enable cronie for cron jobs if yes
if [[ $cronie == y* ]]
  then
  sudo systemctl enable --now cronie 
  else
  echo "Whatever that's fine..."
fi

# recreate the top level mail directories if yes
if [[ $maildirs == y* ]]
  then
  mkdir ~/.local/share/mail && mkdir ~/.local/share/mail/aleksozolins && mkdir ~/.local/share/mail/icloud
  else
  echo "That's fine we'll just move on then..."
fi

# install printer support if yes
if [[ $printer == y* ]]
  then
  sudo pacman -S --noconfirm cups system-config-printer ghostscript avahi nss-mdns
  sudo sed -i '10s/.*/hosts: files mymachines myhostname mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns/' /etc/nsswitch.conf
  sudo systemctl enable --now avahi-daemon.service
  sudo systemctl enable --now org.cups.cupsd.service
  else
  echo "Onward!!!"
fi

# install synaptics if yes
if [[ $synaptics == y* ]]
  then
  sudo pacman -S --noconfirm xf86-input-synaptics
  else
  echo "moving on..."
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

# install nvidia if yes
if [[ $nvidia == y* ]]
  then
  sudo pacman -S --noconfirm nvidia nvidia-settings
  else
  echo "um ok..."
fi

# change to ~/repos
cd ~/repos

# clone into yay
git clone https://aur.archlinux.org/yay.git

# change to ~/repos/yay
cd ~/repos/yay

# install yay
makepkg -si --noconfirm

echo "yay installed!"

# install programs
yay -S --noconfirm --removemake ttf-symbola dropbox dropbox-cli pam-gnupg-git breeze-default-cursor-theme geekbench nestopia gtk-theme-arc-gruvbox-git j4-dmenu-desktop

# change to ~/repos
cd ~/repos

# clone into dwm
git clone https://github.com/aleksozolins/dwm62c.git

# change to ~/repos/dwm62c
cd ~/repos/dwm62c

# install dwm
sudo make install

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
cat ~/repos/reprov/ips | sudo tee -a /etc/hosts

# install vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.config/nvim/bundle/Vundle.vim

# mbsync all accounts if yes
if [[ $mailsync == y* ]]
  then
  mbsync -c ~/.config/mbsyncrc -a
  else
  echo "no mail for you!"
fi

# if cronie enabled, ask about mailsync cronjob
if [[ $cronie == y* ]]
  then
  echo "How many minutes between mailsyncs?"
  read mailmin
  (crontab -l; echo "*/$mailmin * * * * export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus; export DISPLAY=:0; . \$HOME/.profile; $(type mailsync | cut -d' ' -f3)") | crontab -
  echo "mailsync cron job enabled"
  else
  echo "cronie is not enabled"
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
echo "-Configure Thunderbird email" >> ~/reprov_todo.txt
echo "-Login to Firefox" >> ~/reprov_todo.txt
echo "-Set your screenlayouts using arandr. default.sh and docked.sh. Remember to set wallpapers there too. Use ~/.config/screenlayout/" >> ~/reprov_todo.txt
echo "-Configure your GTK theme/fonts/cursor using lxappearance" >> ~/reprov_todo.txt
echo "-If your console font is too small, remember to add (for example) FONT=ter-128n to /etc/vconsole.conf" >> ~/reprov_todo.txt
echo "-Run :PluginInstall from within vim" >> ~/reprov_todo.txt
