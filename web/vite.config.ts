import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  // Tailwind v4 is compiled by Vite, so no separate PostCSS file is needed.
  plugins: [react(), tailwindcss()],
})
