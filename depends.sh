#!/usr/bin/env bash

set -euo pipefail

# ====== CONFIG: put your desired packages here ======
PACKAGES_DEFAULT=(
  git
  vim
  ripgrep
  fzf
  fdfind
)

# Optional: set to 1 to do a "dry run"
DRY_RUN="${DRY_RUN:-0}"

# ====== helpers ======
log() { printf '%s\n' "$*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    log "[dry-run] $*"
  else
    eval "$@"
  fi
}

as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    if need_cmd sudo; then
      sudo "$@"
    else
      log "ERROR: sudo not found and not running as root."
      exit 1
    fi
  fi
}

detect_pm() {
  # Order matters a bit (some systems have multiple)
  if need_cmd apt-get; then echo "apt"
  elif need_cmd dnf; then echo "dnf"
  elif need_cmd yum; then echo "yum"
  elif need_cmd pacman; then echo "pacman"
  elif need_cmd zypper; then echo "zypper"
  elif need_cmd apk; then echo "apk"
  elif need_cmd brew; then echo "brew"
  else
    echo "unknown"
  fi
}

pkg_installed() {
  # best-effort checks per PM; if unsupported, return 1 (not installed) to attempt install
  local pm="$1" pkg="$2"
  case "$pm" in
    apt)    dpkg -s "$pkg" >/dev/null 2>&1 ;;
    dnf|yum) rpm -q "$pkg" >/dev/null 2>&1 ;;
    pacman) pacman -Qi "$pkg" >/dev/null 2>&1 ;;
    zypper) rpm -q "$pkg" >/dev/null 2>&1 ;;
    *)      return 1 ;;
  esac
}

install_packages() {
  local pm="$1"; shift
  local -a pkgs=("$@")

  case "$pm" in
    apt)
      as_root bash -c "apt-get update -y"
      as_root bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y ${pkgs[*]}"
      ;;
    dnf)
      as_root dnf install -y "${pkgs[@]}"
      ;;
    yum)
      as_root yum install -y "${pkgs[@]}"
      ;;
    pacman)
      as_root pacman -Syu --noconfirm
      as_root pacman -S --noconfirm "${pkgs[@]}"
      ;;
    zypper)
      as_root zypper refresh
      as_root zypper install -y "${pkgs[@]}"
      ;;
    *)
      log "ERROR: Unsupported/unknown package manager."
      exit 1
      ;;
  esac
}

# Help Section
usage() {
  cat <<'EOF'
Usage:
  bootstrap.sh [packages...]

Examples:
  ./bootstrap.sh            # installs defaults in PACKAGES_DEFAULT
  ./bootstrap.sh ripgrep fd # installs exactly what you pass

Env:
  DRY_RUN=1                 # prints commands instead of executing
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  local -a requested=()
  if [[ "$#" -gt 0 ]]; then
    requested=("$@")
  else
    requested=("${PACKAGES_DEFAULT[@]}")
  fi

  if [[ "${#requested[@]}" -eq 0 ]]; then
    log "No packages provided and default list is empty."
    exit 0
  fi

  local pm
  pm="$(detect_pm)"
  if [[ "$pm" == "unknown" ]]; then
    log "ERROR: Could not detect a supported package manager (apt/dnf/yum/pacman/zypper/apk/brew)."
    exit 1
  fi
  log "Detected package manager: $pm"

  local -a to_install=()
  for p in "${requested[@]}"; do
    if pkg_installed "$pm" "$p"; then
      log "Already installed: $p"
    else
      to_install+=("$p")
    fi
  done

  if [[ "${#to_install[@]}" -eq 0 ]]; then
    log "All requested packages already installed."
    exit 0
  fi

  log "Installing: ${to_install[*]}"
  install_packages "$pm" "${to_install[@]}"
  log "Done."
}

main "$@"

