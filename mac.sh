#!/bin/zsh
set -e

TARGET="Nights"

echo "Cleaning previous build..."
make clean

echo "Building binary..."
make all

echo "Creating macOS ARM64 bundle..."
make macos-arm

echo "Renaming bundle to $TARGET-arm64.app"
mv bundle/$TARGET.app bundle/$TARGET-arm64.app

echo "Creating macOS x86_64 bundle..."
make macos-intel

echo "Renaming bundle to $TARGET-x86_64.app"
mv bundle/$TARGET.app bundle/$TARGET-x86_64.app

echo "Creating universal bundle..."
make macos-fat

echo "Renaming bundle to $TARGET-universal.app"
mv bundle/$TARGET.app bundle/$TARGET-universal.app

echo "All bundles built successfully."
