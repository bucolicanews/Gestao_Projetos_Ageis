<template>
  <div>
    <div v-if="verificando" class="flex items-center justify-center h-40 text-slate-400">
      Verificando permissões...
    </div>

    <template v-else-if="isDevelopAdmin">
      <!-- Header -->
      <div class="flex justify-between items-center mb-6">
        <div>
          <h1 class="text-2xl font-bold">🏢 Organizações</h1>
          <p class="text-sm text-slate-500 mt-0.5">{{ orgs.length }} organização{{ orgs.length !== 1 ? 'ões' : '' }} encontrada{{ orgs.length !== 1 ? 's' : '' }}</p>
        </div>
      </div>

      <!-- Filtros -->
      <div class="flex flex-wrap gap-3 mb-5">
        <select v-model="filtroStatus"
          class="border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria">
          <option value="todos">Todos os status</option>
          <option value="ativo">Ativo</option>
          <option value="trial">Trial</option>
          <option value="bloqueado">Bloqueado</option>
          <option value="vencido">Vencido</option>
          <option value="cancelado">Cancelado</option>
        </select>

        <select v-model="filtroPlano"
          class="border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria">
          <option value="">Todos os planos</option>
          <option v-for="p in planos" :key="p.id" :value="p.id">{{ p.titulo }}</option>
        </select>

        <input v-model="busca" placeholder="Buscar por nome..."
          class="border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria flex-1 min-w-40" />

        <button class="botao-secundario text-sm" @click="carregar">↻ Atualizar</button>
      </div>

      <!-- Erro -->
      <div v-if="erroCarregar" class="mb-4 p-3 bg-red-50 rounded-lg text-sm text-perigo border border-red-100">
        {{ erroCarregar }}
      </div>

      <!-- Carregando -->
      <div v-if="carregando" class="text-slate-400 text-sm py-8 text-center">Carregando...</div>

      <!-- Tabela -->
      <div v-else class="cartao p-0 overflow-hidden">
        <table class="w-full text-sm">
          <thead>
            <tr class="bg-slate-50 border-b border-slate-100">
              <th class="text-left px-4 py-3 font-semibold text-slate-600">Organização</th>
              <th class="text-left px-4 py-3 font-semibold text-slate-600 hidden md:table-cell">Plano</th>
              <th class="text-left px-4 py-3 font-semibold text-slate-600">Status</th>
              <th class="text-left px-4 py-3 font-semibold text-slate-600 hidden lg:table-cell">Vencimento</th>
              <th class="text-left px-4 py-3 font-semibold text-slate-600 hidden lg:table-cell">Telefone</th>
              <th class="text-right px-4 py-3 font-semibold text-slate-600">Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="org in orgsFiltradas"
              :key="org.id"
              class="border-b border-slate-50 hover:bg-slate-50 transition"
            >
              <td class="px-4 py-3">
                <NuxtLink :to="`/develop/organizacoes/${org.id}`" class="font-medium hover:text-primaria">
                  {{ org.nome }}
                </NuxtLink>
                <p class="text-xs text-slate-400">{{ org.dono?.email }}</p>
              </td>
              <td class="px-4 py-3 hidden md:table-cell">
                <span v-if="org.planos" class="text-slate-700">{{ org.planos.titulo }}</span>
                <span v-else class="text-slate-400 text-xs">Sem plano</span>
              </td>
              <td class="px-4 py-3">
                <span class="text-xs px-2 py-0.5 rounded-full font-semibold" :class="corStatus(org.status)">
                  {{ org.status }}
                </span>
              </td>
              <td class="px-4 py-3 hidden lg:table-cell text-slate-600">
                <span v-if="org.vencimento" :class="vencimentoProximo(org.vencimento) ? 'text-amber-600 font-semibold' : ''">
                  {{ new Date(org.vencimento).toLocaleDateString('pt-BR') }}
                  <span v-if="vencimentoProximo(org.vencimento)" class="text-xs">⚠</span>
                </span>
                <span v-else class="text-slate-400 text-xs">—</span>
              </td>
              <td class="px-4 py-3 hidden lg:table-cell text-slate-600 text-xs">
                {{ org.telefone || '—' }}
              </td>
              <td class="px-4 py-3">
                <div class="flex gap-1 justify-end">
                  <NuxtLink :to="`/develop/organizacoes/${org.id}`"
                    class="text-xs px-2 py-1 rounded bg-slate-100 hover:bg-slate-200 transition">
                    👁 Ver
                  </NuxtLink>
                  <button class="text-xs px-2 py-1 rounded bg-slate-100 hover:bg-slate-200 transition"
                    @click="abrirEdicao(org)">
                    ✏️
                  </button>
                  <button
                    class="text-xs px-2 py-1 rounded transition"
                    :class="org.status === 'bloqueado' ? 'bg-green-100 hover:bg-green-200 text-green-700' : 'bg-amber-100 hover:bg-amber-200 text-amber-700'"
                    @click="abrirBloqueio(org)">
                    {{ org.status === 'bloqueado' ? '🔓' : '🔒' }}
                  </button>
                  <button class="text-xs px-2 py-1 rounded bg-blue-100 hover:bg-blue-200 text-blue-700 transition"
                    @click="abrirMensagem(org)">
                    💬
                  </button>
                </div>
              </td>
            </tr>

            <tr v-if="!orgsFiltradas.length">
              <td colspan="6" class="px-4 py-10 text-center text-slate-400 text-sm">
                Nenhuma organização encontrada com os filtros aplicados.
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Modais -->
      <ModalOrganizacao
        v-if="orgEditando"
        :org="orgEditando"
        :planos="planos"
        @fechar="orgEditando = null"
        @salvo="onSalvo"
      />
      <ModalBloquearOrg
        v-if="orgBloqueando"
        :org="orgBloqueando"
        @fechar="orgBloqueando = null"
        @atualizado="carregar"
      />
      <ModalMensagemOrg
        v-if="orgMensagem"
        :org="orgMensagem"
        @fechar="orgMensagem = null"
        @enviado="orgMensagem = null"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import type { OrgAdmin } from '~/servicos/servicoOrganizacoesAdmin'

