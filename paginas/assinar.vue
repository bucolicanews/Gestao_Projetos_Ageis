<template>
  <div class="min-h-screen bg-slate-50 py-12 px-6">
    <div class="max-w-xl mx-auto">

      <!-- Voltar -->
      <NuxtLink to="/planos" class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-primaria mb-8 transition">
        ← Voltar aos planos
      </NuxtLink>

      <!-- Sucesso gratuito -->
      <div v-if="etapa === 'sucesso' && plano?.gratuito"
        class="bg-white rounded-2xl border border-green-200 shadow p-10 text-center">
        <div class="text-5xl mb-4">🎁</div>
        <h2 class="text-2xl font-bold text-slate-900 mb-2">Plano ativado gratuitamente!</h2>
        <p class="text-slate-500 mb-1">
          Seu plano <strong>{{ plano?.titulo }}</strong> está ativo.
        </p>
        <p v-if="fimGratis" class="text-sm font-semibold text-green-700 mb-6">
          Gratuito até {{ fimGratis }}
        </p>
        <p v-else class="text-sm text-slate-400 mb-6">Sem data de expiração</p>
        <NuxtLink to="/" class="botao-primario px-6 py-3">Acessar o sistema →</NuxtLink>
      </div>

      <!-- Sucesso pago -->
      <div v-else-if="etapa === 'sucesso'"
        class="bg-white rounded-2xl border border-green-200 shadow p-10 text-center">
        <div class="text-5xl mb-4">🎉</div>
        <h2 class="text-2xl font-bold text-slate-900 mb-2">Pagamento confirmado!</h2>
        <p class="text-slate-500 mb-6">Seu plano <strong>{{ plano?.titulo }}</strong> está ativo.</p>
        <NuxtLink to="/" class="botao-primario px-6 py-3">Acessar o sistema →</NuxtLink>
      </div>

      <!-- Carregando -->
      <div v-else-if="carregando" class="text-center py-20 text-slate-400">Carregando...</div>

      <!-- Sem login -->
      <div v-else-if="!usuario" class="bg-white rounded-2xl border border-slate-200 shadow p-8 text-center">
        <div class="text-4xl mb-4">🔐</div>
        <h2 class="text-xl font-bold text-slate-900 mb-2">Crie sua conta para assinar</h2>
        <p class="text-slate-500 mb-6 text-sm">Já tem conta? Entre para continuar.</p>
        <div class="flex gap-3 justify-center">
          <NuxtLink :to="`/cadastro?redirect=/assinar?plano_id=${planoId}`" class="botao-primario px-5 py-2.5">
            Criar conta →
          </NuxtLink>
          <NuxtLink :to="`/login?redirect=/assinar?plano_id=${planoId}`" class="botao-secundario px-5 py-2.5">
            Entrar
          </NuxtLink>
        </div>
      </div>

      <template v-else-if="plano && !carregando">

        <!-- Resumo do plano -->
        <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 mb-6">
          <div class="flex items-start justify-between gap-4">
            <div>
              <p class="text-xs font-semibold uppercase tracking-wide text-slate-400 mb-1">Plano selecionado</p>
              <h2 class="text-xl font-bold text-slate-900">{{ plano.titulo }}</h2>
              <p class="text-sm text-slate-500 mt-0.5">{{ plano.descricao }}</p>
            </div>
            <div class="text-right shrink-0">
              <template v-if="plano.gratuito">
                <span class="text-2xl font-extrabold text-green-600">Grátis</span>
                <span class="text-slate-400 text-xs block">sem pagamento</span>
              </template>
              <template v-else>
                <span class="text-2xl font-extrabold text-slate-900">R$ {{ formatarPreco(plano.preco) }}</span>
                <span class="text-slate-400 text-xs block">/mês</span>
              </template>
            </div>
          </div>
          <ul class="mt-4 flex flex-wrap gap-2">
            <li v-for="r in (plano.recursos as string[])" :key="r"
              class="text-xs bg-slate-50 border border-slate-100 rounded-full px-3 py-1 text-slate-600">
              ✓ {{ r }}
            </li>
          </ul>
        </div>

        <!-- Banner upgrade -->
        <div v-if="ehUpgrade" class="mb-4 p-4 bg-indigo-50 border border-indigo-200 rounded-xl text-sm text-indigo-700 flex items-center gap-3">
          <span class="text-xl">⬆</span>
          <div>
            <p class="font-semibold">Troca de plano</p>
            <p class="text-xs mt-0.5">
              Plano atual: <strong>{{ planoAtual.titulo }}</strong> (R$ {{ formatarPreco(planoAtual.preco) }}/mês)
              → Novo: <strong>{{ plano?.titulo }}</strong>
            </p>
          </div>
        </div>

        <!-- Retorno Stripe -->
        <div v-if="route.query.payment === 'success'"
          class="mb-4 p-3 bg-green-50 border border-green-200 rounded-xl text-sm text-green-700">
          ✓ Pagamento processado pelo Stripe! Aguarde a confirmação.
        </div>
        <div v-if="route.query.payment === 'cancel'"
          class="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-xl text-sm text-amber-700">
          Pagamento cancelado. Escolha outro método ou tente novamente.
        </div>

        <!-- Erro -->
        <div v-if="pag.erro.value"
          class="mb-4 p-3 bg-red-50 border border-red-100 rounded-xl text-sm text-perigo">
          {{ pag.erro.value }}
          <span v-if="pag.erro.value?.includes('CPF')" class="ml-2 font-medium">
            — Preencha o CPF abaixo e tente novamente.
          </span>
        </div>

        <!-- CPF (PagBank exige) -->
        <div v-if="precisaCpf || pag.erro.value?.includes('CPF')" class="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-4">
          <label class="text-sm font-medium text-amber-800 mb-2 block">CPF do responsável *</label>
          <input v-model="cpf" type="text" placeholder="000.000.000-00" maxlength="14"
            class="w-full border border-amber-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
          <p class="text-xs text-amber-600 mt-1">Exigido pelo Banco Central para pagamentos PIX.</p>
        </div>

        <!-- QR Code PIX -->
        <div v-if="etapa === 'pix'" class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 mb-6 text-center">
          <p class="font-semibold text-slate-800 mb-4">📱 Escaneie o QR Code PIX</p>
          <img v-if="pixData?.qr_code" :src="pixData.qr_code" alt="QR Code PIX"
            class="mx-auto w-48 h-48 rounded-xl border border-slate-200 mb-4" />
          <div v-if="pixData?.qr_code_text" class="mb-4">
            <p class="text-xs text-slate-400 mb-1">Ou copie o código:</p>
            <div class="flex items-center gap-2">
              <input :value="pixData.qr_code_text" readonly
                class="flex-1 border border-slate-200 rounded-lg px-3 py-2 text-xs font-mono bg-slate-50" />
              <button class="botao-secundario px-3 py-2 text-xs" @click="copiarPix">
                {{ copiado ? '✓' : '📋' }}
              </button>
            </div>
          </div>
          <div class="flex items-center justify-center gap-2 text-sm text-slate-400">
            <span class="animate-pulse">●</span>
            Aguardando confirmação do pagamento...
          </div>
          <button class="mt-4 text-xs text-slate-400 hover:text-slate-600 underline" @click="etapa = 'metodos'">
            Cancelar
          </button>
        </div>

        <!-- PIX Manual -->
        <div v-if="etapa === 'pix_manual'" class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 mb-6">
          <p class="font-semibold text-slate-800 mb-4">📱 Pague via PIX Manual</p>
          <div class="bg-slate-50 rounded-xl border border-slate-200 p-4 space-y-2 text-sm mb-4">
            <div class="flex justify-between">
              <span class="text-slate-500">Chave PIX:</span>
              <span class="font-semibold text-slate-800">{{ gateways?.pix_key }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-500">Nome:</span>
              <span class="font-medium text-slate-700">{{ gateways?.pix_name }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-500">Valor:</span>
              <span class="font-bold text-primaria">R$ {{ formatarPreco(plano.preco) }}</span>
            </div>
          </div>
          <p class="text-sm text-slate-500 mb-4">
            Após realizar o pagamento, envie o comprovante para o nosso suporte.
            Seu plano será ativado manualmente em até 24h.
          </p>
          <button class="text-xs text-slate-400 hover:text-slate-600 underline" @click="etapa = 'metodos'">
            Voltar
          </button>
        </div>

        <!-- Ativação gratuita -->
        <div v-if="etapa === 'metodos' && plano.gratuito" class="bg-white rounded-2xl border border-green-200 shadow-sm p-8 text-center">
          <div class="text-4xl mb-3">🎁</div>
          <h3 class="text-lg font-bold text-slate-900 mb-1">Este plano é gratuito</h3>

          <!-- Valor -->
          <div class="my-4">
            <span class="text-3xl font-extrabold text-green-600">R$ 0,00</span>
            <span class="text-slate-400 text-sm ml-1">/mês</span>
          </div>

          <!-- Dias trial e data de término -->
          <div v-if="plano.dias_trial > 0" class="bg-green-50 rounded-xl px-4 py-3 mb-5 inline-block text-left">
            <p class="text-sm font-semibold text-green-800">
              {{ plano.dias_trial }} dias gratuitos
            </p>
            <p class="text-xs text-green-600 mt-0.5">
              Ativo até {{ previsaoFim(plano.dias_trial) }}
            </p>
          </div>
          <p v-else class="text-sm text-slate-500 mb-5">Sem data de expiração</p>

          <div class="block">
            <button class="botao-primario px-8 py-3" :disabled="ativando" @click="ativarGratis">
              {{ ativando ? 'Ativando...' : 'Ativar gratuitamente →' }}
            </button>
          </div>
          <p v-if="erroGratis" class="text-sm text-perigo mt-3">{{ erroGratis }}</p>
        </div>

        <!-- Métodos de pagamento -->
        <div v-if="etapa === 'metodos' && !plano.gratuito" class="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
          <h3 class="font-bold text-slate-800 mb-5">Escolha o método de pagamento</h3>

          <div class="flex flex-col gap-3">

            <!-- PIX PagBank -->
            <button v-if="gateways?.pagbank_enabled"
              class="w-full flex items-center justify-between p-4 rounded-xl border border-slate-200 hover:border-green-400 hover:bg-green-50 transition text-left"
              :disabled="pag.processando.value"
              @click="iniciarPagBankPix">
              <div class="flex items-center gap-3">
                <span class="text-2xl">📱</span>
                <div>
                  <p class="font-semibold text-slate-800 text-sm">PIX (PagBank)</p>
                  <p class="text-xs text-slate-400">QR Code instantâneo — aprovação em segundos</p>
                </div>
              </div>
              <div class="text-right">
                <p v-if="gateways.pagbank_pass_fees_to_customer" class="text-xs text-slate-400">
                  + taxa
                </p>
                <span class="text-green-600 text-sm font-semibold">
                  R$ {{ formatarPreco(valorComTaxa('pix')) }}
                </span>
              </div>
            </button>

            <!-- Cartão PagBank -->
            <button v-if="gateways?.pagbank_enabled"
              class="w-full flex items-center justify-between p-4 rounded-xl border border-slate-200 hover:border-primaria hover:bg-indigo-50 transition text-left"
              :disabled="pag.processando.value"
              @click="iniciarPagBankCartao">
              <div class="flex items-center gap-3">
                <span class="text-2xl">💳</span>
                <div>
                  <p class="font-semibold text-slate-800 text-sm">Cartão de crédito (PagBank)</p>
                  <p class="text-xs text-slate-400">Página de checkout segura do PagBank</p>
                </div>
              </div>
              <div class="text-right">
                <p v-if="gateways.pagbank_pass_fees_to_customer" class="text-xs text-slate-400">
                  + taxa
                </p>
                <span class="text-primaria text-sm font-semibold">
                  R$ {{ formatarPreco(valorComTaxa('cartao')) }}
                </span>
              </div>
            </button>

            <!-- Stripe -->
            <button v-if="gateways?.stripe_enabled"
              class="w-full flex items-center justify-between p-4 rounded-xl border border-slate-200 hover:border-violet-400 hover:bg-violet-50 transition text-left"
              :disabled="pag.processando.value"
              @click="iniciarStripe">
              <div class="flex items-center gap-3">
                <span class="text-2xl">💳</span>
                <div>
                  <p class="font-semibold text-slate-800 text-sm">Cartão de crédito (Stripe)</p>
                  <p class="text-xs text-slate-400">Internacional — Visa, Mastercard, etc.</p>
                </div>
              </div>
              <div class="text-right">
                <p v-if="gateways.stripe_pass_fees_to_customer" class="text-xs text-slate-400">
                  + taxa
                </p>
                <span class="text-violet-600 text-sm font-semibold">
                  R$ {{ formatarPreco(valorComTaxa('stripe')) }}
                </span>
              </div>
            </button>

            <!-- PIX Manual -->
            <button v-if="gateways?.pix_key"
              class="w-full flex items-center justify-between p-4 rounded-xl border border-dashed border-slate-300 hover:border-slate-400 hover:bg-slate-50 transition text-left"
              @click="etapa = 'pix_manual'">
              <div class="flex items-center gap-3">
                <span class="text-2xl">🔑</span>
                <div>
                  <p class="font-semibold text-slate-800 text-sm">PIX Manual</p>
                  <p class="text-xs text-slate-400">Ativação manual em até 24h úteis</p>
                </div>
              </div>
              <span class="text-slate-500 text-sm font-semibold">R$ {{ formatarPreco(plano.preco) }}</span>
            </button>

            <!-- Nenhum gateway -->
            <div v-if="!gateways?.pagbank_enabled && !gateways?.stripe_enabled && !gateways?.pix_key"
              class="p-6 text-center text-slate-400 text-sm">
              Nenhum método de pagamento disponível no momento. Entre em contato com o suporte.
            </div>
          </div>

          <div v-if="pag.processando.value" class="mt-4 text-center text-sm text-slate-400 animate-pulse">
            Processando pagamento...
          </div>
        </div>

      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: false })

