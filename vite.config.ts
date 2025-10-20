import { defineConfig } from 'vite';
import { resolve } from 'path';
import dts from 'vite-plugin-dts';

export default defineConfig({
  root: '.',
  publicDir: 'public',
  server: {
    open: process.env.CI ? false : '/tests/index.html',
    fs: {
      deny: ['**/emsdk/**'],
      strict: false
    },
    watch: {
      ignored: ['**/emsdk/**', '**/native/**']
    }
  },
  optimizeDeps: {
    exclude: ['emsdk'],
    entries: [
      'src/**/*.ts'
    ]
  },
  build: {
    outDir: 'dist',
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      formats: ['es', 'cjs'],
      fileName: (format) => format === 'es' ? 'index.mjs' : 'index.js'
    },
    rollupOptions: {
      external: []
    },
    sourcemap: true
  },
  plugins: [
    dts({
      insertTypesEntry: true,
      rollupTypes: true
    })
  ]
});
