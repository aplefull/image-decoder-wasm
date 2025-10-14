import { ImageDecoder } from './types';
import { AvifDecoder } from './decoders/avif-decoder';
import { HeifDecoder } from './decoders/heif-decoder';
import { WebpDecoder } from './decoders/webp-decoder';

class DecoderRegistry {
  private decoders: Map<string, ImageDecoder> = new Map();

  constructor() {
    this.registerDefaultDecoders();
  }

  private registerDefaultDecoders(): void {
    this.register(new AvifDecoder());
    this.register(new HeifDecoder());
    this.register(new WebpDecoder());
  }

  register(decoder: ImageDecoder): void {
    this.decoders.set(decoder.format.toLowerCase(), decoder);
  }

  getDecoder(format: string): ImageDecoder | undefined {
    return this.decoders.get(format.toLowerCase());
  }

  getDecoderForBuffer(buffer: ArrayBuffer): ImageDecoder | undefined {
    for (const decoder of this.decoders.values()) {
      if (decoder.canDecode(buffer)) {
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
