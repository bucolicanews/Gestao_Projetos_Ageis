import type { Config } from 'tailwindcss'

export default <Partial<Config>>{
  content: [
    './componentes/**/*.{vue,ts}',
    './paginas/**/*.vue',
    './layouts/**/*.vue',
    './app.vue',
  ],
  theme: {
    extend: {
      colors: {
        primaria: '#4f46e5',
        secundaria: '#0ea5e9',
        sucesso: '#16a34a',
        alerta: '#f59e0b',
        perigo: '#dc2626',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
}
