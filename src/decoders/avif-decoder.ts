import { BaseDecoder } from './base-decoder';
import { detectImageFormat } from '../utils/image-utils';
import decoderUrl from '../../wasm/avif/decoder.js?url';

export class AvifDecoder extends BaseDecoder {
  readonly format = 'avif';
  readonly wasmJsPath = decoderUrl;

  async canDecode(buffer: ArrayBuffer): Promise<boolean> {
    return detectImageFormat(buffer) === 'avif';
  }
}
