#!/usr/bin/env bash
# Cambric Game — Linux install helper
# Usage: bash install_linux.sh [source_dir] [dest_dir]
#
# Copies the Linux release bundle and creates a .desktop launcher.
# Run after: dart run scripts/cambric.dart build linux  (requires Linux host or CI)

set -euo pipefail

SOURCE="${1:-build/linux/x64/release/bundle}"
DEST="${2:-$HOME/.local/share/cambric-game}"
DESKTOP_DIR="$HOME/.local/share/applications"
APP_NAME="Cambric Game"
EXEC_NAME="cambric_game"

if [ ! -d "$SOURCE" ]; then
  echo "Source not found: $SOURCE"
  echo "Run 'flutter build linux --release' first."
  exit 1
fi

echo "Installing to $DEST ..."
mkdir -p "$DEST"
cp -r "$SOURCE"/. "$DEST/"
chmod +x "$DEST/$EXEC_NAME" 2>/dev/null || true

# Create .desktop entry
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/cambric-game.desktop" <<EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$DEST/$EXEC_NAME
Type=Application
Categories=Game;
Comment=Cambric Game
EOF

echo "Installed to $DEST"
echo "Launcher created: $DESKTOP_DIR/cambric-game.desktop"
