import { EmscriptenModule } from "../types";

export class WasmLoader {
  private cache = new Map<string, EmscriptenModule>();
  private loadingScripts = new Map<string, Promise<void>>();

  private async loadScript(jsPath: string): Promise<void> {
    if (this.loadingScripts.has(jsPath)) {
      return this.loadingScripts.get(jsPath);
    }

    const promise = new Promise<void>((resolve, reject) => {
      const script = document.createElement('script');
      script.src = jsPath;
      script.onload = () => resolve();
      script.onerror = () => reject(new Error(`Failed to load ${jsPath}`));
      document.head.appendChild(script);
    });

    this.loadingScripts.set(jsPath, promise);
    return promise;
  }

  async loadEmscriptenModule(jsPath: string): Promise<EmscriptenModule> {
    const cached = this.cache.get(jsPath);
    if (cached) return cached;
    
    await this.loadScript(jsPath);

    const pathParts = jsPath.split('/');
    const formatName = pathParts[pathParts.length - 2] || '';
    const factoryName = `create${formatName.charAt(0).toUpperCase() + formatName.slice(1)}Module`;

    const factory = (window as any)[factoryName];
    if (!factory) {
      throw new Error(`Emscripten module factory '${factoryName}' not found for ${jsPath}`);
    }

    const module = await factory({
      locateFile: (path: string) => {
        if (path.endsWith('.wasm')) {
          return jsPath.replace('.js', '.wasm');
        }
        return path;
      }
    });
    this.cache.set(jsPath, module);
    return module;
  }

  clearCache(): void {
    this.cache.clear();
  }
}

export const wasmLoader = new WasmLoader();
