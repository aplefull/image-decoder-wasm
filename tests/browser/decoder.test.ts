import { describe, it, expect, beforeEach } from 'vitest';

describe('Image Decoders', () => {
  beforeEach(() => {
    document.body.innerHTML = '';
  });

  describe('AVIF Decoder', () => {
    it('should decode AVIF image', async () => {
      const response = await fetch('/tests/fixtures/avif/sample.avif');
      const arrayBuffer = await response.arrayBuffer();

      const { default: imageDecoder } = await import('/src/index.ts');
      const imageData = await imageDecoder.decode(arrayBuffer);

      expect(imageData.width).toBeGreaterThan(0);
      expect(imageData.height).toBeGreaterThan(0);
      expect(imageData.data.length).toBe(imageData.width * imageData.height * 4);
    });
  });

  describe('HEIF Decoder', () => {
    it('should decode HEIF image', async () => {
      const response = await fetch('/tests/fixtures/heif/sample3.heif');
      const arrayBuffer = await response.arrayBuffer();

      const { default: imageDecoder } = await import('/src/index.ts');
      const imageData = await imageDecoder.decode(arrayBuffer);

      expect(imageData.width).toBeGreaterThan(0);
      expect(imageData.height).toBeGreaterThan(0);
      expect(imageData.data.length).toBe(imageData.width * imageData.height * 4);
    });
  });

  describe('JXL Decoder', () => {
    it('should decode JXL image (dice)', async () => {
      const response = await fetch('/tests/fixtures/jxl/dice.jxl');
      const arrayBuffer = await response.arrayBuffer();

      const { default: imageDecoder } = await import('/src/index.ts');
      const imageData = await imageDecoder.decode(arrayBuffer);

      expect(imageData.width).toBeGreaterThan(0);
      expect(imageData.height).toBeGreaterThan(0);
      expect(imageData.data.length).toBe(imageData.width * imageData.height * 4);
    });

    it('should decode JXL image (animated)', async () => {
      const response = await fetch('/tests/fixtures/jxl/anim-icos.jxl');
      const arrayBuffer = await response.arrayBuffer();

      const { default: imageDecoder } = await import('/src/index.ts');
      const imageData = await imageDecoder.decode(arrayBuffer);

      expect(imageData.width).toBeGreaterThan(0);
      expect(imageData.height).toBeGreaterThan(0);
      expect(imageData.data.length).toBe(imageData.width * imageData.height * 4);
    });

    it('should decode JXL image (webkit-logo)', async () => {
      const response = await fetch('/tests/fixtures/jxl/Webkit-logo-P3.jxl');
      const arrayBuffer = await response.arrayBuffer();

      const { default: imageDecoder } = await import('/src/index.ts');
      const imageData = await imageDecoder.decode(arrayBuffer);

      expect(imageData.width).toBeGreaterThan(0);
      expect(imageData.height).toBeGreaterThan(0);
      expect(imageData.data.length).toBe(imageData.width * imageData.height * 4);
    });

    it('should decode JXL image (large photo)', async () => {
      const response = await fetch('/tests/fixtures/jxl/zoltan-tasi-CLJeQCr2F_A-unsplash.jxl');
      const arrayBuffer = await response.arrayBuffer();

      const { default: imageDecoder } = await import('/src/index.ts');
      const imageData = await imageDecoder.decode(arrayBuffer);

      expect(imageData.width).toBeGreaterThan(0);
      expect(imageData.height).toBeGreaterThan(0);
      expect(imageData.data.length).toBe(imageData.width * imageData.height * 4);
    });
  });
});
