<template>
  <div>
    <!-- Header -->
    <div class="flex justify-between items-start mb-6 flex-wrap gap-3">
      <div>
        <NuxtLink to="/projetos" class="text-xs text-slate-400 hover:text-primaria">← Projetos</NuxtLink>
        <h1 class="text-3xl font-bold mt-1">{{ projeto?.nome || 'Carregando...' }}</h1>
        <p v-if="projeto?.descricao" class="text-sm text-slate-500 mt-1">{{ projeto.descricao }}</p>
      </div>

      <div class="flex gap-2 flex-wrap">
        <NuxtLink :to="`/dashboardProjeto?id=${projetoId}`" class="botao-secundario text-sm">📊 Dashboard</NuxtLink>
        <NuxtLink :to="`/kanban?projeto=${projetoId}`" class="botao-secundario text-sm">📌 Kanban</NuxtLink>
        <NuxtLink :to="`/sprints?projeto=${projetoId}`" class="botao-secundario text-sm">🔄 Sprints</NuxtLink>
        <NuxtLink :to="`/backlog?projeto=${projetoId}`" class="botao-secundario text-sm">📋 Backlog</NuxtLink>
        <NuxtLink :to="`/equipe?projeto=${projetoId}`" class="botao-secundario text-sm">👥 Equipe</NuxtLink>
      </div>
    </div>

    <div v-if="carregando" class="text-center py-20 text-slate-400">Carregando...</div>

    <div v-else class="space-y-4">
      <!-- Sumário rápido -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-primaria">{{ membros.length }}</div>
          <div class="text-xs text-slate-500">Membros</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-amber-600">{{ tarefasAtivas }}</div>
          <div class="text-xs text-slate-500">Tarefas ativas</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-green-600">{{ tarefasConcluidas }}</div>
          <div class="text-xs text-slate-500">Concluídas</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-slate-600">{{ semResponsavel }}</div>
          <div class="text-xs text-slate-500">Sem responsável</div>
        </div>
      </div>

      <!-- Tarefas sem responsável -->
      <div v-if="semResponsavel > 0" class="cartao border-l-4 border-amber-400">
        <div class="flex items-center justify-between mb-3">
          <h3 class="font-semibold text-slate-700">⚠ Sem responsável ({{ semResponsavel }})</h3>
          <button class="text-xs text-slate-400 hover:text-slate-600" @click="expandidoSemResponsavel = !expandidoSemResponsavel">
            {{ expandidoSemResponsavel ? '▾' : '▸' }}
          </button>
        </div>
        <ul v-if="expandidoSemResponsavel" class="space-y-1">
          <li
            v-for="t in tarefasSemResponsavel"
            :key="t.id"
            class="flex items-center gap-2 text-sm py-1 border-b border-slate-50 last:border-0"
          >
            <span :class="['w-2 h-2 rounded-full shrink-0', corPonto(t.coluna)]" />
            <span class="flex-1 truncate text-slate-700">{{ t.titulo }}</span>
            <span :class="['text-[10px] px-1.5 py-0.5 rounded font-bold uppercase', corColuna(t.coluna)]">{{ labelColuna(t.coluna) }}</span>
            <span v-if="t.prioridade" :class="['text-[10px] px-1.5 py-0.5 rounded font-bold uppercase', corPrioridade(t.prioridade)]">{{ t.prioridade }}</span>
          </li>
        </ul>
      </div>

      <!-- Card por membro -->
      <div v-for="m in membros" :key="m.usuario_id" class="cartao">
        <!-- Cabeçalho do membro -->
        <div class="flex items-center gap-3 mb-3">
          <div class="shrink-0">
            <img v-if="m.usuarios?.avatar_url" :src="m.usuarios.avatar_url" class="w-10 h-10 rounded-full object-cover" />
            <div v-else class="w-10 h-10 rounded-full bg-indigo-100 text-indigo-700 font-bold flex items-center justify-center">
              {{ inicial(m.usuarios?.nome) }}
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="font-semibold text-slate-800">{{ m.usuarios?.nome || '—' }}</span>
              <span :class="['text-[10px] px-2 py-0.5 rounded-full font-bold uppercase', corPapel(m.papel)]">
                {{ nomePapel(m.papel) }}
              </span>
            </div>
            <div class="text-xs text-slate-500">{{ m.usuarios?.email }}</div>
          </div>
          <!-- Stats do membro -->
          <div class="flex gap-4 text-center shrink-0">
            <div>
              <div class="text-lg font-bold text-amber-600">{{ tarefasDoMembro(m.usuario_id).filter(t => t.coluna !== 'concluido').length }}</div>
              <div class="text-[10px] text-slate-400">ativas</div>
            </div>
            <div>
              <div class="text-lg font-bold text-green-600">{{ tarefasDoMembro(m.usuario_id).filter(t => t.coluna === 'concluido').length }}</div>
              <div class="text-[10px] text-slate-400">concluídas</div>
            </div>
            <div>
              <div class="text-lg font-bold text-indigo-600">{{ pontosDoMembro(m.usuario_id) }}</div>
              <div class="text-[10px] text-slate-400">pontos</div>
            </div>
          </div>
        </div>

        <!-- Lista de tarefas do membro -->
        <div v-if="tarefasDoMembro(m.usuario_id).length" class="border-t border-slate-100 pt-3 space-y-1">
          <div
            v-for="t in tarefasDoMembro(m.usuario_id)"
            :key="t.id"
            class="group"
          >
            <div class="flex items-center gap-2 text-sm py-1.5 rounded px-1 hover:bg-slate-50">
              <span :class="['w-2 h-2 rounded-full shrink-0', corPonto(t.coluna)]" />
              <span class="flex-1 truncate text-slate-700">{{ t.titulo }}</span>
              <span v-if="t.pontos" class="text-[10px] text-slate-400 shrink-0">{{ t.pontos }}pts</span>
              <span :class="['text-[10px] px-1.5 py-0.5 rounded font-bold uppercase shrink-0', corColuna(t.coluna)]">
                {{ labelColuna(t.coluna) }}
              </span>
              <span :class="['text-[10px] px-1.5 py-0.5 rounded font-bold uppercase shrink-0', corPrioridade(t.prioridade)]">
                {{ t.prioridade }}
              </span>
              <!-- Expandir subtarefas -->
              <button
                v-if="t.subtarefas_count > 0"
                class="text-[10px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-500 hover:bg-slate-200 shrink-0"
                @click="toggleSub(t.id)"
              >
                {{ expandidoSub[t.id] ? '▾' : '▸' }} {{ t.subtarefas_count }}
              </button>
            </div>

            <!-- Subtarefas -->
            <div v-if="expandidoSub[t.id] && subTarefasMap[t.id]?.length" class="ml-6 border-l-2 border-slate-100 pl-3 pb-1 space-y-0.5">
              <div
                v-for="sub in subTarefasMap[t.id]"
                :key="sub.id"
                class="flex items-center gap-2 text-xs py-1 text-slate-600"
              >
                <span :class="['w-1.5 h-1.5 rounded-full shrink-0', corPonto(sub.coluna)]" />
                <span class="flex-1 truncate" :class="sub.coluna === 'concluido' ? 'line-through text-slate-400' : ''">
                  {{ sub.titulo }}
                </span>
                <span :class="['text-[10px] px-1.5 py-0.5 rounded font-bold uppercase shrink-0', corColuna(sub.coluna)]">
                  {{ labelColuna(sub.coluna) }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div v-else class="border-t border-slate-100 pt-3 text-xs text-slate-400 text-center py-2">
          Nenhuma tarefa atribuída
        </div>
      </div>

      <!-- Sem membros -->
      <div v-if="!membros.length" class="cartao text-center py-10 text-slate-400">
        Nenhum membro neste projeto.
        <NuxtLink :to="`/equipe?projeto=${projetoId}`" class="block mt-2 text-indigo-500 hover:underline text-sm">
          Adicionar membros →
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted } from 'vue'

