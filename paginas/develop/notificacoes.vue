<template>
  <div>
    <div v-if="verificando" class="flex items-center justify-center h-40 text-slate-400">
      Verificando permissões...
    </div>

    <template v-else-if="isDevelopAdmin">
      <!-- Header -->
      <div class="flex justify-between items-center mb-6">
        <div>
          <h1 class="text-2xl font-bold">🔔 Notificações</h1>
          <p class="text-sm text-slate-500 mt-0.5">Histórico de mensagens enviadas às organizações</p>
        </div>
        <button class="botao-secundario text-sm" :disabled="carregando" @click="carregar">↻ Atualizar</button>
      </div>

      <!-- Filtros -->
      <div class="flex flex-wrap gap-3 mb-5">
        <select v-model="filtroTipo"
          class="border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria">
          <option value="">Todos os tipos</option>
          <option value="manual">Manual</option>
          <option value="vencimento_iminente">Vencimento iminente</option>
          <option value="dia_vencimento">Dia do vencimento</option>
          <option value="apos_vencimento">Após vencimento</option>
        </select>

        <select v-model="filtroStatus"
          class="border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria">
          <option value="">Todos os status</option>
          <option value="enviado">Enviado</option>
          <option value="confirmado">Confirmado</option>
          <option value="falhou">Falhou</option>
        </select>

        <input v-model="busca" placeholder="Buscar por organização..."
          class="border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria flex-1 min-w-40" />
      </div>

      <!-- Stats rápidos -->
      <div class="grid grid-cols-3 gap-4 mb-6">
        <div class="cartao text-center">
          <p class="text-2xl font-bold">{{ total }}</p>
          <p class="text-xs text-slate-500 mt-0.5">Total enviadas</p>
        </div>
        <div class="cartao text-center">
          <p class="text-2xl font-bold text-green-600">{{ totalEnviadas }}</p>
          <p class="text-xs text-slate-500 mt-0.5">Com sucesso</p>
        </div>
        <div class="cartao text-center">
          <p class="text-2xl font-bold text-perigo">{{ totalFalhas }}</p>
          <p class="text-xs text-slate-500 mt-0.5">Falharam</p>
        </div>
      </div>

      <div v-if="carregando" class="text-slate-400 text-sm py-8 text-center">Carregando...</div>
      <div v-else-if="erro" class="p-3 bg-red-50 rounded-lg text-sm text-perigo">{{ erro }}</div>

      <!-- Tabela -->
      <div v-else class="cartao p-0 overflow-hidden">
        <table class="w-full text-sm">
          <thead>
            <tr class="bg-slate-50 border-b border-slate-100">
              <th class="text-left px-4 py-3 font-semibold text-slate-600">Organização</th>
              <th class="text-left px-4 py-3 font-semibold text-slate-600">Tipo</th>
              <th class="text-left px-4 py-3 font-semibold text-slate-600 hidden md:table-cell">Mensagem</th>
              <th class="text-left px-4 py-3 font-semibold text-slate-600">Status</th>
              <th class="text-left px-4 py-3 font-semibold text-slate-600 hidden lg:table-cell">Enviado em</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="msg in mensagensFiltradas"
              :key="msg.id"
              class="border-b border-slate-50 hover:bg-slate-50 transition"
            >
              <td class="px-4 py-3">
                <NuxtLink
                  v-if="msg.organizacoes"
                  :to="`/develop/organizacoes/${msg.org_id}`"
                  class="font-medium hover:text-primaria"
                >
                  {{ msg.organizacoes.nome }}
                </NuxtLink>
                <span v-else class="text-slate-400 text-xs">Org removida</span>
              </td>
              <td class="px-4 py-3">
                <span class="text-xs px-2 py-0.5 rounded-full font-medium" :class="corTipo(msg.tipo)">
                  {{ labelTipo(msg.tipo) }}
                </span>
              </td>
              <td class="px-4 py-3 hidden md:table-cell text-slate-600 max-w-xs">
                <p class="line-clamp-2 text-xs">{{ msg.mensagem }}</p>
              </td>
              <td class="px-4 py-3">
                <span class="text-xs px-2 py-0.5 rounded-full font-medium" :class="corStatus(msg.status)">
                  {{ msg.status }}
                </span>
              </td>
              <td class="px-4 py-3 hidden lg:table-cell text-slate-500 text-xs">
                {{ new Date(msg.enviado_em).toLocaleString('pt-BR') }}
              </td>
            </tr>

            <tr v-if="!mensagensFiltradas.length">
              <td colspan="5" class="px-4 py-10 text-center text-slate-400 text-sm">
                Nenhuma notificação encontrada.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { isDevelopAdmin, verificando } = useDevelopAdmin()
const cliente = useSupabaseClient()

const mensagens = ref<any[]>([])
const carregando = ref(false)
const erro = ref<string | null>(null)
const filtroTipo = ref('')
const filtroStatus = ref('')
const busca = ref('')

const mensagensFiltradas = computed(() => {
  return mensagens.value.filter(m => {
    const matchTipo   = !filtroTipo.value   || m.tipo === filtroTipo.value
    const matchStatus = !filtroStatus.value || m.status === filtroStatus.value
    const matchBusca  = !busca.value        || m.organizacoes?.nome?.toLowerCase().includes(busca.value.toLowerCase())
    return matchTipo && matchStatus && matchBusca
  })
})

const total         = computed(() => mensagens.value.length)
const totalEnviadas = computed(() => mensagens.value.filter(m => m.status === 'enviado' || m.status === 'confirmado').length)
const totalFalhas   = computed(() => mensagens.value.filter(m => m.status === 'falhou').length)

async function carregar() {
  carregando.value = true
  erro.value = null
  try {
    const { data, error } = await cliente
      .from('log_mensagens_org')
      .select('*, organizacoes ( id, nome )')
      .order('enviado_em', { ascending: false })
      .limit(200)
    if (error) throw error
    mensagens.value = data ?? []
  } catch (e: any) {
    erro.value = e.message
  } finally {
    carregando.value = false
  }
}

onMounted(() => carregar())

function corStatus(status: string) {
  const map: Record<string, string> = {
    enviado:    'bg-green-100 text-green-700',
    confirmado: 'bg-blue-100 text-blue-700',
    falhou:     'bg-red-100 text-red-700',
  }
  return map[status] ?? 'bg-slate-100 text-slate-500'
}

function corTipo(tipo: string) {
  const map: Record<string, string> = {
    manual:               'bg-slate-100 text-slate-600',
    vencimento_iminente:  'bg-amber-100 text-amber-700',
    dia_vencimento:       'bg-orange-100 text-orange-700',
    apos_vencimento:      'bg-red-100 text-red-700',
  }
  return map[tipo] ?? 'bg-slate-100 text-slate-500'
}

function labelTipo(tipo: string) {
  const map: Record<string, string> = {
    manual:               'Manual',
    vencimento_iminente:  'Venc. iminente',
    dia_vencimento:       'Dia venc.',
    apos_vencimento:      'Após venc.',
  }
  return map[tipo] ?? tipo
}
</script>
