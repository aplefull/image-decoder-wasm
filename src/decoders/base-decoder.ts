import { ImageDecoder, DecodedImage, DecoderOptions, EmscriptenModule } from '../types';
import { wasmLoader } from '../utils/wasm-loader';

export abstract class BaseDecoder implements ImageDecoder {
  protected wasmModule: EmscriptenModule | null = null;

  abstract readonly format: string;
  abstract readonly wasmJsPath: string;

  async initialize(): Promise<void> {
    if (this.wasmModule) return;

    this.wasmModule = await wasmLoader.loadEmscriptenModule(this.wasmJsPath);
  }

  async decode(buffer: ArrayBuffer, options?: DecoderOptions): Promise<DecodedImage> {
    await this.initialize();

    if (!this.wasmModule) {
      throw new Error('WASM module was not initialized');
    }

    const inputArray = new Uint8Array(buffer);
    const inputPtr = this.wasmModule._alloc(inputArray.length);

    if (!inputPtr) {
      throw new Error('Failed to allocate input memory');
    }

    this.wasmModule.HEAPU8.set(inputArray, inputPtr);

    const outPtr = this.wasmModule._alloc(16);

    const result = this.wasmModule._decode(inputPtr, inputArray.length, outPtr);

    if (result !== 0) {
      this.wasmModule._free_mem(inputPtr);
      this.wasmModule._free_mem(outPtr);

      throw new Error(`Decoding failed with error code: ${result}`);
    }

    const outIdx = outPtr >> 2;
    const width = this.wasmModule.HEAP32[outIdx];
    const height = this.wasmModule.HEAP32[outIdx + 1];
    const dataPtr = this.wasmModule.HEAP32[outIdx + 2];
    const dataLen = this.wasmModule.HEAP32[outIdx + 3];

    const imageData = new Uint8ClampedArray(dataLen);
    for (let i = 0; i < dataLen; i++) {
      imageData[i] = this.wasmModule.HEAPU8[dataPtr + i];
    }

    this.wasmModule._free_mem(inputPtr);
    this.wasmModule._free_mem(outPtr);
    this.wasmModule._free_mem(dataPtr);

    return {
      width,
      height,
      data: imageData,
      channels: 4
    };
  }

  abstract canDecode(buffer: ArrayBuffer): Promise<boolean>;
}
