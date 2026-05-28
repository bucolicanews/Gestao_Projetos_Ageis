<template>
  <div>
    <!-- Header -->
    <div class="flex flex-wrap justify-between items-start mb-6 gap-3">
      <div>
        <NuxtLink to="/projetos" class="text-sm text-primaria hover:underline">
          ← Projetos
        </NuxtLink>
        <h1 class="text-2xl sm:text-3xl font-bold mt-1">
          📊 {{ dash?.projeto?.nome || 'Carregando...' }}
        </h1>
        <p v-if="dash?.projeto?.descricao" class="text-slate-500 text-sm mt-1">
          {{ dash.projeto.descricao }}
        </p>
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <!-- Health score -->
        <div v-if="dash" class="cartao text-center px-4 py-2 min-w-[70px]">
          <div :class="corSaude" class="text-2xl font-bold">{{ dash.saude_score }}</div>
          <div class="text-xs text-slate-500">Saúde</div>
        </div>

        <NuxtLink :to="`/kanban?projeto=${projetoId}`" class="botao-secundario text-sm">
          📌 Kanban
        </NuxtLink>
        <NuxtLink :to="`/sprints?projeto=${projetoId}`" class="botao-secundario text-sm">
          🔄 Sprints
        </NuxtLink>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="carregando" class="text-slate-500 py-12 text-center">Carregando dashboard...</div>

    <!-- Erro -->
    <div v-else-if="erro" class="cartao text-perigo">{{ erro }}</div>

    <div v-else-if="dash" class="space-y-6">

      <!-- KPI cards -->
      <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-slate-700">{{ dash.totais.tarefas }}</div>
          <div class="text-xs text-slate-500">Total tarefas</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-amber-600">{{ dash.totais.ativas }}</div>
          <div class="text-xs text-slate-500">Em andamento</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-green-600">{{ dash.totais.concluidas }}</div>
          <div class="text-xs text-slate-500">Concluídas</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-primaria">{{ dash.totais.sprints_ativas }}</div>
          <div class="text-xs text-slate-500">Sprints ativas</div>
        </div>
        <div class="cartao text-center">
          <div class="text-2xl font-bold text-slate-600">{{ dash.totais.membros }}</div>
          <div class="text-xs text-slate-500">Membros</div>
        </div>
      </div>

      <!-- Alertas -->
      <div v-if="temAlertas" class="space-y-2">
        <div v-if="dash.wip_violacoes?.length" class="bg-red-50 border border-red-200 rounded-lg px-4 py-3 text-sm">
          <span class="font-semibold text-red-700">⚠️ WIP violado:</span>
          <span v-for="v in dash.wip_violacoes" :key="v.coluna" class="ml-2 text-red-600">
            {{ v.coluna }} ({{ v.atual }}/{{ v.limite }})
          </span>
        </div>
        <div v-if="dash.atrasadas?.length" class="bg-amber-50 border border-amber-200 rounded-lg px-4 py-3 text-sm">
          <span class="font-semibold text-amber-700">🔴 {{ dash.atrasadas.length }} tarefa(s) atrasada(s):</span>
          <span v-for="t in dash.atrasadas.slice(0,3)" :key="t.id" class="ml-2 text-amber-600">{{ t.titulo }}</span>
          <span v-if="dash.atrasadas.length > 3" class="ml-1 text-amber-500">+{{ dash.atrasadas.length - 3 }} mais</span>
        </div>
        <div v-if="dash.presas?.length" class="bg-slate-50 border border-slate-200 rounded-lg px-4 py-3 text-sm">
          <span class="font-semibold text-slate-700">🐢 {{ dash.presas.length }} tarefa(s) parada(s) &gt;72h:</span>
          <span v-for="t in dash.presas.slice(0,3)" :key="t.id" class="ml-2 text-slate-600">
            {{ t.titulo }} ({{ t.idade_horas }}h em {{ t.coluna }})
          </span>
        </div>
      </div>

      <!-- WIP atual por coluna -->
      <div class="cartao">
        <h3 class="font-semibold mb-3">📊 WIP atual por coluna</h3>
        <div class="grid grid-cols-3 sm:grid-cols-5 gap-3">
          <div v-for="(col, nome) in colunas" :key="nome" class="text-center">
            <div
              class="rounded-lg py-3 px-2"
              :class="wipViolado(nome) ? 'bg-red-100' : 'bg-slate-50'"
            >
              <div class="text-2xl font-bold" :class="wipViolado(nome) ? 'text-red-600' : 'text-slate-700'">
                {{ dash.wip_atual[nome] ?? 0 }}
              </div>
              <div v-if="dash.wip_limite[nome]" class="text-xs text-slate-400">
                / {{ dash.wip_limite[nome] }}
              </div>
            </div>
            <div class="text-xs text-slate-500 mt-1 capitalize">{{ col }}</div>
          </div>
        </div>
      </div>

      <!-- Gráficos: CFD + Burndown -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <GraficoCFD :dados="dash.cfd" />

        <GraficoBurndown :snapshots="snapshots" @atualizar="registrarSnapshot" />
      </div>

      <!-- Throughput -->
      <GraficoThroughput
        :dados="dash.throughput.por_dia"
        :total="dash.throughput.total_periodo"
        :media="dash.throughput.media_dia"
      />

      <!-- Lead time / Cycle time -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="cartao">
          <h3 class="font-semibold mb-3">⏱ Lead Time (horas)</h3>
          <div v-if="dash.lead_time_horas.n === 0" class="text-slate-400 text-sm">Sem tarefas concluídas no período.</div>
          <div v-else class="grid grid-cols-3 gap-3 text-center">
            <div>
              <div class="text-xl font-bold text-slate-700">{{ dash.lead_time_horas.media }}</div>
              <div class="text-xs text-slate-500">Média</div>
            </div>
            <div>
              <div class="text-xl font-bold text-blue-600">{{ dash.lead_time_horas.p50 }}</div>
              <div class="text-xs text-slate-500">P50</div>
            </div>
            <div>
              <div class="text-xl font-bold text-purple-600">{{ dash.lead_time_horas.p90 }}</div>
              <div class="text-xs text-slate-500">P90</div>
            </div>
          </div>
          <p class="text-xs text-slate-400 mt-2">Baseado em {{ dash.lead_time_horas.n }} tarefas</p>
        </div>

        <div class="cartao">
          <h3 class="font-semibold mb-3">🔄 Cycle Time (horas)</h3>
          <div v-if="dash.cycle_time_horas.n === 0" class="text-slate-400 text-sm">Sem tarefas concluídas no período.</div>
          <div v-else class="grid grid-cols-3 gap-3 text-center">
            <div>
              <div class="text-xl font-bold text-slate-700">{{ dash.cycle_time_horas.media }}</div>
              <div class="text-xs text-slate-500">Média</div>
            </div>
            <div>
              <div class="text-xl font-bold text-blue-600">{{ dash.cycle_time_horas.p50 }}</div>
              <div class="text-xs text-slate-500">P50</div>
            </div>
            <div>
              <div class="text-xl font-bold text-purple-600">{{ dash.cycle_time_horas.p90 }}</div>
              <div class="text-xs text-slate-500">P90</div>
            </div>
          </div>
          <p class="text-xs text-slate-400 mt-2">Baseado em {{ dash.cycle_time_horas.n }} tarefas</p>
        </div>
      </div>

      <!-- Equipe -->
      <div class="cartao">
        <div class="flex justify-between items-center mb-4">
          <h3 class="font-semibold">👥 Equipe e carga</h3>
          <button
            v-if="!adicionandoMembro"
            class="botao-primario text-xs px-3 py-1"
            @click="abrirFormMembro"
          >
            + Adicionar membro
          </button>
        </div>

        <!-- Formulário inline adicionar membro -->
        <div v-if="adicionandoMembro" class="mb-4 p-4 bg-slate-50 rounded-lg border border-slate-200 space-y-3">
          <h4 class="text-sm font-semibold text-slate-700">Novo membro</h4>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="text-xs text-slate-500 block mb-1">Usuário</label>
              <select v-model="novoMembroUsuarioId" class="w-full px-3 py-2 border rounded-lg text-sm">
                <option value="">Selecione um usuário...</option>
                <option
                  v-for="u in usuariosDisponiveis"
                  :key="u.id"
                  :value="u.id"
                >
                  {{ u.nome }} — {{ u.email }}
                </option>
              </select>
            </div>

            <div>
              <label class="text-xs text-slate-500 block mb-1">Função no projeto</label>
              <select v-model="novoMembroPapel" class="w-full px-3 py-2 border rounded-lg text-sm">
                <option v-if="!papeis.length" value="Desenvolvedor">Desenvolvedor</option>
                <option v-for="p in papeis" :key="p.id" :value="p.nome">
                  {{ p.nome }}
                </option>
              </select>
            </div>
          </div>

          <p v-if="erroMembro" class="text-xs text-perigo">{{ erroMembro }}</p>

          <div class="flex gap-2 justify-end">
            <button class="botao-secundario text-xs px-3 py-1" @click="adicionandoMembro = false">Cancelar</button>
            <button
              class="botao-primario text-xs px-3 py-1"
              :disabled="!novoMembroUsuarioId || salvandoMembro"
              @click="confirmarAdicionarMembro"
            >
              {{ salvandoMembro ? 'Adicionando...' : 'Adicionar' }}
            </button>
          </div>
        </div>

        <div v-if="!membrosCompletos.length" class="text-slate-400 text-sm py-4 text-center">
          Nenhum membro na equipe. Adicione o primeiro.
        </div>
        <div v-else class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b text-left text-slate-500">
                <th class="pb-2 font-medium">Membro</th>
                <th class="pb-2 font-medium">Função</th>
                <th class="pb-2 font-medium text-center">Ativas</th>
                <th class="pb-2 font-medium text-center">Concluídas</th>
                <th class="pb-2 font-medium text-center">Pontos</th>
                <th class="pb-2 font-medium">Carga</th>
                <th class="pb-2 w-8"></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="m in membrosCompletos" :key="m.usuario_id" class="border-b last:border-0 group">
                <td class="py-2 font-medium">
                  <div class="flex items-center gap-2">
                    <div class="w-7 h-7 rounded-full bg-primaria/10 flex items-center justify-center text-xs font-bold text-primaria">
                      {{ (m.nome || '?').charAt(0).toUpperCase() }}
                    </div>
                    <span>{{ m.nome }}</span>
                  </div>
                </td>
                <td class="py-2">
                  <span class="text-xs px-2 py-0.5 rounded bg-slate-100 text-slate-600 capitalize">
                    {{ formatarPapel(m.papel) }}
                  </span>
                </td>
                <td class="py-2 text-center text-amber-600 font-semibold">{{ m.ativas ?? 0 }}</td>
                <td class="py-2 text-center text-green-600 font-semibold">{{ m.concluidas ?? 0 }}</td>
                <td class="py-2 text-center text-slate-600">{{ m.pontos ?? 0 }}</td>
                <td class="py-2 w-28">
                  <div class="h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div
                      class="h-full rounded-full transition-all"
                      :class="(m.ativas ?? 0) > 5 ? 'bg-red-400' : (m.ativas ?? 0) > 2 ? 'bg-amber-400' : 'bg-green-400'"
                      :style="{ width: Math.min(100, ((m.ativas ?? 0) / maxCarga) * 100) + '%' }"
                    />
                  </div>
                </td>
                <td class="py-2 text-right">
                  <button
                    class="text-xs text-slate-300 hover:text-perigo opacity-0 group-hover:opacity-100 transition-opacity"
                    title="Remover membro"
                    @click="removerMembro(m)"
                  >
                    ✕
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Sprints -->
      <div class="cartao">
        <h3 class="font-semibold mb-4">🔄 Sprints</h3>
        <div v-if="!dash.sprints?.length" class="text-slate-400 text-sm">Nenhuma sprint criada.</div>
        <div v-else class="space-y-2">
          <div
            v-for="s in dash.sprints"
            :key="s.id"
            class="flex items-center justify-between py-2 px-3 rounded-lg bg-slate-50"
          >
            <div>
              <span class="font-medium">{{ s.nome }}</span>
              <span class="text-xs text-slate-400 ml-2">
                {{ formatarData(s.data_inicio) }} → {{ formatarData(s.data_fim) }}
              </span>
            </div>
            <span
              class="text-xs px-2 py-1 rounded"
              :class="{
                'bg-green-100 text-green-700': s.status === 'ativa',
                'bg-slate-100 text-slate-600': s.status === 'planejada',
                'bg-blue-100 text-blue-700': s.status === 'concluida',
              }"
            >{{ s.status }}</span>
          </div>
        </div>
      </div>

      <!-- Distribuição por prioridade -->
      <div class="cartao" v-if="prioridades.length">
        <h3 class="font-semibold mb-4">🎯 Distribuição por prioridade</h3>
        <div class="space-y-2">
          <div v-for="p in prioridades" :key="p.nome" class="flex items-center gap-3">
            <span class="text-sm w-20 capitalize" :class="corPrioridade(p.nome)">{{ p.nome }}</span>
            <div class="flex-1 h-4 bg-slate-100 rounded-full overflow-hidden">
              <div
                class="h-full rounded-full"
                :class="bgPrioridade(p.nome)"
                :style="{ width: (p.total / totalTarefas * 100) + '%' }"
              />
            </div>
            <span class="text-sm text-slate-600 font-semibold w-8 text-right">{{ p.total }}</span>
          </div>
        </div>
      </div>

      <!-- Atrasadas detalhadas -->
      <div class="cartao" v-if="dash.atrasadas?.length">
        <h3 class="font-semibold mb-4 text-red-600">🔴 Tarefas atrasadas</h3>
        <div class="space-y-1">
          <div
            v-for="t in dash.atrasadas"
            :key="t.id"
            class="flex items-center justify-between py-2 px-3 bg-red-50 rounded"
          >
            <span class="text-sm font-medium">{{ t.titulo }}</span>
            <div class="flex items-center gap-2">
              <span class="text-xs px-2 py-0.5 rounded bg-slate-100 capitalize">{{ t.coluna?.replace('_', ' ') }}</span>
              <span class="text-xs px-2 py-0.5 rounded" :class="bgPrioridade(t.prioridade)">{{ t.prioridade }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Presas detalhadas -->
      <div class="cartao" v-if="dash.presas?.length">
        <h3 class="font-semibold mb-4 text-slate-600">🐢 Tarefas paradas (&gt;72h)</h3>
        <div class="space-y-1">
          <div
            v-for="t in dash.presas"
            :key="t.id"
            class="flex items-center justify-between py-2 px-3 bg-slate-50 rounded"
          >
            <span class="text-sm font-medium">{{ t.titulo }}</span>
            <div class="flex items-center gap-2">
              <span class="text-xs text-slate-500">{{ t.coluna?.replace('_', ' ') }}</span>
              <span class="text-xs font-semibold text-slate-600">{{ t.idade_horas }}h</span>
            </div>
          </div>
        </div>
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
    const projetoId = (route.query.id || route.query.projeto) as string

    return {
      projetoId,
      dash: null as any,
      snapshots: [] as any[],
      sprints: [] as any[],
      carregando: false,
      erro: '',
      membrosReais: [] as any[],
      todosUsuarios: [] as any[],
      adicionandoMembro: false,
      novoMembroUsuarioId: '',
      novoMembroPapel: 'Desenvolvedor',
      erroMembro: '',
      salvandoMembro: false,
      papeis: [] as any[]
    }
  },

  computed: {
    temAlertas(): boolean {
      return !!(
        this.dash?.wip_violacoes?.length ||
        this.dash?.atrasadas?.length ||
        this.dash?.presas?.length
      )
    },

    corSaude(): string {
      const s = this.dash?.saude_score ?? 100
      if (s >= 80) return 'text-green-600'
      if (s >= 50) return 'text-amber-600'
      return 'text-red-600'
    },

    colunas(): Record<string, string> {
      return {
        backlog: 'Backlog',
        a_fazer: 'A fazer',
        em_progresso: 'Em progresso',
        em_revisao: 'Em revisão',
        concluido: 'Concluído'
      }
    },

    membrosCompletos(): any[] {
      const carga = this.dash?.carga_por_pessoa ?? {}
      return this.membrosReais.map((m: any) => {
        const c = carga[m.usuario_id] ?? {}
        return {
          ...m,
          nome: m.usuarios?.nome || c.nome || '—',
          email: m.usuarios?.email || '',
          ativas: c.ativas ?? 0,
          concluidas: c.concluidas ?? 0,
          pontos: c.pontos ?? 0
        }
      }).sort((a: any, b: any) => b.ativas - a.ativas)
    },

    usuariosDisponiveis(): any[] {
      const jaAdicionados = new Set(this.membrosReais.map((m: any) => m.usuario_id))
      return this.todosUsuarios.filter((u: any) => !jaAdicionados.has(u.id))
    },

    maxCarga(): number {
      return Math.max(1, ...this.membrosCompletos.map((m: any) => m.ativas))
    },

    prioridades(): any[] {
      if (!this.dash?.por_prioridade) return []
      return Object.entries(this.dash.por_prioridade)
        .map(([nome, total]) => ({ nome, total: total as number }))
        .sort((a, b) => b.total - a.total)
    },

    totalTarefas(): number {
      return Math.max(1, this.dash?.totais?.tarefas ?? 1)
    }
  },

  async mounted() {
    await this.carregarDados()
  },

  methods: {
    async carregarDados() {
      this.carregando = true
      this.erro = ''
      try {
        const cliente = useSupabaseClient()

        const { data, error } = await cliente.functions.invoke('dashboardProjeto', {
          body: { projeto_id: this.projetoId, dias: 14 }
        })

        if (error) throw error
        this.dash = data

        // Busca membros reais (com papel) e sprint ativa em paralelo
        const sprintAtiva = (data?.sprints ?? []).find((s: any) => s.status === 'ativa')
        this.sprints = data?.sprints ?? []

        const [membros] = await Promise.all([
          servicoEquipe().listarMembrosPorID(this.projetoId),
          sprintAtiva
            ? cliente.from('snapshots_sprint').select('*').eq('sprint_id', sprintAtiva.id).order('data', { ascending: true })
              .then(({ data: snaps }) => { this.snapshots = snaps || [] })
            : Promise.resolve()
        ])
        this.membrosReais = membros || []
      } catch (e: any) {
        this.erro = e?.message || 'Erro ao carregar dashboard'
      } finally {
        this.carregando = false
      }
    },

    async abrirFormMembro() {
      this.adicionandoMembro = true
      this.erroMembro = ''
      const [usuarios, papeis] = await Promise.all([
        this.todosUsuarios.length ? Promise.resolve(this.todosUsuarios) : servicoEquipe().listarTodos(),
        this.papeis.length ? Promise.resolve(this.papeis) : servicoPapeis().listar()
      ])
      this.todosUsuarios = usuarios
      this.papeis = papeis
      if (papeis.length && !this.novoMembroPapel) {
        this.novoMembroPapel = papeis[0].nome
      }
    },

    async confirmarAdicionarMembro() {
      if (!this.novoMembroUsuarioId) return
      this.salvandoMembro = true
      this.erroMembro = ''
      try {
        await servicoEquipe().adicionarMembro(this.projetoId, this.novoMembroUsuarioId, this.novoMembroPapel || 'Desenvolvedor')
        this.membrosReais = await servicoEquipe().listarMembrosPorID(this.projetoId)
        this.adicionandoMembro = false
        this.novoMembroUsuarioId = ''
        this.novoMembroPapel = 'desenvolvedor'
      } catch (e: any) {
        this.erroMembro = e?.message || 'Erro ao adicionar membro'
      } finally {
        this.salvandoMembro = false
      }
    },

    async removerMembro(m: any) {
      if (!confirm(`Remover ${m.nome} da equipe?`)) return
      await servicoEquipe().removerMembro(m.id)
      this.membrosReais = this.membrosReais.filter((mb: any) => mb.id !== m.id)
    },

    formatarPapel(papel: string): string {
      const map: Record<string, string> = {
        desenvolvedor: 'Desenvolvedor',
        admin: 'Administrador',
        visualizador: 'Visualizador'
      }
      return map[papel] ?? papel
    },

    async registrarSnapshot() {
      const sprintAtiva = this.sprints.find((s: any) => s.status === 'ativa')
      if (!sprintAtiva) return alert('Nenhuma sprint ativa para registrar snapshot.')
      await servicoSprints().registrarSnapshotHoje(sprintAtiva.id)
      await this.carregarDados()
    },

    wipViolado(coluna: string): boolean {
      return (this.dash?.wip_violacoes ?? []).some((v: any) => v.coluna === coluna)
    },

    formatarData(data: string | null): string {
      if (!data) return '—'
      return data.slice(0, 10).split('-').reverse().join('/')
    },

    corPrioridade(p: string): string {
      const map: Record<string, string> = {
        critica: 'text-red-600',
        alta: 'text-orange-600',
        media: 'text-amber-600',
        baixa: 'text-slate-500'
      }
      return map[p] ?? 'text-slate-500'
    },

    bgPrioridade(p: string): string {
      const map: Record<string, string> = {
        critica: 'bg-red-100 text-red-700',
        alta: 'bg-orange-100 text-orange-700',
        media: 'bg-amber-100 text-amber-700',
        baixa: 'bg-slate-100 text-slate-600'
      }
      return map[p] ?? 'bg-slate-100 text-slate-600'
    }
  }
})
</script>
