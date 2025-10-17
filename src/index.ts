import { decoderRegistry } from './decoder-registry';
import type { DecodedImage } from './types';
import { createImageData } from './utils/image-utils';
import { ImageFormat } from './formats';

export type { DecodedImage, ImageDecoder } from './types';
export { ImageFormat } from './formats';

export { BaseDecoder } from './decoders/base-decoder';
export { AvifDecoder } from './decoders/avif-decoder';
export { HeifDecoder } from './decoders/heif-decoder';
export { WebpDecoder } from './decoders/webp-decoder';
export { JxlDecoder } from './decoders/jxl-decoder';
export { JpegDecoder } from './decoders/jpeg-decoder';
export { JpegLsDecoder } from './decoders/jpegls-decoder';
export { TiffDecoder } from './decoders/tiff-decoder';
export { RawDecoder } from './decoders/raw-decoder';

class ImageDecoderWasm {
  private async decodeInternal(buffer: ArrayBuffer): Promise<DecodedImage> {
    const decoder = await decoderRegistry.getDecoderForBuffer(buffer);

    if (!decoder) {
      throw new Error('Unable to detect image format or no decoder available for this format');
    }

    try {
      return await decoder.decode(buffer);
    } catch (error) {
      if (decoder.format.toLowerCase() === ImageFormat.AVIF) {
        const heifDecoder = decoderRegistry.getDecoder(ImageFormat.HEIF);
        if (heifDecoder) {
          try {
            return await heifDecoder.decode(buffer);
          } catch (heifError) {
            throw error;
          }
        }
      }
      throw error;
    }
  }

  async decode(buffer: ArrayBuffer): Promise<ImageData> {
    const decoded = await this.decodeInternal(buffer);
    return createImageData(decoded.width, decoded.height, decoded.data);
  }

  async decodeToImage(buffer: ArrayBuffer): Promise<HTMLImageElement> {
    const imageData = await this.decode(buffer);

    const canvas = document.createElement('canvas');
    canvas.width = imageData.width;
    canvas.height = imageData.height;

    const ctx = canvas.getContext('2d');
    if (!ctx) {
      throw new Error('Failed to get canvas 2D context');
    }

    ctx.putImageData(imageData, 0, 0);

    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = () => reject(new Error('Failed to create image element'));
      img.src = canvas.toDataURL();
    });
  }

  getSupportedFormats(): string[] {
    return decoderRegistry.getSupportedFormats();
  }
}

export const imageDecoder = new ImageDecoderWasm();

export default imageDecoder;
