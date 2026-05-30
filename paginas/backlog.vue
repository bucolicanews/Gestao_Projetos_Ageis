<template>
  <div>
    <!-- Cabeçalho -->
    <div class="mb-6">
      <div class="flex items-center justify-between gap-3">
        <h1 class="text-3xl font-bold">📋 Backlog</h1>
        <button
          v-if="projetoId"
          class="px-3 py-1.5 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
          @click="abrirNova"
        >
          + Nova tarefa
        </button>
      </div>
      <p class="text-sm text-slate-500 mt-1">Tarefas sem sprint atribuída</p>

      <div class="flex items-center gap-3 mt-3">
        <select v-model="projetoId" class="px-3 py-2 border rounded-lg text-sm">
          <option value="">Selecione um projeto...</option>
          <option v-for="p in lojaProjetos.projetos" :key="p.id" :value="p.id">
            {{ p.nome }}
          </option>
        </select>
      </div>
    </div>

    <div v-if="!projetoId" class="text-center py-20 text-slate-400">
      Selecione um projeto para ver o backlog.
    </div>

    <div v-else-if="carregando" class="text-center py-20 text-slate-400">
      Carregando...
    </div>

    <div v-else-if="erro" class="text-center py-20">
      <p class="text-red-500 font-medium">Erro ao carregar backlog</p>
      <p class="text-sm text-slate-400 mt-1">{{ erro }}</p>
      <button class="mt-4 text-sm text-indigo-600 hover:underline" @click="carregar">Tentar novamente</button>
    </div>

    <div v-else class="space-y-4">
      <!-- Barra de ações -->
      <div class="w-[95%] mx-auto">
      <div class="flex flex-wrap items-center gap-3">
        <!-- Busca -->
        <input
          v-model="busca"
          type="text"
          placeholder="🔍 Buscar..."
          class="px-3 py-1.5 text-sm border rounded-lg focus:outline-none focus:border-indigo-400 w-full sm:w-48 mx-2 sm:mx-0"
        />

        <!-- Filtro prioridade -->
        <select v-model="filtroPrioridade" class="px-3 py-2 border rounded-lg text-sm">
          <option value="">Todas as prioridades</option>
          <option value="urgente">🔴 Urgente</option>
          <option value="alta">🟠 Alta</option>
          <option value="media">🔵 Média</option>
          <option value="baixa">⚪ Baixa</option>
        </select>

        <!-- Filtro sprint -->
        <select v-model="filtroSprint" class="px-3 py-2 border rounded-lg text-sm max-w-full sm:max-w-[220px]">
          <option value="">Todas as tarefas</option>
          <option value="sem_sprint">Apenas backlog</option>
          <option v-for="s in sprints" :key="s.id" :value="s.id">🔄 {{ s.nome }}</option>
        </select>

        <span class="text-xs text-slate-400 ml-1">
          {{ tarefasFiltradas.length }} tarefa{{ tarefasFiltradas.length !== 1 ? 's' : '' }}
          <span v-if="selecionadas.length"> · {{ selecionadas.length }} selecionada{{ selecionadas.length !== 1 ? 's' : '' }}</span>
        </span>

        <!-- Ações em massa -->
        <div v-if="selecionadas.length" class="w-full flex flex-col gap-2 mt-1">
          <select v-model="sprintDestino" class="px-3 py-2 border rounded-lg text-sm mx-2">
            <option value="">Mover para sprint...</option>
            <option v-for="s in sprints" :key="s.id" :value="s.id">
              {{ s.nome }}
            </option>
          </select>
          <div class="flex items-center gap-2 mx-2">
            <button
              :disabled="!sprintDestino"
              class="px-3 py-1.5 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed"
              @click="moverSelecionadas"
            >
              Mover ({{ selecionadas.length }})
            </button>
            <button
              class="px-3 py-1.5 text-sm bg-red-500 text-white rounded-lg hover:bg-red-600"
              @click="excluirSelecionadas"
            >
              🗑️ Excluir ({{ selecionadas.length }})
            </button>
            <button class="text-xs text-slate-400 hover:text-slate-600 ml-auto" @click="selecionadas = []">
              Cancelar
            </button>
          </div>
        </div>

      </div>
      </div>

      <!-- Tabela de tarefas -->
      <div class="bg-white rounded-xl border border-slate-200 overflow-hidden overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-slate-50 border-b border-slate-200">
            <tr>
              <th class="w-8 px-4 py-3">
                <input
                  type="checkbox"
                  :checked="todasSelecionadas"
                  :indeterminate="selecionadas.length > 0 && !todasSelecionadas"
                  class="rounded"
                  @change="alternarTodas"
                />
              </th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Tarefa</th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide w-36">Sprint</th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide w-28">Prioridade</th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide w-24">Pontos</th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide w-36">Responsável</th>
              <th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide w-32">Prazo</th>
              <th class="px-4 py-3 w-28"></th>
            </tr>
          </thead>

          <tbody class="divide-y divide-slate-100">
            <!-- Sem resultados -->
            <tr v-if="tarefasFiltradas.length === 0">
              <td colspan="8" class="px-4 py-12 text-center text-slate-400">
                {{ lista.length === 0 ? 'Nenhuma tarefa. Crie a primeira.' : 'Nenhuma tarefa encontrada.' }}
              </td>
            </tr>

            <!-- Linhas de tarefa -->
            <tr
              v-for="t in tarefasFiltradas"
              :key="t.id"
              :class="['group hover:bg-slate-50 transition-colors', selecionadas.includes(t.id) ? 'bg-indigo-50' : '']"
            >
              <td class="px-4 py-3">
                <input
                  type="checkbox"
                  :checked="selecionadas.includes(t.id)"
                  class="rounded"
                  @change="alternarSelecao(t.id)"
                />
              </td>

              <td class="px-4 py-3">
                <span class="font-medium text-slate-800">{{ t.titulo }}</span>
                <span v-if="t.descricao" class="text-slate-400 text-xs ml-2 truncate max-w-xs hidden md:inline">
                  {{ t.descricao }}
                </span>
              </td>

              <td class="px-4 py-3">
                <span
                  v-if="t.sprint"
                  class="text-[10px] px-2 py-0.5 rounded-full bg-indigo-100 text-indigo-700 font-semibold"
                  :title="t.sprint.nome"
                >
                  {{ t.sprint.nome }}
                </span>
                <span v-else class="text-slate-300 text-xs">— backlog</span>
              </td>

              <td class="px-4 py-3">
                <span :class="['text-[10px] px-2 py-0.5 rounded-full uppercase font-bold', corPrioridade(t.prioridade)]">
                  {{ t.prioridade || '—' }}
                </span>
              </td>

              <td class="px-4 py-3 text-slate-500">
                <span v-if="t.pontos" class="bg-slate-100 text-slate-600 text-xs px-2 py-0.5 rounded-full font-medium">
                  {{ t.pontos }} pts
                </span>
                <span v-else class="text-slate-300">—</span>
              </td>

              <td class="px-4 py-3 text-slate-500 text-xs">
                {{ t.responsavel?.nome || '—' }}
              </td>

              <td class="px-4 py-3 text-slate-400 text-xs">
                {{ t.prazo ? new Date(t.prazo).toLocaleDateString('pt-BR') : '—' }}
              </td>

              <td class="px-4 py-3">
                <div class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    v-if="!t.sprint"
                    class="text-xs text-indigo-500 hover:text-indigo-700 px-2 py-1 rounded hover:bg-indigo-50"
                    @click="abrirMoverUnica(t)"
                  >
                    Sprint ↗
                  </button>
                  <button
                    v-else
                    class="text-xs text-rose-400 hover:text-rose-600 px-2 py-1 rounded hover:bg-rose-50"
                    @click="removerDaSprint(t)"
                  >
                    ← Backlog
                  </button>
                  <button
                    class="text-xs text-slate-400 hover:text-primaria px-2 py-1 rounded hover:bg-slate-50"
                    title="Editar tarefa"
                    @click="abrirEdicao(t)"
                  >
                    ✏️
                  </button>
                  <button
                    class="text-xs text-slate-400 hover:text-red-500 px-2 py-1 rounded hover:bg-red-50"
                    title="Excluir tarefa"
                    @click="excluirUma(t)"
                  >
                    🗑️
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Rodapé com totais -->
      <div v-if="lista.length" class="flex gap-6 text-xs text-slate-400 px-2">
        <span>Total: <strong class="text-slate-600">{{ lista.length }}</strong></span>
        <span>Pontos: <strong class="text-slate-600">{{ totalPontos }}</strong></span>
        <span>Urgente: <strong class="text-red-500">{{ contarPrioridade('urgente') }}</strong></span>
        <span>Alta: <strong class="text-amber-500">{{ contarPrioridade('alta') }}</strong></span>
      </div>
    </div>

    <!-- Modal criar / editar tarefa -->
    <ModalTarefa
      :exibir="exibirModal"
      :tarefa="tarefaParaEditar ?? { projeto_id: projetoId, coluna: 'backlog', prioridade: 'media' }"
      :membros="membrosDoProj"
      @fechar="fecharModal"
      @salvo="aoSalvarTarefa"
      @deletado="aoExcluirTarefa"
    />

    <!-- Modal mover tarefa única para sprint -->
    <div v-if="tarefaParaMover" class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-xl p-6 w-full max-w-xs shadow-xl">
        <h3 class="font-semibold text-slate-800 mb-1">Mover para sprint</h3>
        <p class="text-sm text-slate-500 mb-4 truncate">{{ tarefaParaMover.titulo }}</p>
        <select v-model="sprintUnica" class="w-full px-3 py-2 border rounded-lg text-sm mb-4 focus:outline-none focus:border-indigo-400">
          <option value="">Selecione uma sprint...</option>
          <option v-for="s in sprints" :key="s.id" :value="s.id">{{ s.nome }}</option>
        </select>
        <div class="flex gap-2 justify-end">
          <button class="px-4 py-2 text-sm text-slate-600 hover:text-slate-800" @click="tarefaParaMover = null">Cancelar</button>
          <button
            :disabled="!sprintUnica"
            class="px-4 py-2 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-40"
            @click="confirmarMoverUnica"
          >
            Mover
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import ModalTarefa from '~/componentes/ModalTarefa.vue'

