export const ImageFormat = {
  AVIF: 'avif',
  HEIF: 'heif',
  HEIC: 'heic',
  WEBP: 'webp',
  JXL: 'jxl',
  JPEG: 'jpeg',
  JPEGLS: 'jpegls',
  TIFF: 'tiff',
  RAW: 'raw'
} as const;

export type ImageFormat = typeof ImageFormat[keyof typeof ImageFormat];
