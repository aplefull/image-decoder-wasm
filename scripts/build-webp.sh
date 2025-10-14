#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/setup-emsdk.sh"

NATIVE_DIR="$PROJECT_ROOT/native/webp"
WASM_DIR="$PROJECT_ROOT/wasm/webp"

mkdir -p "$NATIVE_DIR"
mkdir -p "$WASM_DIR"

cd "$NATIVE_DIR"

if [ ! -d "libwebp" ]; then
  echo "Cloning libwebp..."
  git clone --depth 1 https://github.com/webmproject/libwebp.git
fi

echo "Building libwebp..."
mkdir -p libwebp_build
cd libwebp_build

emcmake cmake ../libwebp \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-O3 -msimd128" \
  -DCMAKE_CXX_FLAGS="-O3 -msimd128" \
  -DWEBP_BUILD_ANIM_UTILS=OFF \
  -DWEBP_BUILD_CWEBP=OFF \
  -DWEBP_BUILD_DWEBP=OFF \
  -DWEBP_BUILD_GIF2WEBP=OFF \
  -DWEBP_BUILD_IMG2WEBP=OFF \
  -DWEBP_BUILD_VWEBP=OFF \
  -DWEBP_BUILD_WEBPINFO=OFF \
  -DWEBP_BUILD_WEBPMUX=OFF \
  -DWEBP_BUILD_EXTRAS=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX="$NATIVE_DIR/libwebp_install"

emmake make -j$(nproc)
emmake make install

cd "$NATIVE_DIR"

echo "Compiling WASM module..."
emcc \
  webp_decoder.c \
  -I"$NATIVE_DIR/libwebp_install/include" \
  -L"$NATIVE_DIR/libwebp_install/lib" \
  -lwebp \
  -msimd128 \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["HEAP8","HEAPU8","HEAP32"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=67108864 \
  -s MAXIMUM_MEMORY=268435456 \
  -s STACK_SIZE=5242880 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createWebpModule' \
  -s EXPORT_ES6=0 \
  -O3 \
  -o "$WASM_DIR/decoder.js"

echo "WebP WASM module built at $WASM_DIR/decoder.wasm"
