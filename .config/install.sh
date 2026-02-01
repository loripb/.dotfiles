#!/bin/bash
set -e # STOP immediately if any command fails

# 1. Define variables
# Use SSH URL since you have keys set up
REPO_URL="git@github.com:lei/.dotfiles.git"
# Ensure we use the absolute path safely
BARE_DIR="$HOME/.dotfiles"

echo "--------------------------------------------------"
echo "Target: $BARE_DIR"
echo "Source: $REPO_URL"
echo "--------------------------------------------------"

if [ -d "$BARE_DIR" ]; then
  echo "Directory $BARE_DIR already exists."
  echo "Please remove it or back it up before running this script."
  exit 1
fi

echo "Cloning bare repository..."
git clone --bare $REPO_URL $BARE_DIR

# Define the alias/function for the current session
function config {
  /usr/bin/git --git-dir=$BARE_DIR --work-tree=$HOME "$@"
}

# Checkout and handle conflicts
echo "Attempting checkout..."
config checkout

if [ $? = 0 ]; then
  echo "Checked out dotfiles."
else
  echo "Backing up pre-existing dotfiles to ~/.dotfiles-backup"
  mkdir -p .dotfiles-backup

  # Move conflicting files
  config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}

  # Re-attempt checkout
  echo "Re-attempting checkout..."
  config checkout
fi

# Configuration (Hide untracked files)
config config --local status.showUntrackedFiles no

# AUTOMATIC SHELL CONFIGURATION (Fish, Zsh, Bash)
echo "--------------------------------------------------"
echo "Detecting shell to configure alias..."

# Detect the user's login shell
CURRENT_SHELL=$(basename "$SHELL")
ALIAS_CMD="alias config='/usr/bin/git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME'"

if [ "$CURRENT_SHELL" = "zsh" ]; then
  CONFIG_FILE="$HOME/.zshrc"
  echo "Zsh detected. Appending alias to $CONFIG_FILE"
  echo "" >>$CONFIG_FILE
  echo "# Dotfiles Bare Alias" >>$CONFIG_FILE
  echo "$ALIAS_CMD" >>$CONFIG_FILE

elif [ "$CURRENT_SHELL" = "bash" ]; then
  CONFIG_FILE="$HOME/.bashrc"
  # On Mac, might be .bash_profile, but .bashrc is standard for Linux
  if [ "$(uname)" == "Darwin" ]; then CONFIG_FILE="$HOME/.bash_profile"; fi

  echo "Bash detected. Appending alias to $CONFIG_FILE"
  echo "" >>$CONFIG_FILE
  echo "# Dotfiles Bare Alias" >>$CONFIG_FILE
  echo "$ALIAS_CMD" >>$CONFIG_FILE

elif [ "$CURRENT_SHELL" = "fish" ]; then
  # Fish handles aliases slightly differently
  CONFIG_DIR="$HOME/.config/fish"
  CONFIG_FILE="$CONFIG_DIR/config.fish"

  echo "Fish detected. Appending alias to $CONFIG_FILE"
  mkdir -p $CONFIG_DIR
  touch $CONFIG_FILE

  echo "" >>$CONFIG_FILE
  echo "# Dotfiles Bare Alias" >>$CONFIG_FILE
  # Fish syntax usually prefers space over =, but accepts = in newer versions.
  # We use double quotes to ensure variables are valid.
  echo "alias config \"/usr/bin/git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME\"" >>$CONFIG_FILE

else
  echo "Could not detect a supported shell (Found: $CURRENT_SHELL)."
  echo "Please manually add this alias to your config:"
  echo "$ALIAS_CMD"
fi

echo "--------------------------------------------------"
echo "Done! Please restart your terminal."
