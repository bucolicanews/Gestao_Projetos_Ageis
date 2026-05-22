<template>
    <div class="p-6 max-w-2xl mx-auto">

        <div class="flex justify-between items-center mb-6">
            <div>
                <h1 class="text-2xl font-bold text-slate-800">Subtarefas</h1>
                <p v-if="!tarefaPaiId" class="text-sm text-amber-600 mt-1">
                    ⚠️ Acesse esta página via uma tarefa (parâmetro <code>tarefaId</code> ausente)
                </p>
            </div>

            <button
                class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-indigo-700 disabled:opacity-50"
                :disabled="!tarefaPaiId"
                @click="abrirNovo"
            >
                + Adicionar Subtarefa
            </button>
        </div>

        <div v-if="carregando" class="text-center py-10 text-slate-400">
            Carregando...
        </div>

        <div v-else-if="!tarefaPaiId" class="text-center py-10 text-slate-400">
            Nenhuma tarefa selecionada.
        </div>

        <div v-else-if="lista.length === 0" class="text-center py-10 text-slate-400">
            Nenhuma subtarefa encontrada.
        </div>

        <div v-else class="space-y-2">
            <div
                v-for="sub in lista"
                :key="sub.id"
                class="flex items-center justify-between p-3 bg-white border border-slate-200 rounded-lg hover:border-indigo-300 transition-colors"
            >
                <div class="flex items-center gap-3">
                    <input
                        type="checkbox"
                        :checked="sub.coluna === 'concluido'"
                        class="rounded accent-indigo-600"
                        @change="alternar(sub)"
                    />
                    <span :class="['text-sm', sub.coluna === 'concluido' ? 'line-through text-slate-400' : 'text-slate-700']">
                        {{ sub.titulo }}
                    </span>
                    <span :class="[
                        'text-[10px] px-1.5 py-0.5 rounded uppercase font-bold',
                        corPrioridade(sub.prioridade)
                    ]">
                        {{ sub.prioridade }}
                    </span>
                </div>

                <div class="flex gap-2">
                    <button
                        class="text-xs text-slate-500 hover:text-indigo-600 px-2 py-1 rounded hover:bg-slate-50"
                        @click="abrirEdicao(sub)"
                    >
                        Editar
                    </button>
                    <button
                        class="text-xs text-red-400 hover:text-red-600 px-2 py-1 rounded hover:bg-red-50"
                        @click="confirmarExclusao(sub.id)"
                    >
                        Excluir
                    </button>
                </div>
            </div>
        </div>

        <ModalSubTarefa
            v-model="modalAberto"
            :projeto-id="projetoId"
            :tarefa-pai-id="tarefaPaiId"
            :sub-tarefa-para-editar="itemSelecionado"
            @sucesso="recarregarDados"
        />
    </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

const route = useRoute()

const tarefaPaiId = computed(() => String(route.query.tarefaId || route.params.tarefaId || ''))
const projetoId = computed(() => String(route.query.projetoId || route.params.projetoId || ''))

const svc = servicoSubTarefas()

const modalAberto = ref(false)
const itemSelecionado = ref<any>(null)
const lista = ref<any[]>([])
const carregando = ref(false)

function abrirNovo() {
    itemSelecionado.value = null
    modalAberto.value = true
}

function abrirEdicao(sub: any) {
    itemSelecionado.value = sub
    modalAberto.value = true
}

async function recarregarDados() {
    if (!tarefaPaiId.value) return
    carregando.value = true
    try {
        lista.value = await svc.listar(tarefaPaiId.value)
    } finally {
        carregando.value = false
    }
}

async function confirmarExclusao(id: string) {
    if (!confirm('Deseja excluir esta subtarefa?')) return
    await svc.excluir(id)
    lista.value = lista.value.filter(s => s.id !== id)
}

async function alternar(sub: any) {
    const virarConcluido = sub.coluna !== 'concluido'
    await svc.alternarColunaById(sub.id, virarConcluido)
    sub.coluna = virarConcluido ? 'concluido' : 'a_fazer'
}

function corPrioridade(p: string) {
    return {
        baixa: 'bg-slate-100 text-slate-500',
        media: 'bg-blue-100 text-blue-600',
        alta: 'bg-amber-100 text-amber-700',
        urgente: 'bg-red-100 text-red-600',
    }[p] || 'bg-slate-100'
}

onMounted(recarregarDados)
</script>
