#!/bin/sh
echo "This script will set up your public and private git bare repositories and prepare your computer for the reprov scrips."
echo "Make sure to run as user and to delete any files in ~ that will conflict (such as .bashrc)"

read -p "Press Enter to begin..."

# make sure we're in ~
cd

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

# set the UntrackedFiles flag
cfgp config --local status.showUntrackedFiles no

