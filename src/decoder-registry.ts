import { ImageDecoder } from './types';
import { AvifDecoder } from './decoders/avif-decoder';
import { HeifDecoder } from './decoders/heif-decoder';
import { WebpDecoder } from './decoders/webp-decoder';
import { JxlDecoder } from './decoders/jxl-decoder';
import { JxrDecoder } from './decoders/jxr-decoder';
import { JpegDecoder } from './decoders/jpeg-decoder';
import { JpegLsDecoder } from './decoders/jpegls-decoder';
import { TiffDecoder } from './decoders/tiff-decoder';
import { RawDecoder } from './decoders/raw-decoder';

class DecoderRegistry {
  private decoders: Map<string, ImageDecoder> = new Map();

  constructor() {
    this.registerDefaultDecoders();
  }

  private registerDefaultDecoders(): void {
    this.register(new AvifDecoder());
    this.register(new HeifDecoder());
    this.register(new WebpDecoder());
    this.register(new JxlDecoder());
    this.register(new JxrDecoder());
    this.register(new JpegDecoder());
    this.register(new JpegLsDecoder());
    this.register(new TiffDecoder());
    this.register(new RawDecoder());
  }

  register(decoder: ImageDecoder): void {
    this.decoders.set(decoder.format.toLowerCase(), decoder);
  }

  getDecoder(format: string): ImageDecoder | undefined {
    return this.decoders.get(format.toLowerCase());
  }

  async getDecoderForBuffer(buffer: ArrayBuffer): Promise<ImageDecoder | undefined> {
    for (const decoder of this.decoders.values()) {
      if (await decoder.canDecode(buffer)) {
        return decoder;
      }
    }
    return undefined;
  }

  getSupportedFormats(): string[] {
    return Array.from(this.decoders.keys());
  }
}

export const decoderRegistry = new DecoderRegistry();
