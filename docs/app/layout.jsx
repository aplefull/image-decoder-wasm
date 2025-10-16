import { Head } from 'nextra/components';
import { Layout, Navbar } from 'nextra-theme-docs';
import { getPageMap } from 'nextra/page-map';
import 'nextra-theme-docs/style.css';

export const metadata = {
  title: {
    template: '%s - Image Decoder WASM',
    default: 'Image Decoder WASM',
  },
  description: 'Browser-based image decoder library using WebAssembly',
};

const navbar = (
  <Navbar
    logo={<span style={{ fontWeight: 'bold' }}>Image Decoder WASM</span>}
    projectLink="https://github.com/aplefull/image-decoder-wasm"
  />
);

export default async function RootLayout({ children }) {
  const pageMap = await getPageMap();

  return (
    <html lang="en" dir="ltr" suppressHydrationWarning>
      <Head />
      <body>
        <Layout
          navbar={navbar}
          pageMap={pageMap}
          docsRepositoryBase="https://github.com/aplefull/image-decoder-wasm/tree/main/docs"
          editLink={false}
          feedback={{content: null}}
        >
          {children}
        </Layout>
      </body>
    </html>
  );
}
