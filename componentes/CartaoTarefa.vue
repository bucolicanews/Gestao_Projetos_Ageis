<template>
  <div
    class="bg-white p-3 rounded-lg shadow-sm border border-slate-200 hover:border-primaria transition-colors cursor-pointer"
    @click="$emit('clicar', tarefa)"
  >
    <div class="flex flex-col gap-2">
      <h4 class="text-sm font-semibold text-slate-700 leading-tight">
        {{ tarefa.titulo }}
      </h4>

      <div class="flex flex-wrap items-center gap-2">
        <span v-if="tarefa.subtarefas_count" class="flex items-center gap-1 text-[10px] bg-slate-100 px-1.5 py-0.5 rounded text-slate-500 font-medium">
          📋 {{ tarefa.subtarefas_count }}
        </span>

        <span v-if="tarefa.pontos" class="text-[9px] px-1.5 py-0.5 rounded bg-primaria/10 text-primaria font-bold">
          {{ tarefa.pontos }} SP
        </span>

        <span v-if="tarefa.dor_ok" class="text-[9px] px-1 py-0.5 rounded bg-green-100 text-green-700 font-bold" title="Definition of Ready OK">
          DoR ✓
        </span>

        <span v-if="tarefa.prazo" class="text-[10px] text-slate-400">
          📅 {{ prazoFormatado }}
        </span>

        <span :class="[
          'text-[9px] px-1.5 py-0.5 rounded uppercase font-bold',
          corPrioridade(tarefa.prioridade)
        ]">
          {{ tarefa.prioridade }}
        </span>

        <span v-if="tarefa.sprint?.nome" class="text-[9px] px-1.5 py-0.5 rounded bg-indigo-100 text-indigo-600 font-medium truncate max-w-[90px]" :title="tarefa.sprint.nome">
          🏃 {{ tarefa.sprint.nome }}
        </span>
      </div>

      <div class="flex justify-between items-center mt-1 border-t pt-2 border-slate-50">
        <span class="text-[9px] text-slate-400 uppercase font-bold tracking-wider">
          {{ nomeResponsavel }}
        </span>

        <div class="w-6 h-6 rounded-full bg-slate-200 flex items-center justify-center text-[10px] font-bold text-slate-500">
          {{ inicialResponsavel }}
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'CartaoTarefa',

  props: {
    tarefa: {
      type: Object,
      required: true
    }
  },

  emits: ['clicar'],

  computed: {
    prazoFormatado(): string {
      if (!this.tarefa.prazo) return ''
      return new Date(this.tarefa.prazo).toLocaleDateString('pt-BR')
    },

    nomeResponsavel(): string {
      return this.tarefa.responsavel?.nome || 'Sem responsável'
    },

    inicialResponsavel(): string {
      return (this.tarefa.responsavel?.nome ?? '?').charAt(0).toUpperCase()
    }
  },

  methods: {
    corPrioridade(p: string) {
      return {
        baixa: 'bg-slate-100 text-slate-500',
        media: 'bg-blue-100 text-blue-600',
        alta: 'bg-amber-100 text-amber-700',
        urgente: 'bg-red-100 text-red-600',
      }[p] || 'bg-slate-100'
    }
  }
})
</script>
