import { defineStore } from 'pinia'

export const COLUNAS = [
  { id: 'backlog', titulo: 'Backlog' },
  { id: 'a_fazer', titulo: 'A Fazer' },
  { id: 'em_progresso', titulo: 'Em Progresso' },
  { id: 'em_revisao', titulo: 'Em Revisão' },
  { id: 'concluido', titulo: 'Concluído' }
]

export const useLojaKanban = defineStore('kanban', {
  state: () => ({
    tarefas: [] as any[],
    carregando: false,
  }),

  getters: {
    porColuna: (state) => (colunaId: string) => {
      return state.tarefas.filter(t => t.coluna === colunaId)
    }
  },

  actions: {
    async carregar(projetoId: string) {
      this.carregando = true
      try {
        this.tarefas = await servicoTarefas().listarTarefas(projetoId)
      } finally {
        this.carregando = false
      }
    },

    async mover(tarefa_id: string, coluna: string, posicao: number) {
      // 1. Atualização Otimista: Move na UI instantaneamente
      const index = this.tarefas.findIndex(t => t.id === tarefa_id)
      if (index === -1) return

      const backupTarefa = { ...this.tarefas[index] }
      
      // Atualiza localmente
      Object.assign(this.tarefas[index], { coluna, posicao })

      // 2. Persistência
      try {
        // Ordena localmente para refletir a nova posição imediatamente
        this.tarefas.sort((a, b) => a.posicao - b.posicao)
        
        await servicoTarefas().moverTarefa(tarefa_id, coluna, posicao)
      } catch (error) {
        console.error('Erro ao persistir movimento:', error)
        // Reverte em caso de erro
        this.tarefas[index] = backupTarefa
      }
    },

    async criar(payload: any) {
      const nova = await servicoTarefas().criarTarefa(payload)
      this.tarefas.push(nova)
      return nova
    }
  }
})