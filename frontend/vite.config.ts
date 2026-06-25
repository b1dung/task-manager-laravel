/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'node:path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@shared': path.resolve(__dirname, '../shared'),
    },
  },
  server: {
    // Port 5174 so this Laravel project can run alongside the NestJS one (5173).
    port: 5174,
    host: true,
    proxy: {
      // FE → backend. Defaults to the dockerised stack's nginx on :8080
      // (which fronts the Laravel API). Override with env VITE_PROXY_TARGET if elsewhere
      // (e.g. http://localhost:8000 for a standalone `php artisan serve`).
      '/api': {
        target: process.env.VITE_PROXY_TARGET ?? 'http://localhost:8080',
        changeOrigin: true,
      },
      '/uploads': {
        target: process.env.VITE_PROXY_TARGET ?? 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: true,
    exclude: ['**/node_modules/**', '**/e2e/**'],
  },
})
