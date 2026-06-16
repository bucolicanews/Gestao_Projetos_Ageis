<template>
  <Teleport to="body">
    <div
      v-if="exibir"
      class="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">

        <!-- Cabeçalho -->
        <div class="p-6 border-b flex justify-between items-center">
          <h2 class="text-xl font-bold text-slate-800">{{ criando ? 'Nova tarefa' : 'Editar tarefa' }}</h2>
          <button class="text-slate-400 hover:text-slate-600 text-2xl leading-none" @click="$emit('fechar')">
            &times;
          </button>
        </div>

        <!-- Abas -->
        <div class="flex border-b px-6">
          <button
            v-for="aba in abasVisiveis"
            :key="aba.id"
            :class="[
              'px-4 py-2 text-sm font-medium transition-colors',
              abaAtiva === aba.id
                ? 'border-b-2 border-primaria text-primaria'
                : 'text-slate-500 hover:text-slate-700'
            ]"
            @click="abaAtiva = aba.id"
          >
            {{ aba.label }}
          </button>
        </div>

        <!-- ═══ ABA: DETALHES ═══ -->
        <div v-if="abaAtiva === 'detalhe'" class="p-6 space-y-5">

          <!-- Título -->
          <div>
            <label class="label-campo">Título</label>
            <input
              v-model="form.titulo"
              type="text"
              class="campo"
              placeholder="O que precisa ser feito?"
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="label-campo">Tipo</label>
              <select v-model="form.tipo_tarefa" class="campo">
                <option v-for="t in TIPOS" :key="t.v" :value="t.v">{{ t.l }}</option>
              </select>
            </div>
            <div>
              <label class="label-campo">Prioridade</label>
              <select v-model="form.prioridade" class="campo">
                <option value="baixa">Baixa</option>
                <option value="media">Média</option>
                <option value="alta">Alta</option>
                <option value="urgente">Urgente</option>
              </select>
            </div>
            <div>
              <label class="label-campo">Coluna Kanban</label>
              <select v-model="form.coluna" class="campo">
                <option value="backlog">Backlog</option>
                <option value="a_fazer">A Fazer</option>
                <option value="em_progresso">Em Progresso</option>
                <option value="em_revisao">Em Revisão</option>
                <option value="concluido">Concluído</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="label-campo">Responsável</label>
              <select v-model="form.responsavel_id" class="campo">
                <option :value="null">Não atribuído</option>
                <option
                  v-for="m in membros"
                  :key="m.usuario_id || m.id"
                  :value="m.usuario_id || m.id"
                >
                  {{ m.usuario?.nome || m.usuarios?.nome || m.nome || m.email }}
                </option>
              </select>
            </div>
            <div>
              <label class="label-campo">Prazo</label>
              <input v-model="form.prazo" type="date" class="campo" />
            </div>
          </div>

          <div>
            <label class="label-campo">Descrição</label>
            <textarea
              v-model="form.descricao"
              rows="3"
              class="campo"
              placeholder="Contexto, objetivo, detalhes..."
            />
          </div>

          <!-- Subtarefas -->
          <div>
            <label class="label-campo">Subtarefas</label>
            <div class="border rounded-lg p-3 bg-slate-50">
              <ListaSubtarefas
                v-if="tarefa?.id"
                :tarefa-pai-id="tarefa.id"
                :projeto-id="tarefa.projeto_id"
                :sprint-id="tarefa.sprint_id"
              />
              <p v-else class="text-xs text-slate-400">Salve a tarefa primeiro para adicionar subtarefas.</p>
            </div>
          </div>
        </div>

        <!-- ═══ ABA: ESTIMATIVA ═══ -->
        <div v-else-if="abaAtiva === 'estimativa'" class="p-6 space-y-6">

          <!-- Story Points -->
          <div>
            <label class="label-campo">Story Points (Fibonacci)</label>
            <div class="flex flex-wrap gap-2 mt-1">
              <button
                v-for="p in FIBONACCI"
                :key="p"
                type="button"
                :class="['fib-btn', form.pontos === p ? 'fib-btn--active' : '']"
                @click="form.pontos = form.pontos === p ? null : p"
              >
                {{ p }}
              </button>
              <button
                v-if="form.pontos !== null"
                type="button"
                class="fib-btn text-slate-400 text-xs"
                @click="form.pontos = null"
              >
                limpar
              </button>
            </div>
            <p class="text-xs text-slate-400 mt-1">Selecionado: <strong>{{ form.pontos ?? '—' }}</strong></p>
          </div>

          <!-- Complexidade -->
          <div>
            <label class="label-campo">Complexidade técnica (1 = trivial · 5 = muito alta)</label>
            <div class="flex gap-2 mt-1">
              <button
                v-for="n in 5"
                :key="n"
                type="button"
                :class="['fib-btn', form.complexidade === n ? 'fib-btn--active' : '']"
                @click="form.complexidade = form.complexidade === n ? null : n"
              >
                {{ n }}
              </button>
            </div>
          </div>

          <!-- Estimativa de horas -->
          <div>
            <label class="label-campo">Estimativa (horas ideais)</label>
            <input
              v-model.number="form.estimativa_horas"
              type="number"
              min="0"
              step="0.5"
              class="campo max-w-[140px]"
              placeholder="Ex: 4"
            />
          </div>

          <!-- Tags -->
          <div>
            <label class="label-campo">Tags <span class="font-normal normal-case text-slate-400">(separadas por vírgula)</span></label>
            <input
              v-model="tagsInput"
              type="text"
              class="campo"
              placeholder="frontend, api, autenticação"
            />
          </div>

          <!-- Critério de aceite -->
          <div>
            <label class="label-campo">Critério de aceite</label>
            <textarea
              v-model="form.criterio_aceite"
              rows="4"
              class="campo"
              placeholder="Dado que [contexto], quando [ação], então [resultado esperado]..."
            />
          </div>

          <!-- DoR / DoD -->
          <div class="grid grid-cols-2 gap-3">
            <label
              :class="[
                'flex items-start gap-3 p-4 rounded-xl border cursor-pointer transition-colors',
                form.dor_ok
                  ? 'border-sucesso bg-green-50 text-green-800'
                  : 'border-slate-200 hover:border-slate-300'
              ]"
            >
              <input v-model="form.dor_ok" type="checkbox" class="mt-0.5" />
              <div>
                <p class="font-semibold text-sm">Definition of Ready</p>
                <p class="text-xs text-slate-500 mt-0.5">Descrição clara, estimada, refinada, sem bloqueios</p>
              </div>
            </label>
            <label
              :class="[
                'flex items-start gap-3 p-4 rounded-xl border cursor-pointer transition-colors',
                form.dod_ok
                  ? 'border-sucesso bg-green-50 text-green-800'
                  : 'border-slate-200 hover:border-slate-300'
              ]"
            >
              <input v-model="form.dod_ok" type="checkbox" class="mt-0.5" />
              <div>
                <p class="font-semibold text-sm">Definition of Done</p>
                <p class="text-xs text-slate-500 mt-0.5">Código, testes, review, deploy staging, aceite aprovado</p>
              </div>
            </label>
          </div>
        </div>

        <!-- ═══ ABA: GIT ═══ -->
        <GuiaGit
          v-else-if="abaAtiva === 'git'"
          :tipo="form.tipo_tarefa"
          :titulo="form.titulo"
        />

        <!-- ═══ ABA: HISTÓRICO ═══ -->
        <div v-else-if="abaAtiva === 'historico'" class="p-6 space-y-4">
          <div v-if="carregandoHistorico" class="text-center py-10 text-slate-400 text-sm">
            Carregando...
          </div>
          <div v-else-if="historico.length">
            <div v-for="h in historico" :key="h.id" class="flex gap-3 text-sm py-2 border-b last:border-0">
              <div class="w-2 h-2 rounded-full bg-primaria mt-1.5 shrink-0" />
              <div>
                <p class="text-slate-700">
                  Movida para <strong>{{ rotuloColunaHistorico(h.coluna_destino) }}</strong>
                  <span v-if="h.coluna_origem">
                    de <span class="text-slate-400">{{ rotuloColunaHistorico(h.coluna_origem) }}</span>
                  </span>
                </p>
                <p class="text-[10px] text-slate-400">{{ formatarData(h.movido_em) }}</p>
              </div>
            </div>
          </div>
          <div v-else class="text-center py-10 text-slate-400 text-sm">
            Nenhuma movimentação registrada.
          </div>
        </div>

        <!-- Rodapé -->
        <div class="p-6 border-t bg-slate-50 space-y-3">
          <!-- Erro -->
          <div v-if="erroSalvar" class="text-xs text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
            ⚠️ {{ erroSalvar }}
          </div>

          <div class="flex justify-between items-center gap-4">
            <button
              v-if="!criando"
              class="text-red-500 text-sm font-semibold hover:text-red-700 flex items-center gap-1"
              @click="excluir"
            >
              🗑️ Deletar
            </button>
            <div v-else />

            <div class="flex gap-3">
              <button class="px-4 py-2 text-sm text-slate-600 hover:text-slate-800" @click="$emit('fechar')">
                Cancelar
              </button>
              <button
                :disabled="salvando || !form.titulo.trim()"
                class="bg-primaria text-white px-4 py-2 rounded-lg text-sm font-semibold hover:opacity-90 disabled:opacity-50"
                @click="salvar"
              >
                {{ salvando ? 'Salvando...' : criando ? 'Criar tarefa' : 'Salvar' }}
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue'

