#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/setup-emsdk.sh"

NATIVE_DIR="$PROJECT_ROOT/native/jxr"
WASM_DIR="$PROJECT_ROOT/wasm/jxr"

mkdir -p "$NATIVE_DIR"
mkdir -p "$WASM_DIR"

cd "$NATIVE_DIR"

if [ ! -d "jxrlib" ]; then
  echo "Cloning jxrlib..."
  git clone --depth 1 https://github.com/glencoesoftware/jxrlib.git

  echo "Patching jxrlib for emscripten compatibility..."
  cd jxrlib

  sed -i 's/^#ifdef _WIN32/#if defined(_WIN32) \&\& !defined(__EMSCRIPTEN__)/' common/include/guiddef.h

  cat >> common/include/guiddef.h << 'EOF'

#ifdef __EMSCRIPTEN__
#ifndef INITGUID
#define DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
    extern const GUID name
#else
#define DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
    const GUID name = { l, w1, w2, { b1, b2, b3, b4, b5, b6, b7, b8 } }
#endif
#endif
EOF

  sed -i '1i#define INITGUID' jxrgluelib/JXRGlue.c

  cat > jxrgluelib/emscripten_compat.h << 'EOF'
#ifndef EMSCRIPTEN_COMPAT_H
#define EMSCRIPTEN_COMPAT_H

#ifdef __EMSCRIPTEN__
#include <wchar.h>
#include <string.h>

#ifndef strcpy_s
static inline int strcpy_s(char *dest, size_t destsz, const char *src) {
    if (!dest || !src || destsz == 0) return 1;
    size_t len = strlen(src);
    if (len >= destsz) return 1;
    strcpy(dest, src);
    return 0;
}
#endif

#endif
#endif
EOF

  sed -i '1i#include "emscripten_compat.h"' jxrgluelib/JXRGlueJxr.c

  cat >> image/sys/strcodec.h << 'EOF'

#if defined(__EMSCRIPTEN__) && !defined(_BIG__ENDIAN_)
U32 _byteswap_ulong(U32 bits);
#endif
EOF

  cd ..
fi

cd jxrlib

echo "Building jxrlib with emscripten..."
emmake make -j4 build/libjxrglue.a build/libjpegxr.a \
  CC=emcc AR=emar RANLIB=emranlib \
  CFLAGS="-O3 -I$NATIVE_DIR/jxrlib -I$NATIVE_DIR/jxrlib/common/include -I$NATIVE_DIR/jxrlib/image/sys -I$NATIVE_DIR/jxrlib/jxrgluelib -D__ANSI__ -DDISABLE_PERF_MEASUREMENT -Wno-incompatible-pointer-types -Wno-macro-redefined" \
  DIR_BUILD=build \
  SHARED=

cd "$NATIVE_DIR"

echo "Compiling WASM module..."
emcc \
  jxr_decoder.c \
  -I"$NATIVE_DIR/jxrlib" \
  -I"$NATIVE_DIR/jxrlib/common/include" \
  -I"$NATIVE_DIR/jxrlib/image/sys" \
  -I"$NATIVE_DIR/jxrlib/jxrgluelib" \
  "$NATIVE_DIR/jxrlib/build/libjxrglue.a" \
  "$NATIVE_DIR/jxrlib/build/libjpegxr.a" \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["HEAP8","HEAPU8","HEAP32"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=67108864 \
  -s MAXIMUM_MEMORY=268435456 \
  -s STACK_SIZE=5242880 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createJxrModule' \
  -s EXPORT_ES6=0 \
  -O3 \
  -o "$WASM_DIR/decoder.js"

echo "JXR WASM module built at $WASM_DIR/decoder.wasm"
