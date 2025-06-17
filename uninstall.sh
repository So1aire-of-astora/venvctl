#!/bin/bash
set -e

# =============================================================
# venvctl uninstall script
# =============================================================

INSTALL_DIR="$HOME/.config/venvctl"
BIN_DIR="$HOME/.local/bin"

# Confirm before uninstalling
read -r -p "Are you sure you want to uninstall venvctl? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "venvctl: Aborted."
    exit 1
fi

# Remove registry/config directory
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    # echo "Removed config directory: $INSTALL_DIR"
else
    echo "Config directory not found: $INSTALL_DIR"
fi

# Remove symlink or binary
if [ -L "$BIN_DIR/venvctl" ] || [ -f "$BIN_DIR/venvctl" ]; then
    rm -f "$BIN_DIR/venvctl"
    # echo "Removed executable: $BIN_DIR/venvctl"
else
    echo "Executable not found: $BIN_DIR/venvctl"
fi

echo "venvctl uninstalled successfully."
