import { detectImageFormat } from '../utils/image-utils';
import { BaseDecoder } from './base-decoder';

export class JpegDecoder extends BaseDecoder {
  readonly format = 'jpeg';
  readonly wasmJsPath = '/wasm/jpeg/decoder.js';

  async canDecode(buffer: ArrayBuffer): Promise<boolean> {
    return detectImageFormat(buffer) === 'jpeg';
  }
}