const route = useRoute()
const lojaProjetos = useLojaProjetos()
const svcTarefas = servicoTarefas()
const svcSprints = servicoSprints()

const projetoId = ref(String(route.query.projeto ?? ''))
const lista = ref<any[]>([])
const sprints = ref<any[]>([])
const carregando = ref(false)
const erro = ref('')
const busca = ref('')
const filtroPrioridade = ref('')
const filtroSprint = ref('')
const selecionadas = ref<string[]>([])
const sprintDestino = ref('')
const exibirModal = ref(false)
const membrosDoProj = ref<any[]>([])
const tarefaParaMover = ref<any>(null)
const tarefaParaEditar = ref<any>(null)
const sprintUnica = ref('')

const tarefasFiltradas = computed(() => {
  return lista.value.filter(t => {
    const buscaOk = !busca.value || t.titulo.toLowerCase().includes(busca.value.toLowerCase())
    const prioOk = !filtroPrioridade.value || t.prioridade === filtroPrioridade.value
    const sprintOk = !filtroSprint.value
      || (filtroSprint.value === 'sem_sprint' && !t.sprint)
      || (filtroSprint.value !== 'sem_sprint' && t.sprint?.id === filtroSprint.value)
    return buscaOk && prioOk && sprintOk
  })
})

const selecionaveis = computed(() => tarefasFiltradas.value)

