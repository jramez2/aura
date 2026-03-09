import { defineConfig } from 'vite';

export default defineConfig({
  base: '/aura/',
  server: {
    port: 3000,
    open: true
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  }
});
