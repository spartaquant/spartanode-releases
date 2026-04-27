#!/usr/bin/env bash
# SpartaNode Desktop — Linux / macOS uninstaller
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/spartaquant/spartanode-releases/main/uninstall.sh | bash
#
# Options:
#   --purge   Also remove user data (database, settings)
#
set -euo pipefail

PURGE=false
for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=true ;;
    --help|-h) echo "Usage: uninstall.sh [--purge]"; exit 0 ;;
  esac
done

info() { echo "  [+] $*"; }
warn() { echo "  [!] $*" >&2; }

OS="$(uname -s)"

case "$OS" in
  Linux)
    INSTALL_DIR="$HOME/.local/share/SpartaNode"
    DESKTOP_FILE="$HOME/.local/share/applications/spartanode.desktop"
    DATA_DIR="$HOME/.config/spartanode-desktop"
    ;;
  Darwin)
    INSTALL_DIR="$HOME/Applications/SpartaNode.app"
    DESKTOP_FILE=""
    DATA_DIR="$HOME/Library/Application Support/spartanode-desktop"
    ;;
  *)
    echo "Unsupported OS: $OS"; exit 1 ;;
esac

if [ -d "$INSTALL_DIR" ]; then
  info "Removing $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR"
else
  warn "Installation not found at $INSTALL_DIR"
fi

# Remove any .bak directories from previous installs
for bak in "${INSTALL_DIR}.bak."*; do
  [ -d "$bak" ] && { info "Removing backup $bak..."; rm -rf "$bak"; }
done

if [ -n "$DESKTOP_FILE" ] && [ -f "$DESKTOP_FILE" ]; then
  info "Removing desktop entry..."
  rm -f "$DESKTOP_FILE"
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  fi
fi

if [ "$PURGE" = true ]; then
  if [ -d "$DATA_DIR" ]; then
    info "Purging user data at $DATA_DIR..."
    rm -rf "$DATA_DIR"
  fi
fi

echo ""
info "SpartaNode has been uninstalled."
if [ "$PURGE" = false ]; then
  info "User data preserved at $DATA_DIR (use --purge to remove)."
fi