const PAPEIS = [
  { codigo: 'desenvolvedor', nome: 'Desenvolvedor' },
  { codigo: 'admin', nome: 'Administrador' },
  { codigo: 'engenheiro_software', nome: 'Engenheiro de Software' },
  { codigo: 'gerente_projeto', nome: 'Gerente de Projeto' },
  { codigo: 'lider_equipe', nome: 'Líder de Equipe' },
  { codigo: 'analista_qualidade', nome: 'Qualidade / QA' },
  { codigo: 'designer', nome: 'Designer UX/UI' },
]

const COR_PAPEL: Record<string, string> = {
  desenvolvedor: 'bg-purple-100 text-purple-700',
  admin: 'bg-blue-100 text-blue-700',
  engenheiro_software: 'bg-cyan-100 text-cyan-700',
  gerente_projeto: 'bg-amber-100 text-amber-700',
  lider_equipe: 'bg-green-100 text-green-700',
  analista_qualidade: 'bg-emerald-100 text-emerald-700',
  designer: 'bg-pink-100 text-pink-700',
}

const route = useRoute()
const cliente = useSupabaseClient()
const svcEquipe = servicoEquipe()

const projetoId = String(route.query.id || route.query.projeto || '')
const projeto = ref<any>(null)
const membros = ref<any[]>([])
const tarefas = ref<any[]>([])          // root tasks
const subTarefasMap = reactive<Record<string, any[]>>({})
const carregando = ref(false)
const expandidoSub = reactive<Record<string, boolean>>({})
const expandidoSemResponsavel = ref(false)

