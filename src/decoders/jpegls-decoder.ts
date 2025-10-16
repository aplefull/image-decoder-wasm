import { detectImageFormat } from '../utils/image-utils';
import { BaseDecoder } from './base-decoder';

export class JpegLsDecoder extends BaseDecoder {
  readonly format = 'jpegls';
  readonly wasmJsPath = '/wasm/jpegls/decoder.js';

  async canDecode(buffer: ArrayBuffer): Promise<boolean> {
    return detectImageFormat(buffer) === 'jpegls';
  }
}
