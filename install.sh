#!/bin/bash
set -e

INSTALL_DIR="$HOME/.config/venvctl"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$INSTALL_DIR"
touch "$INSTALL_DIR/venvs.db"

cp venvctl.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/venvctl.sh"

mkdir -p "$BIN_DIR"
rm -f "$BIN_DIR/venvctl"  # Remove old link (or file) if any
ln -s "$INSTALL_DIR/venvctl.sh" "$BIN_DIR/venvctl"

echo
echo "venvctl installed successfully."
echo
echo "Make sure '$BIN_DIR' is in your PATH. If not, run"
echo "  \$ export PATH=\"\$HOME/.local/bin:\$PATH\""
echo
echo "You can now run: venvctl help"