const route   = useRoute()
const usuario = useSupabaseUser()
const cliente = useSupabaseClient()
const pag     = usePagamento()

const planoId    = computed(() => route.query.plano_id as string)
const carregando = ref(true)
const plano      = ref<any>(null)
const planoAtual = ref<any>(null)
const gateways   = ref<any>(null)
const orgId      = ref('')
const ehUpgrade  = computed(() => !!planoAtual.value && planoAtual.value.id !== planoId.value)
const etapa    = ref<'metodos' | 'pix' | 'pix_manual' | 'sucesso'>('metodos')
const pixData  = ref<{ qr_code: string; qr_code_text: string; order_id: string } | null>(null)
const cpf      = ref('')
const copiado  = ref(false)
const precisaCpf = ref(false)
const ativando  = ref(false)
const erroGratis = ref('')
const fimGratis = ref('')

function previsaoFim(dias: number): string {
  const d = new Date()
  d.setDate(d.getDate() + dias)
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

function formatarPreco(v: number) {
  return Number(v).toFixed(2).replace('.', ',')
}

function valorComTaxa(tipo: 'pix' | 'cartao' | 'stripe'): number {
  if (!plano.value || !gateways.value) return 0
  const v = plano.value.preco
  if (tipo === 'pix' && gateways.value.pagbank_pass_fees_to_customer)
    return pag.calcularTaxa(v, Number(gateways.value.pagbank_pix_fee_fixed), Number(gateways.value.pagbank_pix_fee_percentage))
  if (tipo === 'cartao' && gateways.value.pagbank_pass_fees_to_customer)
    return pag.calcularTaxa(v, Number(gateways.value.pagbank_card_fee_fixed), Number(gateways.value.pagbank_card_fee_percentage))
  if (tipo === 'stripe' && gateways.value.stripe_pass_fees_to_customer)
    return pag.calcularTaxa(v, Number(gateways.value.stripe_fee_fixed), Number(gateways.value.stripe_fee_percentage))
  return v
}

async function iniciarPagBankPix() {
  if (!cpf.value && !precisaCpf.value) { precisaCpf.value = true; return }
  const r = await pag.pagarPagBankPix({
    org_id: orgId.value,
    plano_id: planoId.value,
    amount: plano.value.preco,
    cpf: cpf.value.replace(/\D/g, ''),
  })
  if (r) {
    pixData.value = r
    etapa.value = 'pix'
    aguardarPagamento(r.order_id)
  }
}

async function iniciarPagBankCartao() {
  if (!cpf.value && !precisaCpf.value) { precisaCpf.value = true; return }
  await pag.pagarPagBankCartao({
    org_id: orgId.value,
    plano_id: planoId.value,
    amount: plano.value.preco,
    cpf: cpf.value.replace(/\D/g, ''),
  })
}

async function iniciarStripe() {
  await pag.pagarStripe({
    org_id: orgId.value,
    plano_id: planoId.value,
    amount: plano.value.preco,
  })
}

async function aguardarPagamento(orderId: string) {
  const pago = await pag.pollPagamento(orderId)
  if (pago) etapa.value = 'sucesso'
}

function copiarPix() {
  if (pixData.value?.qr_code_text) {
    navigator.clipboard.writeText(pixData.value.qr_code_text)
    copiado.value = true
    setTimeout(() => copiado.value = false, 2000)
  }
}

async function ativarGratis() {
  ativando.value = true
  erroGratis.value = ''
  try {
    const res = await $fetch<{ ok: boolean; vencimento: string | null; dias_trial: number }>('/api/assinar-gratis', {
      method: 'POST',
      body: { plano_id: planoId.value },
    })
    if (res.vencimento) {
      const [ano, mes, dia] = res.vencimento.split('-')
      fimGratis.value = `${dia}/${mes}/${ano}`
    }
    etapa.value = 'sucesso'
  } catch (e: any) {
    erroGratis.value = e?.data?.message ?? e?.message ?? 'Erro ao ativar plano'
  } finally {
    ativando.value = false
  }
}

// Verifica retorno Stripe success
onMounted(async () => {
  if (route.query.payment === 'success') etapa.value = 'sucesso'

  if (!planoId.value) { carregando.value = false; return }

  const [planoData, gatewaysData] = await Promise.all([
    cliente.from('planos').select('id, titulo, descricao, preco, recursos, gratuito, dias_trial').eq('id', planoId.value).maybeSingle(),
    pag.carregarGateways(),
  ])
  plano.value   = planoData.data
  gateways.value = gatewaysData

  // Busca org do usuário logado
  if (usuario.value) {
    const { data: org } = await cliente
      .from('organizacoes')
      .select('id, plano_id, planos(id, titulo, preco)')
      .eq('dono_id', usuario.value.id)
      .maybeSingle()
    orgId.value    = org?.id ?? ''
    planoAtual.value = (org as any)?.planos ?? null
  }

  carregando.value = false
})
</script>
