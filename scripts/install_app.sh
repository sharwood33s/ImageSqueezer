#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILT_APP="$ROOT_DIR/dist/ImageSqueezer.app"
INSTALL_APP="/Applications/ImageSqueezer.app"

cd "$ROOT_DIR"
"$ROOT_DIR/scripts/build_app.sh"

if pgrep -x ImageSqueezer >/dev/null; then
  osascript -e 'tell application "ImageSqueezer" to quit' || true
  sleep 1
fi

rm -rf "$INSTALL_APP"
cp -R "$BUILT_APP" "$INSTALL_APP"
open "$INSTALL_APP"

echo "Installed $INSTALL_APP"
