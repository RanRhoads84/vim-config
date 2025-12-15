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

ok "Setup complete"
