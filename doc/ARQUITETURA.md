# Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                       Navegador                         │
│  Nuxt 3 (Vue 3 + Pinia + Tailwind) — interface PT-BR    │
└──────────────┬──────────────────────────┬───────────────┘
               │ HTTPS                    │ HTTPS
               ▼                          ▼
       ┌──────────────┐          ┌────────────────────┐
       │  Nitro API   │          │  Supabase Cloud    │
       │ (utilitário) │          │                    │
       │ /api/saude   │          │ • Auth (JWT)       │
       └──────────────┘          │ • PostgreSQL + RLS │
                                 │ • Edge Functions   │
                                 │   (Deno)           │
                                 │ • Storage          │
                                 └────────────────────┘
```

## Princípios

1. **Sem backend monolítico** — sem Nest/Express. Lógica sensível mora em Edge Functions.
2. **RLS em primeiro lugar** — qualquer query do cliente é filtrada pelo Postgres.
3. **Papéis fora do perfil** — `papeis_usuario` é tabela separada, lida via função `SECURITY DEFINER`.
4. **PT-BR em tudo** — nomes de pastas, variáveis, funções, tabelas.
5. **Otimista + reconciliação** — Kanban move tarefa imediatamente na UI e persiste em background.

## Fluxo: mover tarefa no Kanban

```
Usuário arrasta cartão
      │
      ▼
ColunaKanban emite "mover"
      │
      ▼
lojaKanban.mover() — atualiza estado local
      │
      ▼
servicoTarefas.moverTarefa()
      │
      ▼
Edge Function moverTarefaKanban
      │
      ▼
UPDATE tarefas SET coluna, posicao  (RLS valida membresia)
```
