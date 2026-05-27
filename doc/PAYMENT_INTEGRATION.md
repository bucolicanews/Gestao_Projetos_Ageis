# Tarefas
## 1 Criar o Papel ( Develope_Admin)
-- esse sou eu o dono do sistema
## 2 Develop_Admin tem acesso a tudo.
## 3 Develop_Admin pode criar :
### Dasheboarde financeiro
### Controle das organizações
### Hook de envio de notificação para o celular da organização informando ( que ira vencer,dia do  vencimento, após o verncimento)
### Painel de edição de envio das mensagens
### Hook de resposta para confimar o envio
### Controle dos planos de forma a criar editar e deletar planos com titulos descrição imagem etc..
### Cagina de venda e pagina de apresentação do sistema
### Implantação dos métodos de pagamento


# Integração de Pagamentos — Guia Completo

Sistema usa **PagBank** (principal) + **Stripe** (alternativo) + **PIX Manual** (fallback).
Backend: Supabase Edge Functions (Deno). Frontend atual: React. Alvo novo: Vue.js.

---

## Índice

1. [Arquitetura Geral](#1-arquitetura-geral)
2. [Configurações no Banco de Dados](#2-configurações-no-banco-de-dados)
3. [Edge Functions — Backend](#3-edge-functions--backend)
4. [PagBank — PIX e Cartão de Crédito](#4-pagbank--pix-e-cartão-de-crédito)
5. [Stripe — Cartão de Crédito](#5-stripe--cartão-de-crédito)
6. [PIX Manual — Fallback](#6-pix-manual--fallback)
7. [Webhooks](#7-webhooks)
8. [Cálculo de Taxas](#8-cálculo-de-taxas)
9. [Tipos de Pagamento (payment_type)](#9-tipos-de-pagamento-payment_type)
10. [Implementação Vue.js](#10-implementação-vuejs)
11. [Segurança](#11-segurança)
12. [Status de Pagamento](#12-status-de-pagamento)
13. [Variáveis de Ambiente](#13-variáveis-de-ambiente)
14. [Checklist de Implementação](#14-checklist-de-implementação)

---

## 1. Arquitetura Geral

```
┌─────────────┐     invoke      ┌──────────────────────────────────┐
│  Frontend   │ ──────────────► │  Supabase Edge Function          │
│  (Vue.js)   │                 │  create-pagbank-payment          │
│             │ ◄────────────── │  create-stripe-session           │
│             │  qr_code /      └──────────────┬───────────────────┘
│             │  checkout_link                 │ POST API
└─────────────┘                                ▼
       │                         ┌─────────────────────────┐
       │ redirect                │  PagBank API /          │
       └──────────────────────►  │  Stripe API             │
                                 └──────────────┬──────────┘
                                                │ webhook
                                                ▼
                                 ┌─────────────────────────┐
                                 │  pagbank-webhook /      │
                                 │  stripe-webhook         │
                                 │  (libera créditos,      │
                                 │   atualiza status)      │
                                 └─────────────────────────┘
```

**Fluxo resumido:**
1. Usuário clica "Pagar" no frontend
2. Frontend chama Edge Function via `supabase.functions.invoke()`
3. Edge Function busca config no banco, calcula taxas, chama API do gateway
4. Retorna QR Code (PIX) ou link de checkout (Cartão)
5. Usuário paga
6. Gateway envia webhook para Edge Function
7. Webhook libera créditos / atualiza status no banco

---

## 2. Configurações no Banco de Dados

Tabela `configuracoes` (1 linha por admin — multi-tenant):

```sql
-- PagBank
pagbank_enabled          BOOLEAN    DEFAULT false
pagbank_env              TEXT       DEFAULT 'sandbox'  -- 'sandbox' | 'producao'
pagbank_token_sandbox    TEXT
pagbank_token_producao   TEXT
pagbank_pass_fees_to_customer  BOOLEAN  DEFAULT false
pagbank_pix_fee_fixed    NUMERIC    DEFAULT 0.99   -- R$ fixo por transação PIX
pagbank_pix_fee_percentage  NUMERIC  DEFAULT 0     -- % sobre o valor PIX
pagbank_card_fee_fixed   NUMERIC    DEFAULT 0.39   -- R$ fixo por transação Cartão
pagbank_card_fee_percentage  NUMERIC  DEFAULT 4.99 -- % sobre o valor Cartão

-- Stripe
stripe_enabled           BOOLEAN    DEFAULT false
stripe_env               TEXT       DEFAULT 'test'  -- 'test' | 'live'
stripe_secret_key        TEXT       -- chave live
stripe_secret_key_test   TEXT       -- chave test
stripe_webhook_secret    TEXT       -- webhook live
stripe_webhook_secret_test  TEXT    -- webhook test
stripe_pass_fees_to_customer  BOOLEAN  DEFAULT false
stripe_fee_percentage    NUMERIC    DEFAULT 3.99
stripe_fee_fixed         NUMERIC    DEFAULT 0.39

-- PIX Manual
pix_key                  TEXT       -- chave PIX do admin
pix_name                 TEXT       DEFAULT 'BINGO SHOW'
pix_city                 TEXT       DEFAULT 'SAO PAULO'

-- Sistema
admin_id                 UUID
admin_profit             NUMERIC    DEFAULT 0
comissao_vendedor_global  NUMERIC   DEFAULT 0  -- % comissão global
valor_por_credito        NUMERIC    DEFAULT 1  -- R$ por crédito
```

**IMPORTANTE:** Tokens/chaves nunca vão para o frontend. Ficam no banco e são usados só no backend.

---

## 3. Edge Functions — Backend

Base URL: `https://<seu-projeto>.supabase.co/functions/v1/`

| Função | Método | Descrição |
|--------|--------|-----------|
| `create-pagbank-payment` | POST | Cria PIX ou link de checkout PagBank |
| `create-stripe-session` | POST | Cria sessão de checkout Stripe |
| `pagbank-webhook` | POST | Recebe notificações do PagBank (não chamar manualmente) |
| `stripe-webhook` | POST | Recebe notificações do Stripe (não chamar manualmente) |

### Como invocar via Supabase Client

```javascript
// Vue.js — usando @supabase/supabase-js
const { data, error } = await supabase.functions.invoke('create-pagbank-payment', {
  body: {
    amount: 50.00,
    type: 'credits',
    payment_method: 'pix',  // 'pix' | 'CREDIT_CARD'
    admin_id: 'uuid-do-admin',  // opcional em single-tenant
    metadata: {
      credits_requested: 50,
      customer_cpf: '12345678901',
      cliente_nome: 'João Silva',
      cliente_telefone: '11999999999'
    }
  }
})
```

---

## 4. PagBank — PIX e Cartão de Crédito

### 4.1 URLs da API PagBank

| Ambiente | URL |
|----------|-----|
| Sandbox  | `https://sandbox.api.pagseguro.com` |
| Produção | `https://api.pagseguro.com` |

API Version: `4.0` (header: `x-api-version: 4.0`)

### 4.2 Payload para chamar a Edge Function

```javascript
// PIX
const payload = {
  amount: 50.00,               // valor em reais (sem taxas)
  type: 'credits',             // 'credits' | 'venda_bingo' | 'venda_rifa'
  payment_method: 'pix',       // OBRIGATÓRIO: 'pix'
  admin_id: 'uuid-do-admin',   // para multi-tenant
  metadata: {
    credits_requested: 50,     // para type='credits'
    customer_cpf: '12345678901',   // CPF sem pontuação (OBRIGATÓRIO pelo PagBank)
    cliente_nome: 'João Silva',
    cliente_telefone: '11999999999',
    venda_id: 'uuid-da-venda'  // para type='venda_bingo' ou 'venda_rifa'
  }
}

// Cartão de Crédito
const payload = {
  amount: 50.00,
  type: 'credits',
  payment_method: 'CREDIT_CARD',  // OBRIGATÓRIO: 'CREDIT_CARD'
  admin_id: 'uuid-do-admin',
  metadata: { /* igual ao PIX */ }
}
```

### 4.3 Resposta da Edge Function

```javascript
// PIX — sucesso
{
  success: true,
  qr_code: "https://sandbox.api.pagseguro.com/...png",  // imagem do QR Code
  qr_code_text: "00020126580014br.gov.bcb.pix...",       // código copia e cola
  checkout_link: null,
  order_id: "ORDE_XXXXXXXXXX"
}

// Cartão — sucesso
{
  success: true,
  qr_code: null,
  qr_code_text: null,
  checkout_link: "https://pagbank.uol.com.br/checkout/...",  // redirecionar usuário
  order_id: "CHKT_XXXXXXXXXX"
}

// Erro
{
  success: false,
  error: "CPF_REQUIRED: O Banco exige um CPF ou CNPJ válido matematicamente."
}
```

### 4.4 Payload real enviado ao PagBank — PIX (Orders API)

```javascript
// POST /orders
{
  reference_id: "CREDITS_1748390400000_123",  // gerado: TYPE_timestamp_random
  customer: {
    name: "João Silva Cliente",   // mín. 2 palavras
    email: "joao@email.com",
    tax_id: "12345678901"         // CPF sem pontuação (11 dígitos) ou CNPJ (14)
  },
  items: [{
    name: "Créditos Bingo Show",
    quantity: 1,
    unit_amount: 5000             // valor em centavos
  }],
  qr_codes: [{
    amount: { value: 5000 },
    expiration_date: "2024-01-02T00:00:00Z"  // +24h
  }],
  notification_urls: ["https://<projeto>.supabase.co/functions/v1/pagbank-webhook"]
}
```

### 4.5 Payload real enviado ao PagBank — Cartão (Checkouts API)

```javascript
// POST /checkouts
{
  reference_id: "CREDITS_1748390400000_123",
  expiration_date: "2024-01-08T00:00:00Z",  // +7 dias
  customer: {
    name: "João Silva Cliente",
    email: "joao@email.com",
    tax_id: "12345678901",
    phones: [{
      country: "55",
      area: "11",
      number: "999999999",
      type: "MOBILE"
    }]
  },
  items: [{
    reference_id: "ITEM_CREDITS_1748390400000_123",
    name: "Créditos Bingo Show",
    quantity: 1,
    unit_amount: 5000
  }],
  notification_urls: ["https://<projeto>.supabase.co/functions/v1/pagbank-webhook"]
}
```

### 4.6 Exigências obrigatórias do PagBank

- **CPF/CNPJ**: 11 ou 14 dígitos numéricos, matematicamente válido
- **Nome**: mínimo 2 palavras (código adiciona " Cliente" se necessário)
- **Valor**: em centavos (inteiro)
- **Token**: no header `Authorization: Bearer <token>`

---

## 5. Stripe — Cartão de Crédito

### 5.1 Payload para chamar a Edge Function

```javascript
const payload = {
  amount: 50.00,      // valor em reais
  type: 'credits',    // 'credits' | 'venda_bingo' | 'venda_rifa'
  metadata: {
    credits_requested: 50,
    venda_id: 'uuid',     // para venda_bingo/venda_rifa
    codigo: 'ABC123'      // código da cartela (para redirect)
  }
}

const { data, error } = await supabase.functions.invoke('create-stripe-session', {
  body: payload
})
// data.url — redirecionar usuário para este URL
```

### 5.2 Resposta da Edge Function

```javascript
// Sucesso
{ url: "https://checkout.stripe.com/c/pay/cs_test_..." }

// Erro
{ error: "Usuário não autenticado para compra de créditos." }
```

### 5.3 Sessão Stripe criada (internamente)

```javascript
stripe.checkout.sessions.create({
  payment_method_types: ['card'],
  line_items: [{
    price_data: {
      currency: 'brl',
      product_data: { name: 'Créditos Bingo Show' },
      unit_amount: 5000  // centavos
    },
    quantity: 1
  }],
  mode: 'payment',
  success_url: `${origin}/?payment=success`,
  cancel_url: `${origin}/?payment=cancel`,
  customer_email: 'usuario@email.com',
  client_reference_id: 'user-uuid',
  metadata: {
    user_id: 'user-uuid',
    payment_type: 'credits',
    original_amount: 50,
    credits_requested: 50
  }
})
```

### 5.4 Redirect após pagamento Stripe

Usuário retorna para:
- Sucesso: `<origin>/?payment=success`
- Cancelamento: `<origin>/?payment=cancel`
- Para cartelas: `<origin>/pagar-cartela?codigo=XXX&payment=success`

---

## 6. PIX Manual — Fallback

Não precisa de Edge Function. Dados buscados direto do banco.

```javascript
// Buscar configuração PIX manual
const { data: config } = await supabase
  .from('configuracoes')
  .select('pix_key, pix_name, pix_city')
  .single()

// config.pix_key   → chave PIX (ex: email, CPF, aleatória)
// config.pix_name  → nome do recebedor
// config.pix_city  → cidade do recebedor
```

Usuário copia a chave e paga manualmente. Admin aprova depois via painel.
Upload de comprovante → `solicitacoes_credito` com `status: 'pending'`.

---

## 7. Webhooks

### 7.1 URL dos Webhooks

```
PagBank:  https://<projeto>.supabase.co/functions/v1/pagbank-webhook
Stripe:   https://<projeto>.supabase.co/functions/v1/stripe-webhook
```

Configurar na dashboard de cada gateway.

### 7.2 PagBank Webhook

**Eventos recebidos:** mudança de status do order/charge.

**Payload recebido (simplificado):**
```json
{
  "charges": [{
    "id": "CHAR_XXXXXXXXXX",
    "reference_id": "CREDITS_1748390400000_123",
    "status": "PAID",
    "amount": { "value": 5000, "summary": { "total": 5000 } },
    "payment_response": { "code": "20000", "message": "SUCESSO" }
  }]
}
```

**Status reconhecidos como pagos:** `PAID`, `COMPLETED`, `AUTHORIZED`

**Ações ao receber pagamento confirmado:**
1. Marca `pagbank_payments` como `PAID` (idempotência)
2. Se `payment_type === 'credits'`: adiciona créditos em `perfis.credits`
3. Se `payment_type === 'venda_bingo'`: atualiza `vendas_bingo_fisico.status = 'pago'`
4. Se `payment_type === 'venda_rifa'`: atualiza `compras_rifa.status = 'pago'`
5. Cria registro em `solicitacoes_credito`
6. Calcula e distribui comissão de vendedor
7. Atualiza `admin_profit`

### 7.3 Stripe Webhook

**Eventos:** `checkout.session.completed`, `checkout.session.async_payment_succeeded`

**Verificação de assinatura (obrigatória):**
```javascript
const event = await stripe.webhooks.constructEventAsync(
  rawBody,          // texto bruto (não parsear antes!)
  signature,        // header 'stripe-signature'
  webhookSecret     // do banco de dados
)
```

**Ações idênticas ao PagBank** (créditos, bingo, rifa, comissão, lucro admin).

**Idempotência:** verifica `stripe_payments` por `stripe_session_id` antes de processar.

---

## 8. Cálculo de Taxas

Taxa pode ser repassada ao cliente (admin configura). Fórmula:

```javascript
// Se pagbank_pass_fees_to_customer === true
function calcularValorFinal(amount, feeFixed, feePercentage) {
  // feeFixed: valor fixo em R$ (ex: 0.99)
  // feePercentage: percentual (ex: 3.99 para 3.99%)
  const finalAmount = (amount + feeFixed) / (1 - (feePercentage / 100))
  return Math.ceil(finalAmount * 100) / 100  // arredonda para cima
}

// Exemplos com taxas padrão:
// PIX: feeFixed=0.99, feePercentage=0
// Cartão PagBank: feeFixed=0.39, feePercentage=4.99
// Stripe: feeFixed=0.39, feePercentage=3.99
```

**IMPORTANTE:** Frontend calcula taxa só para exibição (UX). Backend recalcula do zero para evitar manipulação de preço.

### Buscar configuração de taxas no frontend

```javascript
const { data: settings } = await supabase
  .from('configuracoes')
  .select(`
    pagbank_enabled, pagbank_env,
    pagbank_pass_fees_to_customer,
    pagbank_pix_fee_fixed, pagbank_pix_fee_percentage,
    pagbank_card_fee_fixed, pagbank_card_fee_percentage,
    stripe_enabled, stripe_env,
    stripe_pass_fees_to_customer,
    stripe_fee_fixed, stripe_fee_percentage,
    pix_key, pix_name, pix_city,
    valor_por_credito
  `)
  .single()
```

---

## 9. Tipos de Pagamento (payment_type)

| Valor | Descrição | Ação no webhook |
|-------|-----------|-----------------|
| `credits` | Compra de créditos virtuais | Adiciona créditos em `perfis.credits` |
| `venda_bingo` | Pagamento de cartela bingo físico | Atualiza `vendas_bingo_fisico.status = 'pago'` |
| `venda_rifa` | Compra de rifa | Atualiza `compras_rifa.status = 'pago'` |

---

## 10. Implementação Vue.js

### 10.1 Setup inicial

```bash
npm install @supabase/supabase-js
```

```javascript
// src/lib/supabase.js
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)
```

### 10.2 Composable de pagamento

```javascript
// src/composables/usePayment.js
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export function usePayment() {
  const loading = ref(false)
  const error = ref(null)

  // Busca configurações do gateway
  async function fetchPaymentSettings(adminId = null) {
    let query = supabase.from('configuracoes').select(`
      pagbank_enabled, pagbank_env,
      pagbank_pass_fees_to_customer,
      pagbank_pix_fee_fixed, pagbank_pix_fee_percentage,
      pagbank_card_fee_fixed, pagbank_card_fee_percentage,
      stripe_enabled, stripe_env,
      stripe_pass_fees_to_customer,
      stripe_fee_fixed, stripe_fee_percentage,
      pix_key, pix_name, pix_city,
      valor_por_credito
    `)
    if (adminId) query = query.eq('admin_id', adminId)
    const { data } = await query.limit(1).single()
    return data
  }

  // Calcula valor com taxa (só para UX — backend recalcula)
  function calcFinalAmount(amount, feeFixed, feePercentage) {
    if (!feeFixed && !feePercentage) return amount
    const final = (amount + Number(feeFixed || 0)) / (1 - (Number(feePercentage || 0) / 100))
    return Math.ceil(final * 100) / 100
  }

  // PIX via PagBank
  async function createPagBankPix({ amount, type, metadata, adminId }) {
    loading.value = true
    error.value = null
    try {
      const { data, error: fnError } = await supabase.functions.invoke('create-pagbank-payment', {
        body: {
          amount,
          type,
          payment_method: 'pix',
          admin_id: adminId,
          metadata
        }
      })
      if (fnError) throw fnError
      if (!data.success) throw new Error(data.error)
      return data  // { qr_code, qr_code_text, order_id }
    } catch (e) {
      error.value = e.message
      return null
    } finally {
      loading.value = false
    }
  }

  // Cartão via PagBank
  async function createPagBankCard({ amount, type, metadata, adminId }) {
    loading.value = true
    error.value = null
    try {
      const { data, error: fnError } = await supabase.functions.invoke('create-pagbank-payment', {
        body: {
          amount,
          type,
          payment_method: 'CREDIT_CARD',
          admin_id: adminId,
          metadata
        }
      })
      if (fnError) throw fnError
      if (!data.success) throw new Error(data.error)
      // Redirecionar para checkout_link
      window.open(data.checkout_link, '_blank')
      return data
    } catch (e) {
      error.value = e.message
      return null
    } finally {
      loading.value = false
    }
  }

  // Cartão via Stripe
  async function createStripeSession({ amount, type, metadata }) {
    loading.value = true
    error.value = null
    try {
      const { data, error: fnError } = await supabase.functions.invoke('create-stripe-session', {
        body: { amount, type, metadata }
      })
      if (fnError) throw fnError
      if (data.error) throw new Error(data.error)
      // Redirecionar para Stripe checkout
      window.location.href = data.url
      return data
    } catch (e) {
      error.value = e.message
      return null
    } finally {
      loading.value = false
    }
  }

  return {
    loading,
    error,
    fetchPaymentSettings,
    calcFinalAmount,
    createPagBankPix,
    createPagBankCard,
    createStripeSession
  }
}
```

### 10.3 Componente de pagamento PIX

```vue
<!-- src/components/PaymentPixDialog.vue -->
<template>
  <div v-if="visible" class="payment-dialog">
    <!-- Seleção de método -->
    <div v-if="!pixData && !stripeLoading">
      <h2>Escolha o método de pagamento</h2>
      
      <!-- Valor com taxa -->
      <p v-if="settings?.pagbank_pass_fees_to_customer">
        Valor com taxa PIX: R$ {{ pixFinalAmount.toFixed(2) }}
      </p>

      <!-- PIX PagBank -->
      <button
        v-if="settings?.pagbank_enabled"
        @click="payWithPix"
        :disabled="loading"
      >
        {{ loading ? 'Gerando PIX...' : 'Pagar com PIX' }}
      </button>

      <!-- Cartão PagBank -->
      <button
        v-if="settings?.pagbank_enabled"
        @click="payWithCard"
        :disabled="loading"
      >
        Pagar com Cartão (PagBank)
      </button>

      <!-- Stripe -->
      <button
        v-if="settings?.stripe_enabled"
        @click="payWithStripe"
        :disabled="loading"
      >
        Pagar com Cartão (Stripe)
      </button>
    </div>

    <!-- QR Code PIX -->
    <div v-if="pixData">
      <h3>Escaneie o QR Code</h3>
      <img :src="pixData.qr_code" alt="QR Code PIX" />
      <p>Ou copie o código:</p>
      <input :value="pixData.qr_code_text" readonly />
      <button @click="copyPixCode">Copiar Código</button>
      <p>Aguardando confirmação do pagamento...</p>
    </div>

    <!-- Erro CPF -->
    <div v-if="needsCpf">
      <input v-model="cpf" placeholder="Digite seu CPF" />
      <button @click="retryCpf">Confirmar</button>
    </div>

    <p v-if="error" class="error">{{ error }}</p>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { usePayment } from '@/composables/usePayment'

const props = defineProps({
  visible: Boolean,
  amount: Number,       // valor em R$
  type: String,         // 'credits' | 'venda_bingo' | 'venda_rifa'
  metadata: Object,     // { credits_requested, venda_id, etc }
  adminId: String
})

const emit = defineEmits(['close', 'success'])

const { loading, error, fetchPaymentSettings, calcFinalAmount,
        createPagBankPix, createPagBankCard, createStripeSession } = usePayment()

const settings = ref(null)
const pixData = ref(null)  // { qr_code, qr_code_text }
const cpf = ref('')
const needsCpf = ref(false)
const stripeLoading = ref(false)

const pixFinalAmount = computed(() => {
  if (!settings.value?.pagbank_pass_fees_to_customer) return props.amount
  return calcFinalAmount(
    props.amount,
    settings.value.pagbank_pix_fee_fixed,
    settings.value.pagbank_pix_fee_percentage
  )
})

onMounted(async () => {
  settings.value = await fetchPaymentSettings(props.adminId)
})

async function payWithPix() {
  const result = await createPagBankPix({
    amount: props.amount,
    type: props.type,
    adminId: props.adminId,
    metadata: {
      ...props.metadata,
      customer_cpf: cpf.value || undefined
    }
  })

  if (result) {
    pixData.value = result
  } else if (error.value?.includes('CPF_REQUIRED')) {
    needsCpf.value = true
    error.value = 'Informe seu CPF para continuar.'
  }
}

async function payWithCard() {
  await createPagBankCard({
    amount: props.amount,
    type: props.type,
    adminId: props.adminId,
    metadata: { ...props.metadata, customer_cpf: cpf.value || undefined }
  })
}

async function payWithStripe() {
  await createStripeSession({
    amount: props.amount,
    type: props.type,
    metadata: props.metadata
  })
}

async function retryCpf() {
  needsCpf.value = false
  await payWithPix()
}

function copyPixCode() {
  navigator.clipboard.writeText(pixData.value.qr_code_text)
}
</script>
```

### 10.4 Detectar retorno do Stripe (success/cancel)

```javascript
// src/router/index.js ou App.vue — ao montar
import { useRoute } from 'vue-router'

const route = useRoute()
const paymentStatus = route.query.payment  // 'success' | 'cancel'

if (paymentStatus === 'success') {
  // Mostrar mensagem de sucesso
  // Recarregar créditos do usuário
}
```

### 10.5 Polling de status PIX (opcional)

```javascript
// Verificar se PIX foi pago — checar tabela pagbank_payments
async function pollPixStatus(orderId, maxAttempts = 20) {
  for (let i = 0; i < maxAttempts; i++) {
    await new Promise(r => setTimeout(r, 5000))  // aguarda 5s
    
    const { data } = await supabase
      .from('pagbank_payments')
      .select('status')
      .eq('pagbank_order_id', orderId)
      .single()

    if (data?.status === 'PAID') {
      return true
    }
  }
  return false
}
```

Ou usar Realtime do Supabase:

```javascript
// Subscribe ao status do pagamento
const channel = supabase
  .channel('payment-status')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'pagbank_payments',
    filter: `pagbank_order_id=eq.${orderId}`
  }, (payload) => {
    if (payload.new.status === 'PAID') {
      emit('success')
    }
  })
  .subscribe()

// Limpar ao desmontar
onUnmounted(() => supabase.removeChannel(channel))
```

---

## 11. Segurança

### Tokens nunca no frontend
- Chaves PagBank/Stripe ficam em `configuracoes` no banco
- Somente Edge Functions acessam (via `SUPABASE_SERVICE_ROLE_KEY`)
- Frontend só usa `SUPABASE_ANON_KEY`

### Cálculo de preço server-side
- Frontend pode calcular taxa para UX/exibição
- Backend recalcula do zero usando config do banco
- Usuário não pode manipular valor final enviado ao gateway

### CPF obrigatório (PagBank)
- Exigência do Banco Central (PIX)
- Validado: 11 dígitos (CPF) ou 14 dígitos (CNPJ)
- Salvo automaticamente no perfil do usuário

### Idempotência nos webhooks
- PagBank: checa `pagbank_payments.status` antes de processar
- Stripe: checa `stripe_payments.stripe_session_id` antes de inserir
- Evita dupla liberação de créditos/produtos

### Verificação de assinatura (Stripe)
- `stripe.webhooks.constructEventAsync()` valida HMAC do payload
- Rejeita requisições não originadas do Stripe

---

## 12. Status de Pagamento

### PagBank (`pagbank_payments.status`)

| Status | Descrição |
|--------|-----------|
| `PENDING` | Aguardando pagamento |
| `WAITING` | Em análise |
| `PAID` | Pago — processado pelo webhook |
| `COMPLETED` | Concluído |
| `AUTHORIZED` | Autorizado (cartão) |

### Stripe (`stripe_payments.status`)

| Status | Descrição |
|--------|-----------|
| `completed` | Pago e processado |

### Créditos/Vendas (`solicitacoes_credito.status`)

| Status | Descrição |
|--------|-----------|
| `pending` | Aguardando aprovação manual |
| `approved` | Aprovado (manual ou automático via webhook) |
| `rejected` | Rejeitado pelo admin |

---

## 13. Variáveis de Ambiente

### Frontend (.env)

```env
VITE_SUPABASE_URL=https://<projeto>.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...  # chave anon pública
```

### Backend (Supabase Edge Functions — configurar no Dashboard)

```
SUPABASE_URL                # automático no Supabase
SUPABASE_SERVICE_ROLE_KEY   # automático no Supabase
SUPABASE_ANON_KEY           # automático no Supabase
```

Tokens PagBank e Stripe **não** são variáveis de ambiente — ficam na tabela `configuracoes`.

---

## 14. Checklist de Implementação

### Banco de Dados
- [ ] Criar tabela `configuracoes` com campos de pagamento
- [ ] Criar tabela `pagbank_payments`
- [ ] Criar tabela `stripe_payments`
- [ ] Criar tabela `solicitacoes_credito`
- [ ] Criar campo `credits` em `perfis` (ou equivalente)

### Edge Functions (copiar do App_Bingo)
- [ ] `create-pagbank-payment/index.ts`
- [ ] `create-stripe-session/index.ts`
- [ ] `pagbank-webhook/index.ts`
- [ ] `stripe-webhook/index.ts`

### Gateway — PagBank
- [ ] Criar conta em sandbox.pagseguro.com.br
- [ ] Gerar token sandbox
- [ ] Configurar URL de notificação: `https://<projeto>.supabase.co/functions/v1/pagbank-webhook`
- [ ] Salvar token em `configuracoes.pagbank_token_sandbox`

### Gateway — Stripe
- [ ] Criar conta em dashboard.stripe.com
- [ ] Copiar chave secreta de teste
- [ ] Criar webhook endpoint apontando para Edge Function
- [ ] Copiar webhook secret
- [ ] Salvar em `configuracoes.stripe_secret_key_test` e `stripe_webhook_secret_test`

### Frontend Vue.js
- [ ] Instalar `@supabase/supabase-js`
- [ ] Criar `src/lib/supabase.js` com cliente configurado
- [ ] Copiar composable `usePayment.js`
- [ ] Criar componente de pagamento
- [ ] Tratar retorno do Stripe (`?payment=success`)
- [ ] Implementar exibição do QR Code PIX
- [ ] Implementar polling ou Realtime para confirmar PIX pago
- [ ] Tratar erro `CPF_REQUIRED` com form de CPF

### Produção
- [ ] Substituir tokens sandbox por produção
- [ ] Alterar `pagbank_env` para `'producao'`
- [ ] Alterar `stripe_env` para `'live'`
- [ ] Atualizar URLs de webhook para produção
