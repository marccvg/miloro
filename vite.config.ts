import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";

const host = process.env.TAURI_DEV_HOST;

// Vite config — Tauri expects fixed port 1420 and clean HMR over Tauri's webview.
export default defineConfig(async () => ({
  plugins: [svelte()],
  clearScreen: false,
  publicDir: "static",
  server: {
    port: 1420,
    strictPort: true,
    host: host || false,
    hmr: host
      ? { protocol: "ws", host, port: 1421 }
      : undefined,
    watch: { ignored: ["**/src-tauri/**"] },
  },
}));
