export interface DecodedImage {
  width: number;
  height: number;
  data: Uint8ClampedArray;
  channels: number;
}

export interface DecoderOptions {
  maxWidth?: number;
  maxHeight?: number;
  targetFormat?: 'rgba' | 'rgb';
}

export interface ImageDecoder {
  decode(buffer: ArrayBuffer, options?: DecoderOptions): Promise<DecodedImage>;
  canDecode(buffer: ArrayBuffer): Promise<boolean>;
  readonly format: string;
}

export type EmscriptenModule = {
  _alloc(size: number): number;
  _free_mem(ptr: number): void;
  _decode(inputPtr: number, inputSize: number, outPtr: number): number;
  HEAP8: Int8Array;
  HEAPU8: Uint8Array;
  HEAP32: Int32Array;
};
