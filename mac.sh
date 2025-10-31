#!/bin/zsh
set -e

TARGET="FNaF N.I.G.H.T.S."

echo "Cleaning previous build..."
make clean

echo "Building binary..."
make all

echo "Creating macOS bundle..."
make bundle

echo "Build complete!"

read -q "?Launch app bundle? [Y/n]: " REPLY
echo
# Treat empty input (Enter) as yes
if [[ -z "$REPLY" || "$REPLY" =~ [Yy] ]]; then
    "./bundle/$TARGET.app/Contents/MacOS/$TARGET"
fi
