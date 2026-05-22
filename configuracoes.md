````md
# 🧠 DIRETRIZ MESTRA — IMPLEMENTAÇÃO DO CHECKLIST OPERACIONAL
# Sistema de Gerenciamento de Projetos
## Métodos Ágeis + Gestão de Configuração + Engenharia de Software

---

# 📌 OBJETIVO

Este documento define TODAS as diretrizes operacionais, arquiteturais, funcionais, visuais e técnicas necessárias para implementação completa do sistema de gerenciamento de projetos.

O sistema deve ser construído com foco em:

- Escalabilidade
- Modularidade
- Gestão Ágil
- Gestão de Configuração
- Segurança
- Alta performance
- SaaS multiempresa
- Automação
- Observabilidade
- Realtime
- DevOps
- UX moderna

---

# 🏗️ VISÃO GERAL DO SISTEMA

O sistema será uma plataforma SaaS de gerenciamento de projetos inspirada em:

- Jira
- Trello
- ClickUp
- Monday
- Asana
- Azure DevOps

Porém com:

- Gestão ágil avançada
- Gestão de configuração integrada
- DevOps integrado
- Observabilidade
- Multiempresa
- Sistema de permissões avançado
- Automação
- Inteligência operacional

---

# 🧱 ARQUITETURA PRINCIPAL

# Backend
- Node.js
- **NestJS** (obrigatório)
- TypeScript
- **Supabase** (PostgreSQL + Auth + Realtime + Storage) — já em produção
- Supabase Client SDK (substituí Prisma ORM)
- Redis (cache + filas)
- BullMQ (filas assíncronas)

> Supabase provê: banco PostgreSQL, autenticação JWT, Realtime via WebSocket, RLS (Row Level Security) e Storage. Não usar Prisma — usar Supabase SDK ou queries diretas via `@supabase/supabase-js`.

# Frontend
- **Vue.js** (obrigatório)
- **Nuxt.js** (obrigatório)
- **Pinia** (store)
- **Tailwind CSS** (estilo — não Vuetify)
- TypeScript

> Estrutura de pastas em PT-BR: `paginas/`, `componentes/`, `loja/`, `servicos/`, `composables/`.

# Infraestrutura
- Docker
- Docker Compose
- Nginx
- GitHub Actions
- Cloudflare
- VPS/Dedicado

# Observabilidade
- Prometheus
- Grafana
- Loki
- Sentry

---

# 📂 ESTRUTURA PADRÃO DO PROJETO