const todasSelecionadas = computed(() =>
  selecionaveis.value.length > 0 && selecionaveis.value.every(t => selecionadas.value.includes(t.id))
)

const totalPontos = computed(() => lista.value.reduce((a, t) => a + (t.pontos || 0), 0))

function contarPrioridade(p: string) {
  return lista.value.filter(t => t.prioridade === p).length
}

function corPrioridade(p: string) {
  return {
    baixa: 'bg-slate-100 text-slate-500',
    media: 'bg-blue-100 text-blue-600',
    alta: 'bg-amber-100 text-amber-700',
    urgente: 'bg-red-100 text-red-600',
  }[p] || 'bg-slate-100 text-slate-400'
}

function alternarSelecao(id: string) {
  const i = selecionadas.value.indexOf(id)
  if (i >= 0) selecionadas.value.splice(i, 1)
  else selecionadas.value.push(id)
}

function alternarTodas() {
  if (todasSelecionadas.value) {
    selecionadas.value = []
  } else {
    selecionadas.value = selecionaveis.value.map(t => t.id)
  }
}

async function carregar() {
  if (!projetoId.value) return
  carregando.value = true
  erro.value = ''
  try {
    const [tarefas, sprintsData] = await Promise.all([
      svcTarefas.listarComSprint(projetoId.value),
      svcSprints.listar(projetoId.value),
    ])
    lista.value = tarefas
    sprints.value = sprintsData
    selecionadas.value = []
  } catch (e: any) {
    erro.value = e?.message || 'Erro desconhecido'
  } finally {
    carregando.value = false
  }
}

