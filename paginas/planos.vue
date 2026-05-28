<template>
  <div>
    <!-- Hero -->
    <section class="bg-gradient-to-br from-slate-50 to-indigo-50 py-16 px-6 text-center">
      <h1 class="text-4xl font-extrabold text-slate-900 mb-3">Planos e Preços</h1>
      <p class="text-slate-500 text-lg max-w-xl mx-auto">
        Escolha o plano ideal para o seu time. Sem taxas ocultas.
      </p>
    </section>

    <!-- Banner trial ativo -->
    <div v-if="usuario && !planoAtualId && emTrial"
      class="bg-indigo-50 border-b border-indigo-100 py-4 px-6 text-center">
      <p class="text-indigo-700 text-sm font-medium">
        Você está no período de teste gratuito de 14 dias.
        <NuxtLink to="/" class="underline font-bold ml-2">Acessar o painel →</NuxtLink>
      </p>
    </div>

    <!-- Cards dos planos -->
    <section class="py-16 px-6 bg-white">
      <div v-if="carregando" class="text-center text-slate-400 py-12">Carregando planos...</div>
      <template v-else>

        <!-- Card Testar Grátis (visitante) -->
        <div v-if="!usuario" class="max-w-7xl mx-auto mb-8">
          <div class="rounded-2xl border-2 border-dashed border-primaria/40 bg-indigo-50/50 p-8 flex flex-col sm:flex-row items-center justify-between gap-6">
            <div>
              <div class="inline-flex items-center gap-1.5 text-xs font-bold text-primaria uppercase tracking-wide mb-2">
                ✦ Sem cartão de crédito
              </div>
              <h3 class="text-2xl font-extrabold text-slate-900 mb-1">Testar grátis por 14 dias</h3>
              <p class="text-sm text-slate-500">Acesso completo a todos os recursos. Cancele quando quiser.</p>
            </div>
            <NuxtLink to="/cadastro" class="botao-primario px-8 py-3 text-base shrink-0">
              Começar trial gratuito →
            </NuxtLink>
          </div>
        </div>

        <div class="max-w-7xl mx-auto grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
        <div
          v-for="(plano, i) in planos"
          :key="plano.id"
          class="rounded-2xl border p-8 flex flex-col transition hover:shadow-lg"
          :class="i === 1
            ? 'border-primaria shadow-lg shadow-indigo-100 relative'
            : 'border-slate-200'"
        >
          <!-- Badge plano atual -->
          <div v-if="planoAtualId === plano.id"
            class="absolute -top-3 left-1/2 -translate-x-1/2 bg-green-500 text-white text-xs font-bold px-4 py-1 rounded-full">
            ✓ SEU PLANO ATUAL
          </div>
          <!-- Badge popular -->
          <div v-else-if="i === 1"
            class="absolute -top-3 left-1/2 -translate-x-1/2 bg-primaria text-white text-xs font-bold px-4 py-1 rounded-full">
            ✦ MAIS POPULAR
          </div>

          <!-- Imagem do plano -->
          <div v-if="plano.imagem_url" class="w-full h-32 rounded-xl overflow-hidden mb-5">
            <img :src="plano.imagem_url" :alt="plano.titulo" class="w-full h-full object-cover" />
          </div>
          <div v-else class="w-full h-16 rounded-xl mb-5 flex items-center justify-center text-3xl"
            :class="['bg-slate-50', 'bg-indigo-50', 'bg-purple-50'][i]">
            {{ ['🌱', '🚀', '🏢'][i] }}
          </div>

          <h3 class="text-xl font-bold text-slate-900 mb-1">{{ plano.titulo }}</h3>
          <p class="text-sm text-slate-500 mb-5">{{ plano.descricao }}</p>

          <div class="mb-6">
            <template v-if="plano.gratuito">
              <span class="text-4xl font-extrabold text-green-600">Grátis</span>
              <span class="text-slate-400 text-sm ml-1">para sempre</span>
            </template>
            <template v-else>
              <span class="text-4xl font-extrabold text-slate-900">R$ {{ formatarPreco(plano.preco) }}</span>
              <span class="text-slate-400 text-sm">/mês</span>
            </template>
          </div>

          <!-- Recursos -->
          <ul class="flex flex-col gap-2 mb-8 flex-1">
            <li v-for="recurso in (plano.recursos as string[])" :key="recurso"
              class="flex items-center gap-2 text-sm text-slate-600">
              <span class="text-green-500 shrink-0">✓</span>
              {{ recurso }}
            </li>
          </ul>

          <NuxtLink
            :to="`/assinar?plano_id=${plano.id}`"
            class="w-full text-center py-3 rounded-xl font-semibold text-sm transition"
            :class="planoAtualId === plano.id
              ? 'bg-green-100 text-green-700 hover:bg-green-200 border border-green-200'
              : i === 1
                ? 'bg-primaria text-white hover:bg-indigo-700'
                : 'border border-slate-200 text-slate-700 hover:border-primaria hover:text-primaria'"
          >
            {{ planoAtualId === plano.id ? '🔄 Renovar' : planoAtualId ? '⬆ Trocar para ' + plano.titulo : plano.gratuito ? 'Ativar ' + plano.titulo + ' grátis' : 'Assinar ' + plano.titulo }} →
          </NuxtLink>
        </div><!-- /card -->
        </div><!-- /grid -->
      </template>
    </section>

    <!-- FAQ / garantia -->
    <section class="py-16 px-6 bg-slate-50">
      <div class="max-w-3xl mx-auto">
        <h2 class="text-2xl font-bold text-slate-900 text-center mb-10">Perguntas frequentes</h2>
        <div class="flex flex-col gap-4">
          <div v-for="faq in faqs" :key="faq.p"
            class="bg-white rounded-xl border border-slate-100 p-5">
            <p class="font-semibold text-slate-800 mb-1">{{ faq.p }}</p>
            <p class="text-sm text-slate-500">{{ faq.r }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="py-14 px-6 bg-white text-center">
      <p class="text-slate-500 mb-4">Ainda tem dúvidas? Fale com a gente.</p>
      <NuxtLink to="/cadastro" class="botao-primario px-6 py-3 text-base">
        Criar conta grátis →
      </NuxtLink>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'publica' })

