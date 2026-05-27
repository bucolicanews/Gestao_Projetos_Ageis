// loja/lojaPlanos.ts
import { defineStore } from 'pinia'
import type { Plano, PlanoInput } from '~/servicos/servicoPlanos'

export const useLojaPlanos = defineStore('planos', {
  state: () => ({
    planos: [] as Plano[],
    carregando: false,
    erro: null as string | null,
  }),

  getters: {
    ativos: (state) => state.planos.filter(p => p.ativo),
    inativos: (state) => state.planos.filter(p => !p.ativo),
  },

  actions: {
    async carregar() {
      this.carregando = true
      this.erro = null
      try {
        this.planos = await servicoPlanos().listar()
      } catch (e: any) {
        this.erro = e.message
      } finally {
        this.carregando = false
      }
    },

    async criar(payload: PlanoInput) {
      const novo = await servicoPlanos().criar(payload)
      this.planos.push(novo)
      this.planos.sort((a, b) => a.preco - b.preco)
      return novo
    },

    async atualizar(id: string, payload: Partial<PlanoInput>) {
      const atualizado = await servicoPlanos().atualizar(id, payload)
      const idx = this.planos.findIndex(p => p.id === id)
      if (idx !== -1) this.planos[idx] = atualizado
      return atualizado
    },

    async excluir(id: string) {
      await servicoPlanos().excluir(id)
      this.planos = this.planos.filter(p => p.id !== id)
    },

    async alternarAtivo(id: string) {
      const plano = this.planos.find(p => p.id === id)
      if (!plano) return
      const novoAtivo = !plano.ativo
      await servicoPlanos().alternarAtivo(id, novoAtivo)
      plano.ativo = novoAtivo
    },
  },
})