async function abrirNova() {
  if (!membrosDoProj.value.length && projetoId.value) {
    membrosDoProj.value = await servicoEquipe().listarMembrosPorID(projetoId.value).catch(() => [])
  }
  tarefaParaEditar.value = null
  exibirModal.value = true
}

async function abrirEdicao(t: any) {
  if (!membrosDoProj.value.length && projetoId.value) {
    membrosDoProj.value = await servicoEquipe().listarMembrosPorID(projetoId.value).catch(() => [])
  }
  tarefaParaEditar.value = t
  exibirModal.value = true
}

function fecharModal() {
  exibirModal.value = false
  tarefaParaEditar.value = null
}

function aoSalvarTarefa(salva: any) {
  if (!salva?.id) return
  const idx = lista.value.findIndex(t => t.id === salva.id)
  if (idx >= 0) lista.value[idx] = { ...lista.value[idx], ...salva }
  else lista.value.unshift({ ...salva, sprint: salva.sprint ?? null })
  fecharModal()
}

function aoExcluirTarefa(id: string) {
  lista.value = lista.value.filter(t => t.id !== id)
  selecionadas.value = selecionadas.value.filter(s => s !== id)
}

async function excluirUma(t: any) {
  if (!confirm(`Excluir "${t.titulo}"?`)) return
  await servicoTarefas().excluirTarefa(t.id)
  aoExcluirTarefa(t.id)
}

async function excluirSelecionadas() {
  if (!confirm(`Excluir ${selecionadas.value.length} tarefa(s) permanentemente?`)) return
  await Promise.all(selecionadas.value.map(id => servicoTarefas().excluirTarefa(id)))
  selecionadas.value.forEach(id => aoExcluirTarefa(id))
  selecionadas.value = []
}

async function moverSelecionadas() {
  if (!sprintDestino.value || !selecionadas.value.length) return
  const sprintId = sprintDestino.value
  await Promise.all(selecionadas.value.map(id => svcSprints.associarTarefa(id, sprintId)))
  const sprint = sprints.value.find(s => s.id === sprintId)
  // Update in-place so the Sprint column shows the link
  lista.value = lista.value.map(t =>
    selecionadas.value.includes(t.id) ? { ...t, sprint_id: sprintId, sprint: sprint ?? null } : t
  )
  selecionadas.value = []
  sprintDestino.value = ''
}

function abrirMoverUnica(t: any) {
  tarefaParaMover.value = t
  sprintUnica.value = ''
}

async function confirmarMoverUnica() {
  if (!sprintUnica.value || !tarefaParaMover.value) return
  const sprintId = sprintUnica.value
  await svcSprints.associarTarefa(tarefaParaMover.value.id, sprintId)
  const sprint = sprints.value.find(s => s.id === sprintId)
  lista.value = lista.value.map(t =>
    t.id === tarefaParaMover.value.id ? { ...t, sprint_id: sprintId, sprint: sprint ?? null } : t
  )
  tarefaParaMover.value = null
}

async function removerDaSprint(t: any) {
  await svcSprints.associarTarefa(t.id, null)
  lista.value = lista.value.map(r =>
    r.id === t.id ? { ...r, sprint_id: null, sprint: null } : r
  )
}

watch(projetoId, carregar, { immediate: true })

onMounted(async () => {
  if (!lojaProjetos.projetos.length) await lojaProjetos.carregar()
})
</script>
