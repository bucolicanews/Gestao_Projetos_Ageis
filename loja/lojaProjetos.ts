// loja/lojaProjetos.ts
import { defineStore } from 'pinia'

export const useLojaProjetos = defineStore('projetos', {
  state: () => ({
    projetos: [] as any[],
    projetoAtual: null as any | null,
    carregando: false,
  }),
  actions: {
    async carregar() {
      this.carregando = true
      try { this.projetos = await servicoProjetos().listarProjetos() }
      finally { this.carregando = false }
    },
    async selecionar(id: string) {
      this.projetoAtual = await servicoProjetos().obterProjeto(id)
    },
    async criar(payload: { nome: string; descricao?: string }) {
      const novo = await servicoProjetos().criarProjeto(payload)
      this.projetos.unshift(novo)
      return novo
    },
    async atualizar(payload: { id: string; nome?: string; descricao?: string; status?: string }) {
      const atualizado = await servicoProjetos().atualizarProjeto(payload)
      const idx = this.projetos.findIndex(p => p.id === payload.id)
      if (idx !== -1) this.projetos[idx] = atualizado
      if (this.projetoAtual?.id === payload.id) this.projetoAtual = atualizado
      return atualizado
    },
    async excluir(id: string) {
      await servicoProjetos().excluirProjeto(id)
      this.projetos = this.projetos.filter(p => p.id !== id)
    },
  },
})
