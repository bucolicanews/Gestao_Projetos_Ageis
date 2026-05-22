<template>
  <div class="space-y-0.5">
    <div v-for="sub in subtarefas" :key="sub.id" class="group">
      <div class="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-slate-50">
        <input
          type="checkbox"
          :checked="sub.coluna === 'concluido'"
          class="rounded accent-primaria shrink-0"
          @change="alternar(sub)"
        />

        <span :class="[
          'flex-1 text-sm',
          sub.coluna === 'concluido' ? 'line-through text-slate-400' : 'text-slate-700'
        ]">
          {{ sub.titulo }}
        </span>

        <button
          v-if="sub.subtarefas_count > 0 || expandidos[sub.id]"
          class="text-[10px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-500 hover:bg-slate-200 shrink-0"
          :title="expandidos[sub.id] ? 'Recolher' : 'Expandir subtarefas'"
          @click="toggleExpandir(sub.id)"
        >
          {{ expandidos[sub.id] ? '▾' : '▸' }} {{ sub.subtarefas_count }}
        </button>

        <button
          class="opacity-0 group-hover:opacity-100 text-[10px] text-primaria hover:underline shrink-0"
          @click="toggleExpandir(sub.id); expandidos[sub.id] = true"
        >
          + sub
        </button>

        <button
          class="opacity-0 group-hover:opacity-100 text-[10px] text-blue-500 hover:text-blue-700 px-1 shrink-0"
          title="Editar"
          @click="abrirEditar(sub)"
        >
          ✏
        </button>

        <button
          class="opacity-0 group-hover:opacity-100 text-slate-400 hover:text-perigo text-sm leading-none px-1 shrink-0"
          title="Excluir"
          @click="excluirItem(sub)"
        >
          ×
        </button>
      </div>

      <div v-if="expandidos[sub.id]" class="ml-6 border-l-2 border-slate-100 pl-2 py-0.5">
        <ListaSubtarefas
          :tarefa-pai-id="sub.id"
          :projeto-id="projetoId"
          :sprint-id="sprintId"
        />
      </div>
    </div>

    <div v-if="adicionando" class="flex gap-1 mt-1 px-2">
      <input
        ref="inputNovo"
        v-model="novoTitulo"
        class="flex-1 text-sm px-2 py-1 border rounded-lg focus:outline-none focus:border-primaria"
        placeholder="Nova subtarefa..."
        @keydown.enter="confirmarAdicionar"
        @keydown.esc="cancelarAdicionar"
      />
      <button class="botao-primario text-xs px-2 py-1" @click="confirmarAdicionar">✓</button>
      <button class="botao-secundario text-xs px-2 py-1" @click="cancelarAdicionar">×</button>
    </div>

    <button
      v-if="!adicionando"
      class="text-xs text-primaria px-2 py-1 hover:underline"
      @click="abrirAdicionar"
    >
      + Adicionar subtarefa
    </button>
  </div>

  <ModalSubTarefa
    v-model="modalEditarAberto"
    :projeto-id="projetoId"
    :tarefa-pai-id="tarefaPaiId"
    :sub-tarefa-para-editar="subEditando"
    @sucesso="aoEditar"
  />
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, nextTick } from 'vue'

defineOptions({ name: 'ListaSubtarefas' })

const props = defineProps<{
  tarefaPaiId: string
  projetoId: string
  sprintId?: string | null
}>()

const svc = servicoSubTarefas()

const subtarefas = ref<any[]>([])
const expandidos = reactive<Record<string, boolean>>({})
const adicionando = ref(false)
const novoTitulo = ref('')
const inputNovo = ref<HTMLInputElement | null>(null)
const modalEditarAberto = ref(false)
const subEditando = ref<any>(null)

async function carregar() {
  subtarefas.value = await svc.listar(props.tarefaPaiId)
}

async function alternar(sub: any) {
  const virarConcluido = sub.coluna !== 'concluido'
  await svc.alternarColunaById(sub.id, virarConcluido)
  sub.coluna = virarConcluido ? 'concluido' : 'a_fazer'
}

function toggleExpandir(id: string) {
  expandidos[id] = !expandidos[id]
}

async function excluirItem(sub: any) {
  const msg = sub.subtarefas_count > 0
    ? `Excluir "${sub.titulo}" e suas ${sub.subtarefas_count} subtarefa(s)?`
    : `Excluir "${sub.titulo}"?`
  if (!confirm(msg)) return
  await svc.excluir(sub.id)
  subtarefas.value = subtarefas.value.filter(s => s.id !== sub.id)
}

async function abrirAdicionar() {
  adicionando.value = true
  await nextTick()
  inputNovo.value?.focus()
}

async function confirmarAdicionar() {
  const titulo = novoTitulo.value.trim()
  if (!titulo) return
  const nova = await svc.criar({
    titulo,
    tarefa_pai_id: props.tarefaPaiId,
    projeto_id: props.projetoId,
    sprint_id: props.sprintId ?? null,
  })
  subtarefas.value.push({ ...nova, subtarefas_count: 0 })
  novoTitulo.value = ''
  adicionando.value = false
}

function cancelarAdicionar() {
  novoTitulo.value = ''
  adicionando.value = false
}

function abrirEditar(sub: any) {
  subEditando.value = sub
  modalEditarAberto.value = true
}

async function aoEditar() {
  await carregar()
}

onMounted(carregar)
</script>
