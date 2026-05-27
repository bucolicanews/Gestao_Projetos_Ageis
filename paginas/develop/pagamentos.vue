<template>
  <div>
    <div v-if="verificando" class="flex items-center justify-center h-40 text-slate-400">
      Verificando permissões...
    </div>

    <template v-else-if="isDevelopAdmin">
      <!-- Header -->
      <div class="flex justify-between items-center mb-6">
        <div>
          <h1 class="text-2xl font-bold">💳 Métodos de Pagamento</h1>
          <p class="text-sm text-slate-500 mt-0.5">Configure os gateways usados pelas organizações</p>
        </div>
        <button class="botao-primario" :disabled="cfg.salvando.value" @click="salvar">
          {{ cfg.salvando.value ? 'Salvando...' : '💾 Salvar' }}
        </button>
      </div>

      <div v-if="cfg.carregando.value" class="text-slate-400 text-sm py-8 text-center">Carregando...</div>

      <template v-else>
        <div v-if="cfg.sucesso.value" class="mb-4 p-3 bg-green-50 border border-green-100 rounded-xl text-sm text-green-700 flex gap-2 items-center">
          <span>✓</span> Configurações salvas.
        </div>
        <div v-if="cfg.erro.value" class="mb-4 p-3 bg-red-50 border border-red-100 rounded-xl text-sm text-perigo">
          {{ cfg.erro.value }}
        </div>

        <!-- Tabs -->
        <div class="flex gap-1 p-1 bg-slate-100 rounded-xl mb-6 w-fit">
          <button v-for="tab in tabs" :key="tab.id" type="button"
            class="px-4 py-2 rounded-lg text-sm font-medium transition"
            :class="abaAtiva === tab.id ? 'bg-white shadow text-primaria' : 'text-slate-500 hover:text-slate-700'"
            @click="abaAtiva = tab.id">
            {{ tab.label }}
          </button>
        </div>

        <div class="flex flex-col gap-6">

          <!-- ── PagBank ── -->
          <template v-if="abaAtiva === 'pagbank'">
            <div class="cartao">
              <div class="flex items-center justify-between mb-5">
                <div>
                  <h2 class="font-semibold text-base">🏦 PagBank</h2>
                  <p class="text-xs text-slate-400 mt-0.5">PIX + Cartão de crédito via PagBank</p>
                </div>
                <label class="flex items-center gap-2 cursor-pointer select-none">
                  <div class="relative">
                    <input type="checkbox" class="sr-only" v-model="form.pagbank_enabled" />
                    <div class="w-10 h-6 rounded-full transition"
                      :class="form.pagbank_enabled ? 'bg-primaria' : 'bg-slate-200'">
                      <div class="absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-transform"
                        :class="form.pagbank_enabled ? 'translate-x-5' : 'translate-x-1'" />
                    </div>
                  </div>
                  <span class="text-sm font-medium" :class="form.pagbank_enabled ? 'text-primaria' : 'text-slate-400'">
                    {{ form.pagbank_enabled ? 'Habilitado' : 'Desabilitado' }}
                  </span>
                </label>
              </div>

              <div v-if="form.pagbank_enabled" class="flex flex-col gap-5">

                <!-- Ambiente -->
                <div>
                  <label class="text-sm font-semibold text-slate-600 mb-2 block">Ambiente</label>
                  <div class="flex gap-2">
                    <button type="button"
                      class="px-4 py-2 rounded-xl text-sm font-medium border transition"
                      :class="form.pagbank_env === 'sandbox' ? 'bg-amber-50 border-amber-300 text-amber-700' : 'border-slate-200 text-slate-500 hover:border-slate-300'"
                      @click="form.pagbank_env = 'sandbox'">
                      🧪 Sandbox
                    </button>
                    <button type="button"
                      class="px-4 py-2 rounded-xl text-sm font-medium border transition"
                      :class="form.pagbank_env === 'producao' ? 'bg-green-50 border-green-300 text-green-700' : 'border-slate-200 text-slate-500 hover:border-slate-300'"
                      @click="form.pagbank_env = 'producao'">
                      🚀 Produção
                    </button>
                  </div>
                </div>

                <!-- Tokens -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="text-sm font-medium text-slate-700 mb-1 block flex items-center gap-1">
                      <span class="text-amber-500">🧪</span> Token Sandbox
                      <span v-if="form.pagbank_env === 'sandbox'" class="text-[10px] text-amber-600 font-semibold ml-1">● ATIVO</span>
                    </label>
                    <div class="relative">
                      <input
                        v-model="form.pagbank_token_sandbox"
                        :type="mostrar.pagbank_sandbox ? 'text' : 'password'"
                        placeholder="Token sandbox PagBank"
                        class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono pr-10 focus:outline-none focus:ring-2 focus:ring-primaria"
                        :class="form.pagbank_env === 'sandbox' ? 'border-amber-300 bg-amber-50' : ''"
                      />
                      <button type="button" class="absolute right-3 top-2.5 text-slate-400 hover:text-slate-600 text-xs"
                        @click="mostrar.pagbank_sandbox = !mostrar.pagbank_sandbox">
                        {{ mostrar.pagbank_sandbox ? '🙈' : '👁' }}
                      </button>
                    </div>
                  </div>
                  <div>
                    <label class="text-sm font-medium text-slate-700 mb-1 block flex items-center gap-1">
                      <span class="text-green-500">🚀</span> Token Produção
                      <span v-if="form.pagbank_env === 'producao'" class="text-[10px] text-green-600 font-semibold ml-1">● ATIVO</span>
                    </label>
                    <div class="relative">
                      <input
                        v-model="form.pagbank_token_producao"
                        :type="mostrar.pagbank_prod ? 'text' : 'password'"
                        placeholder="Token produção PagBank"
                        class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono pr-10 focus:outline-none focus:ring-2 focus:ring-primaria"
                        :class="form.pagbank_env === 'producao' ? 'border-green-300 bg-green-50' : ''"
                      />
                      <button type="button" class="absolute right-3 top-2.5 text-slate-400 hover:text-slate-600 text-xs"
                        @click="mostrar.pagbank_prod = !mostrar.pagbank_prod">
                        {{ mostrar.pagbank_prod ? '🙈' : '👁' }}
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Taxas -->
                <div class="rounded-xl border border-slate-200 p-4">
                  <div class="flex items-center justify-between mb-4">
                    <p class="font-semibold text-sm text-slate-700">💰 Taxas PagBank</p>
                    <label class="flex items-center gap-2 cursor-pointer select-none text-sm">
                      <div class="relative">
                        <input type="checkbox" class="sr-only" v-model="form.pagbank_pass_fees_to_customer" />
                        <div class="w-8 h-5 rounded-full transition"
                          :class="form.pagbank_pass_fees_to_customer ? 'bg-primaria' : 'bg-slate-200'">
                          <div class="absolute top-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform"
                            :class="form.pagbank_pass_fees_to_customer ? 'translate-x-4' : 'translate-x-0.5'" />
                        </div>
                      </div>
                      <span class="text-slate-600">Repassar ao cliente</span>
                    </label>
                  </div>
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">PIX</p>
                      <div class="flex items-center gap-2">
                        <label class="text-xs text-slate-500 whitespace-nowrap">R$ fixo</label>
                        <input v-model.number="form.pagbank_pix_fee_fixed" type="number" step="0.01" min="0"
                          class="w-20 border border-slate-200 rounded-lg px-2 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                        <label class="text-xs text-slate-500">%</label>
                        <input v-model.number="form.pagbank_pix_fee_percentage" type="number" step="0.01" min="0"
                          class="w-20 border border-slate-200 rounded-lg px-2 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                      </div>
                    </div>
                    <div>
                      <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Cartão</p>
                      <div class="flex items-center gap-2">
                        <label class="text-xs text-slate-500 whitespace-nowrap">R$ fixo</label>
                        <input v-model.number="form.pagbank_card_fee_fixed" type="number" step="0.01" min="0"
                          class="w-20 border border-slate-200 rounded-lg px-2 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                        <label class="text-xs text-slate-500">%</label>
                        <input v-model.number="form.pagbank_card_fee_percentage" type="number" step="0.01" min="0"
                          class="w-20 border border-slate-200 rounded-lg px-2 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                      </div>
                    </div>
                  </div>
                </div>

                <!-- URL webhook info -->
                <div class="rounded-xl bg-slate-50 border border-slate-200 p-4 text-xs text-slate-500">
                  <p class="font-semibold text-slate-600 mb-1">🔔 URL do Webhook PagBank</p>
                  <p class="font-mono break-all">{{ supabaseUrl }}/functions/v1/pagbank-webhook</p>
                  <p class="mt-1">Configure esta URL no painel PagBank em Notificações.</p>
                </div>

              </div>
            </div>
          </template>

          <!-- ── Stripe ── -->
          <template v-if="abaAtiva === 'stripe'">
            <div class="cartao">
              <div class="flex items-center justify-between mb-5">
                <div>
                  <h2 class="font-semibold text-base">💳 Stripe</h2>
                  <p class="text-xs text-slate-400 mt-0.5">Cartão de crédito internacional via Stripe</p>
                </div>
                <label class="flex items-center gap-2 cursor-pointer select-none">
                  <div class="relative">
                    <input type="checkbox" class="sr-only" v-model="form.stripe_enabled" />
                    <div class="w-10 h-6 rounded-full transition"
                      :class="form.stripe_enabled ? 'bg-primaria' : 'bg-slate-200'">
                      <div class="absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-transform"
                        :class="form.stripe_enabled ? 'translate-x-5' : 'translate-x-1'" />
                    </div>
                  </div>
                  <span class="text-sm font-medium" :class="form.stripe_enabled ? 'text-primaria' : 'text-slate-400'">
                    {{ form.stripe_enabled ? 'Habilitado' : 'Desabilitado' }}
                  </span>
                </label>
              </div>

              <div v-if="form.stripe_enabled" class="flex flex-col gap-5">

                <!-- Ambiente -->
                <div>
                  <label class="text-sm font-semibold text-slate-600 mb-2 block">Ambiente</label>
                  <div class="flex gap-2">
                    <button type="button"
                      class="px-4 py-2 rounded-xl text-sm font-medium border transition"
                      :class="form.stripe_env === 'test' ? 'bg-amber-50 border-amber-300 text-amber-700' : 'border-slate-200 text-slate-500 hover:border-slate-300'"
                      @click="form.stripe_env = 'test'">
                      🧪 Test
                    </button>
                    <button type="button"
                      class="px-4 py-2 rounded-xl text-sm font-medium border transition"
                      :class="form.stripe_env === 'live' ? 'bg-green-50 border-green-300 text-green-700' : 'border-slate-200 text-slate-500 hover:border-slate-300'"
                      @click="form.stripe_env = 'live'">
                      🚀 Live
                    </button>
                  </div>
                </div>

                <!-- Chaves -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="text-sm font-medium text-slate-700 mb-1 block flex items-center gap-1">
                      <span class="text-amber-500">🧪</span> Secret Key (Test)
                      <span v-if="form.stripe_env === 'test'" class="text-[10px] text-amber-600 font-semibold ml-1">● ATIVO</span>
                    </label>
                    <div class="relative">
                      <input v-model="form.stripe_secret_key_test"
                        :type="mostrar.stripe_test ? 'text' : 'password'"
                        placeholder="sk_test_..."
                        class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono pr-10 focus:outline-none focus:ring-2 focus:ring-primaria"
                        :class="form.stripe_env === 'test' ? 'border-amber-300 bg-amber-50' : ''"
                      />
                      <button type="button" class="absolute right-3 top-2.5 text-xs text-slate-400 hover:text-slate-600"
                        @click="mostrar.stripe_test = !mostrar.stripe_test">
                        {{ mostrar.stripe_test ? '🙈' : '👁' }}
                      </button>
                    </div>
                  </div>
                  <div>
                    <label class="text-sm font-medium text-slate-700 mb-1 block flex items-center gap-1">
                      <span class="text-green-500">🚀</span> Secret Key (Live)
                      <span v-if="form.stripe_env === 'live'" class="text-[10px] text-green-600 font-semibold ml-1">● ATIVO</span>
                    </label>
                    <div class="relative">
                      <input v-model="form.stripe_secret_key"
                        :type="mostrar.stripe_live ? 'text' : 'password'"
                        placeholder="sk_live_..."
                        class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono pr-10 focus:outline-none focus:ring-2 focus:ring-primaria"
                        :class="form.stripe_env === 'live' ? 'border-green-300 bg-green-50' : ''"
                      />
                      <button type="button" class="absolute right-3 top-2.5 text-xs text-slate-400 hover:text-slate-600"
                        @click="mostrar.stripe_live = !mostrar.stripe_live">
                        {{ mostrar.stripe_live ? '🙈' : '👁' }}
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Webhook secrets -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="text-sm font-medium text-slate-700 mb-1 block">
                      Webhook Secret (Test)
                    </label>
                    <div class="relative">
                      <input v-model="form.stripe_webhook_secret_test"
                        :type="mostrar.stripe_wh_test ? 'text' : 'password'"
                        placeholder="whsec_..."
                        class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono pr-10 focus:outline-none focus:ring-2 focus:ring-primaria"
                      />
                      <button type="button" class="absolute right-3 top-2.5 text-xs text-slate-400 hover:text-slate-600"
                        @click="mostrar.stripe_wh_test = !mostrar.stripe_wh_test">
                        {{ mostrar.stripe_wh_test ? '🙈' : '👁' }}
                      </button>
                    </div>
                  </div>
                  <div>
                    <label class="text-sm font-medium text-slate-700 mb-1 block">
                      Webhook Secret (Live)
                    </label>
                    <div class="relative">
                      <input v-model="form.stripe_webhook_secret"
                        :type="mostrar.stripe_wh_live ? 'text' : 'password'"
                        placeholder="whsec_..."
                        class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono pr-10 focus:outline-none focus:ring-2 focus:ring-primaria"
                      />
                      <button type="button" class="absolute right-3 top-2.5 text-xs text-slate-400 hover:text-slate-600"
                        @click="mostrar.stripe_wh_live = !mostrar.stripe_wh_live">
                        {{ mostrar.stripe_wh_live ? '🙈' : '👁' }}
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Taxas -->
                <div class="rounded-xl border border-slate-200 p-4">
                  <div class="flex items-center justify-between mb-4">
                    <p class="font-semibold text-sm text-slate-700">💰 Taxas Stripe</p>
                    <label class="flex items-center gap-2 cursor-pointer select-none text-sm">
                      <div class="relative">
                        <input type="checkbox" class="sr-only" v-model="form.stripe_pass_fees_to_customer" />
                        <div class="w-8 h-5 rounded-full transition"
                          :class="form.stripe_pass_fees_to_customer ? 'bg-primaria' : 'bg-slate-200'">
                          <div class="absolute top-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform"
                            :class="form.stripe_pass_fees_to_customer ? 'translate-x-4' : 'translate-x-0.5'" />
                        </div>
                      </div>
                      <span class="text-slate-600">Repassar ao cliente</span>
                    </label>
                  </div>
                  <div class="flex items-center gap-3">
                    <label class="text-xs text-slate-500 whitespace-nowrap">R$ fixo</label>
                    <input v-model.number="form.stripe_fee_fixed" type="number" step="0.01" min="0"
                      class="w-20 border border-slate-200 rounded-lg px-2 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                    <label class="text-xs text-slate-500">%</label>
                    <input v-model.number="form.stripe_fee_percentage" type="number" step="0.01" min="0"
                      class="w-20 border border-slate-200 rounded-lg px-2 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                  </div>
                </div>

                <!-- URL webhook info -->
                <div class="rounded-xl bg-slate-50 border border-slate-200 p-4 text-xs text-slate-500">
                  <p class="font-semibold text-slate-600 mb-1">🔔 URL do Webhook Stripe</p>
                  <p class="font-mono break-all">{{ supabaseUrl }}/functions/v1/stripe-webhook</p>
                  <p class="mt-1">Configure no Stripe Dashboard → Developers → Webhooks.</p>
                  <p class="mt-0.5">Eventos: <code class="bg-slate-100 px-1 rounded">checkout.session.completed</code></p>
                </div>

              </div>
            </div>
          </template>

          <!-- ── PIX Manual ── -->
          <template v-if="abaAtiva === 'pix'">
            <div class="cartao">
              <div class="mb-5">
                <h2 class="font-semibold text-base">📱 PIX Manual</h2>
                <p class="text-xs text-slate-400 mt-0.5">Fallback manual — cliente copia a chave e paga. Admin aprova manualmente.</p>
              </div>

              <div class="flex flex-col gap-4">
                <div>
                  <label class="text-sm font-medium text-slate-700 mb-1 block">Chave PIX</label>
                  <input v-model="form.pix_key" type="text" placeholder="email@exemplo.com / CPF / telefone / chave aleatória"
                    class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="text-sm font-medium text-slate-700 mb-1 block">Nome do recebedor</label>
                    <input v-model="form.pix_name" type="text" placeholder="EMPRESA LTDA"
                      class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
                  </div>
                  <div>
                    <label class="text-sm font-medium text-slate-700 mb-1 block">Cidade</label>
                    <input v-model="form.pix_city" type="text" placeholder="SAO PAULO"
                      class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
                  </div>
                </div>

                <!-- Preview -->
                <div v-if="form.pix_key" class="rounded-xl bg-slate-50 border border-slate-200 p-4">
                  <p class="text-[10px] font-semibold uppercase tracking-wide text-slate-400 mb-2">Preview</p>
                  <div class="text-sm text-slate-700 space-y-1">
                    <p><span class="text-slate-400 text-xs">Chave:</span> {{ form.pix_key }}</p>
                    <p><span class="text-slate-400 text-xs">Nome:</span> {{ form.pix_name || '—' }}</p>
                    <p><span class="text-slate-400 text-xs">Cidade:</span> {{ form.pix_city || '—' }}</p>
                  </div>
                </div>
              </div>
            </div>
          </template>

          <!-- Resumo de gateways ativos -->
          <div class="cartao bg-slate-50">
            <p class="text-xs font-semibold uppercase tracking-wide text-slate-400 mb-3">Status dos Gateways</p>
            <div class="flex flex-wrap gap-3">
              <div class="flex items-center gap-2 text-sm px-3 py-1.5 rounded-full border"
                :class="form.pagbank_enabled ? 'bg-green-50 border-green-200 text-green-700' : 'bg-slate-100 border-slate-200 text-slate-400'">
                <span class="w-2 h-2 rounded-full" :class="form.pagbank_enabled ? 'bg-green-500' : 'bg-slate-300'"></span>
                PagBank
                <span class="text-xs opacity-70">{{ form.pagbank_enabled ? form.pagbank_env : 'desativado' }}</span>
              </div>
              <div class="flex items-center gap-2 text-sm px-3 py-1.5 rounded-full border"
                :class="form.stripe_enabled ? 'bg-green-50 border-green-200 text-green-700' : 'bg-slate-100 border-slate-200 text-slate-400'">
                <span class="w-2 h-2 rounded-full" :class="form.stripe_enabled ? 'bg-green-500' : 'bg-slate-300'"></span>
                Stripe
                <span class="text-xs opacity-70">{{ form.stripe_enabled ? form.stripe_env : 'desativado' }}</span>
              </div>
              <div class="flex items-center gap-2 text-sm px-3 py-1.5 rounded-full border"
                :class="form.pix_key ? 'bg-green-50 border-green-200 text-green-700' : 'bg-slate-100 border-slate-200 text-slate-400'">
                <span class="w-2 h-2 rounded-full" :class="form.pix_key ? 'bg-green-500' : 'bg-slate-300'"></span>
                PIX Manual
                <span class="text-xs opacity-70">{{ form.pix_key ? 'configurado' : 'não configurado' }}</span>
              </div>
            </div>
          </div>

          <div class="flex justify-end">
            <button class="botao-primario" :disabled="cfg.salvando.value" @click="salvar">
              {{ cfg.salvando.value ? 'Salvando...' : '💾 Salvar configurações' }}
            </button>
          </div>

        </div>
      </template>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { isDevelopAdmin, verificando } = useDevelopAdmin()
