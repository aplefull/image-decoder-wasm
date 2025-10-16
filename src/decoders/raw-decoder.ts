import { BaseDecoder } from './base-decoder';

interface RawModule {
  _alloc(size: number): number;
  _free_mem(ptr: number): void;
  _can_decode(inputPtr: number, inputSize: number): number;
  _decode(inputPtr: number, inputSize: number, outPtr: number): number;
  HEAP8: Int8Array;
  HEAPU8: Uint8Array;
  HEAP32: Int32Array;
}

export class RawDecoder extends BaseDecoder {
  readonly format = 'raw';
  readonly wasmJsPath = '/wasm/raw/decoder.js';
  protected wasmModule: RawModule | null = null;
  private initPromise: Promise<void> | null = null;

  async initialize(): Promise<void> {
    if (this.wasmModule) return;

    if (!this.initPromise) {
      this.initPromise = super.initialize();
    }

    return this.initPromise;
  }

  async canDecode(buffer: ArrayBuffer): Promise<boolean> {
    try {
      await this.initialize();

      if (!this.wasmModule) {
        return false;
      }
      
      const inputArray = new Uint8Array(buffer);
      const inputPtr = this.wasmModule._alloc(inputArray.length);

      if (!inputPtr) {
        return false;
      }
      
      this.wasmModule.HEAPU8.set(inputArray, inputPtr);
      console.log(2);
      const result = this.wasmModule._can_decode(inputPtr, inputArray.length);
      this.wasmModule._free_mem(inputPtr);

      return result === 1;
    } catch (error) {
      return false;
    }
  }
}
