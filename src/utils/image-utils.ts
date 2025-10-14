export function detectImageFormat(buffer: ArrayBuffer): string | null {
  const view = new Uint8Array(buffer);

  if (view.length < 12) return null;

  if (view[0] === 0xFF && view[1] === 0xD8 && view[2] === 0xFF) {
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

  if (view[0] === 0xFF && view[1] === 0x0A) {
    return 'jxl';
  }

  if (view[0] === 0x00 && view[1] === 0x00 && view[2] === 0x00 && view[3] === 0x0C &&
      view[4] === 0x4A && view[5] === 0x58 && view[6] === 0x4C && view[7] === 0x20) {
    return 'jxl';
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
