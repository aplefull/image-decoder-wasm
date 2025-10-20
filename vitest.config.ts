import { defineConfig } from 'vitest/config';

export default defineConfig({
  server: {
    fs: {
      strict: false,
    },
  },
  test: {
    globals: true,
    projects: [
      {
        test: {
          name: 'unit',
          include: ['tests/unit/**/*.test.ts'],
          browser: {
            enabled: true,
            provider: 'playwright',
            instances: [
              { browser: 'chromium' },
            ],
            headless: true,
          },
        },
      },
      {
        test: {
          name: 'browser',
          include: ['tests/browser/**/*.test.ts'],
          browser: {
            enabled: true,
            provider: 'playwright',
            instances: [
              { browser: 'chromium' },
            ],
            headless: true,
          },
        },
      },
    ],
  },
});
