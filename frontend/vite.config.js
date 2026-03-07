import { defineConfig } from "vite";
import path from "node:path";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  esbuild: {
    loader: "tsx",
    include: [/src\/.*\.[jt]sx?$/, /pages\/.*\.[jt]sx?$/],
  },
  resolve: {
    alias: {
      agents: path.resolve(__dirname, "src/agents"),
    },
  },
  optimizeDeps: {
    esbuildOptions: {
      loader: {
        ".js": "jsx",
      },
    },
  },
  server: {
    proxy: {
      "/api": "http://localhost:3000",
    },
  },
});
