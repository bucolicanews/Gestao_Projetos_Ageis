<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <div>
        <NuxtLink to="/projetos" class="text-sm text-primaria hover:underline">
          ← Voltar aos projetos
        </NuxtLink>
        <h1 class="text-3xl font-bold mt-1">
          📊 Dashboard: {{ projeto?.nome || 'Carregando...' }}
        </h1>
      </div>

      <div class="flex gap-2">
        <NuxtLink :to="`/kanban?projeto=${projetoId}`" class="botao-secundario">
          📌 Kanban
        </NuxtLink>
        <NuxtLink :to="`/sprints?projeto=${projetoId}`" class="botao-secundario">
          🔄 Sprints
        </NuxtLink>
      </div>
    </div>

    <div v-if="!projeto" class="text-slate-500">
      Projeto não encontrado.
    </div>

    <div v-else class="space-y-6">
      <!-- Métricas Rápidas -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-primaria">{{ metricas.total }}</div>
          <div class="text-sm text-slate-500">Total de Tarefas</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-amber-600">{{ metricas.emProgresso }}</div>
          <div class="text-sm text-slate-500">Em Progresso</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-blue-600">{{ metricas.concluidas }}</div>
          <div class="text-sm text-slate-500">Concluídas</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-green-600">{{ metricas.sprints }}</div>
          <div class="text-sm text-slate-500">Sprints Ativos</div>
        </div>
      </div>

      <!-- Gráficos -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <GraficoBurndown :snapshots="snapshots" @atualizar="registrarSnapshot" />

        <GraficoCFD :tarefas="tarefas" />
      </div>

      <div class="grid grid-cols-1">
        <GraficoThroughput :tarefas="tarefas" />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'DashboardProjeto',

  data() {
    const route = useRoute()
    const projetoId = route.params.id as string

    return {
      projetoId,
      projeto: null as any,
      tarefas: [] as any[],
      snapshots: [] as any[],
      sprints: [] as any[]
    }
  },

  computed: {
    metricas() {
      const total = this.tarefas.length
      const concluidas = this.tarefas.filter((t: any) => t.coluna === 'concluido').length
      const emProgresso = this.tarefas.filter((t: any) => 
        t.coluna === 'em_progresso' || t.coluna === 'em_revisao'
      ).length

      return {
        total,
        concluidas,
        emProgresso,
        sprints: this.sprints.filter((s: any) => s.status === 'ativo').length
      }
    }
  },

  async mounted() {
    await this.carregarDados()
  },

  methods: {
    async carregarDados() {
      const cliente = useSupabaseClient()

      // Carrega projeto
      const { data: projeto } = await cliente
        .from('projetos')
        .select('*')
        .eq('id', this.projetoId)
        .single()

      this.projeto = projeto

      // Carrega tarefas
      const { data: tarefas } = await cliente
        .from('tarefas')
        .select('*')
        .eq('projeto_id', this.projetoId)
        .order('created_at', { ascending: false })

      this.tarefas = tarefas || []

      // Carrega snapshots do burndown
      const { data: snapshots } = await cliente
        .from('burndown_snapshots')
        .select('*')
        .eq('projeto_id', this.projetoId)
        .order('data', { ascending: true })

      this.snapshots = snapshots || []

      // Carrega sprints
      const { data: sprints } = await cliente
        .from('sprints')
        .select('*')
        .eq('projeto_id', this.projetoId)
        .order('numero', { ascending: false })

      this.sprints = sprints || []
    },

    async registrarSnapshot() {
      const cliente = useSupabaseClient()

      const total = this.tarefas.length
      const concluidas = this.tarefas.filter((t: any) => t.coluna === 'concluido').length

      await cliente.from('burndown_snapshots').insert({
        projeto_id: this.projetoId,
        data: new Date().toISOString().split('T')[0],
        total_tarefas: total,
        tarefas_concluidas: concluidas,
        restantes: total - concluidas
      })

      await this.carregarDados()
    }
  }
})
</script>