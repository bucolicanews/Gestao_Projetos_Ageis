# Resumo das atividades

## Objetivo
Construir um sistema de gestão de projetos ágeis (Kanban + Scrum) com Nuxt 3 + Supabase, totalmente em PT-BR.

## O que foi entregue nesta iteração

### 1. Arquitetura
- Frontend único em **Nuxt 3 (Vue 3 + TS)**, sem backend separado.
- **Nitro** apenas para endpoints utilitários (`/api/saude`).
- **Supabase** como backend principal: Postgres, Auth, RLS, Edge Functions Deno.

### 2. Modelo de dados
| Tabela | Função |
|---|---|
| `usuarios` | Perfil estendido do `auth.users` |
| `papeis_usuario` | Papéis (admin/desenvolvedor/visualizador) — separado para segurança |
| `projetos` | Projetos do usuário/equipe |
| `membros_projeto` | Vincula usuários a projetos com papel |
| `sprints` | Ciclos Scrum |
| `tarefas` | User stories com coluna Kanban, prioridade, prazo, subtarefas |
| `comentarios` | Discussão por tarefa |

### 3. Segurança (RLS)
- `eh_membro(projeto, usuario)` libera acesso a quem é dono ou membro.
- `tem_papel(usuario, papel)` verifica papel sem recursão.
- Todas as tabelas têm RLS habilitado e políticas granulares (SELECT/INSERT/UPDATE/DELETE).

### 4. Edge Functions
6 funções Deno cobrindo o fluxo principal (criar/atualizar projeto, criar tarefa, mover Kanban, comentar, dashboard agregado).

### 5. Frontend
- Telas: Login, Cadastro, Dashboard, Projetos, Kanban (com drag-and-drop), Sprints, Equipe.
- Pinia para estado global (projetos e quadro Kanban).
- Middleware global de autenticação.

### 6. DevOps
- Dockerfile Node 20 + Supabase CLI.
- docker-compose pronto para subir o frontend.

## Como continuar

1. Implementar telas detalhadas de Sprint (planejamento, burndown).
2. Tela de Equipe com convites por e-mail.
3. Modal de detalhe da tarefa com comentários e subtarefas.
4. Realtime via `supabase.channel` para Kanban colaborativo ao vivo.
5. Notificações (in-app + e-mail via Edge Function).
6. Testes E2E com Playwright.

## Como rodar
Ver [`../README.md`](../README.md).
