import typescript from '@rollup/plugin-typescript';
import resolve from '@rollup/plugin-node-resolve';
import wasm from '@rollup/plugin-wasm';

export default {
  input: 'src/index.ts',
  output: [
    {
      file: 'dist/index.js',
      format: 'cjs',
      sourcemap: true
    },
    {
      file: 'dist/index.mjs',
      format: 'es',
      sourcemap: true
    }
  ],
  plugins: [
    resolve(),
    typescript({
      tsconfig: './tsconfig.json'
    }),
    wasm({
      targetEnv: 'auto-inline'
    })
  ]
};
