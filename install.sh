#!/usr/bin/env bash
set -e

# Remove git metadata
rm -rf .git

# Copy Vim config
cp -r .vim ~/
cp .vimrc ~/

# Add FZF defaults to bashrc (only once)
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'
elif command -v fdfind >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow'
fi

