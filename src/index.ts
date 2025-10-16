import { decoderRegistry } from './decoder-registry';
import type { DecodedImage, DecoderOptions } from './types';
import { detectImageFormat, createImageData } from './utils/image-utils';

export type { DecodedImage, DecoderOptions, ImageDecoder } from './types';
export { BaseDecoder } from './decoders/base-decoder';
export { AvifDecoder } from './decoders/avif-decoder';

export class ImageDecoderWasm {
  private async decodeInternal(buffer: ArrayBuffer, options?: DecoderOptions): Promise<DecodedImage> {
    const decoder = await decoderRegistry.getDecoderForBuffer(buffer);

    if (!decoder) {
      const format = detectImageFormat(buffer);
      throw new Error(
        format
          ? `No decoder registered for format: ${format}`
          : 'Unable to detect image format'
      );
    }

    try {
      return await decoder.decode(buffer, options);
    } catch (error) {
      if (decoder.format.toLowerCase() === 'avif') {
        const heifDecoder = decoderRegistry.getDecoder('heif');
        if (heifDecoder) {
          try {
            return await heifDecoder.decode(buffer, options);
          } catch (heifError) {
            throw error;
          }
        }
      }
      throw error;
    }
  }

  async decode(buffer: ArrayBuffer, options?: DecoderOptions): Promise<ImageData> {
    const decoded = await this.decodeInternal(buffer, options);
    return createImageData(decoded.width, decoded.height, decoded.data);
  }

  getSupportedFormats(): string[] {
    return decoderRegistry.getSupportedFormats();
  }

  detectFormat(buffer: ArrayBuffer): string | null {
    return detectImageFormat(buffer);
  }
}

export const imageDecoder = new ImageDecoderWasm();

export default ImageDecoderWasm;
