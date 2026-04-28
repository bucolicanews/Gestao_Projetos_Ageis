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
    async excluir(id: string) {
      await servicoProjetos().excluirProjeto(id)
      this.projetos = this.projetos.filter(p => p.id !== id)
    },
  },
})
