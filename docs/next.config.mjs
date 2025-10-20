import nextra from 'nextra';

const isProd = process.env.NODE_ENV === 'production';
const basePath = isProd ? '/image-decoder-wasm' : '';

const withNextra = nextra({});

export default withNextra({
  output: 'export',
  basePath: basePath,
  assetPrefix: basePath,
  images: {
    unoptimized: true,
  },
});
