import { detectImageFormat } from '../utils/image-utils';
import { BaseDecoder } from './base-decoder';

export class JxlDecoder extends BaseDecoder {
  readonly format = 'jxl';
  readonly wasmJsPath = '/wasm/jxl/decoder.js';

  canDecode(buffer: ArrayBuffer): boolean {
    return detectImageFormat(buffer) === 'jxl';
  }
}
