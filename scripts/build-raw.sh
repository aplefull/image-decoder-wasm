#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/setup-emsdk.sh"

NATIVE_DIR="$PROJECT_ROOT/native/raw"
WASM_DIR="$PROJECT_ROOT/wasm/raw"

mkdir -p "$NATIVE_DIR"
mkdir -p "$WASM_DIR"

cd "$NATIVE_DIR"

if [ ! -d "LibRaw" ]; then
  echo "Cloning LibRaw..."
  git clone --depth 1 https://github.com/LibRaw/LibRaw.git
fi

echo "Building LibRaw..."
if [ ! -f "libraw_install/lib/libraw.a" ]; then
  cd LibRaw

  if [ ! -f "configure" ]; then
    autoreconf -fi
  fi

  CFLAGS="-DUSE_X3FTOOLS -DUSE_6BY9RPI" \
  CXXFLAGS="-DUSE_X3FTOOLS -DUSE_6BY9RPI" \
  emconfigure ./configure \
    --prefix="$NATIVE_DIR/libraw_install" \
    --enable-static \
    --disable-shared \
    --disable-examples \
    --disable-jasper \
    --disable-lcms \
    --disable-demosaic-pack-gpl2 \
    --disable-demosaic-pack-gpl3

  emmake make -j$(nproc) CFLAGS="-DUSE_X3FTOOLS -DUSE_6BY9RPI" CXXFLAGS="-DUSE_X3FTOOLS -DUSE_6BY9RPI"
  emmake make install
  cd "$NATIVE_DIR"
fi

echo "Compiling WASM module..."
emcc \
  raw_decoder.c \
  -I"$NATIVE_DIR/libraw_install/include" \
  -L"$NATIVE_DIR/libraw_install/lib" \
  -lraw \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_can_decode","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["HEAP8","HEAPU8","HEAP32"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=134217728 \
  -s MAXIMUM_MEMORY=1073741824 \
  -s STACK_SIZE=5242880 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createRawModule' \
  -s EXPORT_ES6=0 \
  -O3 \
  -o "$WASM_DIR/decoder.js"

echo "RAW WASM module built at $WASM_DIR/decoder.wasm"
