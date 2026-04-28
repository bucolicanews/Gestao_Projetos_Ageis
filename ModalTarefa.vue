<template>
  <Teleport to="body">
  <div v-if="exibir" class="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
    <div class="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
      <!-- Cabeçalho -->
      <div class="p-6 border-b flex justify-between items-center">
        <h2 class="text-xl font-bold text-slate-800">Editar Tarefa</h2>
        <button @click="$emit('fechar')" class="text-slate-400 hover:text-slate-600">
          <span class="text-2xl">&times;</span>
        </button>
      </div>

      <!-- Abas -->
      <div class="flex border-b px-6">
        <button @click="abaAtiva = 'detalhe'" :class="['px-4 py-2 text-sm font-medium', abaAtiva === 'detalhe' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-slate-500']">Detalhes</button>
        <button @click="abaAtiva = 'historico'" :class="['px-4 py-2 text-sm font-medium', abaAtiva === 'historico' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-slate-500']">Histórico</button>
      </div>

      <div v-if="abaAtiva === 'detalhe'" class="p-6 space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 bg-slate-50 p-3 rounded-lg border border-slate-100">
          <div>
            <label class="block text-[10px] font-bold text-slate-400 uppercase">Master (Criador)</label>
            <span class="text-sm text-slate-600">{{ tarefa.criador?.nome || 'Sistema' }}</span>
          </div>
          <div class="flex items-center gap-2">
            <input type="checkbox" v-model="form.notificar_responsavel" id="notificar" class="rounded text-blue-600">
            <label for="notificar" class="text-xs text-slate-500">Enviar para o colaborador (Notificar)</label>
          </div>
        </div>

        <!-- Assunto -->
        <div>
          <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Assunto (Título)</label>
          <input :disabled="!podeEditarTarefa" v-model="form.titulo" type="text" class="w-full border rounded-lg px-3 py-2 disabled:bg-slate-50" placeholder="O que precisa ser feito?">
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Colaborador / Responsável -->
          <div>
            <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Responsável</label>
            <select :disabled="!podeEditarTarefa" v-model="form.responsavel_id" class="w-full border rounded-lg px-3 py-2 disabled:bg-slate-50">
              <option :value="null">Não atribuído</option>
              <option v-for="m in membros" :key="m.usuario_id" :value="m.usuario_id">
                {{ m.nome_usuario || m.email }}
              </option>
            </select>
          </div>

          <!-- Quadro Kanban -->
          <div>
            <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Quadro Kanban</label>
            <select v-model="form.coluna" class="w-full border rounded-lg px-3 py-2">
              <option value="backlog">BACKLOG</option>
              <option value="a_fazer">A FAZER</option>
              <option value="em_progresso">EM PROGRESSO</option>
              <option value="em_revisao">EM REVISÃO</option>
              <option value="concluido">CONCLUÍDO</option>
            </select>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Data Fim -->
          <div>
            <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Data de Entrega (Fim)</label>
            <input v-model="form.prazo_final" type="date" class="w-full border rounded-lg px-3 py-2">
          </div>
        </div>

        <!-- Detalhes / Descrição -->
        <div>
          <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Detalhes / Descrição</label>
          <textarea v-model="form.descricao" rows="3" class="w-full border rounded-lg px-3 py-2" placeholder="Descrição detalhada..."></textarea>
        </div>

        <!-- Subtarefas -->
        <div class="space-y-3">
          <div class="flex justify-between items-center">
            <label class="block text-xs font-bold text-slate-500 uppercase mb-0">Subtarefas</label>
            <button @click="adicionarSubtarefa" class="text-xs text-blue-600 font-semibold">+ Adicionar Subtarefa</button>
          </div>
          <div v-for="(sub, idx) in form.subtarefas" :key="idx" class="flex gap-2 items-center bg-slate-50 p-2 rounded">
            <input type="checkbox" v-model="sub.concluida" class="rounded text-blue-600">
            <input v-model="sub.titulo" type="text" class="flex-1 text-sm bg-transparent border-none focus:ring-0" placeholder="Título da subtarefa...">
            <button @click="removerSubtarefa(idx)" class="text-red-500 text-xs px-2">Remover</button>
          </div>
        </div>

        <!-- Anexos (Placeholder) -->
        <div>
          <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Anexos</label>
          <div class="border-2 border-dashed border-slate-200 rounded-lg p-4 text-center text-slate-400 text-sm cursor-pointer hover:bg-slate-50">
            Clique para selecionar ou arraste arquivos aqui
          </div>
        </div>
      </div>

      <!-- Aba de Histórico (Placeholder) -->
      <div v-else class="p-6 space-y-4">
        <div v-for="h in historico" :key="h.id" class="flex gap-3 text-sm">
          <div class="w-2 h-2 rounded-full bg-blue-400 mt-1.5"></div>
          <div>
            <p class="text-slate-700"><strong>{{ h.usuario }}</strong> moveu para <strong>{{ h.coluna }}</strong></p>
            <p class="text-[10px] text-slate-400">{{ h.data }}</p>
          </div>
        </div>
        <div v-if="!historico.length" class="text-center py-10 text-slate-400 text-sm">
          Nenhuma movimentação registrada ainda.
        </div>
      </div>

      <!-- Rodapé com Ações -->
      <div class="p-6 border-t bg-slate-50 flex flex-wrap justify-between items-center gap-4">
        <button @click="excluir" class="text-red-600 text-sm font-semibold flex items-center gap-1">
          <span>🗑️</span> Deletar Tarefa
        </button>
        <div class="flex gap-3">
          <button @click="$emit('fechar')" class="px-4 py-2 text-sm font-medium text-slate-600">Cancelar</button>
          <button @click="salvar" class="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-blue-700">
            Salvar Alterações
          </button>
        </div>
      </div>
    </div>
  </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'

const props = defineProps<{
  exibir: boolean
  tarefa: any
  membros: any[] 
}>()

const emit = defineEmits(['fechar', 'salvar', 'deletar'])

const COLUNAS = ['backlog', 'a_fazer', 'em_progresso', 'em_revisao', 'concluido']
const abaAtiva = ref('detalhe')
const historico = ref([]) // Carregar do banco via prop ou fetch

const user = useSupabaseUser()
const podeEditarTarefa = computed(() => {
  const m = props.membros.find(m => m.usuario_id === user.value?.id)
  return ['desenvolvedor', 'admin', 'engenheiro_software', 'lider_equipe'].includes(m?.papel)
})

const form = ref({
  id: '',
  titulo: '',
  responsavel_id: null,
  coluna: 'backlog',
  descricao: '',
  prazo_final: '',
  notificar_responsavel: false,
  subtarefas: [] as any[]
})

// Sincroniza dados da tarefa com o formulário local
watch(() => props.exibir, (val) => {
  if (val && props.tarefa) {
    form.value = { 
      ...props.tarefa,
      subtarefas: props.tarefa.subtarefas || [],
      prazo_final: props.tarefa.prazo_final ? props.tarefa.prazo_final.split('T')[0] : ''
    }
  }
}, { immediate: true })

function adicionarSubtarefa() {
  form.value.subtarefas.push({ titulo: '', concluida: false })
}

function removerSubtarefa(idx: number) {
  form.value.subtarefas.splice(idx, 1)
}

function salvar() {
  // Aqui você chamaria a Edge Function ou serviço para salvar
  emit('salvar', { ...form.value })
}

function excluir() {
  if (confirm('Deseja excluir permanentemente esta tarefa?')) {
    emit('deletar', form.value.id)
  }
}
</script>