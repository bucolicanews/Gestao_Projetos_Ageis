# Plano — Módulo develop_admin

> Última atualização: 2026-05-27
> Branch ativa: `perm_jhon`
> Stack: Nuxt 3 · Supabase · Tailwind · Pinia

---

## Contexto do Sistema

**Dono:** `develop_admin` — acesso total, papel especial fora da hierarquia de organizações.  
**Sistema atual:** gestão de projetos ágeis (Kanban, Sprints, Backlog, Equipe, Papéis).  
**Objetivo:** adicionar camada SaaS — planos, pagamentos, organizações, notificações.

### Estrutura de pastas (PT-BR)
```
paginas/          → rotas da aplicação
componentes/      → componentes Vue
composables/      → lógica reutilizável (useXxx.ts)
loja/             → stores Pinia
servicos/         → chamadas Supabase isoladas
layouts/          → layouts Nuxt
middleware/       → guards de rota
doc/              → documentação técnica
```

---

## Escopo completo — develop_admin

### FASE 1 — Planos e Infraestrutura (base para tudo)
> Sem planos não há pagamento nem organização.

- [ ] **1.1** Banco: tabela `planos` (id, titulo, descricao, imagem_url, preco, recursos JSON, ativo, criado_em)
- [ ] **1.2** Banco: tabela `organizacoes` (id, nome, plano_id, status, vencimento, admin_id, criado_em)
- [ ] **1.3** Banco: tabela `assinaturas` (id, org_id, plano_id, status, inicio, fim, pagamento_id)
- [ ] **1.4** RLS: `develop_admin` lê/escreve tudo; organizações veem só seus dados
- [ ] **1.5** Página `paginas/develop/planos.vue` — CRUD de planos
- [ ] **1.6** Composable `composables/usePlanos.ts`
- [ ] **1.7** Serviço `servicos/servicoPlanos.ts`

### FASE 2 — Controle de Organizações
- [ ] **2.1** Página `paginas/develop/organizacoes/index.vue` — lista com filtros (status, plano, vencimento)
- [ ] **2.2** Página `paginas/develop/organizacoes/[id].vue` — detalhe + ações
- [ ] **2.3** Composable `composables/useOrganizacoes.ts`
- [ ] **2.4** Serviço `servicos/servicoOrganizacoes.ts`
- [ ] **2.5** Loja `loja/lojaOrganizacoes.ts`

### FASE 3 — Métodos de Pagamento
> Ver `doc/PAYMENT_INTEGRATION.md` para payload completo.

- [ ] **3.1** Banco: tabela `pagbank_payments`, `stripe_payments`, `solicitacoes_credito`
- [ ] **3.2** Banco: campos de pagamento na tabela `configuracoes`
- [ ] **3.3** Edge Functions (copiar do App_Bingo):
  - `create-pagbank-payment/index.ts`
  - `create-stripe-session/index.ts`
  - `pagbank-webhook/index.ts`
  - `stripe-webhook/index.ts`
- [ ] **3.4** Composable `composables/usePagamento.ts` (ver seção 10.2 de PAYMENT_INTEGRATION.md)
- [ ] **3.5** Componente `componentes/PagamentoPixDialog.vue`
- [ ] **3.6** Página `paginas/develop/configuracoes-pagamento.vue` — ativar/configurar gateways
- [ ] **3.7** Tratar retorno Stripe (`?payment=success/cancel`) em App.vue ou middleware

### FASE 4 — Notificações por Celular
> Hook que dispara mensagens para a organização sobre vencimento do plano.

- [ ] **4.1** Banco: tabela `notificacoes_config` (mensagem_iminente, mensagem_dia, mensagem_apos, canal, ativo)
- [ ] **4.2** Banco: tabela `notificacoes_log` (org_id, tipo, enviado_em, status)
- [ ] **4.3** Supabase Edge Function `notificar-vencimentos/index.ts`:
  - Busca organizações com vencimento em X dias / hoje / vencidas
  - Envia via WhatsApp API (ex: Z-API, Evolution API, Twilio)
  - Registra em `notificacoes_log`
- [ ] **4.4** Cron: pg_cron ou Supabase scheduled function — disparo diário
- [ ] **4.5** Composable `composables/useNotificacoes.ts`
- [ ] **4.6** Página `paginas/develop/notificacoes.vue` — painel edição mensagens + histórico
- [ ] **4.7** Componente `componentes/EditorMensagemNotificacao.vue` — editor com variáveis ({nome}, {dias}, {plano})
- [ ] **4.8** Hook de confirmação: webhook de resposta do canal (ex: confirmação de leitura WhatsApp)

### FASE 5 — Dashboard Financeiro
- [ ] **5.1** Página `paginas/develop/financeiro.vue`
- [ ] **5.2** Métricas: MRR, churn, novas assinaturas, vencimentos próximos
- [ ] **5.3** Gráficos: receita por mês, distribuição por plano, status de pagamentos
- [ ] **5.4** Composable `composables/useFinanceiro.ts`
- [ ] **5.5** Reutilizar componentes gráficos existentes (GraficoBurndown, GraficoVelocity como base)

