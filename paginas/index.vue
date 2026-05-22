<template>
  <div class="space-y-6">

    <!-- Header -->
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold">📊 Portfolio</h1>
        <p class="text-sm text-slate-500 mt-0.5">Visão completa do portfólio de projetos</p>
      </div>

      <button
        class="botao-secundario text-sm"
        :disabled="carregando"
        @click="carregarDashboard"
      >
        {{ carregando ? 'Carregando...' : '🔄 Atualizar' }}
      </button>
    </div>

    <!-- Filtro por projeto -->
    <div v-if="dados" class="flex flex-wrap gap-2">
      <button
        :class="['px-3 py-1.5 rounded-full text-sm font-medium transition-colors',
          projetoFiltro === null
            ? 'bg-primaria text-white'
            : 'bg-slate-100 text-slate-600 hover:bg-slate-200']"
        @click="selecionarProjeto(null)"
      >
        Todos os projetos
      </button>
      <button
        v-for="p in dados.projetos"
        :key="p.id"
        :class="['px-3 py-1.5 rounded-full text-sm font-medium transition-colors',
          projetoFiltro === p.id
            ? 'bg-primaria text-white'
            : 'bg-slate-100 text-slate-600 hover:bg-slate-200']"
        @click="selecionarProjeto(p.id)"
      >
        {{ p.nome }}
        <span v-if="p.tarefas_atrasadas" class="ml-1 text-[10px] bg-red-500 text-white rounded-full px-1">
          {{ p.tarefas_atrasadas }}
        </span>
      </button>
    </div>

    <div v-if="carregando" class="text-center py-16 text-slate-400">Carregando dashboard...</div>

    <div v-else-if="erro" class="cartao text-perigo">{{ erro }}</div>

    <template v-else-if="dados">

      <!-- KPI cards -->
      <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-primaria">{{ totais.projetos }}</div>
          <div class="text-xs text-slate-500 mt-1">Projetos</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-slate-700">{{ totais.tarefas }}</div>
          <div class="text-xs text-slate-500 mt-1">Tarefas</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-sucesso">{{ totais.sp_concluidos }}</div>
          <div class="text-xs text-slate-500 mt-1">
            SP concluídos
            <span v-if="totais.sp_planejados" class="block text-[10px] opacity-60">
              de {{ totais.sp_planejados }}
            </span>
          </div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-indigo-600">{{ totais.sprints_ativas }}</div>
          <div class="text-xs text-slate-500 mt-1">Sprints ativas</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold" :class="totais.atrasadas > 0 ? 'text-perigo' : 'text-sucesso'">
            {{ totais.atrasadas }}
          </div>
          <div class="text-xs text-slate-500 mt-1">Atrasadas</div>
        </div>
      </div>

      <!-- SP progress bar global -->
      <div v-if="totais.sp_planejados > 0" class="cartao">
        <div class="flex justify-between text-sm mb-2">
          <span class="font-medium">Story Points — progresso geral</span>
          <span class="text-slate-500">{{ spPercent }}%</span>
        </div>
        <div class="w-full bg-slate-100 rounded-full h-3">
          <div
            class="h-3 rounded-full transition-all"
            :class="spPercent >= 80 ? 'bg-sucesso' : spPercent >= 50 ? 'bg-primaria' : 'bg-alerta'"
            :style="{ width: spPercent + '%' }"
          />
        </div>
        <div class="flex justify-between text-xs text-slate-400 mt-1">
          <span>{{ totais.sp_concluidos }} concluídos</span>
          <span>{{ totais.sp_planejados - totais.sp_concluidos }} restantes</span>
        </div>
      </div>

      <div class="grid md:grid-cols-2 gap-6">

        <!-- Coluna esquerda: Sprints ativas + Tarefas por coluna -->
        <div class="space-y-4">

          <!-- Sprints ativas -->
          <div class="cartao">
            <h2 class="font-semibold mb-4">🏃 Sprints em andamento</h2>

            <div v-if="!sprintsFiltradas.length" class="text-sm text-slate-400 py-4 text-center">
              Nenhuma sprint ativa no momento.
            </div>

            <div v-else class="space-y-4">
              <div
                v-for="s in sprintsFiltradas"
                :key="s.id"
                class="border border-slate-100 rounded-lg p-3 space-y-2"
              >
                <div class="flex justify-between items-start">
                  <div>
                    <div class="font-medium text-sm">{{ s.nome }}</div>
                    <div class="text-xs text-slate-500">{{ s.projeto_nome }}</div>
                  </div>
                  <div class="text-right">
                    <div class="text-sm font-bold" :class="corDiasRestantes(s.dias_restantes)">
                      {{ s.dias_restantes != null ? s.dias_restantes + 'd' : '—' }}
                    </div>
                    <div class="text-[10px] text-slate-400">restantes</div>
                  </div>
                </div>

                <div>
                  <div class="flex justify-between text-xs text-slate-500 mb-1">
                    <span>{{ s.tarefas_concluidas }}/{{ s.tarefas_total }} tarefas</span>
                    <span>{{ s.sp_concluidos }}/{{ s.sp_planejados || '?' }} SP</span>
                  </div>
                  <div class="w-full bg-slate-100 rounded-full h-2">
                    <div
                      class="h-2 rounded-full transition-all"
                      :class="s.progresso_percent >= 80 ? 'bg-sucesso' : s.progresso_percent >= 50 ? 'bg-primaria' : 'bg-alerta'"
                      :style="{ width: s.progresso_percent + '%' }"
                    />
                  </div>
                  <div class="text-right text-[10px] text-slate-400 mt-0.5">
                    {{ s.progresso_percent }}%
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Distribuição tarefas por coluna -->
          <div class="cartao">
            <h2 class="font-semibold mb-4">📋 Distribuição por coluna</h2>

            <div class="space-y-2">
              <div v-for="(qtd, col) in tarefasPorColunaFiltradas" :key="col" class="flex items-center gap-3">
                <div class="w-24 text-xs text-slate-500 text-right">{{ formatarColuna(col) }}</div>
                <div class="flex-1 bg-slate-100 rounded-full h-5 relative overflow-hidden">
                  <div
                    class="h-5 rounded-full transition-all flex items-center"
                    :class="corColuna(col)"
                    :style="{ width: percentColuna(qtd) + '%', minWidth: qtd > 0 ? '1.5rem' : '0' }"
                  />
                </div>
                <div class="w-8 text-xs font-semibold text-slate-700 text-right">{{ qtd }}</div>
              </div>
            </div>

            <div class="mt-3 text-xs text-slate-400 text-right">
              Total: {{ totalTarefasFiltradas }} tarefas
            </div>
          </div>

        </div>

        <!-- Coluna direita: Minhas tarefas + Atrasadas -->
        <div class="space-y-4">

          <!-- Minhas tarefas -->
          <div class="cartao">
            <div class="flex items-center justify-between mb-4">
              <h2 class="font-semibold">👤 Minhas tarefas</h2>
              <span class="text-xs text-slate-400">{{ minhasTarefasFiltradas.length }} aberta(s)</span>
            </div>

            <div v-if="!minhasTarefasFiltradas.length" class="text-sm text-slate-400 py-4 text-center">
              Sem tarefas atribuídas.
            </div>

            <ul v-else class="divide-y divide-slate-50">
              <li
                v-for="t in minhasTarefasFiltradas.slice(0, 8)"
                :key="t.id"
                class="py-2 flex items-start justify-between gap-2"
              >
                <div class="min-w-0">
                  <div class="text-sm font-medium text-slate-700 truncate">{{ t.titulo }}</div>
                  <div class="flex gap-1.5 mt-0.5 flex-wrap">
                    <span :class="['text-[9px] px-1.5 py-0.5 rounded uppercase font-bold', corPrioridade(t.prioridade)]">
                      {{ t.prioridade }}
                    </span>
                    <span v-if="t.pontos" class="text-[9px] px-1.5 py-0.5 rounded bg-primaria/10 text-primaria font-bold">
                      {{ t.pontos }} SP
                    </span>
                  </div>
                </div>
                <span :class="['text-[10px] px-1.5 py-0.5 rounded whitespace-nowrap shrink-0 font-medium', corBadgeColuna(t.coluna)]">
                  {{ formatarColuna(t.coluna) }}
                </span>
              </li>
            </ul>

            <div v-if="minhasTarefasFiltradas.length > 8" class="text-xs text-slate-400 text-center mt-2">
              + {{ minhasTarefasFiltradas.length - 8 }} mais
            </div>
          </div>

          <!-- Tarefas atrasadas -->
          <div class="cartao">
            <div class="flex items-center justify-between mb-4">
              <h2 class="font-semibold text-perigo">⚠️ Atrasadas</h2>
              <span class="text-xs text-slate-400">{{ tarefasAtrasadasFiltradas.length }}</span>
            </div>

            <div v-if="!tarefasAtrasadasFiltradas.length" class="text-sm text-slate-400 py-4 text-center">
              Nenhuma tarefa em atraso. 🎉
            </div>

            <ul v-else class="divide-y divide-slate-50">
              <li
                v-for="t in tarefasAtrasadasFiltradas.slice(0, 6)"
                :key="t.id"
                class="py-2 flex items-start justify-between gap-2"
              >
                <div class="min-w-0">
                  <div class="text-sm font-medium text-slate-700 truncate">{{ t.titulo }}</div>
                  <div class="text-[10px] text-perigo mt-0.5">
                    prazo: {{ formatarData(t.prazo) }}
                  </div>
                </div>
                <span :class="['text-[9px] px-1.5 py-0.5 rounded uppercase font-bold shrink-0', corPrioridade(t.prioridade)]">
                  {{ t.prioridade }}
                </span>
              </li>
            </ul>
          </div>

          <!-- Saúde por projeto -->
          <div class="cartao">
            <h2 class="font-semibold mb-4">🏥 Saúde dos projetos</h2>
            <div class="space-y-2">
              <div
                v-for="p in projetosFiltrados"
                :key="p.id"
                class="flex items-center justify-between py-1.5"
              >
                <div class="min-w-0">
                  <div class="text-sm font-medium text-slate-700 truncate">{{ p.nome }}</div>
                  <div class="text-[10px] text-slate-400">
                    {{ p.total_tarefas }} tarefas · {{ p.tarefas_concluidas }} concluídas
                  </div>
                </div>
                <div class="flex items-center gap-2 shrink-0">
                  <span v-if="p.tarefas_atrasadas" class="text-[10px] text-perigo font-bold">
                    {{ p.tarefas_atrasadas }} atrasada(s)
                  </span>
                  <span
                    :class="['text-[10px] px-2 py-0.5 rounded-full font-bold',
                      p.status === 'ativo' ? 'bg-green-100 text-green-700'
                      : p.status === 'pausado' ? 'bg-amber-100 text-amber-700'
                      : 'bg-slate-100 text-slate-500']"
                  >
                    {{ p.status }}
                  </span>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>

      <!-- Velocity (projeto selecionado) -->
      <div v-if="projetoFiltro && velocityHistorico.length" class="cartao">
        <GraficoVelocity :historico="velocityHistorico" :media="velocityMedia" />
      </div>

    </template>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'