const usuario  = useSupabaseUser()
const cliente  = useSupabaseClient()
const carregando = ref(true)
const planos   = ref<any[]>([])
const planoAtualId = ref<string | null>(null)
const emTrial  = ref(false)

function formatarPreco(v: number) {
  return Number(v).toFixed(2).replace('.', ',')
}

onMounted(async () => {
  const planosReq = cliente
    .from('planos')
    .select('id, titulo, descricao, preco, recursos, imagem_url, gratuito')
    .eq('ativo', true)
    .order('preco', { ascending: true })

  if (usuario.value) {
    const [{ data: pData }, orgReq] = await Promise.all([
      planosReq,
      cliente.from('organizacoes').select('plano_id, status').eq('dono_id', usuario.value.id).maybeSingle(),
    ])
    planos.value = pData ?? []
    planoAtualId.value = orgReq.data?.plano_id ?? null
    emTrial.value = orgReq.data?.status === 'trial'
  } else {
    const { data } = await planosReq
    planos.value = data ?? []
  }
  carregando.value = false
})

const faqs = [
  { p: 'Posso cancelar a qualquer momento?',         r: 'Sim. Sem multa ou fidelidade. Cancele quando quiser.' },
  { p: 'Há período de trial?',                       r: 'Sim, todas as contas têm 14 dias gratuitos para testar sem precisar de cartão.' },
  { p: 'O que acontece após o vencimento?',          r: 'Seu acesso é pausado mas seus dados ficam seguros por 30 dias.' },
  { p: 'Posso mudar de plano depois?',               r: 'Sim, você pode fazer upgrade ou downgrade a qualquer momento no painel.' },
  { p: 'Os dados são compartilhados entre empresas?', r: 'Não. Cada organização tem seus dados completamente isolados.' },
]
</script>
