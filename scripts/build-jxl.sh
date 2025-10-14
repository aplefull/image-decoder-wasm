#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/setup-emsdk.sh"

NATIVE_DIR="$PROJECT_ROOT/native/jxl"
WASM_DIR="$PROJECT_ROOT/wasm/jxl"

mkdir -p "$NATIVE_DIR"
mkdir -p "$WASM_DIR"

cd "$NATIVE_DIR"

if [ ! -d "libjxl" ]; then
  echo "Cloning libjxl..."
  git clone --depth 1 https://github.com/libjxl/libjxl.git
  cd libjxl
  git submodule update --init --recursive --depth 1
  cd ..
  
  echo "Patching Highway aligned_allocator to avoid compiler crash..."
  cat > libjxl/third_party/highway/hwy/aligned_allocator.cc << 'EOF'
#include "hwy/aligned_allocator.h"
#include <stdlib.h>

namespace hwy {

void* AllocateAlignedBytes(const size_t payload_size,
                           AllocPtr alloc_ptr, void* opaque_ptr) {
  (void)alloc_ptr;
  (void)opaque_ptr;
  return malloc(payload_size);
}

void FreeAlignedBytes(const void* aligned_pointer, FreePtr free_ptr,
                      void* opaque_ptr) {
  (void)free_ptr;
  (void)opaque_ptr;
  free(const_cast<void*>(aligned_pointer));
}

}  // namespace hwy
EOF
fi

echo "Building libjxl..."
mkdir -p libjxl_build
cd libjxl_build

emcmake cmake ../libjxl \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-O3 -msimd128" \
  -DCMAKE_CXX_FLAGS="-O3 -fno-exceptions -msimd128" \
  -DBUILD_TESTING=OFF \
  -DJPEGXL_ENABLE_TOOLS=OFF \
  -DJPEGXL_ENABLE_MANPAGES=OFF \
  -DJPEGXL_ENABLE_BENCHMARK=OFF \
  -DJPEGXL_ENABLE_EXAMPLES=OFF \
  -DJPEGXL_ENABLE_JNI=OFF \
  -DJPEGXL_ENABLE_SJPEG=OFF \
  -DJPEGXL_ENABLE_OPENEXR=ON \
  -DJPEGXL_ENABLE_SKCMS=ON \
  -DJPEGXL_BUNDLE_LIBPNG=OFF \
  -DJPEGXL_ENABLE_TCMALLOC=OFF \
  -DJPEGXL_ENABLE_VIEWERS=OFF \
  -DJPEGXL_FORCE_SYSTEM_HWY=OFF \
  -DJPEGXL_ENABLE_TRANSCODE_JPEG=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_INSTALL_PREFIX="$NATIVE_DIR/libjxl_install"

emmake make -j$(nproc)
emmake make install

cd "$NATIVE_DIR"

echo "Compiling WASM module..."
emcc \
  jxl_decoder.c \
  -I"$NATIVE_DIR/libjxl_install/include" \
  -L"$NATIVE_DIR/libjxl_install/lib" \
  -L"$NATIVE_DIR/libjxl_build/third_party/highway" \
  -L"$NATIVE_DIR/libjxl_build/third_party/brotli" \
  -ljxl \
  -msimd128 \
  -ljxl_threads \
  -lhwy \
  -lbrotlidec \
  -lbrotlicommon \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["HEAP8","HEAPU8","HEAP32"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=67108864 \
  -s MAXIMUM_MEMORY=536870912 \
  -s STACK_SIZE=5242880 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createJxlModule' \
  -s EXPORT_ES6=0 \
  -s ALLOW_UNIMPLEMENTED_SYSCALLS=1 \
  -O3 \
  -o "$WASM_DIR/decoder.js"

echo "JXL WASM module built at $WASM_DIR/decoder.wasm"
