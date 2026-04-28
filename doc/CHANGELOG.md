# Changelog

Histórico de alterações principais do sistema de gestão ágil.

## [0.4.0] — Dashboard por projeto + Indicadores de fluxo

### Adicionado
- **Documento `doc/AUDITORIA_AGIL.md`**: análise completa contra Manifesto Ágil (4 valores + 12 princípios), Scrum (artefatos/eventos) e Kanban (6 práticas), com gap analysis e roadmap priorizado.
- **Migration `0005_metricas.sql`** (idempotente):
  - Campos `pontos`, `entrou_coluna_em`, `concluido_em` em `tarefas`.
  - Campo `wip_limite` (jsonb) em `projetos`.
  - Tabela `historico_movimentacao` + RLS por membro.
  - Trigger `tocar_movimento_kanban` que registra cada transição de coluna.
  - View `v_metricas_tarefa` com `lead_time_horas`, `cycle_time_horas`, `idade_coluna_horas`, `atrasada`.
  - Backfill de `concluido_em` para tarefas já concluídas.
- **Edge Function `dashboardProjeto`**: KPIs ágeis completos por projeto — saúde 0-100, throughput diário/médio, lead/cycle time (média + p50 + p90), CFD, WIP atual + violações, distribuição por prioridade, carga por responsável, atrasadas, itens "presos" (>72h).
- **Página `/projetos/[id]`**: dashboard executivo com cards, alertas, **Cumulative Flow Diagram (SVG)**, gráfico de throughput, barras de WIP, prioridades e tabela de carga por pessoa. Seletor de janela (7/14/30 dias).
- **Componentes** `GraficoCFD.vue` e `GraficoThroughput.vue` (SVG puro, sem libs externas).
- Cards da `/projetos` agora apontam para o dashboard, com atalhos para Kanban e Sprints.

### Como aplicar
```bash
supabase db push   # aplica 0005_metricas.sql
supabase functions deploy dashboardProjeto
```

## [0.3.0] — Correções de autenticação e visibilidade de dados

### Corrigido
- **Login não persistia / loop em `/login`**: middleware `auth.global.ts` agora só executa no cliente (`import.meta.server` early-return) e trata o caso "logado tentando abrir /login" para redirecionar ao dashboard.
- **Conflito de redirect**: removido `redirectOptions` do `@nuxtjs/supabase` (`supabase: { redirect: false }`) — quem manda agora é o middleware único.
- **Variável de ambiente errada**: o módulo espera `SUPABASE_KEY` (e não `SUPABASE_ANON_KEY`). `.env.example` atualizado com as duas.
- **`window` no SSR** em `useAutenticacao.cadastrar()`: agora protegido por `typeof window !== 'undefined'`.
- **Race condition no login**: aguarda `nextTick()` antes de `router.push('/')` para o cookie de sessão propagar.

### Banco — migration `0004_correcoes.sql` (incremental, idempotente)
- Trigger `handle_novo_usuario` agora é **tolerante a falhas** (`on conflict do nothing` + `exception when others`) — signup nunca mais quebra por causa do perfil.
- **Backfill** de `public.usuarios` e `public.papeis_usuario` para usuários já existentes em `auth.users` sem perfil.
- **Auto-membro**: trigger `trg_projeto_proprietario_membro` adiciona o proprietário em `membros_projeto` ao criar projeto (resolve "criei projeto e some da lista" por RLS).
- Backfill de membros para projetos antigos.
- Policies faltantes: `usuarios_insert_proprio` e `papeis_insert_proprio`.
- Realtime garantido em `tarefas` (`replica identity full` + `supabase_realtime` publication).

### Como aplicar
```bash
supabase db push       # aplica 0004_correcoes.sql
# ou, se Cloud:
psql $DATABASE_URL -f supabase/migrations/0004_correcoes.sql
```

## [0.2.0] — Realtime Kanban + Sprints completas


### Adicionado

#### Realtime no Kanban
- Composable `useRealtimeKanban` que assina `postgres_changes` na tabela `tarefas` filtrando por `projeto_id`.
  - INSERT/UPDATE/DELETE são refletidos automaticamente na `lojaKanban`.
- Canal de **presença** (`presence`) mostra avatares dos usuários conectados ao quadro com indicador pulsante.
- Página `paginas/kanban.vue` integra o composable e exibe quem está online.

#### Sprints completas
- `paginas/sprints.vue` reformulada:
  - Lista lateral de sprints por projeto.
  - Detalhe com objetivo, datas, status editável e barra de progresso.
  - Painel de tarefas da sprint + backlog do projeto para associação rápida.
- `componentes/GraficoBurndown.vue`: burndown chart em SVG puro (sem dependências), com linha ideal vs real.
- `componentes/ModalSprint.vue`: criação de sprints com nome/objetivo/datas/status.
- `loja/lojaSprints.ts`: estado, getters de progresso e ações (carregar, selecionar, criar, atualizar, associar tarefa, atualizar snapshot).
- `servicoSprints` ampliado com `tarefasDaSprint`, `tarefasDoBacklog`, `associarTarefa`, `snapshots`, `registrarSnapshotHoje`.

#### Banco de dados
- Migration `0003_burndown.sql`:
  - Tabela `snapshots_sprint` (sprint_id, data, total/concluídas/restantes) com RLS.
  - Função `registrar_snapshot_sprint(sprint_id)` (SECURITY DEFINER) — upsert do dia atual.
  - Trigger `trg_tarefas_snapshot` que recalcula o snapshot do dia sempre que tarefas da sprint mudam.

### Notas
- Realtime requer que a tabela `tarefas` esteja com Realtime habilitado no Supabase
  (`alter publication supabase_realtime add table public.tarefas;`).
- Burndown é renderizado em SVG inline para evitar dependência externa.

---

## [0.1.0] — Primeira versão (estrutura completa)

### Adicionado

#### Frontend Nuxt 3
- Configuração `nuxt.config.ts` com diretórios em PT-BR (`paginas/`, `componentes/`, `layouts/`, `publico/`).
- Layouts `default.vue` (com sidebar) e `autenticacao.vue` (telas públicas).
- Páginas: `login`, `cadastro`, `index` (Dashboard), `projetos`, `kanban`, `sprints`, `equipe`.
- Componentes: `ColunaKanban`, `CartaoTarefa`, `ModalProjeto`.
- Composable `useAutenticacao` (login/cadastro/logout).
- Serviços: `servicoProjetos`, `servicoTarefas`, `servicoComentarios`, `servicoSprints`, `servicoEquipe`.
- Lojas Pinia: `lojaProjetos`, `lojaKanban` (com getters por coluna e ações otimistas).
- Middleware global `auth.global.ts` que protege rotas privadas.
- Tailwind configurado com paleta semântica (`primaria`, `secundaria`, `sucesso`, `alerta`, `perigo`).
- Endpoint Nitro `/api/saude` (health-check).

#### Backend Supabase
- Migration `0001_inicial.sql` (schema completo com triggers e funções de papel).
- Migration `0002_rls.sql` (políticas RLS para todas as tabelas).
- 6 Edge Functions Deno: criarProjeto, atualizarProjeto, criarTarefa, moverTarefaKanban, adicionarComentario, listarDashboard.

#### Infraestrutura
- `Dockerfile` baseado em Node 20 + Supabase CLI.
- `docker-compose.yml` com serviço frontend.
- `.env.example`.