const FIBONACCI = [1, 2, 3, 5, 8, 13, 21]

const TIPOS = [
  { v: 'feature',  l: '✨ Feature' },
  { v: 'bug',      l: '🐛 Bug' },
  { v: 'melhoria', l: '⚡ Melhoria' },
  { v: 'techdeb',  l: '🔧 Tech Debt' },
  { v: 'spike',    l: '🔬 Spike' },
]

const ABAS = [
  { id: 'detalhe',    label: 'Detalhes' },
  { id: 'estimativa', label: 'Estimativa' },
  { id: 'git',        label: '🌿 Git' },
  { id: 'historico',  label: 'Histórico' },
]

const props = defineProps<{
  exibir: boolean
  tarefa: any
  membros: any[]
}>()

const emit = defineEmits(['fechar', 'salvo', 'deletado'])

const abaAtiva = ref('detalhe')
const salvando = ref(false)
const erroSalvar = ref('')
const carregandoHistorico = ref(false)
const historico = ref<any[]>([])
const tagsInput = ref('')

const form = ref({
  titulo: '',
  tipo_tarefa: 'feature',
  responsavel_id: null as string | null,
  coluna: 'backlog',
  prioridade: 'media',
  descricao: '',
  prazo: '',
  pontos: null as number | null,
  complexidade: null as number | null,
  estimativa_horas: null as number | null,
  criterio_aceite: '',
  tags: [] as string[],
  dor_ok: false,
  dod_ok: false,
})

