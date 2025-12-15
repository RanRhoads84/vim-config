#!/usr/bin/env bash
set -euo pipefail

VERBOSE=1

# --- colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # no color

log() {
  [[ "$VERBOSE" -eq 1 ]] && printf "${BLUE}[*]${NC} %s\n" "$*"
}

ok() {
  printf "${GREEN}[+]${NC} %s\n" "$*"
}

warn() {
  printf "${YELLOW}[!]${NC} %s\n" "$*"
}

err() {
  printf "${RED}[x]${NC} %s\n" "$*" >&2
}

log "Starting Vim environment setup"

# --- Remove git metadata ---
if [[ -d .git ]]; then
  log "Removing .git directory"
  rm -rf .git
  ok ".git directory removed"
else
  warn ".git directory not found, skipping"
fi

# --- Copy Vim config ---
if [[ -d .vim ]]; then
  log "Copying .vim directory to home"
  cp -rv .vim ~/
  ok ".vim directory copied"
else
  warn ".vim directory not found, skipping"
fi

if [[ -f .vimrc ]]; then
  log "Copying .vimrc to home"
  cp -v .vimrc ~/
  ok ".vimrc copied"
else
  warn ".vimrc not found, skipping"
fi

# --- Configure FZF default command ---
log "Configuring FZF_DEFAULT_COMMAND"

if command -v fd >/dev/null 2>&1; then
  FZF_CMD="fd --type f --hidden --follow"
  ok "Detected fd"
elif command -v fdfind >/dev/null 2>&1; then
  FZF_CMD="fdfind --type f --hidden --follow"
  ok "Detected fdfind"
else
  warn "Neither fd nor fdfind found; skipping FZF configuration"
  exit 0
fi

LINE="export FZF_DEFAULT_COMMAND='$FZF_CMD'"

if grep -qxF "$LINE" ~/.bashrc; then
  warn "FZF_DEFAULT_COMMAND already present in ~/.bashrc"
else
  log "Appending FZF_DEFAULT_COMMAND to ~/.bashrc"
  echo "$LINE" >> ~/.bashrc
  ok "FZF_DEFAULT_COMMAND added to ~/.bashrc"
fi

ok "Setup complete"

