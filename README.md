# Image Decoder WASM

A browser-based image decoder library using WebAssembly to support image formats/features not natively supported by browsers.

## Installation

```bash
npm install image-decoder-wasm
```

## Usage

```typescript
import { imageDecoder } from 'image-decoder-wasm';

const response = await fetch('image.avif');
const buffer = await response.arrayBuffer();

const imageData = await imageDecoder.decode(buffer);

const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');
canvas.width = imageData.width;
canvas.height = imageData.height;
ctx.putImageData(imageData, 0, 0);
```

## Development

### Install dependencies

```bash
pnpm install
```

### Build WASM Decoders
```bash
pnpm run build:wasm         # Build all WASM decoders
pnpm run build:wasm:avif    # Build only AVIF decoder
```

### Start Dev Server

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

### 6. Add Test Fixture

Add `test/fixtures/sample.format`

### 7. Update Tests

In `test/decoder.test.js`, add:

```javascript
{ format: 'format', file: join(__dirname, 'fixtures/sample.format') }
```