const criando = computed(() => !props.tarefa?.id)
const abasVisiveis = computed(() =>
  criando.value ? ABAS.filter(a => a.id !== 'historico') : ABAS
)

watch(() => props.exibir, async (val) => {
  if (val) {
    abaAtiva.value = 'detalhe'
    erroSalvar.value = ''
    const t = props.tarefa
    form.value = {
      titulo:           t?.titulo           ?? '',
      tipo_tarefa:      t?.tipo_tarefa      ?? 'feature',
      responsavel_id:   t?.responsavel_id   ?? null,
      coluna:           t?.coluna           ?? 'a_fazer',
      prioridade:       t?.prioridade       ?? 'media',
      descricao:        t?.descricao        ?? '',
      prazo:            t?.prazo ? t.prazo.split('T')[0] : '',
      pontos:           t?.pontos           ?? null,
      complexidade:     t?.complexidade     ?? null,
      estimativa_horas: t?.estimativa_horas ?? null,
      criterio_aceite:  t?.criterio_aceite  ?? '',
      tags:             Array.isArray(t?.tags) ? [...t.tags] : [],
      dor_ok:           t?.dor_ok           ?? false,
      dod_ok:           t?.dod_ok           ?? false,
    }
    tagsInput.value = form.value.tags.join(', ')
  }
}, { immediate: true })

