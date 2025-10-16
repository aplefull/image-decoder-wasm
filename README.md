# Image Decoder WASM

A browser-based image decoder library using WebAssembly to support image formats not natively supported by browsers.

## Supported Formats

| Format | Extension | Description |
|--------|-----------|-------------|
| **AVIF** | `.avif` | AV1 Image File Format |
| **HEIF/HEIC** | `.heif`, `.heic` | High Efficiency Image Format |
| **WebP** | `.webp` | Google's WebP format |
| **JXL** | `.jxl` | JPEG XL |
| **JPEG** | `.jpg`, `.jpeg` | Standard JPEG with all features |
| **JPEG-LS** | `.jls` | Lossless/Near-lossless JPEG |
| **TIFF** | `.tif`, `.tiff` | Tagged Image File Format (with all compression codecs) |
| **RAW** | `.cr2`, `.nef`, `.arw`, `.dng`, etc. |  Camera RAW formats |

## Installation

```bash
npm i image-decoder-wasm
```

or

```bash
pnpm add image-decoder-wasm
```

## Usage

### Basic Example

```typescript
import { imageDecoder } from 'image-decoder-wasm';

const response = await fetch('image.avif');
const buffer = await response.arrayBuffer();
const imageData = await imageDecoder.decode(buffer);
```

### Detect Format

```typescript
import { imageDecoder } from 'image-decoder-wasm';

const format = imageDecoder.detectFormat(buffer);
console.log(`Detected format: ${format}`);
```

### Get Supported Formats

```typescript
import { imageDecoder } from 'image-decoder-wasm';

const formats = imageDecoder.getSupportedFormats();
console.log(formats);
```

### Using Specific Decoders

```typescript
import { AvifDecoder } from 'image-decoder-wasm';

const decoder = new AvifDecoder();
await decoder.initialize();

if (decoder.canDecode(buffer)) {
  const decoded = await decoder.decode(buffer);
}
```

## Development

### Prerequisites

- Node.js 22+
- [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html) (for building WASM modules)

### Setup

```bash
# Install dependencies
pnpm install
```

### Build

```bash
# Build TypeScript library with Vite
pnpm run build

# Build all WASM decoders
pnpm run build:wasm

# Build specific decoder (Note that some formats depend on each other)
pnpm run build:wasm:avif
pnpm run build:wasm:heif
pnpm run build:wasm:webp
pnpm run build:wasm:jxl
pnpm run build:wasm:jpeg
pnpm run build:wasm:jpegls
pnpm run build:wasm:tiff
pnpm run build:wasm:raw
```

### Development Server

```bash
pnpm run dev
```

### Testing

```bash
pnpm test
```

## Adding a New Decoder

### 1. Create Native Decoder

Create `native/FORMAT/format_decoder.c`:

```c
#include <emscripten.h>

EMSCRIPTEN_KEEPALIVE
uint8_t* alloc(size_t size) {
    return (uint8_t*)malloc(size);
}

EMSCRIPTEN_KEEPALIVE
void free_mem(uint8_t* ptr) {
    if (ptr) free(ptr);
}

EMSCRIPTEN_KEEPALIVE
int decode(uint8_t* input, size_t inputSize, uint8_t* outPtr) {
    // Decode logic here
    // Write to outPtr: [width, height, dataPtr, dataSize]
    return 0; // 0 = success
}
```

### 2. Create Build Script

Create `scripts/build-FORMAT.sh`:

```bash
#!/bin/bash
set -e

source "$EMSDK_PATH/emsdk_env.sh"
cd native/FORMAT

emcc format_decoder.c \
  -s WASM=1 \
  -s EXPORTED_FUNCTIONS='["_alloc","_free_mem","_decode"]' \
  -s EXPORTED_RUNTIME_METHODS='["cwrap","ccall","HEAPU8"]' \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createFormatModule' \
  -O3 \
  -o "../../wasm/FORMAT/decoder.js"
```

### 3. Create TypeScript Decoder

Create `src/decoders/format-decoder.ts`:

```typescript
import { BaseDecoder } from './base-decoder';
import { detectImageFormat } from '../utils/image-utils';

export class FormatDecoder extends BaseDecoder {
  readonly format = 'format';
  readonly wasmJsPath = '/wasm/format/decoder.js';

  canDecode(buffer: ArrayBuffer): boolean {
    return detectImageFormat(buffer) === 'format';
  }
}
```

### 4. Register Decoder

In `src/decoder-registry.ts`:

```typescript
import { FormatDecoder } from './decoders/format-decoder';

private registerDefaultDecoders(): void {
  this.register(new FormatDecoder());
  // ... other decoders
}
```

### 5. Add Format Detection

In `src/utils/image-utils.ts`:

```typescript
if (view[0] === 0xXX && view[1] === 0xYY) {
  return 'format';
}
```

## Acknowledgments

This library uses the following open-source projects:

- [libaom](https://aomedia.googlesource.com/aom/) - AV1 codec
- [libavif](https://github.com/AOMedia/avif) - AV1 Image File Format
- [libde265](https://github.com/strukturag/libde265) - H.265 decoder
- [libheif](https://github.com/strukturag/libheif) - HEIF/HEIC decoder
- [libwebp](https://chromium.googlesource.com/webm/libwebp) - WebP decoder
- [libjxl](https://github.com/libjxl/libjxl) - JPEG XL reference implementation
- [libjpeg-turbo](https://libjpeg-turbo.org/) - JPEG decoder
- [CharLS](https://github.com/team-charls/charls) - JPEG-LS implementation
- [libtiff](https://libtiff.gitlab.io/libtiff/) - TIFF library
- [LibRaw](https://www.libraw.org/) - RAW image decoder
- [Emscripten](https://emscripten.org/) - WebAssembly compiler toolchain
