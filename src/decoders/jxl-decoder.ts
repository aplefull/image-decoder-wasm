import { detectImageFormat } from '../utils/image-utils';
import { BaseDecoder } from './base-decoder';

export class JxlDecoder extends BaseDecoder {
  readonly format = 'jxl';
  readonly wasmJsPath = '/wasm/jxl/decoder.js';

  async canDecode(buffer: ArrayBuffer): Promise<boolean> {
    return detectImageFormat(buffer) === 'jxl';
  }
}
