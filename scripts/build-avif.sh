#!/bin/bash
set -e

EMSDK_PATH="${EMSDK_PATH:-$HOME/Repos/emsdk}"
NATIVE_DIR="$(pwd)/native/avif"
WASM_DIR="$(pwd)/wasm/avif"

if [ ! -d "$EMSDK_PATH" ]; then
  echo "Error: EMSDK not found at $EMSDK_PATH"
  exit 1
fi

source "$EMSDK_PATH/emsdk_env.sh"

mkdir -p "$NATIVE_DIR"
mkdir -p "$WASM_DIR"

cd "$NATIVE_DIR"

if [ ! -d "aom" ]; then
  echo "Cloning aom codec..."
  git clone --depth 1 https://aomedia.googlesource.com/aom
fi

if [ ! -d "libavif" ]; then
  echo "Cloning libavif..."
  git clone --depth 1 https://github.com/AOMediaCodec/libavif.git
fi

echo "Patching AOM for WebAssembly..."
if [ ! -f "$NATIVE_DIR/aom/aom_ports/x86.h.orig" ]; then
  cp "$NATIVE_DIR/aom/aom_ports/x86.h" "$NATIVE_DIR/aom/aom_ports/x86.h.orig"
  cat > "$NATIVE_DIR/aom/aom_ports/x86.h" << 'EOF'
#ifndef AOM_AOM_PORTS_X86_H_
#define AOM_AOM_PORTS_X86_H_

#include <stdlib.h>
#include "aom_ports/aom_once.h"
#include "config/aom_config.h"

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__EMSCRIPTEN__)

#define HAS_MMX 0
#define HAS_SSE 0
#define HAS_SSE2 0
#define HAS_SSE3 0
#define HAS_SSSE3 0
#define HAS_SSE4_1 0
#define HAS_SSE4_2 0
#define HAS_AVX 0
#define HAS_AVX2 0
#define HAS_AVX512 0

static inline int aom_get_cpu_flags(void) { return 0; }
static inline int x86_simd_caps(void) { return 0; }
static inline unsigned short x87_set_double_precision(void) { return 0; }
static inline void x87_set_control_word(unsigned short mode) { (void)mode; }

#else
#include "aom_ports/x86_abi_support.h"

typedef enum {
  AOM_CPU_FLAGS_MMX = 1 << 0,
  AOM_CPU_FLAGS_SSE = 1 << 1,
  AOM_CPU_FLAGS_SSE2 = 1 << 2,
  AOM_CPU_FLAGS_SSE3 = 1 << 3,
  AOM_CPU_FLAGS_SSSE3 = 1 << 4,
  AOM_CPU_FLAGS_SSE4_1 = 1 << 5,
  AOM_CPU_FLAGS_SSE4_2 = 1 << 6,
  AOM_CPU_FLAGS_AVX = 1 << 7,
  AOM_CPU_FLAGS_AVX2 = 1 << 8,
  AOM_CPU_FLAGS_AVX512 = 1 << 9,
} aom_cpu_flags;

#define HAS_MMX (1 << 0)
#define HAS_SSE (1 << 1)
#define HAS_SSE2 (1 << 2)
#define HAS_SSE3 (1 << 3)
#define HAS_SSSE3 (1 << 4)
#define HAS_SSE4_1 (1 << 5)
#define HAS_SSE4_2 (1 << 6)
#define HAS_AVX (1 << 7)
#define HAS_AVX2 (1 << 8)
#define HAS_AVX512 (1 << 9)

int aom_get_cpu_flags(void);
int x86_simd_caps(void);
#endif

#ifdef __cplusplus
}
#endif

#endif
EOF
fi

echo "Building AOM codec..."
mkdir -p "$NATIVE_DIR/aom_build"
cd "$NATIVE_DIR/aom_build"

emcmake cmake "$NATIVE_DIR/aom" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-O3 -msimd128" \
  -DCMAKE_CXX_FLAGS="-O3 -msimd128" \
  -DENABLE_TESTS=0 \
  -DENABLE_EXAMPLES=0 \
  -DENABLE_TOOLS=0 \
  -DENABLE_DOCS=0 \
  -DCONFIG_AV1_ENCODER=0 \
  -DCONFIG_AV1_DECODER=1 \
  -DCONFIG_RUNTIME_CPU_DETECT=0 \
  -DAOM_TARGET_CPU=generic \
  -DCONFIG_WEBM_IO=0 \
  -DBUILD_SHARED_LIBS=OFF

emmake make -j$(nproc)

echo "Building libavif..."
mkdir -p "$NATIVE_DIR/libavif_build"
cd "$NATIVE_DIR/libavif_build"

emcmake cmake "$NATIVE_DIR/libavif" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-O3 -msimd128" \
  -DCMAKE_CXX_FLAGS="-O3 -msimd128" \
  -DAVIF_CODEC_AOM=SYSTEM \
  -DAVIF_CODEC_AOM_DECODE=ON \
  -DAVIF_CODEC_AOM_ENCODE=OFF \
  -DAVIF_CODEC_DAV1D=OFF \
  -DAVIF_LIBYUV=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DAOM_INCLUDE_DIR="$NATIVE_DIR/aom" \
  -DAOM_LIBRARY="$NATIVE_DIR/aom_build/libaom.a"

emmake make -j$(nproc)

cd "$NATIVE_DIR"

echo "Creating WASM wrapper..."
emcc avif_decoder.c \
  -I"$NATIVE_DIR/libavif/include" \
  -I"$NATIVE_DIR/aom" \
  -L"$NATIVE_DIR/libavif_build" \
  -L"$NATIVE_DIR/aom_build" \
  -lavif \
  -laom \
  -msimd128 \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["HEAP8","HEAPU8","HEAP32"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=671088640 \
  -s MAXIMUM_MEMORY=2684354560 \
  -s STACK_SIZE=20971520 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createAvifModule' \
  -s EXPORT_ES6=0 \
  -O3 \
  -o "$WASM_DIR/decoder.js"

echo "AVIF WASM module built at $WASM_DIR/decoder.wasm"
