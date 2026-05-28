<template>
  <div>
    <div class="flex justify-between items-center mb-6 flex-wrap gap-3">
      <h1 class="text-3xl font-bold">
        📌 Quadro Kanban
      </h1>

      <div class="flex items-center gap-3">
        <div v-if="presentes.length" class="flex items-center gap-2">
          <div class="flex -space-x-2">
            <div
              v-for="p in presentesLimitados"
              :key="p.id"
              :title="p.nome"
              class="w-8 h-8 rounded-full bg-primaria text-white text-xs flex items-center justify-center border-2 border-white"
            >
              {{ inicialNome(p.nome) }}
            </div>
          </div>

          <span class="text-xs text-slate-500">
            {{ presentes.length }} online
            <span class="inline-block w-2 h-2 rounded-full bg-sucesso animate-pulse ml-1" />
          </span>
        </div>

        <select v-model="projetoId" class="px-3 py-2 border rounded-lg">
          <option value="">Selecione um projeto...</option>
          <option v-for="p in lojaProjetos.projetos" :key="p.id" :value="p.id">
            {{ p.nome }}
          </option>
        </select>
      </div>
    </div>

    <div v-if="!projetoId" class="text-slate-500">
      Escolha um projeto para visualizar o quadro.
    </div>

    <div v-else class="flex gap-4 overflow-x-auto pb-4">
      <ColunaKanban
        v-for="col in COLUNAS"
        :key="col.id"
        :titulo="col.titulo"
        :coluna="col.id"
        :tarefas="loja.porColuna(col.id)"
        :pode-criar="podeCriarTarefas"
        @mover="aoMover"
        @nova="criarNovaTarefa($event, col.id)"
        @clicar-tarefa="abrirModal"
      />
    </div>

    <ModalTarefa
      :exibir="modalAberto"
      :tarefa="tarefaSelecionada"
      :membros="membros"
      @fechar="fecharModal"
      @salvo="aoSalvarTarefa"
      @deletado="aoDeletarTarefa"
    />
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'
import { COLUNAS } from '~/loja/lojaKanban'

export default defineComponent({
  name: 'PaginaKanban',

  data() {
    const route = useRoute()

    return {
      COLUNAS,
      loja: useLojaKanban(),
      lojaProjetos: useLojaProjetos(),
      user: useSupabaseUser(),
      projetoId: String(route.query.projeto ?? ''),
      presentes: [] as any[],
      membros: [] as any[],
      tarefaSelecionada: null as any,
      modalAberto: false,
    }
  },

  computed: {
    podeCriarTarefas() {
      return !!this.user
    },

    presentesLimitados() {
      return this.presentes.slice(0, 5)
    }
  },

  watch: {
    projetoId: {
      immediate: true,
      async handler(id: string) {
        if (id) {
          await this.loja.carregar(id)
          await this.carregarMembros(id)
          this.iniciarRealtime()
        }
      }
    }
  },

  async mounted() {
    if (!this.lojaProjetos.projetos.length) {
      await this.lojaProjetos.carregar()
    }
  },

  methods: {
    async carregarMembros(projetoId: string) {
      const dados = await servicoEquipe().listarMembrosPorID(projetoId)
      this.membros = dados || []
    },

    iniciarRealtime() {
      const projetoIdRef = computed(() => this.projetoId || null)
      const { presentes: presentesRef } = useRealtimeKanban(projetoIdRef)
      this.presentes = presentesRef.value || []
    },

    abrirModal(tarefa: any) {
      this.tarefaSelecionada = tarefa
      this.modalAberto = true
    },

    fecharModal() {
      this.modalAberto = false
      this.tarefaSelecionada = null
    },

    aoSalvarTarefa(tarefaAtualizada: any) {
      const i = this.loja.tarefas.findIndex(t => t.id === tarefaAtualizada.id)
      if (i >= 0) Object.assign(this.loja.tarefas[i], tarefaAtualizada)
    },

    aoDeletarTarefa(id: string) {
      this.loja.tarefas = this.loja.tarefas.filter(t => t.id !== id)
      useLojaSprints().removerTarefaLocal(id)
    },

    async aoMover(evento: { tarefa_id: string; coluna: string; posicao: number }) {
      await this.loja.mover(evento.tarefa_id, evento.coluna, evento.posicao)
    },

    async criarNovaTarefa(payload: any, colunaId: string) {
      await this.loja.criar({
        ...payload,
        coluna: colunaId,
        projeto_id: String(this.projetoId)
      })
    },

    inicialNome(nome: string) {
      return (nome ?? '?').slice(0, 1).toUpperCase()
    }
  }
})
</script>
