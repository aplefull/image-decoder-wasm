import { detectImageFormat } from '../utils/image-utils';
import { BaseDecoder } from './base-decoder';

export class JpegDecoder extends BaseDecoder {
  readonly format = 'jpeg';
  readonly wasmJsPath = '/wasm/jpeg/decoder.js';

  canDecode(buffer: ArrayBuffer): boolean {
    return detectImageFormat(buffer) === 'jpeg';
  }
}
