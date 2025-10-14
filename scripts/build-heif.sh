#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/setup-emsdk.sh"

NATIVE_DIR="$PROJECT_ROOT/native/heif"
WASM_DIR="$PROJECT_ROOT/wasm/heif"

mkdir -p "$NATIVE_DIR"
mkdir -p "$WASM_DIR"

cd "$NATIVE_DIR"

if [ ! -d "libheif" ]; then
  echo "Cloning libheif..."
  git clone --depth 1 https://github.com/strukturag/libheif.git
fi

if [ ! -d "libde265" ]; then
  echo "Cloning libde265 (HEVC decoder)..."
  git clone --depth 1 https://github.com/strukturag/libde265.git
fi

echo "Building libde265..."
mkdir -p libde265_build
cd libde265_build

emcmake cmake ../libde265 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-O3 -msimd128" \
  -DCMAKE_CXX_FLAGS="-O3 -msimd128" \
  -DENABLE_SDL=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX="$NATIVE_DIR/libde265_install"

emmake make -j$(nproc)
emmake make install

cd "$NATIVE_DIR"

echo "Building libheif..."
mkdir -p libheif_build
cd libheif_build

emcmake cmake ../libheif \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-O3 -msimd128 -D__EMSCRIPTEN_STANDALONE_WASM__" \
  -DCMAKE_CXX_FLAGS="-O3 -msimd128 -D__EMSCRIPTEN_STANDALONE_WASM__" \
  -DWITH_LIBDE265=ON \
  -DWITH_X265=OFF \
  -DWITH_AOM_DECODER=ON \
  -DWITH_AOM_ENCODER=OFF \
  -DWITH_EXAMPLES=OFF \
  -DWITH_EMSCRIPTEN=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DLIBDE265_INCLUDE_DIR="$NATIVE_DIR/libde265_install/include" \
  -DLIBDE265_LIBRARY="$NATIVE_DIR/libde265_install/lib/libde265.a" \
  -DAOM_INCLUDE_DIR="$PROJECT_ROOT/native/avif/aom" \
  -DAOM_LIBRARY="$PROJECT_ROOT/native/avif/aom_build/libaom.a"

emmake make -j$(nproc)

mkdir -p "$NATIVE_DIR/libheif_build/libheif/libheif"
cp "$NATIVE_DIR/libheif_build/libheif/heif_version.h" "$NATIVE_DIR/libheif_build/libheif/libheif/"

cd "$NATIVE_DIR"

echo "Compiling WASM module..."
emcc \
  heif_decoder.c \
  -I"$NATIVE_DIR/libde265_install/include" \
  -I"$NATIVE_DIR/libheif/libheif/api" \
  -I"$NATIVE_DIR/libheif_build/libheif" \
  -L"$NATIVE_DIR/libheif_build/libheif" \
  -L"$NATIVE_DIR/libde265_install/lib" \
  -L"$PROJECT_ROOT/native/avif/aom_build" \
  -lheif \
  -lde265 \
  -laom \
  -msimd128 \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["HEAP8","HEAPU8","HEAP32"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=67108864 \
  -s MAXIMUM_MEMORY=268435456 \
  -s STACK_SIZE=5242880 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createHeifModule' \
  -s EXPORT_ES6=0 \
  -O3 \
  -o "$WASM_DIR/decoder.js"

echo "HEIF WASM module built at $WASM_DIR/decoder.wasm"