watch(abaAtiva, async (aba) => {
  if (aba === 'historico' && props.tarefa?.id) {
    await carregarHistorico()
  }
})

async function carregarHistorico() {
  carregandoHistorico.value = true
  const cliente = useSupabaseClient()
  const { data } = await cliente
    .from('historico_movimentacao')
    .select('*')
    .eq('tarefa_id', props.tarefa.id)
    .order('movido_em', { ascending: false })
  historico.value = data || []
  carregandoHistorico.value = false
}

async function salvar() {
  if (!form.value.titulo.trim() || salvando.value) return
  salvando.value = true
  erroSalvar.value = ''
  try {
    const svc = servicoTarefas()
    const payload = {
      titulo:           form.value.titulo,
      tipo_tarefa:      form.value.tipo_tarefa,
      responsavel_id:   form.value.responsavel_id,
      coluna:           form.value.coluna,
      prioridade:       form.value.prioridade,
      descricao:        form.value.descricao,
      prazo:            form.value.prazo || null,
      pontos:           form.value.pontos,
      complexidade:     form.value.complexidade,
      estimativa_horas: form.value.estimativa_horas || null,
      criterio_aceite:  form.value.criterio_aceite || null,
      tags: tagsInput.value
        .split(',')
        .map(s => s.trim())
        .filter(Boolean),
      dor_ok: form.value.dor_ok,
      dod_ok: form.value.dod_ok,
    }

    if (criando.value) {
      const nova = await svc.criarTarefa({
        ...payload,
        projeto_id: props.tarefa?.projeto_id,
        sprint_id:  props.tarefa?.sprint_id ?? null,
      })
      emit('salvo', nova)
    } else {
      await svc.atualizarTarefa(props.tarefa.id, payload)
      emit('salvo', { ...props.tarefa, ...payload })
    }
    emit('fechar')
  } catch (e: any) {
    erroSalvar.value = e?.message ?? String(e)
  } finally {
    salvando.value = false
  }
}

async function excluir() {
  if (!confirm(`Excluir "${props.tarefa.titulo}" permanentemente? Subtarefas também serão removidas.`)) return
  await servicoTarefas().excluirTarefa(props.tarefa.id)
  emit('deletado', props.tarefa.id)
  emit('fechar')
}

function rotuloColunaHistorico(col: string) {
  const mapa: Record<string, string> = {
    backlog: 'Backlog', a_fazer: 'A Fazer',
    em_progresso: 'Em Progresso', em_revisao: 'Em Revisão', concluido: 'Concluído',
  }
  return mapa[col] ?? col
}

function formatarData(iso: string) {
  return new Date(iso).toLocaleString('pt-BR')
}
</script>

<style scoped>
.label-campo {
  display: block;
  font-size: 11px;
  font-weight: 700;
  color: hsl(215 16% 47%);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 5px;
}

.campo {
  width: 100%;
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid hsl(214 32% 91%);
  font-size: 14px;
  background: #fff;
  color: hsl(222 47% 11%);
  transition: border-color 0.15s, box-shadow 0.15s;
}

.campo:focus {
  outline: none;
  border-color: hsl(221 83% 53%);
  box-shadow: 0 0 0 3px hsl(221 83% 53% / 0.12);
}

/* Fibonacci / complexidade */
.fib-btn {
  min-width: 40px;
  padding: 6px 10px;
  border-radius: 8px;
  border: 1.5px solid hsl(214 32% 91%);
  background: hsl(210 40% 96%);
  color: hsl(222 47% 11%);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}

.fib-btn:hover {
  border-color: hsl(221 83% 53%);
  color: hsl(221 83% 53%);
}

.fib-btn--active {
  background: hsl(221 83% 53%);
  border-color: hsl(221 83% 53%);
  color: #fff;
  box-shadow: 0 0 0 1px hsl(221 83% 53% / 0.3), 0 4px 12px hsl(221 83% 53% / 0.25);
}
</style>