const cfg = usePagamentosConfig()

const runtimeConfig = useRuntimeConfig()
const supabaseUrl = runtimeConfig.public.supabaseUrl ?? ''

const abaAtiva = ref<'pagbank' | 'stripe' | 'pix'>('pagbank')
const tabs = [
  { id: 'pagbank', label: '🏦 PagBank' },
  { id: 'stripe',  label: '💳 Stripe' },
  { id: 'pix',     label: '📱 PIX Manual' },
]

const mostrar = reactive({
  pagbank_sandbox: false,
  pagbank_prod:    false,
  stripe_test:     false,
  stripe_live:     false,
  stripe_wh_test:  false,
  stripe_wh_live:  false,
})

const form = reactive({
  pagbank_enabled:               false,
  pagbank_env:                   'sandbox' as 'sandbox' | 'producao',
  pagbank_token_sandbox:         '',
  pagbank_token_producao:        '',
  pagbank_pass_fees_to_customer: false,
  pagbank_pix_fee_fixed:         0.99,
  pagbank_pix_fee_percentage:    0,
  pagbank_card_fee_fixed:        0.39,
  pagbank_card_fee_percentage:   4.99,
  stripe_enabled:                false,
  stripe_env:                    'test' as 'test' | 'live',
  stripe_secret_key:             '',
  stripe_secret_key_test:        '',
  stripe_webhook_secret:         '',
  stripe_webhook_secret_test:    '',
  stripe_pass_fees_to_customer:  false,
  stripe_fee_percentage:         3.99,
  stripe_fee_fixed:              0.39,
  pix_key:                       '',
  pix_name:                      '',
  pix_city:                      '',
})

