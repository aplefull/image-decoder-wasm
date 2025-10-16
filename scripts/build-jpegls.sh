#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/setup-emsdk.sh"

NATIVE_DIR="$PROJECT_ROOT/native/jpegls"
WASM_DIR="$PROJECT_ROOT/wasm/jpegls"

mkdir -p "$NATIVE_DIR"
mkdir -p "$WASM_DIR"

cd "$NATIVE_DIR"

if [ ! -d "charls" ]; then
  echo "Cloning CharLS..."
  git clone --depth 1 --branch 2.4.2 https://github.com/team-charls/charls.git
fi

echo "Building CharLS..."
mkdir -p charls_build
cd charls_build

emcmake cmake "$NATIVE_DIR/charls" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$NATIVE_DIR/charls_install" \
  -DBUILD_SHARED_LIBS=OFF \
  -DCHARLS_BUILD_TESTS=OFF \
  -DCHARLS_BUILD_SAMPLES=OFF \
  -DCHARLS_INSTALL=ON

emmake make -j$(nproc)
emmake make install

cd "$NATIVE_DIR"

echo "Compiling WASM module..."
emcc \
  jpegls_decoder.c \
  -I"$NATIVE_DIR/charls_install/include" \
  -L"$NATIVE_DIR/charls_install/lib" \
  -lcharls \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["HEAP8","HEAPU8","HEAP32"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=67108864 \
  -s MAXIMUM_MEMORY=536870912 \
  -s STACK_SIZE=5242880 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createJpeglsModule' \
  -s EXPORT_ES6=0 \
  -O3 \
  -o "$WASM_DIR/decoder.js"

echo "JPEG-LS WASM module built at $WASM_DIR/decoder.wasm"
