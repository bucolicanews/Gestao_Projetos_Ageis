// nuxt.config.ts — Configuração do Nuxt 3 com pastas em PT-BR
export default defineNuxtConfig({
  compatibilityDate: '2025-01-01',
  devtools: { enabled: true },

  // Mapeia diretórios padrão do Nuxt para nomes em português
  dir: {
    pages: 'paginas',
    layouts: 'layouts',
    middleware: 'middleware',
    plugins: 'plugins',
    public: 'publico',
    assets: 'assets',
  },

  modules: [
    '@nuxtjs/supabase',
    '@nuxtjs/tailwindcss',
    '@pinia/nuxt',
  ],

  // Auto-import dos diretórios em PT
  imports: {
    dirs: ['composables', 'servicos', 'loja'],
  },

  components: [
    { path: '~/componentes', pathPrefix: false },
  ],

  // Desativa redirect automático do módulo — usamos nosso middleware global
  // (evita briga entre os dois e loop de /login)
  supabase: {
    redirect: false,
  },

  runtimeConfig: {
    supabaseServiceKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
    public: {
      supabaseUrl: process.env.SUPABASE_URL,
      supabaseAnonKey: process.env.SUPABASE_ANON_KEY,
    },
  },

  app: {
    head: {
      title: 'Gestão Ágil — Projetos & Kanban',
      htmlAttrs: { lang: 'pt-BR' },
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'Sistema ágil de gestão de projetos com Kanban, Sprints e equipe.' },
      ],
    },
  },

  css: ['~/assets/css/principal.css'],
})
