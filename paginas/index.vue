<template>
  <div>
    <h1 class="text-3xl font-bold mb-6">
      📊 Dashboard
    </h1>

    <div v-if="carregando">
      Carregando...
    </div>

    <div v-else-if="dados" class="grid gap-4 md:grid-cols-3">
      <div class="cartao">
        <div class="text-slate-500 text-sm">
          Projetos
        </div>

        <div class="text-3xl font-bold">
          {{ dados.totais.projetos }}
        </div>
      </div>

      <div class="cartao">
        <div class="text-slate-500 text-sm">
          Tarefas
        </div>

        <div class="text-3xl font-bold">
          {{ dados.totais.tarefas }}
        </div>
      </div>

      <div class="cartao">
        <div class="text-slate-500 text-sm">
          Sprints ativas
        </div>

        <div class="text-3xl font-bold">
          {{ dados.totais.sprints_ativas }}
        </div>
      </div>

      <div class="cartao md:col-span-3">
        <h2 class="font-semibold mb-3">
          Tarefas por coluna
        </h2>

        <div class="grid grid-cols-5 gap-3">
          <div v-for="(qtd, col) in dados.tarefas_por_coluna" :key="col" class="text-center">
            <div class="text-2xl font-bold text-primaria">
              {{ qtd }}
            </div>

            <div class="text-xs text-slate-500 capitalize">
              {{ formatarColuna(col) }}
            </div>
          </div>
        </div>
      </div>

      <div class="cartao md:col-span-3">
        <h2 class="font-semibold mb-3">
          Minhas tarefas
        </h2>

        <ul class="divide-y">
          <li v-for="t in dados.minhas_tarefas" :key="t.id" class="py-2 flex justify-between">
            <span>{{ t.titulo }}</span>

            <span class="text-xs text-slate-500">
              {{ t.coluna }}
            </span>
          </li>

          <li v-if="!dados.minhas_tarefas.length" class="py-2 text-slate-500 text-sm">
            Nada por aqui ainda.
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'PaginaDashboard',

  data() {
    return {
      cliente: useSupabaseClient(),
      dados: null as any,
      carregando: true
    }
  },

  async mounted() {
    await this.carregarDashboard()
  },

  methods: {
    async carregarDashboard() {
      this.carregando = true

      try {
        const { data } = await this.cliente.functions.invoke(
          'listarDashboard'
        )

        this.dados = data
      } finally {
        this.carregando = false
      }
    },

    formatarColuna(coluna: string) {
      return String(coluna).replace('_', ' ')
    }
  }
})
</script>