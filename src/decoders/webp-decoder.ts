import { detectImageFormat } from '../utils/image-utils';
import { BaseDecoder } from './base-decoder';

export class WebpDecoder extends BaseDecoder {
  readonly format = 'webp';
  readonly wasmJsPath = '/wasm/webp/decoder.js';

  canDecode(buffer: ArrayBuffer): boolean {
    return detectImageFormat(buffer) === 'webp';
  }
}
