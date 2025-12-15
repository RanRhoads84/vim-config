#!/usr/bin/env bash
set -euo pipefail

# ---------------- colors ----------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { printf "${BLUE}[*]${NC} %s\n" "$*"; }
ok()   { printf "${GREEN}[+]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$*"; }
err()  { printf "${RED}[x]${NC} %s\n" "$*" >&2; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  elif need_cmd sudo; then
    sudo "$@"
  else
    err "Root privileges required but sudo not available."
    exit 1
  fi
}

detect_pm() {
  if need_cmd apt-get; then echo apt
  elif need_cmd dnf; then echo dnf
  elif need_cmd yum; then echo yum
  elif need_cmd pacman; then echo pacman
  elif need_cmd zypper; then echo zypper
  elif need_cmd apk; then echo apk
  elif need_cmd brew; then echo brew
  else echo unknown
  fi
}

install_packages() {
  local pm="$1"

  log "Installing base packages: git vim ripgrep fzf fd"

  case "$pm" in
    apt)
      as_root apt-get update -y
      as_root apt-get install -y \
        git \
        vim \
        ripgrep \
        fzf \
        fd-find
      ok "Installed packages via apt"

      # Fix Debian stupidity: fdfind → fd
      if ! need_cmd fd && need_cmd fdfind; then
        if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
          ln -sf "$(command -v fdfind)" /usr/local/bin/fd
          ok "Created /usr/local/bin/fd -> fdfind"
        else
          mkdir -p "$HOME/.local/bin"
          ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
          export PATH="$HOME/.local/bin:$PATH"
          ok "Created ~/.local/bin/fd -> fdfind"
        fi
      fi
      ;;
    dnf|yum)
      as_root "$pm" install -y git vim ripgrep fzf fd
      ok "Installed packages via $pm"
      ;;
    pacman)
      as_root pacman -Syu --noconfirm git vim ripgrep fzf fd
      ok "Installed packages via pacman"
      ;;
    zypper)
      as_root zypper refresh
      as_root zypper install -y git vim ripgrep fzf fd
      ok "Installed packages via zypper"
      ;;
    apk)
      as_root apk update
      as_root apk add git vim ripgrep fzf fd
      ok "Installed packages via apk"
      ;;
    brew)
      brew update
      brew install git vim ripgrep fzf fd
      ok "Installed packages via brew"
      ;;
    *)
      err "Unsupported package manager."
      exit 1
      ;;
  esac
}

configure_fzf() {
  local line="export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow'"

  log "Configuring FZF_DEFAULT_COMMAND"

  if grep -qxF "$line" "$HOME/.bashrc" 2>/dev/null; then
    warn "FZF_DEFAULT_COMMAND already present"
  else
    echo "$line" >> "$HOME/.bashrc"
    ok "Added FZF_DEFAULT_COMMAND to ~/.bashrc"
  fi
}

main() {
  log "Starting dependency install"

  pm="$(detect_pm)"
  [[ "$pm" == "unknown" ]] && { err "Could not detect package manager"; exit 1; }
  ok "Detected package manager: $pm"

  install_packages "$pm"

  for cmd in git vim rg fzf fd; do
    need_cmd "$cmd" || { err "$cmd not found after install"; exit 1; }
    ok "$cmd available: $(command -v "$cmd")"
  done

  configure_fzf

  ok "All dependencies installed successfully"
}

main "$@"

