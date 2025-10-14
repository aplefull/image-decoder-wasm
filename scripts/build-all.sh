#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "Building all WASM decoders..."
echo ""

BUILD_SCRIPTS=()
for script in "$SCRIPT_DIR"/build-*.sh; do
  if [ -f "$script" ] && [ "$script" != "$SCRIPT_DIR/build-all.sh" ]; then
    BUILD_SCRIPTS+=("$script")
  fi
done

if [ ${#BUILD_SCRIPTS[@]} -eq 0 ]; then
  echo "No build scripts found in $SCRIPT_DIR"
  exit 1
fi

for script in "${BUILD_SCRIPTS[@]}"; do
  script_name=$(basename "$script")
  echo "Running $script_name..."
  bash "$script"
  echo ""
done

echo "All ${#BUILD_SCRIPTS[@]} decoders built successfully!"
