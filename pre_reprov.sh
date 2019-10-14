#!/bin/sh
echo "This script will set up your public and private git repositories, populate your home directory, and prepare your computer for the reprov scripts."
echo "Make sure to run as user and be careful typing your username and password..."

read -p "Press Enter to begin..."

# make sure we're in ~
cd

# delete files that will interfere with our git repositories
[ -f ~/.bashrc ] && rm ~/.bashrc
[ -f ~/.bash_profile ] && rm ~/.bash_profile

# configure the cfg alias
alias cfg='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# eliminate recursion problems
echo ".cfg" >> .gitignore

# clone the repo
git clone --bare https://github.com/aleksozolins/dotfiles.git $HOME/.cfg

# again configure the alias (might be redundant)
alias cfg='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# checkout
cfg checkout

# set the UntrackedFiles flag
cfg config --local status.showUntrackedFiles no

# make sure we're in ~
cd

# set upstream
cfg push --set-upstream origin master

# configure the cfgp alias
alias cfgp='/usr/bin/git --git-dir=$HOME/.cfgp/ --work-tree=$HOME'

# eliminate recursion problems
echo ".cfgp" >> .gitignore

# clone the repo
git clone --bare https://github.com/aleksozolins/dotfiles_private.git $HOME/.cfgp

# again configure the alias (might be redundant)
alias cfgp='/usr/bin/git --git-dir=$HOME/.cfgp/ --work-tree=$HOME'

# checkout
cfgp checkout

# fix permissions on ~/.gnupg
chmod -R go-rwx ~/.gnupg

# set the UntrackedFiles flag
cfgp config --local status.showUntrackedFiles no

# set upstream
cfgp push --set-upstream origin master

# make sure we're in ~
cd

# clone the password store
git clone https://github.com/aleksozolins/.password-store.git

echo "If there were no errors, you should now have a home directory full of dotfiles!"
