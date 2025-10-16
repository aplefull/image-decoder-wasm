import { detectImageFormat } from '../utils/image-utils';
import { BaseDecoder } from './base-decoder';

export class TiffDecoder extends BaseDecoder {
  readonly format = 'tiff';
  readonly wasmJsPath = '/wasm/tiff/decoder.js';

  canDecode(buffer: ArrayBuffer): boolean {
    return detectImageFormat(buffer) === 'tiff';
  }
}