```txt
project/
│
├── backend/
│
├── frontend/
│
├── docs/
│
├── infra/
│
├── docker/
│
├── scripts/
│
├── database/
│
├── monitoring/
│
├── nginx/
│
├── .github/
│
└── README.md
````

---

# ⚙️ FASE 1 — CONCEPÇÃO DO PRODUTO

# Objetivos obrigatórios

* Definir problema principal
* Definir nicho
* Definir público-alvo
* Definir modelo SaaS
* Definir diferencial competitivo
* Definir roadmap

# Entregáveis

* Documento de visão
* Documento de escopo
* Roadmap
* Backlog inicial
* Canvas do produto

---

# 📊 FASE 2 — ENGENHARIA DE REQUISITOS

# Requisitos funcionais

O sistema DEVE possuir:

* Gestão de projetos
* Gestão de tarefas
* Gestão de sprint
* Kanban
* Backlog
* Roadmap
* Time tracking
* Comentários
* Menções
* Uploads
* Notificações
* Dashboard
* Relatórios
* Gestão de usuários
* Gestão de permissões
* Logs
* Auditoria

# Requisitos não funcionais

* Escalabilidade horizontal
* API REST
* Realtime
* Segurança avançada
* Responsividade
* Alta disponibilidade
* Multiempresa
* Modularidade

---

# 🧩 FASE 3 — MODELAGEM

# Modelagens obrigatórias

* Casos de uso
* UML
* Fluxos
* Entidades
* ERD
* DDD
* Arquitetura limpa

# Criar

* Diagramas
* Fluxos operacionais
* Mapa de navegação
* Arquitetura de domínio

---

# 📋 FASE 4 — GESTÃO ÁGIL

# Implementar

* Scrum
* Kanban
* Scrumban

# Criar

* Sprint backlog
* Product backlog
* Epic backlog

# Fluxo Kanban

```txt
Backlog
→ Refinamento
→ Ready
→ Desenvolvimento
→ Code Review
→ Testes
→ Homologação
→ Produção
→ Concluído
```

---

# 🔧 FASE 5 — GESTÃO DE CONFIGURAÇÃO

# Git

Implementar:

* Git Flow
* Conventional Commits
* Semantic Versioning

# Branches obrigatórias

```txt
main
develop
release/*
hotfix/*
feature/*
bugfix/*
```

# Commits

Padrão:

```txt
feat:
fix:
refactor:
docs:
style:
test:
build:
ci:
```

---

# 🧠 FASE 6 — ARQUITETURA BACKEND

# Stack obrigatória

* **NestJS** + TypeScript
* **Supabase SDK** para acesso ao banco (não Prisma)
* Realtime via Supabase Channels (não WebSocket próprio)
* Auth via Supabase Auth (JWT) — não implementar auth próprio

# Estrutura obrigatória

```txt
backend/src/
│
├── modules/
├── common/
├── config/
├── supabase/          ← client Supabase configurado
├── queue/             ← BullMQ
├── shared/
└── main.ts
```

---

# Backend DEVE possuir

# Autenticação

* JWT
* Refresh token
* OAuth
* MFA

# Segurança

* Rate limit
* Helmet
* CORS
* XSS Protection
* SQL Injection Protection
* CSRF Protection

# Observabilidade

* Logs
* Tracing
* Metrics
* Audit

# Performance

* Redis
* Cache
* Queue
* Lazy loading
* Paginação

---

# 🗄️ FASE 7 — BANCO DE DADOS

# Banco principal

* **PostgreSQL via Supabase** (já configurado e rodando)

# Gerenciamento

* Migrations via `supabase/migrations/` (SQL versionado)
* Seeds via `supabase/seed.sql`
* RLS (Row Level Security) obrigatório em todas as tabelas
* Indexes, constraints e relacionamentos via migration SQL

# Regras obrigatórias

* Toda tabela deve ter RLS ativado
* Nunca expor `service_role` key no frontend
* Usar `anon` key + RLS para controle de acesso
* Variáveis de ambiente: `SUPABASE_URL` e `SUPABASE_KEY` (não `SUPABASE_ANON_KEY`)

# Entidades principais

* usuarios
* organizacoes
* projetos
* sprints
* tarefas (auto-referência via `tarefa_pai_id` para subtarefas)
* comentarios
* anexos
* notificacoes
* membros_projeto
* historico_movimentacao
* logs
* atividades

---

# 🎨 FASE 8 — DESIGN SYSTEM

# Criar Design System completo

# Tokens obrigatórios

* colors
* typography
* spacing
* shadows
* radius
* transitions

# Componentes obrigatórios

* Buttons
* Inputs
* Tables
* Modals
* Dialogs
* Sidebar
* Navbar
* Cards
* Kanban cards
* Charts
* Notifications

# Requisitos

* Responsivo
* Dark mode
* Acessibilidade
* Componentização

---

# 🖥️ FASE 9 — FRONTEND

# Stack obrigatória

* **Vue.js** + **Nuxt.js** (obrigatório — não trocar)
* **Pinia** para estado global
* **Tailwind CSS** para estilo
* **TypeScript** em todos os arquivos
* `@nuxtjs/supabase` para integração Supabase
* `vuedraggable` para drag-and-drop Kanban

# Estrutura obrigatória (pastas em PT-BR)

```txt
frontend/
│
├── componentes/       ← components/
├── paginas/           ← pages/
├── layouts/
├── composables/
├── loja/              ← stores/ (Pinia)
├── servicos/          ← services/ (Supabase calls)
├── middleware/
├── assets/
└── nuxt.config.ts
```

---

# Frontend DEVE possuir

# Páginas

* Login
* Cadastro
* Dashboard
* Projetos
* Tarefas
* Sprint
* Backlog
* Roadmap
* Relatórios
* Administração

# Funcionalidades

* Drag and drop
* Realtime
* Loading states
* Skeleton loading
* Error boundaries
* Infinite scroll
* Busca global

---

# 🔄 FASE 10 — REALTIME

# Implementar via Supabase Realtime (não WebSocket próprio)

* Supabase Channels (`postgres_changes`) para sync de tarefas
* Supabase Presence para usuários online no Kanban
* Notificações realtime
* Kanban realtime (drag-and-drop sincronizado)
* Colaboração simultânea

> Usar `useRealtimeKanban` composable já existente como padrão.

---

# 🚀 FASE 11 — DEVOPS

# Docker obrigatório

# Criar

* Dockerfile backend
* Dockerfile frontend
* docker-compose.yml

# Serviços

* app
* nginx
* postgres
* redis
* worker
* websocket

---

# 🔁 FASE 12 — CI/CD

# Pipeline obrigatório

# Executar

* Install
* Build
* Test
* Lint
* Security scan
* Deploy

# Automatizar

* Deploy staging
* Deploy produção
* Rollback

---

# 📈 FASE 13 — OBSERVABILIDADE

# Implementar

* Logs centralizados
* Metrics
* Alerts
* Tracing
* Error tracking

# Stack sugerida

* Grafana
* Prometheus
* Loki
* Sentry

---

# 🧪 FASE 14 — TESTES

# Implementar

* Unit tests
* Integration tests
* E2E tests
* Load tests
* Security tests

# Meta

* Cobertura mínima 80%

---

# 🔒 FASE 15 — SEGURANÇA

# Implementar

* RBAC
* MFA
* Session control
* Audit logs
* Backup
* Encryption
* Secrets manager

---

# 📚 FASE 16 — DOCUMENTAÇÃO

# Criar

* Swagger/OpenAPI
* Guia instalação
* Guia deploy
* Guia contribuição
* Arquitetura
* Manual usuário
* FAQ

---

# 🌎 FASE 17 — MULTIEMPRESA (SaaS)

# Implementar

* Multi-tenant
* Billing
* Planos
* Assinaturas
* Limites por plano
* Trial
* Gestão de uso

---

# 🤖 FASE 18 — AUTOMAÇÕES

# Implementar

* Regras automáticas
* Gatilhos
* Workflows
* Notificações
* Integrações

---

# 🧠 FASE 19 — INTELIGÊNCIA OPERACIONAL

# Futuro

* IA para análise de sprint
* IA para previsão de atrasos
* IA para análise de produtividade
* IA para priorização automática

---

# 📦 FASE 20 — DEPLOY

# Produção DEVE possuir

* SSL
* CDN
* Cache
* Backup
* Monitoring
* Firewall
* Proteção DDoS

---

# 🏁 CHECKLIST FINAL

# Backend

* [ ] API funcional
* [ ] Segurança validada
* [ ] Testes OK
* [ ] Performance OK

# Frontend

* [ ] Responsivo
* [ ] Dark mode
* [ ] UX validada

# Infra

* [ ] Docker OK
* [ ] CI/CD OK
* [ ] Monitoring OK

# Produto

* [ ] MVP validado
* [ ] Sem bugs críticos
* [ ] Deploy realizado

---

# 📌 PADRÕES OBRIGATÓRIOS

# Código

* SOLID
* Clean Code
* DDD
* Clean Architecture

# Git

* Git Flow
* Conventional Commits

# Segurança

* OWASP

# API

* RESTful
* OpenAPI

---

# 📌 META FINAL

Criar uma plataforma SaaS profissional, escalável e enterprise-ready para gerenciamento de projetos, métodos ágeis, gestão operacional e gestão de configuração.

O sistema deve suportar:

* Escalabilidade horizontal
* Multiempresa
* Realtime
* Alta performance
* DevOps
* Observabilidade
* Segurança enterprise
* Integrações futuras
* Inteligência artificial

```
```
