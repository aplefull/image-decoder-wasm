#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/setup-emsdk.sh"

NATIVE_DIR="$PROJECT_ROOT/native/tiff"
WASM_DIR="$PROJECT_ROOT/wasm/tiff"
JPEG_DIR="$PROJECT_ROOT/native/jpeg"
WEBP_DIR="$PROJECT_ROOT/native/webp"

mkdir -p "$NATIVE_DIR"
mkdir -p "$WASM_DIR"

cd "$NATIVE_DIR"

echo "Building zlib..."
if [ ! -d "zlib" ]; then
  git clone --depth 1 --branch v1.3.1 https://github.com/madler/zlib.git
fi
if [ ! -f "zlib_install/lib/libz.a" ]; then
  mkdir -p zlib-build
  cd zlib-build
  emcmake cmake "$NATIVE_DIR/zlib" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$NATIVE_DIR/zlib_install"
  emmake make -j$(nproc)
  emmake make install
  cd "$NATIVE_DIR"
fi

echo "Building xz (LZMA)..."
if [ ! -d "xz" ]; then
  wget https://github.com/tukaani-project/xz/releases/download/v5.6.3/xz-5.6.3.tar.gz
  tar -xzf xz-5.6.3.tar.gz
  mv xz-5.6.3 xz
  rm xz-5.6.3.tar.gz
fi
if [ ! -f "xz_install/lib/liblzma.a" ]; then
  cd xz
  emconfigure ./configure --prefix="$NATIVE_DIR/xz_install" --enable-static --disable-shared --disable-nls
  emmake make -j$(nproc)
  emmake make install
  cd "$NATIVE_DIR"
fi

echo "Building zstd..."
if [ ! -d "zstd" ]; then
  git clone --depth 1 --branch v1.5.6 https://github.com/facebook/zstd.git
fi
if [ ! -f "zstd_install/lib/libzstd.a" ]; then
  mkdir -p zstd-build
  cd zstd-build
  emcmake cmake "$NATIVE_DIR/zstd/build/cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$NATIVE_DIR/zstd_install" \
    -DZSTD_BUILD_PROGRAMS=OFF \
    -DZSTD_BUILD_SHARED=OFF \
    -DZSTD_BUILD_STATIC=ON
  emmake make -j$(nproc)
  emmake make install
  cd "$NATIVE_DIR"
fi

echo "Building jbigkit..."
if [ ! -d "jbigkit" ]; then
  git clone --depth 1 https://github.com/zdenop/jbigkit.git
fi
if [ ! -f "jbig_install/lib/libjbig.a" ]; then
  cd jbigkit/libjbig
  emmake make -j$(nproc) CC=emcc AR=emar RANLIB=emranlib libjbig.a
  mkdir -p "$NATIVE_DIR/jbig_install/lib"
  mkdir -p "$NATIVE_DIR/jbig_install/include"
  cp libjbig.a "$NATIVE_DIR/jbig_install/lib/"
  cp jbig.h jbig_ar.h "$NATIVE_DIR/jbig_install/include/"
  cd "$NATIVE_DIR"
fi

if [ ! -d "libtiff" ]; then
  echo "Cloning libtiff..."
  git clone --depth 1 --branch v4.7.0 https://gitlab.com/libtiff/libtiff.git
fi

echo "Building libtiff..."
mkdir -p libtiff-build
cd libtiff-build

emcmake cmake "$NATIVE_DIR/libtiff" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$NATIVE_DIR/libtiff_install" \
  -DCMAKE_PREFIX_PATH="$NATIVE_DIR/zlib_install;$JPEG_DIR/libjpeg_install;$NATIVE_DIR/xz_install;$NATIVE_DIR/zstd_install;$WEBP_DIR/libwebp_install;$NATIVE_DIR/jbig_install" \
  -DBUILD_SHARED_LIBS=OFF \
  -Dtiff-tools=OFF \
  -Dtiff-tests=OFF \
  -Dtiff-contrib=OFF \
  -Dtiff-docs=OFF \
  -Dzlib=ON \
  -DZLIB_INCLUDE_DIR="$NATIVE_DIR/zlib_install/include" \
  -DZLIB_LIBRARY="$NATIVE_DIR/zlib_install/lib/libz.a" \
  -Dpixarlog=ON \
  -Djpeg=ON \
  -DJPEG_INCLUDE_DIR="$JPEG_DIR/libjpeg_install/include" \
  -DJPEG_LIBRARY="$JPEG_DIR/libjpeg_install/lib/libjpeg.a" \
  -Djbig=ON \
  -DJBIG_INCLUDE_DIR="$NATIVE_DIR/jbig_install/include" \
  -DJBIG_LIBRARY="$NATIVE_DIR/jbig_install/lib/libjbig.a" \
  -Dlerc=OFF \
  -Dlzma=ON \
  -DLIBLZMA_INCLUDE_DIR="$NATIVE_DIR/xz_install/include" \
  -DLIBLZMA_LIBRARY="$NATIVE_DIR/xz_install/lib/liblzma.a" \
  -Dzstd=ON \
  -DZSTD_INCLUDE_DIR="$NATIVE_DIR/zstd_install/include" \
  -DZSTD_LIBRARY="$NATIVE_DIR/zstd_install/lib/libzstd.a" \
  -Dwebp=ON \
  -DWEBP_INCLUDE_DIR="$WEBP_DIR/libwebp_install/include" \
  -DWEBP_LIBRARY="$WEBP_DIR/libwebp_install/lib/libwebp.a"

emmake make -j$(nproc)
emmake make install

cd "$NATIVE_DIR"

echo "Compiling WASM module..."
emcc \
  tiff_decoder.c \
  -I"$NATIVE_DIR/libtiff_install/include" \
  -I"$NATIVE_DIR/zlib_install/include" \
  -I"$JPEG_DIR/libjpeg_install/include" \
  -I"$NATIVE_DIR/xz_install/include" \
  -I"$NATIVE_DIR/zstd_install/include" \
  -I"$WEBP_DIR/libwebp_install/include" \
  -I"$NATIVE_DIR/jbig_install/include" \
  -L"$NATIVE_DIR/libtiff_install/lib" \
  -L"$NATIVE_DIR/zlib_install/lib" \
  -L"$JPEG_DIR/libjpeg_install/lib" \
  -L"$NATIVE_DIR/xz_install/lib" \
  -L"$NATIVE_DIR/zstd_install/lib" \
  -L"$WEBP_DIR/libwebp_install/lib" \
  -L"$NATIVE_DIR/jbig_install/lib" \
  -ltiff -lz -ljpeg -llzma -lzstd -lwebp -ljbig \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["HEAP8","HEAPU8","HEAP32"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=67108864 \
  -s MAXIMUM_MEMORY=536870912 \
  -s STACK_SIZE=5242880 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createTiffModule' \
  -s EXPORT_ES6=0 \
  -O3 \
  -o "$WASM_DIR/decoder.js"

echo "TIFF WASM module built at $WASM_DIR/decoder.wasm"
