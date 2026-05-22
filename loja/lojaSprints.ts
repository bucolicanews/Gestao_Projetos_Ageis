// loja/lojaSprints.ts
import { defineStore } from 'pinia'

export const useLojaSprints = defineStore('sprints', {
  state: () => ({
    sprints: [] as any[],
    sprintAtual: null as any | null,
    tarefasSprint: [] as any[],
    backlog: [] as any[],
    snapshots: [] as any[],
    throughputBruto: [] as any[],
    membrosSprint: [] as any[],
    velocityHistorico: [] as any[],
    velocityMedia: 0,
    projetoId: null as string | null,
    carregando: false,
  }),

  getters: {
    progresso: (s) => {
      const total = s.tarefasSprint.length
      const ok = s.tarefasSprint.filter(t => t.coluna === 'concluido').length
      return { total, ok, percent: total ? Math.round((ok / total) * 100) : 0 }
    },

    pontosAlocados: (s) =>
      s.tarefasSprint.reduce((acc: number, t: any) => acc + (t.pontos || 0), 0),

    pontosConcluidos: (s) =>
      s.tarefasSprint
        .filter((t: any) => t.coluna === 'concluido')
        .reduce((acc: number, t: any) => acc + (t.pontos || 0), 0),

    pontosBacklog: (s) =>
      s.backlog.reduce((acc: number, t: any) => acc + (t.pontos || 0), 0),

    // Capacidade calculada em tempo real (antes de ativar a sprint)
    capacidadeCalculada: (s) => {
      const sprint = s.sprintAtual
      if (!sprint?.data_inicio || !sprint?.data_fim || !s.membrosSprint.length) return 0
      const dias = Math.max(1,
        (new Date(sprint.data_fim).getTime() - new Date(sprint.data_inicio).getTime()) / 86400000
      )
      const soma = s.membrosSprint.reduce(
        (acc: number, m: any) => acc + (m.horas_dia || 6) * (m.fator_produtividade || 0.8),
        0
      )
      return Math.round(soma * dias)
    },

    distribuicao: (s) => {
      const colunas = ['backlog', 'a_fazer', 'em_progresso', 'em_revisao', 'concluido']
      const labels: Record<string, string> = {
        backlog: 'Backlog',
        a_fazer: 'A fazer',
        em_progresso: 'Em progresso',
        em_revisao: 'Em revisão',
        concluido: 'Concluído',
      }
      const cores: Record<string, string> = {
        backlog: '#94a3b8',
        a_fazer: '#60a5fa',
        em_progresso: '#fbbf24',
        em_revisao: '#a78bfa',
        concluido: '#34d399',
      }
      const contagem: Record<string, number> = {}
      for (const col of colunas) contagem[col] = 0
      for (const t of s.tarefasSprint) {
        if (contagem[t.coluna] !== undefined) contagem[t.coluna]++
      }
      return colunas.map(col => ({
        coluna: col,
        label: labels[col],
        cor: cores[col],
        total: contagem[col],
      }))
    },

    throughput: (s) => {
      const por_dia: Record<string, number> = {}
      for (const t of s.throughputBruto) {
        const dia = (t.concluido_em as string | null)?.slice(0, 10)
        if (dia) por_dia[dia] = (por_dia[dia] || 0) + 1
      }
      const total = Object.values(por_dia).reduce((a, b) => a + b, 0)
      const dias = Object.keys(por_dia).length
      return {
        dados: por_dia,
        total,
        media: dias ? +(total / dias).toFixed(1) : 0,
      }
    },
  },

  actions: {
    async carregarPorProjeto(projetoId: string) {
      this.carregando = true
      this.projetoId = projetoId
      try {
        this.sprints = await servicoSprints().listar(projetoId)
      } finally {
        this.carregando = false
      }
    },

    async selecionar(sprintId: string) {
      const svc = servicoSprints()
      this.sprintAtual = await svc.obter(sprintId)
      const projetoId = this.sprintAtual.projeto_id
      // Each call isolated so one failure (e.g. missing table before migration) never empties tarefasSprint
      const [tarefas, backlog, snaps, throughput, membros] = await Promise.all([
        svc.tarefasDaSprint(sprintId).catch(() => []),
        svc.tarefasDoBacklog(projetoId, sprintId).catch(() => []),
        svc.snapshots(sprintId).catch(() => []),
        svc.throughputSprint(sprintId).catch(() => []),
        svc.listarMembros(sprintId).catch(() => []),
      ])
      this.tarefasSprint = tarefas ?? []
      this.backlog = backlog ?? []
      this.snapshots = snaps ?? []
      this.throughputBruto = throughput ?? []
      this.membrosSprint = membros ?? []
    },

    async criar(payload: any) {
      const novo = await servicoSprints().criar({ ...payload, projeto_id: this.projetoId })
      this.sprints.unshift(novo)
      return novo
    },

    async atualizar(id: string, alt: any) {
      const upd = await servicoSprints().atualizar(id, alt)
      const i = this.sprints.findIndex(s => s.id === id)
      if (i >= 0) this.sprints[i] = upd
      if (this.sprintAtual?.id === id) this.sprintAtual = upd
    },

    async excluir(id: string) {
      await servicoSprints().excluir(id)
      this.sprints = this.sprints.filter(s => s.id !== id)
      if (this.sprintAtual?.id === id) {
        this.sprintAtual = null
        this.tarefasSprint = []
        this.backlog = []
        this.snapshots = []
      }
    },

    async criarTarefa(payload: { titulo: string; prioridade?: string; pontos?: number }) {
      if (!this.sprintAtual || !this.projetoId) return
      const nova = await servicoTarefas().criarTarefa({
        ...payload,
        projeto_id: this.projetoId,
        sprint_id: this.sprintAtual.id,
        coluna: 'a_fazer',
      })
      this.tarefasSprint.unshift(nova)
    },

    async associar(tarefaId: string, sprintId: string | null) {
      await servicoSprints().associarTarefa(tarefaId, sprintId)
      // Always reload both lists so sprint <-> backlog stay in sync
      if (this.sprintAtual) {
        await this.selecionar(this.sprintAtual.id)
      }
    },

    async atualizarSnapshot() {
      if (!this.sprintAtual) return
      await servicoSprints().registrarSnapshotHoje(this.sprintAtual.id)
      this.snapshots = await servicoSprints().snapshots(this.sprintAtual.id)
    },

    removerTarefaLocal(id: string) {
      this.tarefasSprint = this.tarefasSprint.filter(t => t.id !== id)
      this.backlog = this.backlog.filter(t => t.id !== id)
    },

    async carregarVelocity(projetoId: string) {
      const svc = servicoSprints()
      const [hist, media] = await Promise.all([
        svc.velocityProjeto(projetoId),
        svc.velocityMedia(projetoId),
      ])
      this.velocityHistorico = hist
      this.velocityMedia = media
    },

    async salvarMembroSprint(usuarioId: string, horas_dia: number, fator_produtividade: number) {
      if (!this.sprintAtual) return
      await servicoSprints().salvarMembro(this.sprintAtual.id, usuarioId, horas_dia, fator_produtividade)
      this.membrosSprint = await servicoSprints().listarMembros(this.sprintAtual.id)
    },

    async removerMembroSprint(usuarioId: string) {
      if (!this.sprintAtual) return
      await servicoSprints().removerMembro(this.sprintAtual.id, usuarioId)
      this.membrosSprint = this.membrosSprint.filter((m: any) => m.usuario_id !== usuarioId)
    },
  },
})
