#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/setup-emsdk.sh"

NATIVE_DIR="$PROJECT_ROOT/native/jpeg"
WASM_DIR="$PROJECT_ROOT/wasm/jpeg"

mkdir -p "$NATIVE_DIR"
mkdir -p "$WASM_DIR"

cd "$NATIVE_DIR"

if [ ! -d "libjpeg-turbo" ]; then
  echo "Cloning libjpeg-turbo..."
  git clone --depth 1 --branch 3.0.4 https://github.com/libjpeg-turbo/libjpeg-turbo.git
fi

echo "Building libjpeg-turbo..."
mkdir -p libjpeg-turbo-build
cd libjpeg-turbo-build

emcmake cmake "$NATIVE_DIR/libjpeg-turbo" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$NATIVE_DIR/libjpeg_install" \
  -DENABLE_SHARED=OFF \
  -DENABLE_STATIC=ON \
  -DWITH_TURBOJPEG=ON \
  -DWITH_JPEG8=ON \
  -DWITH_SIMD=OFF

emmake make -j$(nproc)
emmake make install

cd "$NATIVE_DIR"

echo "Compiling WASM module..."
emcc \
  jpeg_decoder.c \
  -I"$NATIVE_DIR/libjpeg_install/include" \
  -L"$NATIVE_DIR/libjpeg_install/lib" \
  -ljpeg \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["HEAP8","HEAPU8","HEAP32"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=67108864 \
  -s MAXIMUM_MEMORY=536870912 \
  -s STACK_SIZE=5242880 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createJpegModule' \
  -s EXPORT_ES6=0 \
  -O3 \
  -o "$WASM_DIR/decoder.js"

echo "JPEG WASM module built at $WASM_DIR/decoder.wasm"
