# Sistema de Gestão de Projetos Ágeis — Nuxt 3 + Supabase

> ⚠️ **Importante:** Este código é **referência** gerada dentro do projeto Lovable.
> O preview do Lovable roda **React/Vite**, então estes arquivos Nuxt **não executam aqui**.
> Para rodar, copie a pasta `nuxt-reference/` para sua máquina e siga as instruções abaixo.

---

## 🧱 Stack

- **Frontend:** Nuxt 3 (Vue 3 + TypeScript)
- **Server engine:** Nitro (apenas API leve / proxy / middleware)
- **Backend:** Supabase (PostgreSQL + Auth + Edge Functions Deno + RLS)
- **Estado:** Pinia
- **UI:** Tailwind CSS + componentes customizados
- **Drag & Drop:** vuedraggable
- **Idioma:** PT-BR (interface e código)

---

## 📁 Estrutura

```
nuxt-reference/
├── app.vue
├── nuxt.config.ts
├── package.json
├── tsconfig.json
├── tailwind.config.ts
├── .env.example
├── Dockerfile
├── docker-compose.yml
├── /paginas              # pages do Nuxt (renomeadas em PT)
├── /componentes
├── /layouts
├── /composables
├── /servicos
├── /middleware
├── /plugins
├── /loja                 # Pinia
├── /assets
├── /publico
├── /server/api           # Nitro
├── /supabase
│   ├── /migrations
│   ├── /functions
│   └── seed.sql
└── /doc                  # changelog e resumos
```

> Nota: Nuxt usa por convenção `pages/`, `components/`, `stores/`. Para atender ao requisito PT-BR mantemos pastas em PT e mapeamos via `nuxt.config.ts` (`dir`).

---

## 🚀 Como rodar

### 1. Clonar e instalar

```bash
cd nuxt-reference
cp .env.example .env
# preencha SUPABASE_URL e SUPABASE_ANON_KEY
npm install
```

### 2. Subir Supabase local (opcional)

```bash
npx supabase start
npx supabase db reset   # aplica migrations + seed
npx supabase functions serve
```

### 3. Rodar Nuxt

```bash
npm run dev
# http://localhost:3000
```

### 4. Docker

```bash
docker compose up --build
```

---

## 🔐 Autenticação

E-mail/senha via Supabase Auth. Sessão persistida via cookies (módulo `@nuxtjs/supabase`).

## 👥 Papéis

- `admin` — gerencia projetos e equipe
- `desenvolvedor` — cria/edita tarefas
- `visualizador` — somente leitura

Implementados em tabela `papeis_usuario` separada (evita escalada de privilégio) e checados via função `tem_papel()` SECURITY DEFINER.

## 📋 Kanban

Colunas: `backlog`, `a_fazer`, `em_progresso`, `em_revisao`, `concluido`.
Drag & drop persiste via Edge Function `moverTarefaKanban`.

---

## 📚 Documentação interna

Veja [`/doc`](./doc) para changelog e resumos das atividades.