definePageMeta({ layout: 'default' })

const { isDevelopAdmin, verificando } = useDevelopAdmin()
const svc = servicoOrganizacoesAdmin()

const orgs = ref<OrgAdmin[]>([])
const planos = ref<{ id: string; titulo: string; preco: number }[]>([])
const carregando = ref(false)
const filtroStatus = ref('todos')
const filtroPlano = ref('')
const busca = ref('')

const erroCarregar = ref<string | null>(null)
const orgEditando = ref<OrgAdmin | null>(null)
const orgBloqueando = ref<OrgAdmin | null>(null)
const orgMensagem = ref<OrgAdmin | null>(null)

const orgsFiltradas = computed(() => {
  return orgs.value.filter(o => {
    const matchBusca = !busca.value || o.nome.toLowerCase().includes(busca.value.toLowerCase())
    const matchPlano = !filtroPlano.value || o.plano_id === filtroPlano.value
    return matchBusca && matchPlano
  })
})

async function carregar() {
  carregando.value = true
  erroCarregar.value = null
  try {
    const [orgsData, planosData] = await Promise.all([
      svc.listarTodas({ status: filtroStatus.value }),
      useSupabaseClient().from('planos').select('id, titulo, preco').eq('ativo', true),
    ])
    orgs.value = orgsData
    planos.value = (planosData.data ?? []) as any
  } catch (e: any) {
    erroCarregar.value = e.message ?? 'Erro ao carregar organizações.'
  } finally {
    carregando.value = false
  }
}

watch(filtroStatus, () => carregar())
onMounted(() => carregar())

function corStatus(status: string) {
  const map: Record<string, string> = {
    ativo:     'bg-green-100 text-green-700',
    trial:     'bg-blue-100 text-blue-700',
    bloqueado: 'bg-red-100 text-red-700',
    vencido:   'bg-amber-100 text-amber-700',
    cancelado: 'bg-slate-100 text-slate-500',
  }
  return map[status] ?? 'bg-slate-100 text-slate-500'
}

function vencimentoProximo(vencimento: string): boolean {
  const dias = Math.ceil((new Date(vencimento).getTime() - Date.now()) / 86_400_000)
  return dias <= 7 && dias >= 0
}

function abrirEdicao(org: OrgAdmin) { orgEditando.value = org }
function abrirBloqueio(org: OrgAdmin) { orgBloqueando.value = org }
function abrirMensagem(org: OrgAdmin) { orgMensagem.value = org }

function onSalvo(org: OrgAdmin) {
  const idx = orgs.value.findIndex(o => o.id === org.id)
  if (idx !== -1) orgs.value[idx] = { ...orgs.value[idx], ...org }
  orgEditando.value = null
}
</script>
