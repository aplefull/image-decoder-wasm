#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EMSDK_DIR="$PROJECT_ROOT/emsdk"

echo "Setting up Emscripten SDK..."

if [ ! -d "$EMSDK_DIR" ]; then
  echo "Cloning emsdk to $EMSDK_DIR..."
  git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$EMSDK_DIR"
fi

cd "$EMSDK_DIR"

if [ ! -f "$EMSDK_DIR/.emsdk_installed" ]; then
  echo "Installing latest Emscripten..."
  ./emsdk install latest
  ./emsdk activate latest
  touch "$EMSDK_DIR/.emsdk_installed"
else
  echo "Emscripten already installed (use latest)"
fi

source "$EMSDK_DIR/emsdk_env.sh"

echo "Emscripten SDK ready at $EMSDK_DIR"