### FASE 6 — Página de Vendas e Landing
- [ ] **6.1** Layout `layouts/publico.vue` — sem auth, sem sidebar
- [ ] **6.2** Rota pública: `paginas/apresentacao.vue` — landing de apresentação
- [ ] **6.3** Rota pública: `paginas/planos.vue` — pricing page com os planos do banco
- [ ] **6.4** Rota pública: `paginas/assinar.vue` — fluxo de cadastro + pagamento
- [ ] **6.5** Atualizar `middleware/auth.global.ts` — liberar rotas públicas

---

## Ordem de implementação recomendada

```
1 → 2 → 3 → 4 → 5 → 6
```

**Por quê essa ordem:**
- Fase 1 (Planos) desbloqueia todas as outras
- Fase 2 (Orgs) depende de planos
- Fase 3 (Pagamentos) depende de planos + orgs
- Fase 4 (Notificações) depende de orgs + assinaturas
- Fase 5 (Financeiro) depende de tudo ter dados
- Fase 6 (Landing) depende de planos + pagamentos

---

## Roteamento develop_admin

```
/develop/                    → redirect → /develop/financeiro
/develop/financeiro          → dashboard financeiro
/develop/organizacoes        → lista de organizações
/develop/organizacoes/[id]   → detalhe de organização
/develop/planos              → CRUD de planos
/develop/notificacoes        → painel notificações
/develop/configuracoes       → config gateways de pagamento

/apresentacao                → landing (público)
/planos                      → pricing page (público)
/assinar                     → checkout (público pré-auth)
```

Middleware a adicionar: verificar `role === 'develop_admin'` para rotas `/develop/*`.

---

## Tabelas a criar no Supabase

```sql
-- Fase 1
CREATE TABLE planos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  descricao text,
  imagem_url text,
  preco numeric(10,2) NOT NULL,
  recursos jsonb DEFAULT '{}',
  ativo boolean DEFAULT true,
  criado_em timestamptz DEFAULT now()
);

CREATE TABLE organizacoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  plano_id uuid REFERENCES planos(id),
  status text DEFAULT 'ativo',  -- ativo | vencido | cancelado | trial
  vencimento date,
  admin_user_id uuid REFERENCES auth.users(id),
  criado_em timestamptz DEFAULT now()
);

CREATE TABLE assinaturas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid REFERENCES organizacoes(id),
  plano_id uuid REFERENCES planos(id),
  status text DEFAULT 'pendente',  -- pendente | ativo | cancelado
  inicio date,
  fim date,
  valor_pago numeric(10,2),
  gateway text,  -- pagbank | stripe | pix_manual
  criado_em timestamptz DEFAULT now()
);

-- Fase 4
CREATE TABLE notificacoes_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mensagem_iminente text,   -- {dias} dias antes
  dias_antes int DEFAULT 7,
  mensagem_dia_vencimento text,
  mensagem_apos_vencimento text,
  canal text DEFAULT 'whatsapp',
  ativo boolean DEFAULT false
);

CREATE TABLE notificacoes_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid REFERENCES organizacoes(id),
  tipo text,  -- iminente | dia | apos
  enviado_em timestamptz DEFAULT now(),
  status text  -- enviado | falhou | confirmado
);
```

---

## Arquivos existentes relevantes

| Arquivo | Relevância |
|---------|------------|
| `middleware/auth.global.ts` | Adicionar guard `/develop/*` |
| `layouts/default.vue` | Adicionar links develop_admin condicionais |
| `composables/useAutenticacao.ts` | Expor `role` do usuário |
| `doc/PAYMENT_INTEGRATION.md` | Implementação completa pagamentos |

---

## Progresso

| Fase | Status | Observações |
|------|--------|-------------|
| 1 — Planos | ✅ Implementado | Migration: `0031_planos.sql` — rodar via `supabase db push` |
| 2 — Organizações | ✅ Implementado | CRUD + bloqueio + mensagem n8n. Migration: 0033 |
| 3 — Pagamentos | ⬜ Não iniciado | Doc em PAYMENT_INTEGRATION.md |
| 4 — Notificações | ✅ Implementado | Histórico + Configurações webhooks + templates. Falta cron automático. |
| 5 — Financeiro | ✅ Implementado (parcial) | Métricas completas após Fase 2+3 |
| 6 — Landing | ⬜ Não iniciado | |

---

## Decisões pendentes

- [x] Canal de notificação: **n8n** (definido pelo usuário)
- [ ] Storage imagens de planos: Supabase Storage bucket `planos`
- [ ] Multi-tenant: cada organização tem seus projetos isolados? (RLS por `org_id`)
- [ ] Trial: quantos dias de trial gratuito?
