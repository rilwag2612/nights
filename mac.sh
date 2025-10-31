#!/bin/zsh
set -e

TARGET="FNaF N.I.G.H.T.S."

echo "Cleaning previous build..."
make clean

echo "Building binary..."
make all

echo "Creating macOS ARM64 bundle..."
make macos-arm

echo "Creating macOS x86_64 bundle..."
make macos-intel