async function salvar() {
  await cfg.salvar({ ...form })
}

onMounted(async () => {
  const dados = await cfg.carregar()
  if (!dados) return
  Object.assign(form, {
    pagbank_enabled:               dados.pagbank_enabled,
    pagbank_env:                   dados.pagbank_env,
    pagbank_token_sandbox:         dados.pagbank_token_sandbox,
    pagbank_token_producao:        dados.pagbank_token_producao,
    pagbank_pass_fees_to_customer: dados.pagbank_pass_fees_to_customer,
    pagbank_pix_fee_fixed:         Number(dados.pagbank_pix_fee_fixed),
    pagbank_pix_fee_percentage:    Number(dados.pagbank_pix_fee_percentage),
    pagbank_card_fee_fixed:        Number(dados.pagbank_card_fee_fixed),
    pagbank_card_fee_percentage:   Number(dados.pagbank_card_fee_percentage),
    stripe_enabled:                dados.stripe_enabled,
    stripe_env:                    dados.stripe_env,
    stripe_secret_key:             dados.stripe_secret_key,
    stripe_secret_key_test:        dados.stripe_secret_key_test,
    stripe_webhook_secret:         dados.stripe_webhook_secret,
    stripe_webhook_secret_test:    dados.stripe_webhook_secret_test,
    stripe_pass_fees_to_customer:  dados.stripe_pass_fees_to_customer,
    stripe_fee_percentage:         Number(dados.stripe_fee_percentage),
    stripe_fee_fixed:              Number(dados.stripe_fee_fixed),
    pix_key:                       dados.pix_key,
    pix_name:                      dados.pix_name,
    pix_city:                      dados.pix_city,
  })
})
</script>
