import nextra from 'nextra';

const withNextra = nextra({});

const isProd = process.env.NODE_ENV === 'production';

export default withNextra({
  output: 'export',
  basePath: isProd ? '/image-decoder-wasm' : '',
  images: {
    unoptimized: true,
  },
});
