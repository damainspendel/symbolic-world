import { defineConfig } from 'vite'
import { viteSingleFile } from 'vite-plugin-singlefile'

// Relative base so the built site works from any static host.
// viteSingleFile inlines JS/CSS/data into one self-contained index.html
// (shareable as an artifact; no server or separate files needed).
export default defineConfig({
  base: './',
  plugins: [viteSingleFile()]
})
