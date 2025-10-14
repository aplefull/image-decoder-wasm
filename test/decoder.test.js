#!/usr/bin/env node

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

global.window = {
  createAvifModule: null
};
global.document = {
  createElement: () => ({
    src: '',
    onload: null,
    onerror: null
  }),
  head: {
    appendChild: () => {}
  }
};
global.ImageData = class ImageData {
  constructor(width, height) {
    this.width = width;
    this.height = height;
    this.data = new Uint8ClampedArray(width * height * 4);
  }
};

const testResults = [];

async function testDecoder(format, filePath) {
  console.log(`\n🧪 Testing ${format.toUpperCase()} decoder...`);

  try {
    const buffer = readFileSync(filePath);
    const arrayBuffer = buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);

    const { imageDecoder } = await import('../dist/index.mjs');

    const detectedFormat = imageDecoder.detectFormat(arrayBuffer);
    console.log(`   ✓ Format detected: ${detectedFormat}`);

    if (detectedFormat !== format) {
      throw new Error(`Format mismatch: expected ${format}, got ${detectedFormat}`);
    }

    const supportedFormats = imageDecoder.getSupportedFormats();
    console.log(`   ✓ Supported formats: ${supportedFormats.join(', ')}`);

    if (!supportedFormats.includes(format)) {
      throw new Error(`Format ${format} not supported`);
    }

    testResults.push({
      format,
      success: true,
      message: 'Format detection passed'
    });

    console.log(`   ${format.toUpperCase()} test passed`);
    return true;

  } catch (error) {
    console.error(`   ${format.toUpperCase()} test failed:`, error.message);
    testResults.push({
      format,
      success: false,
      error: error.message
    });
    return false;
  }
}

async function runTests() {
  console.log('Starting Image Decoder Tests\n');
  console.log('=' .repeat(50));

  const tests = [
    { format: 'avif', file: join(__dirname, 'fixtures/sample.avif') }
  ];

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    const result = await testDecoder(test.format, test.file);
    if (result) passed++;
    else failed++;
  }

  console.log('\n' + '='.repeat(50));
  console.log('\nTest Summary:');
  console.log(`   Total: ${tests.length}`);
  console.log(`   ✅ Passed: ${passed}`);
  console.log(`   ❌ Failed: ${failed}`);

  if (failed > 0) {
    console.log('\nSome tests failed\n');
    process.exit(1);
  } else {
    console.log('\nAll tests passed!\n');
    process.exit(0);
  }
}

runTests().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
