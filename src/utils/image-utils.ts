export function detectImageFormat(buffer: ArrayBuffer): string | null {
  const view = new Uint8Array(buffer);

  if (view.length < 12) return null;

  if (view[0] === 0xFF && view[1] === 0xD8 && view[2] === 0xFF) {
    for (let i = 0; i < Math.min(view.length - 1, 100); i++) {
      if (view[i] === 0xFF && view[i + 1] === 0xF7) {
        return 'jpegls';
      }
    }
    return 'jpeg';
  }

  if (view[0] === 0x89 && view[1] === 0x50 && view[2] === 0x4E && view[3] === 0x47) {
    return 'png';
  }

  if ((view[0] === 0x52 && view[1] === 0x49 && view[2] === 0x46 && view[3] === 0x46) &&
      (view[8] === 0x57 && view[9] === 0x45 && view[10] === 0x42 && view[11] === 0x50)) {
    return 'webp';
  }

  if (view[4] === 0x66 && view[5] === 0x74 && view[6] === 0x79 && view[7] === 0x70 &&
      view[8] === 0x61 && view[9] === 0x76 && view[10] === 0x69 && view[11] === 0x66) {
    return 'avif';
  }

  if (view[4] === 0x66 && view[5] === 0x74 && view[6] === 0x79 && view[7] === 0x70) {
    const brand = String.fromCharCode(view[8], view[9], view[10], view[11]);
    if (brand === 'heic' || brand === 'heix' || brand === 'hevc' || 
        brand === 'hevx' || brand === 'mif1' || brand === 'msf1') {
      return 'heif';
    }
  }

  if (view[0] === 0xFF && view[1] === 0x0A) {
    return 'jxl';
  }

  if (view[0] === 0x00 && view[1] === 0x00 && view[2] === 0x00 && view[3] === 0x0C &&
      view[4] === 0x4A && view[5] === 0x58 && view[6] === 0x4C && view[7] === 0x20) {
    return 'jxl';
  }

  if (view[0] === 0x49 && view[1] === 0x49 && view[2] === 0xBC) {
    return 'jxr';
  }

  if (view[0] === 0x00 && view[1] === 0x00 && view[2] === 0x00 && view[3] === 0x0C &&
      view[4] === 0x6A && view[5] === 0x50 && view[6] === 0x20 && view[7] === 0x20 &&
      view[8] === 0x0D && view[9] === 0x0A && view[10] === 0x87 && view[11] === 0x0A) {
    return 'jp2';
  }

  if (view[0] === 0xFF && view[1] === 0x4F && view[2] === 0xFF && view[3] === 0x51) {
    return 'j2k';
  }

  if (view[0] === 0x97 && view[1] === 0x4A && view[2] === 0x42 && view[3] === 0x32 &&
      view[4] === 0x0D && view[5] === 0x0A && view[6] === 0x1A && view[7] === 0x0A) {
    return 'jbig';
  }

  if (view[0] === 0x00 && view[1] === 0x00 && view[2] === 0x00 && view[3] === 0x0C &&
      view[4] === 0x6A && view[5] === 0x62 && view[6] === 0x69 && view[7] === 0x67 &&
      view[8] === 0x32) {
    return 'jbig2';
  }

  return null;
}

export function createImageData(
  width: number,
  height: number,
  data: Uint8ClampedArray
): ImageData {
  const imageData = new ImageData(width, height);
  imageData.data.set(data);
  return imageData;
}
