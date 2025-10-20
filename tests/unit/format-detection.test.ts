import { describe, it, expect } from 'vitest';
import { detectImageFormat } from '../../src/utils/image-utils';

describe('Image Format Detection', () => {
  it('should detect AVIF format', async () => {
    const response = await fetch('/tests/fixtures/avif/sample.avif');
    const arrayBuffer = await response.arrayBuffer();

    expect(detectImageFormat(arrayBuffer)).toBe('avif');
  });

  it('should detect HEIF format', async () => {
    const response = await fetch('/tests/fixtures/heif/sample3.heif');
    const arrayBuffer = await response.arrayBuffer();

    expect(detectImageFormat(arrayBuffer)).toBe('heif');
  });

  it('should detect JXL format', async () => {
    const response = await fetch('/tests/fixtures/jxl/dice.jxl');
    const arrayBuffer = await response.arrayBuffer();

    expect(detectImageFormat(arrayBuffer)).toBe('jxl');
  });
});