const tarefasAtivas = computed(() => tarefas.value.filter(t => t.coluna !== 'concluido').length)
const tarefasConcluidas = computed(() => tarefas.value.filter(t => t.coluna === 'concluido').length)
const semResponsavel = computed(() => tarefas.value.filter(t => !t.responsavel_id).length)
const tarefasSemResponsavel = computed(() => tarefas.value.filter(t => !t.responsavel_id))

function tarefasDoMembro(usuarioId: string) {
  return tarefas.value.filter(t => t.responsavel_id === usuarioId)
}

function pontosDoMembro(usuarioId: string) {
  return tarefasDoMembro(usuarioId).reduce((a, t) => a + (t.pontos || 0), 0)
}

function inicial(nome?: string) { return (nome || '?').charAt(0).toUpperCase() }
function nomePapel(c: string) { return PAPEIS.find(p => p.codigo === c)?.nome || c }
function corPapel(c: string) { return COR_PAPEL[c] || 'bg-slate-100 text-slate-600' }

function corColuna(coluna: string) {
  return {
    backlog: 'bg-slate-100 text-slate-500',
    a_fazer: 'bg-blue-100 text-blue-600',
    em_progresso: 'bg-amber-100 text-amber-700',
    em_revisao: 'bg-violet-100 text-violet-700',
    concluido: 'bg-green-100 text-green-700',
  }[coluna] || 'bg-slate-100 text-slate-500'
}

function labelColuna(coluna: string) {
  return {
    backlog: 'Backlog',
    a_fazer: 'A fazer',
    em_progresso: 'Em progresso',
    em_revisao: 'Em revisão',
    concluido: 'Concluído',
  }[coluna] || coluna
}

function corPonto(coluna: string) {
  return {
    backlog: 'bg-slate-300',
    a_fazer: 'bg-blue-400',
    em_progresso: 'bg-amber-400',
    em_revisao: 'bg-violet-400',
    concluido: 'bg-green-400',
  }[coluna] || 'bg-slate-300'
}

function corPrioridade(p: string) {
  return {
    urgente: 'bg-red-100 text-red-600',
    alta: 'bg-amber-100 text-amber-700',
    media: 'bg-blue-100 text-blue-600',
    baixa: 'bg-slate-100 text-slate-500',
  }[p] || 'bg-slate-100 text-slate-400'
}

async function toggleSub(tarefaId: string) {
  expandidoSub[tarefaId] = !expandidoSub[tarefaId]
  if (expandidoSub[tarefaId] && !subTarefasMap[tarefaId]) {
    const { data } = await cliente
      .from('tarefas')
      .select('id, titulo, coluna, prioridade')
      .eq('tarefa_pai_id', tarefaId)
      .order('posicao')
    subTarefasMap[tarefaId] = data || []
  }
}

async function carregar() {
  if (!projetoId) return
  carregando.value = true
  try {
    const [projetoRes, membrosData, tarefasRes] = await Promise.all([
      cliente.from('projetos').select('*').eq('id', projetoId).single(),
      svcEquipe.listarMembrosPorID(projetoId),
      cliente.from('tarefas')
        .select('id, titulo, coluna, prioridade, pontos, responsavel_id, subtarefas_count:tarefas!tarefa_pai_id(count)')
        .eq('projeto_id', projetoId)
        .is('tarefa_pai_id', null)
        .order('posicao'),
    ])
    projeto.value = projetoRes.data
    membros.value = membrosData || []
    tarefas.value = (tarefasRes.data || []).map((t: any) => ({
      ...t,
      subtarefas_count: t.subtarefas_count?.[0]?.count ?? 0,
    }))
  } finally {
    carregando.value = false
  }
}

onMounted(carregar)
</script>
