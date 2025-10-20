import { detectImageFormat } from '../utils/image-utils';
import { BaseDecoder } from './base-decoder';

export class JxrDecoder extends BaseDecoder {
  readonly format = 'jxr';
  readonly wasmJsPath = '/wasm/jxr/decoder.js';

  async canDecode(buffer: ArrayBuffer): Promise<boolean> {
    return detectImageFormat(buffer) === 'jxr';
  }
}
