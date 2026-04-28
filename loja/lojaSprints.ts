// loja/lojaSprints.ts
import { defineStore } from 'pinia'

export const useLojaSprints = defineStore('sprints', {
  state: () => ({
    sprints: [] as any[],
    sprintAtual: null as any | null,
    tarefasSprint: [] as any[],
    backlog: [] as any[],
    snapshots: [] as any[],
    projetoId: null as string | null,
    carregando: false,
  }),
  getters: {
    progresso: (s) => {
      const total = s.tarefasSprint.length
      const ok = s.tarefasSprint.filter(t => t.coluna === 'concluido').length
      return { total, ok, percent: total ? Math.round((ok / total) * 100) : 0 }
    },
  },
  actions: {
    async carregarPorProjeto(projetoId: string) {
      this.carregando = true; this.projetoId = projetoId
      try { this.sprints = await servicoSprints().listar(projetoId) }
      finally { this.carregando = false }
    },
    async selecionar(sprintId: string) {
      const svc = servicoSprints()
      this.sprintAtual = await svc.obter(sprintId)
      const projetoId = this.sprintAtual.projeto_id
      const [tarefas, backlog, snaps] = await Promise.all([
        svc.tarefasDaSprint(sprintId),
        svc.tarefasDoBacklog(projetoId),
        svc.snapshots(sprintId),
      ])
      this.tarefasSprint = tarefas
      this.backlog = backlog
      this.snapshots = snaps
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
    async associar(tarefaId: string, sprintId: string | null) {
      await servicoSprints().associarTarefa(tarefaId, sprintId)
      if (sprintId && this.sprintAtual?.id === sprintId) {
        // recarrega listas
        await this.selecionar(sprintId)
      } else if (!sprintId && this.sprintAtual) {
        this.tarefasSprint = this.tarefasSprint.filter(t => t.id !== tarefaId)
      }
    },
    async atualizarSnapshot() {
      if (!this.sprintAtual) return
      await servicoSprints().registrarSnapshotHoje(this.sprintAtual.id)
      this.snapshots = await servicoSprints().snapshots(this.sprintAtual.id)
    },
  },
})
