# Integração de Pagamentos — Gestão Ágil SaaS

Sistema usa **PagBank** (principal) + **Stripe** (alternativo) + **PIX Manual** (fallback).
Backend: Supabase Edge Functions (Deno). Frontend: Nuxt 3 / Vue.js.

> ⚠️ Este doc é específico para GESTAO_PROJTOS_VUE.
> A tabela de config aqui é `configuracoes_pagamentos` (singleton), diferente do projeto Bingo Show que usa `configuracoes` com `admin_id`.

---

## Índice

1. [Arquitetura Geral](#1-arquitetura-geral)
2. [Tabelas no Banco de Dados](#2-tabelas-no-banco-de-dados)
3. [Edge Functions](#3-edge-functions)
4. [PagBank — PIX e Cartão](#4-pagbank--pix-e-cartão)
5. [Stripe — Cartão de Crédito](#5-stripe--cartão-de-crédito)
6. [PIX Manual — Fallback](#6-pix-manual--fallback)
7. [Webhooks](#7-webhooks)
8. [Cálculo de Taxas](#8-cálculo-de-taxas)
9. [Status de Pagamento](#9-status-de-pagamento)
10. [Mock Local](#10-mock-local)
11. [Problemas Conhecidos / Bugs Corrigidos](#11-problemas-conhecidos--bugs-corrigidos)
12. [Checklist de Implementação](#12-checklist-de-implementação)

---

## 1. Arquitetura Geral

```
┌─────────────────┐   functions.invoke   ┌──────────────────────────────┐
│  assinar.vue    │ ──────────────────►  │  create-pagbank-payment      │
│  usePagamento   │                      │  create-stripe-session       │
│                 │ ◄──────────────────  └──────────────┬───────────────┘
│                 │  qr_code /                          │ POST
└─────────────────┘  checkout_link                     ▼
        │                               ┌──────────────────────────┐
        │ poll pagbank_payments         │  PagBank API             │
        └──────────────────────────►    │  Stripe API              │
                                        └──────────────┬───────────┘
                                                       │ webhook
                                                       ▼
                                        ┌──────────────────────────┐
                                        │  pagbank-webhook         │
                                        │  stripe-webhook          │
                                        │  (atualiza status,       │
                                        │   ativa plano)           │
                                        └──────────────────────────┘
```

**Fluxo:**
1. Usuário em `/assinar?plano_id=X` clica PIX ou Cartão
2. `usePagamento.ts` chama Edge Function via `supabase.functions.invoke()`
3. Edge Function lê config em `configuracoes_pagamentos`, chama API PagBank/Stripe
4. Retorna QR Code (PIX) ou link de checkout (Cartão)
5. Usuário paga
6. Gateway envia webhook → Edge Function atualiza `pagbank_payments.status`
7. Frontend faz polling em `pagbank_payments` e redireciona ao sucesso

---

## 2. Tabelas no Banco de Dados

### `configuracoes_pagamentos` (singleton — 1 linha)

```sql
pagbank_enabled               boolean   DEFAULT false
pagbank_env                   text      DEFAULT 'sandbox'   -- 'sandbox' | 'producao'
pagbank_token_sandbox         text      DEFAULT ''
pagbank_token_producao        text      DEFAULT ''
pagbank_pass_fees_to_customer boolean   DEFAULT false
pagbank_pix_fee_fixed         numeric   DEFAULT 0.99
pagbank_pix_fee_percentage    numeric   DEFAULT 0
pagbank_card_fee_fixed        numeric   DEFAULT 0.39
pagbank_card_fee_percentage   numeric   DEFAULT 4.99
stripe_enabled                boolean   DEFAULT false
stripe_env                    text      DEFAULT 'test'      -- 'test' | 'live'
stripe_secret_key             text      DEFAULT ''
stripe_secret_key_test        text      DEFAULT ''
stripe_webhook_secret         text      DEFAULT ''
stripe_webhook_secret_test    text      DEFAULT ''
stripe_pass_fees_to_customer  boolean   DEFAULT false
stripe_fee_percentage         numeric   DEFAULT 3.99
stripe_fee_fixed              numeric   DEFAULT 0.39
pix_key                       text      DEFAULT ''
pix_name                      text      DEFAULT ''
pix_city                      text      DEFAULT ''
```

> RLS: somente `develop_admin` lê/edita. Edge Functions usam `service_role` (bypassa RLS).

### `config_gateways_publico` (view — sem tokens)

View `SECURITY DEFINER` exposta para usuários autenticados e anon.
Campos: apenas os não-sensíveis (enabled, env, taxas, pix_key/name/city).
Usada pelo `usePagamento.ts` → `carregarGateways()`.

### `pagbank_payments`

```sql
org_id           uuid  → organizacoes.id
plano_id         uuid  → planos.id
pagbank_order_id text  UNIQUE
reference_id     text
status           text  DEFAULT 'PENDING'   -- PENDING | PAID | COMPLETED | AUTHORIZED
amount           numeric
payment_method   text                      -- 'pix' | 'CREDIT_CARD'
qr_code          text
qr_code_text     text
checkout_link    text
criado_em        timestamptz
atualizado_em    timestamptz
```

### `stripe_payments`

```sql
org_id            uuid  → organizacoes.id
plano_id          uuid  → planos.id
stripe_session_id text  UNIQUE
status            text  DEFAULT 'pending'
amount            numeric
checkout_url      text
criado_em         timestamptz
```

---

## 3. Edge Functions

Caminho: `supabase/functions/`

| Função | Método | Descrição |
|--------|--------|-----------|
| `create-pagbank-payment` | POST | Cria PIX ou checkout PagBank |
| `create-stripe-session` | POST | Cria sessão Stripe |
| `pagbank-webhook` | POST | Notificações PagBank (não chamar manualmente) |
| `stripe-webhook` | POST | Notificações Stripe (não chamar manualmente) |

### Payload para `create-pagbank-payment`

```typescript
// PIX
{
  org_id: 'uuid',
  plano_id: 'uuid',        // opcional
  amount: 49.90,           // valor em reais
  payment_method: 'pix',
  metadata: {
    cpf: '65798015220',    // CPF limpo (só dígitos) — obrigatório PagBank
    telefone: '11999999999'
  }
}

// Cartão
{
  org_id: 'uuid',
  plano_id: 'uuid',
  amount: 49.90,
  payment_method: 'CREDIT_CARD',
  metadata: { cpf: '...', telefone: '...' }
}
```

### Resposta da Edge Function

```typescript
// Sucesso PIX
{
  success: true,
  qr_code: 'https://sandbox.api.pagseguro.com/...png',
  qr_code_text: '00020126580014br.gov.bcb.pix...',
  checkout_link: null,
  order_id: 'ORDE_XXXXXXXXXX'
}

// Sucesso Cartão
{
  success: true,
  qr_code: null,
  qr_code_text: null,
  checkout_link: 'https://pagbank.uol.com.br/checkout/...',
  order_id: 'CHKT_XXXXXXXXXX'
}

// Erro (sempre status 200 — ler data.error)
{
  success: false,
  error: 'PagBank não está habilitado'
}
```

> ⚠️ **CRÍTICO**: Edge Function sempre retorna `status: 200`, mesmo em erro.
> Se retornar `status: 400`, o cliente Supabase descarta o body e a mensagem de erro some.
> O front lê `data.success` e `data.error`, nunca o status HTTP.

---

## 4. PagBank — PIX e Cartão

### URLs da API

| Ambiente | URL |
|----------|-----|
| Sandbox  | `https://sandbox.api.pagseguro.com` |
| Produção | `https://api.pagseguro.com` |

Header obrigatório: `x-api-version: 4.0`

### PIX — endpoint `/orders`

```json
{
  "reference_id": "SUB_abc12345_1748390400000",
  "customer": {
    "name": "João Silva",
    "email": "joao@email.com",
    "tax_id": "65798015220"
  },
  "items": [{ "name": "Assinatura Gestão Ágil", "quantity": 1, "unit_amount": 4990 }],
  "qr_codes": [{
    "amount": { "value": 4990 },
    "expiration_date": "2026-05-29T20:00:00Z"
  }],
  "notification_urls": ["https://<projeto>.supabase.co/functions/v1/pagbank-webhook"]
}
```

### Cartão — endpoint `/checkouts`

```json
{
  "reference_id": "SUB_abc12345_1748390400000",
  "expiration_date": "2026-06-04T20:00:00Z",
  "customer": {
    "name": "João Silva",
    "email": "joao@email.com",
    "tax_id": "65798015220",
    "phones": [{ "country": "55", "area": "11", "number": "999999999", "type": "MOBILE" }]
  },
  "items": [{ "reference_id": "ITEM_SUB_...", "name": "Assinatura Gestão Ágil", "quantity": 1, "unit_amount": 4990 }],
  "notification_urls": ["https://<projeto>.supabase.co/functions/v1/pagbank-webhook"]
}
```

### Exigências PagBank

- CPF/CNPJ: 11 ou 14 dígitos, matematicamente válido
- Nome: mínimo 2 palavras (código adiciona " Cliente" se necessário)
- Valor: em centavos (inteiro)
- `expiration_date`: `.toISOString().split('.')[0] + 'Z'` (sem milissegundos)

### Atenção: Conta PagBank

- Token sandbox vem de `dev.pagbank.com.br` → Tokens
- Token sandbox exige **whitelist de IP** em `sandbox.pagseguro.uol.com.br`
- Conta sandbox precisa ter perfil de **vendedor** ativo para usar Orders API
- Erro `merchant account required` = conta sem perfil vendedor
- Erro `whitelist access required` = IP não liberado no sandbox

### Como a Edge Function busca dados do usuário

```typescript
// CORRETO — buscar org e usuário separadamente
const { data: org } = await admin.from('organizacoes').select('nome').eq('id', org_id).single()
const { data: usuarioDB } = await admin.from('usuarios').select('nome, email').eq('id', user.id).single()

// ERRADO — join via FK não funciona (dono_id aponta para auth.users, não public.usuarios)
// .select('nome, dono:usuarios!organizacoes_dono_id_fkey(nome, email)')  // ← NUNCA FAZER
```

---

## 5. Stripe — Cartão de Crédito

### Payload para `create-stripe-session`

```typescript
{
  org_id: 'uuid',
  plano_id: 'uuid',
  amount: 49.90
}
```

### Resposta

```typescript
{ url: 'https://checkout.stripe.com/c/pay/cs_test_...' }
// Frontend redireciona: window.location.href = data.url
```

### Retorno após checkout

- Sucesso: `/assinar?plano_id=X&payment=success`
- Cancelamento: `/assinar?plano_id=X&payment=cancel`

---

## 6. PIX Manual — Fallback

Sem Edge Function. Frontend lê da view `config_gateways_publico`:

```typescript
const { data } = await cliente.from('config_gateways_publico').select('pix_key, pix_name, pix_city').single()
```

Usuário copia a chave e paga manualmente. Ativação manual pelo admin.

---

## 7. Webhooks

```
PagBank:  https://<projeto>.supabase.co/functions/v1/pagbank-webhook
Stripe:   https://<projeto>.supabase.co/functions/v1/stripe-webhook
```

> Em desenvolvimento local: `notification_urls` apontará para `http://kong:8000/...`
> PagBank não consegue chamar esse endereço — usar ngrok para testes de webhook locais.

### PagBank Webhook

Status reconhecidos como pagos: `PAID`, `COMPLETED`, `AUTHORIZED`

Ao receber pagamento confirmado:
1. Atualiza `pagbank_payments.status = 'PAID'`
2. Atualiza `organizacoes.plano_id` com o plano pago
3. Atualiza `organizacoes.status = 'ativo'` e `vencimento`

---

## 8. Cálculo de Taxas

```typescript
// Se pass_fees_to_customer = true
function calcularTaxa(valor: number, fixo: number, pct: number): number {
  if (!fixo && !pct) return valor
  return Math.ceil(((valor + fixo) / (1 - pct / 100)) * 100) / 100
}
```

Frontend calcula para exibição. Backend recalcula do zero (nunca confiar no valor do cliente).

---

## 9. Status de Pagamento

### `pagbank_payments.status`

| Status | Descrição |
|--------|-----------|
| `PENDING` | Aguardando pagamento |
| `PAID` | Pago |
| `COMPLETED` | Concluído |
| `AUTHORIZED` | Autorizado (cartão) |

### Simular pagamento localmente (mock)

```sql
UPDATE pagbank_payments
SET status = 'PAID'
WHERE status = 'PENDING'
ORDER BY criado_em DESC
LIMIT 1;
```

---

## 10. Mock Local

Edge Function detecta ambiente local e bypassa PagBank:

```typescript
const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
if (supabaseUrl.includes('127.0.0.1') || supabaseUrl.includes('localhost')) {
  // retorna QR Code fake, salva em pagbank_payments com status PENDING
  // simular pagamento via SQL: UPDATE pagbank_payments SET status = 'PAID' ...
}
```

Ativo automaticamente em `supabase start` local. Desativado em produção.

---

## 11. Problemas Conhecidos / Bugs Corrigidos

### Bug 1 — Join organizacoes→usuarios retorna erro (causa raiz do 400)

`dono_id` em `organizacoes` referencia `auth.users`, não `public.usuarios`.
Tentar join PostgREST com FK name retorna erro silencioso → `data = null` → throw.

```typescript
// ERRADO — FK não existe para public.usuarios
.select('nome, email_contato, dono:usuarios!organizacoes_dono_usuarios_fkey(nome, email)')

// CORRETO
.select('nome')  // org separado
// + buscar usuário por: admin.from('usuarios').select('nome, email').eq('id', user.id).single()
```

### Bug 2 — Campo `email_contato` não existe em `organizacoes`

Tabela `organizacoes` não tem `email_contato`. Usar `usuarioDB.email` ou `user.email`.

### Bug 3 — `expiration_date` quebra quando ms ≠ 000

```typescript
// ERRADO
new Date().toISOString().replace('.000Z', 'Z')   // falha se ms=123

// CORRETO
new Date().toISOString().split('.')[0] + 'Z'
```

### Bug 4 — Edge Function retornando status 400

Supabase client descarta body quando status ≠ 2xx. A mensagem de erro some.
Catch block deve retornar `status: 200` com `{ success: false, error: msg }`.

### Bug 5 — `max_usuarios` ausente no schema (migration 0040 não aplicada)

Migration `0040_planos_trial_usuarios.sql` foi pulada no remoto.
`0057` corrigiu `dias_trial` mas não `max_usuarios`.
Criada `0058_fix_max_usuarios.sql` para corrigir.

---

## 12. Checklist de Implementação

### Banco
- [x] `configuracoes_pagamentos` (singleton)
- [x] `config_gateways_publico` (view pública sem tokens)
- [x] `pagbank_payments` (org_id + plano_id)
- [x] `stripe_payments` (org_id + plano_id)

### Edge Functions
- [x] `create-pagbank-payment/index.ts`
- [x] `create-stripe-session/index.ts`
- [x] `pagbank-webhook/index.ts`
- [x] `stripe-webhook/index.ts`

### PagBank Sandbox
- [ ] Ativar perfil vendedor na conta sandbox
- [ ] Liberar IP em sandbox.pagseguro.uol.com.br
- [ ] Testar PIX e retornar QR Code real

### PagBank Produção
- [ ] Token direto da conta (não OAuth) em: minhaconta.pagseguro.uol.com.br → Vendas Online → Token
- [ ] Conta PJ com API ativada
- [ ] Configurar webhook URL de produção

### Frontend Vue.js
- [x] `composables/usePagamento.ts`
- [x] `composables/usePagamentosConfig.ts`
- [x] `paginas/assinar.vue`
- [x] Mock local funcionando
- [ ] Webhook ativando plano após pagamento confirmado
