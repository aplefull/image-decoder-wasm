import { detectImageFormat } from '../utils/image-utils';
import { BaseDecoder } from './base-decoder';

export class JpegLsDecoder extends BaseDecoder {
  readonly format = 'jpegls';
  readonly wasmJsPath = '/wasm/jpegls/decoder.js';

  canDecode(buffer: ArrayBuffer): boolean {
    return detectImageFormat(buffer) === 'jpegls';
  }
}
