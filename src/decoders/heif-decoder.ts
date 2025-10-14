import { BaseDecoder } from './base-decoder';
import { detectImageFormat } from '../utils/image-utils';
import decoderUrl from '../../wasm/heif/decoder.js?url';

export class HeifDecoder extends BaseDecoder {
  readonly format = 'heif';
  readonly wasmJsPath = decoderUrl;

  canDecode(buffer: ArrayBuffer): boolean {
    const format = detectImageFormat(buffer);
    return format === 'avif' || format === 'heif' || format === 'heic';
  }
}
