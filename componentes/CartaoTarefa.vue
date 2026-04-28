<template>
  <div
    class="bg-white p-3 rounded-lg shadow-sm border border-slate-200 hover:border-primaria transition-colors group relative">
    <button @click="editarTarefa"
      class="absolute top-2 right-2 opacity-0 group-hover:opacity-100 p-1.5 bg-slate-100 rounded-md hover:bg-primaria hover:text-white transition-all"
      title="Editar tarefa">
      <span class="text-xs">✏️</span>
    </button>

    <div class="flex flex-col gap-2">
      <h4 class="text-sm font-semibold text-slate-700 leading-tight pr-6">
        {{ tarefa.titulo }}
      </h4>

      <div class="flex flex-wrap items-center gap-2 mt-1">
        <div v-if="mostrarSubtarefas"
          class="flex items-center gap-1 text-[10px] bg-slate-100 px-1.5 py-0.5 rounded text-slate-500 font-medium">
          <span>📋</span>
          <span>
            {{ concluidasCount }}/{{ totalSubtarefas }}
          </span>
        </div>

        <div v-if="tarefa.prazo_final" class="text-[10px] text-slate-400">
          📅 {{ prazoFormatado }}
        </div>
      </div>

      <div class="flex justify-between items-center mt-2 border-t pt-2 border-slate-50">
        <span class="text-[9px] text-slate-400 uppercase font-bold tracking-wider">
          {{ nomeResponsavel }}
        </span>

        <div
          class="w-6 h-6 rounded-full bg-slate-200 flex items-center justify-center text-[10px] font-bold text-slate-500">
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

  emits: ['editar'],

  computed: {
    totalSubtarefas(): number {
      return (
        this.tarefa.subtarefas?.length ||
        this.tarefa.subtarefas_count ||
        0
      )
    },

    concluidasCount(): number {
      return (
        this.tarefa.subtarefas?.filter(
          (item: any) => item.concluida
        ).length || 0
      )
    },

    mostrarSubtarefas(): boolean {
      return this.totalSubtarefas > 0
    },

    prazoFormatado(): string {
      return new Date(
        this.tarefa.prazo_final
      ).toLocaleDateString('pt-BR')
    },

    nomeResponsavel(): string {
      return (
        this.tarefa.responsavel?.nome ||
        'Sem responsável'
      )
    },

    inicialResponsavel(): string {
      return (
        this.tarefa.responsavel?.nome ||
        '?'
      )
        .charAt(0)
        .toUpperCase()
    }
  },

  methods: {
    editarTarefa() {
      this.$emit('editar', this.tarefa)
    }
  }
})
</script>