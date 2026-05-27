<template>
  <div class="max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold mb-1">📦 Meu Plano</h1>
    <p class="text-sm text-slate-500 mb-6">Gerencie sua assinatura</p>

    <div v-if="carregando" class="text-slate-400 text-sm py-10 text-center">Carregando...</div>

    <template v-else>

      <!-- Plano ativo -->
      <div v-if="org?.planos" class="cartao mb-6">
        <div class="flex items-start justify-between gap-4 mb-4">
          <div>
            <p class="text-xs font-semibold uppercase tracking-wide text-slate-400 mb-1">Plano atual</p>
            <h2 class="text-2xl font-bold text-slate-900">{{ org.planos.titulo }}</h2>
            <p class="text-sm text-slate-500 mt-0.5">{{ org.planos.descricao }}</p>
          </div>
          <div class="text-right shrink-0">
            <p class="text-2xl font-extrabold text-slate-900">R$ {{ formatarPreco(org.planos.preco) }}<span class="text-sm text-slate-400 font-normal">/mês</span></p>
            <span class="inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full mt-1"
              :class="corStatus">
              <span class="w-1.5 h-1.5 rounded-full bg-current"></span>
              {{ org.status }}
            </span>
          </div>
        </div>

        <!-- Vencimento -->
        <div v-if="org.vencimento" class="flex items-center gap-2 mb-4 p-3 rounded-xl text-sm"
          :class="vencimentoProximo ? 'bg-amber-50 border border-amber-200 text-amber-700' : 'bg-slate-50 text-slate-500'">
          <span>{{ vencimentoProximo ? '⚠️' : '📅' }}</span>
          <span>
            {{ vencimentoProximo ? 'Vence em breve: ' : 'Próxima renovação: ' }}
            <strong>{{ new Date(org.vencimento).toLocaleDateString('pt-BR') }}</strong>
            <span v-if="vencimentoProximo" class="ml-1">({{ diasRestantes }} dias)</span>
          </span>
        </div>

        <!-- Recursos -->
        <ul class="grid grid-cols-1 sm:grid-cols-2 gap-1.5 mb-5">
          <li v-for="r in org.planos.recursos" :key="r" class="flex items-center gap-2 text-sm text-slate-600">
            <span class="text-green-500">✓</span> {{ r }}
          </li>
        </ul>

        <div class="flex gap-3">
          <NuxtLink to="/planos" class="botao-primario text-sm">
            🔄 Trocar plano
          </NuxtLink>
          <NuxtLink :to="`/assinar?plano_id=${org.plano_id}`" class="botao-secundario text-sm">
            💳 Renovar agora
          </NuxtLink>
        </div>
      </div>

      <!-- Sem plano -->
      <div v-else class="cartao mb-6 text-center py-10">
        <div class="text-4xl mb-3">📦</div>
        <h2 class="font-bold text-slate-800 mb-2">Nenhum plano ativo</h2>
        <p class="text-sm text-slate-500 mb-5">Escolha um plano para liberar todos os recursos.</p>
        <NuxtLink to="/planos" class="botao-primario px-6 py-2.5">
          Ver planos →
        </NuxtLink>
      </div>

      <!-- Histórico de pagamentos -->
      <div class="cartao">
        <h3 class="font-semibold text-base mb-4">Histórico de pagamentos</h3>
        <div v-if="carregandoPagamentos" class="text-slate-400 text-sm text-center py-4">Carregando...</div>
        <div v-else-if="!pagamentos.length" class="text-slate-400 text-sm text-center py-6">
          Nenhum pagamento registrado ainda.
        </div>
        <div v-else class="flex flex-col divide-y divide-slate-50">
          <div v-for="p in pagamentos" :key="p.id"
            class="flex items-center justify-between py-3 text-sm">
            <div class="flex items-center gap-3">
              <span class="text-lg">{{ iconeMetodo(p.payment_method ?? p.tipo) }}</span>
              <div>
                <p class="font-medium text-slate-700">
                  {{ p.payment_method === 'pix' ? 'PIX PagBank' : p.payment_method === 'CREDIT_CARD' ? 'Cartão PagBank' : 'Stripe' }}
                </p>
                <p class="text-xs text-slate-400">{{ new Date(p.criado_em).toLocaleDateString('pt-BR') }}</p>
              </div>
            </div>
            <div class="text-right">
              <p class="font-semibold text-slate-800">R$ {{ formatarPreco(p.amount) }}</p>
              <span class="text-xs px-2 py-0.5 rounded-full font-medium"
                :class="p.status === 'PAID' || p.status === 'completed' ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'">
                {{ p.status === 'PAID' || p.status === 'completed' ? 'Pago' : 'Pendente' }}
              </span>
            </div>
          </div>
        </div>
      </div>

    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const svc = servicoOrganizacao()
const cliente = useSupabaseClient()

const carregando = ref(true)
const carregandoPagamentos = ref(true)
const org = ref<Awaited<ReturnType<typeof svc.minha>>>(null)
const pagamentos = ref<any[]>([])

const corStatus = computed(() => {
  const map: Record<string, string> = {
    ativo:     'bg-green-100 text-green-700',
    trial:     'bg-blue-100 text-blue-700',
    bloqueado: 'bg-red-100 text-red-700',
    vencido:   'bg-amber-100 text-amber-700',
    cancelado: 'bg-slate-100 text-slate-500',
  }
  return map[org.value?.status ?? ''] ?? 'bg-slate-100 text-slate-500'
})

const diasRestantes = computed(() => {
  if (!org.value?.vencimento) return 0
  return Math.ceil((new Date(org.value.vencimento).getTime() - Date.now()) / 86_400_000)
})

const vencimentoProximo = computed(() => diasRestantes.value <= 7 && diasRestantes.value >= 0)

function formatarPreco(v: number) {
  return Number(v).toFixed(2).replace('.', ',')
}

function iconeMetodo(m: string) {
  if (m === 'pix') return '📱'
  if (m === 'CREDIT_CARD') return '💳'
  return '💳'
}

onMounted(async () => {
  org.value = await svc.minha()
  carregando.value = false

  if (org.value) {
    const [pb, st] = await Promise.all([
      cliente.from('pagbank_payments').select('id, amount, status, payment_method, criado_em').eq('org_id', org.value.id).order('criado_em', { ascending: false }).limit(10),
      cliente.from('stripe_payments').select('id, amount, status, criado_em').eq('org_id', org.value.id).order('criado_em', { ascending: false }).limit(10),
    ])
    pagamentos.value = [
      ...(pb.data ?? []),
      ...(st.data ?? []).map(s => ({ ...s, payment_method: 'stripe' })),
    ].sort((a, b) => new Date(b.criado_em).getTime() - new Date(a.criado_em).getTime())
  }
  carregandoPagamentos.value = false
})
</script>
