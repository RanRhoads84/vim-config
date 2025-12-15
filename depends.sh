#!/usr/bin/env bash
set -euo pipefail

VERBOSE=1

# --- colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { [[ "$VERBOSE" -eq 1 ]] && printf "${BLUE}[*]${NC} %s\n" "$*"; }
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
    err "Need root privileges but sudo isn't available."
    exit 1
  fi
}

detect_pm() {
  if need_cmd apt-get; then echo "apt"
  elif need_cmd dnf; then echo "dnf"
  elif need_cmd yum; then echo "yum"
  elif need_cmd pacman; then echo "pacman"
  elif need_cmd zypper; then echo "zypper"
  elif need_cmd apk; then echo "apk"
  elif need_cmd brew; then echo "brew"
  else echo "unknown"
  fi
}

install_fd() {
  local pm="$1"

  # If fd already exists, we're done.
  if need_cmd fd; then
    ok "fd already installed: $(command -v fd)"
    return 0
  fi

  log "Installing fd (package manager: $pm)"

  case "$pm" in
    apt)
      # Debian/Ubuntu package name is fd-find, command is usually fdfind.
      as_root apt-get update -y
      as_root apt-get install -y fd-find
      ok "Installed fd-find (apt)"

        # If Debian-style command exists but fd doesn't, make fd available.
  if ! need_cmd fd && need_cmd fdfind; then
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
      # Running as root: create a system-wide alias so everyone gets 'fd'
      log "Running as root: creating system-wide symlink /usr/local/bin/fd -> $(command -v fdfind)"
      ln -sf "$(command -v fdfind)" /usr/local/bin/fd
      ok "Symlinked /usr/local/bin/fd -> $(command -v fdfind)"
    else
      # Non-root: user-local symlink
      log "Creating user-local symlink so 'fd' works (fdfind -> fd)"
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
      ok "Symlinked $HOME/.local/bin/fd -> $(command -v fdfind)"

      # Make it work immediately in this script run
      export PATH="$HOME/.local/bin:$PATH"
    fi
  fi
      ;;
    dnf)
      as_root dnf install -y fd-find fd || as_root dnf install -y fd
      ok "Installed fd (dnf)"
      ;;
    yum)
      as_root yum install -y fd-find fd || as_root yum install -y fd
      ok "Installed fd (yum)"
      ;;
    pacman)
      as_root pacman -Syu --noconfirm
      as_root pacman -S --noconfirm fd
      ok "Installed fd (pacman)"
      ;;
    zypper)
      as_root zypper refresh
      as_root zypper install -y fd
      ok "Installed fd (zypper)"
      ;;
    apk)
      as_root apk update
      as_root apk add fd
      ok "Installed fd (apk)"
      ;;
    brew)
      brew update
      brew install fd
      ok "Installed fd (brew)"
      ;;
    *)
      err "Unsupported/unknown package manager. Install 'fd' manually."
      exit 1
      ;;
  esac

  # Final sanity check
  if need_cmd fd; then
    ok "fd is available: $(command -v fd)"
  else
    err "fd still not found after install. Something is off."
    exit 1
  fi
}

set_fzf_default_command() {
  local cmd="fd --type f --hidden --follow"

  log "Configuring FZF_DEFAULT_COMMAND in ~/.bashrc"
  local line="export FZF_DEFAULT_COMMAND='$cmd'"

  if grep -qxF "$line" "$HOME/.bashrc" 2>/dev/null; then
    warn "FZF_DEFAULT_COMMAND already present in ~/.bashrc"
  else
    echo "$line" >> "$HOME/.bashrc"
    ok "Added FZF_DEFAULT_COMMAND to ~/.bashrc"
  fi
}

main() {
  log "Starting setup"

  local pm
  pm="$(detect_pm)"
  if [[ "$pm" == "unknown" ]]; then
    err "Could not detect package manager."
    exit 1
  fi
  ok "Detected package manager: $pm"

  install_fd "$pm"
  set_fzf_default_command

  ok "Done"
}

main "$@"