import GraficoVelocity from '~/componentes/GraficoVelocity.vue'

export default defineComponent({
  name: 'PaginaDashboard',

  components: { GraficoVelocity },

  data() {
    return {
      cliente: useSupabaseClient(),
      dados: null as any,
      carregando: true,
      erro: null as string | null,
      projetoFiltro: null as string | null,
      velocityHistorico: [] as any[],
      velocityMedia: 0,
    }
  },

  computed: {
    totais(): any {
      if (!this.dados) return {}
      if (!this.projetoFiltro) return this.dados.totais
      const proj = this.dados.projetos.find((p: any) => p.id === this.projetoFiltro)
      const s = this.dados.sprints_ativas.find((s: any) => s.projeto_id === this.projetoFiltro)
      return {
        projetos: 1,
        tarefas: proj?.total_tarefas ?? 0,
        sprints_ativas: s ? 1 : 0,
        sp_planejados: s?.sp_planejados ?? 0,
        sp_concluidos: s?.sp_concluidos ?? 0,
        atrasadas: proj?.tarefas_atrasadas ?? 0,
      }
    },

    spPercent(): number {
      const t = this.totais
      if (!t.sp_planejados) return 0
      return Math.round((t.sp_concluidos / t.sp_planejados) * 100)
    },

    sprintsFiltradas(): any[] {
      if (!this.dados) return []
      return this.projetoFiltro
        ? this.dados.sprints_ativas.filter((s: any) => s.projeto_id === this.projetoFiltro)
        : this.dados.sprints_ativas
    },

    projetosFiltrados(): any[] {
      if (!this.dados) return []
      return this.projetoFiltro
        ? this.dados.projetos.filter((p: any) => p.id === this.projetoFiltro)
        : this.dados.projetos
    },

    minhasTarefasFiltradas(): any[] {
      if (!this.dados) return []
      const all = this.dados.minhas_tarefas.filter((t: any) => t.coluna !== 'concluido')
      return this.projetoFiltro
        ? all.filter((t: any) => t.projeto_id === this.projetoFiltro)
        : all
    },

    tarefasAtrasadasFiltradas(): any[] {
      if (!this.dados) return []
      return this.projetoFiltro
        ? this.dados.tarefas_atrasadas.filter((t: any) => t.projeto_id === this.projetoFiltro)
        : this.dados.tarefas_atrasadas
    },

    tarefasPorColunaFiltradas(): Record<string, number> {
      if (!this.dados) return {}
      if (!this.projetoFiltro) return this.dados.tarefas_por_coluna
      // Recompute for selected project using minhas_tarefas + atrasadas fallback
      // We only have full task list in edge fn response — use projetos enriched data
      return this.dados.tarefas_por_coluna
    },

    totalTarefasFiltradas(): number {
      return Object.values(this.tarefasPorColunaFiltradas as Record<string, number>)
        .reduce((a, b) => a + b, 0)
    },
  },

  async mounted() {
    await this.carregarDashboard()
  },

  methods: {
    async carregarDashboard() {
      this.carregando = true
      this.erro = null
      try {
        const { data, error } = await this.cliente.functions.invoke('listarDashboard')
        if (error) throw error
        this.dados = data
      } catch (e: any) {
        this.erro = e?.message || String(e)
      } finally {
        this.carregando = false
      }
    },

    async selecionarProjeto(id: string | null) {
      this.projetoFiltro = id
      if (id) {
        await this.carregarVelocity(id)
      } else {
        this.velocityHistorico = []
        this.velocityMedia = 0
      }
    },

    async carregarVelocity(projetoId: string) {
      try {
        const [{ data: hist }, { data: mediaRow }] = await Promise.all([
          this.cliente.from('velocity_historico')
            .select('*, sprint:sprints(nome, data_inicio, data_fim)')
            .eq('projeto_id', projetoId)
            .order('gravado_em', { ascending: true })
            .limit(10),
          this.cliente.from('v_velocity_projeto')
            .select('velocity_media')
            .eq('projeto_id', projetoId)
            .single(),
        ])
        this.velocityHistorico = hist ?? []
        this.velocityMedia = Number((mediaRow as any)?.velocity_media || 0)
      } catch {
        this.velocityHistorico = []
        this.velocityMedia = 0
      }
    },

    formatarColuna(col: string): string {
      const map: Record<string, string> = {
        backlog: 'Backlog',
        a_fazer: 'A fazer',
        em_progresso: 'Em progresso',
        em_revisao: 'Em revisão',
        concluido: 'Concluído',
      }
      return map[col] ?? col
    },

    formatarData(d: string): string {
      if (!d) return ''
      return new Date(d).toLocaleDateString('pt-BR')
    },

    percentColuna(qtd: number): number {
      if (!this.totalTarefasFiltradas) return 0
      return Math.round((qtd / this.totalTarefasFiltradas) * 100)
    },

    corColuna(col: string): string {
      return ({
        backlog: 'bg-slate-400',
        a_fazer: 'bg-blue-400',
        em_progresso: 'bg-amber-400',
        em_revisao: 'bg-violet-400',
        concluido: 'bg-emerald-400',
      } as Record<string, string>)[col] ?? 'bg-slate-300'
    },

    corBadgeColuna(col: string): string {
      return ({
        backlog: 'bg-slate-100 text-slate-500',
        a_fazer: 'bg-blue-100 text-blue-600',
        em_progresso: 'bg-amber-100 text-amber-700',
        em_revisao: 'bg-violet-100 text-violet-700',
        concluido: 'bg-emerald-100 text-emerald-700',
      } as Record<string, string>)[col] ?? 'bg-slate-100 text-slate-500'
    },

    corPrioridade(p: string): string {
      return ({
        baixa: 'bg-slate-100 text-slate-500',
        media: 'bg-blue-100 text-blue-600',
        alta: 'bg-amber-100 text-amber-700',
        urgente: 'bg-red-100 text-red-600',
      } as Record<string, string>)[p] ?? 'bg-slate-100'
    },

    corDiasRestantes(dias: number | null): string {
      if (dias === null) return 'text-slate-400'
      if (dias <= 2) return 'text-perigo'
      if (dias <= 5) return 'text-alerta'
      return 'text-sucesso'
    },
  },
})
</script>
