<template>
  <div>
    <div v-if="verificando" class="flex items-center justify-center h-40 text-slate-400">
      Verificando permissões...
    </div>

    <template v-else-if="isDevelopAdmin">
      <!-- Header -->
      <div class="flex flex-wrap justify-between items-center mb-6 gap-3">
        <div>
          <h1 class="text-2xl font-bold">🔔 Notificações</h1>
          <p class="text-sm text-slate-500 mt-0.5">Histórico e envio manual de mensagens</p>
        </div>
        <button class="botao-secundario text-sm" :disabled="carregando" @click="carregar">↻ Atualizar</button>
      </div>

      <!-- ── Envio Manual ── -->
      <div class="cartao mb-6">
        <h2 class="font-semibold text-base mb-4">📨 Envio Manual</h2>

        <div class="flex flex-col gap-4">
          <!-- Seletor de organização -->
          <div>
            <label class="text-sm font-medium text-slate-700 mb-1 block">Organização *</label>
            <select
              v-model="envioOrgId"
              class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria"
            >
              <option value="">Selecione uma organização...</option>
              <option v-for="org in orgs" :key="org.id" :value="org.id">
                {{ org.nome }}
                <template v-if="org.telefone"> · {{ org.telefone }}</template>
              </option>
            </select>
          </div>

          <!-- Mensagem -->
          <div>
            <label class="text-sm font-medium text-slate-700 mb-1 block">Mensagem *</label>
            <textarea
              v-model="envioMensagem"
              rows="4"
              placeholder="Digite a mensagem que será enviada à organização..."
              class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria resize-none"
            />
            <p class="text-xs text-slate-400 mt-1">{{ envioMensagem.length }} caracteres</p>
          </div>

          <!-- Feedback -->
          <div v-if="envioFeedback" class="p-3 rounded-xl text-sm flex items-center gap-2"
            :class="envioFeedback.tipo === 'sucesso' ? 'bg-green-50 border border-green-200 text-green-700' : 'bg-red-50 border border-red-200 text-perigo'">
            <span>{{ envioFeedback.tipo === 'sucesso' ? '✓' : '✕' }}</span>
            {{ envioFeedback.msg }}
          </div>

          <!-- Botão -->
          <div class="flex justify-end">
            <button
              class="botao-primario text-sm px-6"
              :disabled="!envioOrgId || !envioMensagem.trim() || enviando"
              @click="enviarManual"
            >
              {{ enviando ? 'Enviando...' : '📤 Enviar notificação' }}
            </button>
          </div>
        </div>
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
          <option value="cobranca">Cobrança (sistema)</option>
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
const svcAdmin = servicoOrganizacoesAdmin()
const cfg = useConfiguracoesSistema()

const mensagens = ref<any[]>([])
const orgs      = ref<any[]>([])
const carregando = ref(false)
const erro = ref<string | null>(null)
const filtroTipo   = ref('')
const filtroStatus = ref('')
const busca        = ref('')

// Envio manual
const envioOrgId    = ref('')
const envioMensagem = ref('')
const enviando      = ref(false)
const envioFeedback = ref<{ tipo: 'sucesso' | 'erro'; msg: string } | null>(null)

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

async function carregarOrgs() {
  try {
    orgs.value = await svcAdmin.listarTodas()
  } catch { /* sem orgs */ }
}

async function enviarManual() {
  if (!envioOrgId.value || !envioMensagem.value.trim()) return
  enviando.value = true
  envioFeedback.value = null

  const org = orgs.value.find(o => o.id === envioOrgId.value)
  let statusFinal: 'enviado' | 'falhou' = 'enviado'

  try {
    // 1. Persiste no sistema primeiro (sino dos usuários) — garante entrega mesmo se n8n falhar
    await cliente.rpc('criar_notificacoes_org', {
      p_org_id:   envioOrgId.value,
      p_titulo:   '📢 Mensagem do suporte',
      p_mensagem: envioMensagem.value.trim(),
      p_tipo:     'geral',
    })

    // 2. Tenta enviar pelo webhook n8n (melhor esforço)
    const configs = await cfg.carregar()
    const modo = configs['n8n_modo'] || 'producao'
    const webhookUrl = modo === 'teste'
      ? configs['n8n_webhook_url_teste']
      : configs['n8n_webhook_url_producao']

    if (webhookUrl) {
      const res = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tipo: 'notificacao_manual',
          org_id: envioOrgId.value,
          org_nome: org?.nome ?? '',
          telefone: org?.telefone ?? '',
          mensagem: envioMensagem.value.trim(),
        }),
      })
      if (!res.ok) statusFinal = 'falhou'
    }

    // 3. Registra no log de mensagens
    await svcAdmin.registrarMensagem({
      org_id: envioOrgId.value,
      tipo: 'manual',
      mensagem: envioMensagem.value.trim(),
      status: statusFinal,
    })

    envioFeedback.value = {
      tipo: 'sucesso',
      msg: statusFinal === 'enviado'
        ? `Notificação enviada para ${org?.nome ?? 'organização'}.`
        : `Notificação entregue no sistema. Webhook externo falhou.`,
    }

    // Limpa formulário e recarrega histórico
    envioMensagem.value = ''
    envioOrgId.value = ''
    await carregar()
  } catch (e: any) {
    // Tenta registrar falha no log
    try {
      await svcAdmin.registrarMensagem({
        org_id: envioOrgId.value,
        tipo: 'manual',
        mensagem: envioMensagem.value.trim(),
        status: 'falhou',
      })
    } catch { /* ignore */ }
    envioFeedback.value = { tipo: 'erro', msg: e.message || 'Erro ao enviar.' }
  } finally {
    enviando.value = false
    // Limpa feedback após 5 segundos
    setTimeout(() => { envioFeedback.value = null }, 5000)
  }
}

onMounted(async () => {
  await Promise.all([carregar(), carregarOrgs()])
})

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
