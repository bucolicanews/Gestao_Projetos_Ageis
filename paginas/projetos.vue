<template>
  <div>
    <!-- Cabeçalho -->
    <div class="flex flex-wrap justify-between items-center mb-6 gap-3">
      <h1 class="text-2xl sm:text-3xl font-bold">
        📁 Projetos
      </h1>

      <div class="flex gap-2">
        <button
          class="botao-secundario text-sm"
          title="Como gerar projeto com IA"
          @click="mostrarPromptIA = true"
        >
          🤖 Gerar com IA
        </button>

        <button
          class="botao-secundario text-sm"
          :disabled="importando"
          title="Importar projeto a partir de arquivo JSON"
          @click="handleImportar"
        >
          {{ importando ? 'Importando...' : '↑ Importar JSON' }}
        </button>

        <button class="botao-primario text-sm" @click="abrirModal">
          + Novo projeto
        </button>
      </div>
    </div>

    <!-- Abas de filtro por status -->
    <div class="flex gap-1 border-b mb-5 overflow-x-auto">
      <button
        v-for="aba in abas"
        :key="aba.valor"
        class="flex items-center gap-1.5 px-4 py-2 text-sm font-medium whitespace-nowrap transition-colors"
        :class="filtroStatus === aba.valor
          ? 'border-b-2 border-primaria text-primaria -mb-px'
          : 'text-slate-500 hover:text-slate-700'"
        @click="filtroStatus = aba.valor"
      >
        {{ aba.label }}
        <span
          class="text-xs px-1.5 py-0.5 rounded-full font-bold"
          :class="filtroStatus === aba.valor
            ? 'bg-primaria text-white'
            : 'bg-slate-100 text-slate-500'"
        >
          {{ contarStatus(aba.valor) }}
        </span>
      </button>
    </div>

    <div v-if="loja.carregando">
      Carregando...
    </div>

    <div v-else class="grid gap-4 md:grid-cols-3">
      <div v-for="p in projetosFiltrados" :key="p.id" class="cartao hover:shadow-md transition">
        <div class="flex justify-between items-start">
          <NuxtLink :to="linkProjeto(p.id)" class="font-semibold text-lg hover:text-primaria">
            {{ p.nome }}
          </NuxtLink>

          <div class="flex items-center gap-2">
            <span class="text-xs px-2 py-1 rounded bg-slate-100">
              {{ p.status }}
            </span>

            <button
              class="text-xs text-slate-400 hover:text-primaria p-1 rounded"
              title="Exportar projeto como JSON"
              :disabled="exportando"
              @click.stop="exportarProjeto(p.id)"
            >
              ↓
            </button>

            <button
              class="text-xs text-slate-400 hover:text-primaria p-1 rounded"
              title="Editar projeto"
              @click.stop="abrirEdicao(p)"
            >
              ✏️
            </button>

            <template v-if="permissoes.temPermissao(p.id, 'excluir_projeto')">
              <button
                v-if="confirmandoExclusao !== p.id"
                class="text-xs text-slate-400 hover:text-red-500 p-1 rounded"
                title="Excluir projeto"
                @click.stop="confirmandoExclusao = p.id"
              >
                🗑️
              </button>

              <span v-else class="flex items-center gap-1 text-xs">
                <span class="text-red-500 font-medium">Excluir?</span>
                <button
                  class="text-red-600 hover:text-red-800 font-bold px-1"
                  :disabled="excluindo"
                  @click.stop="confirmarExclusao(p.id)"
                >Sim</button>
                <button
                  class="text-slate-400 hover:text-slate-600 px-1"
                  @click.stop="confirmandoExclusao = null"
                >Não</button>
              </span>
            </template>
          </div>
        </div>

        <p class="text-sm text-slate-500 mt-2 line-clamp-3">
          {{ p.descricao || 'Sem descrição.' }}
        </p>

        <div class="mt-3 flex gap-3 text-xs text-slate-500">
          <NuxtLink :to="linkProjeto(p.id)" class="hover:text-primaria">
            📊 Dashboard
          </NuxtLink>

          <NuxtLink :to="linkKanban(p.id)" class="hover:text-primaria">
            Kanban
          </NuxtLink>

          <NuxtLink :to="linkSprint(p.id)" class="hover:text-primaria">
            Sprints
          </NuxtLink>
        </div>
      </div>

      <div v-if="!projetosFiltrados.length" class="text-slate-500 col-span-3">
        Nenhum projeto {{ labelStatus(filtroStatus) }} ainda.
      </div>
    </div>

    <!-- Modal prompt IA -->
    <ModalPromptIA v-if="mostrarPromptIA" @fechar="mostrarPromptIA = false" />

    <!-- Modal criar/editar projeto -->
    <ModalProjeto
      v-if="abrindo"
      :projeto="projetoEditando"
      @fechar="fecharModal"
      @criado="projetoCriado"
      @atualizado="fecharModal"
    />

    <!-- Modal relatório de importação -->
    <div
      v-if="relatorio"
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
      @click.self="fecharRelatorio"
    >
      <div class="bg-white rounded-xl shadow-xl max-w-md w-full p-6 space-y-4">
        <div v-if="relatorio.erros.length">
          <h2 class="text-lg font-bold text-red-600">❌ Importação falhou</h2>
          <ul class="mt-2 text-sm text-red-500 space-y-1">
            <li v-for="e in relatorio.erros" :key="e">{{ e }}</li>
          </ul>
        </div>

        <div v-else>
          <h2 class="text-lg font-bold text-green-600">✅ Projeto importado com sucesso</h2>
          <p class="text-slate-700 font-medium mt-1">{{ relatorio.projetoNome }}</p>

          <div class="grid grid-cols-3 gap-2 mt-3 text-center text-sm">
            <div class="bg-slate-50 rounded p-2">
              <p class="font-bold text-lg">{{ relatorio.sprintsCriadas }}</p>
              <p class="text-slate-500 text-xs">Sprints</p>
            </div>
            <div class="bg-slate-50 rounded p-2">
              <p class="font-bold text-lg">{{ relatorio.tarefasCriadas }}</p>
              <p class="text-slate-500 text-xs">Tarefas</p>
            </div>
            <div class="bg-slate-50 rounded p-2">
              <p class="font-bold text-lg">{{ relatorio.subTarefasCriadas }}</p>
              <p class="text-slate-500 text-xs">Sub-tarefas</p>
            </div>
            <div class="bg-slate-50 rounded p-2">
              <p class="font-bold text-lg">{{ relatorio.comentariosCriados }}</p>
              <p class="text-slate-500 text-xs">Comentários</p>
            </div>
            <div class="bg-slate-50 rounded p-2">
              <p class="font-bold text-lg">{{ relatorio.anotacoesCriadas }}</p>
              <p class="text-slate-500 text-xs">Anotações</p>
            </div>
            <div class="bg-slate-50 rounded p-2">
              <p class="font-bold text-lg">{{ relatorio.membrosCriados }}</p>
              <p class="text-slate-500 text-xs">Membros</p>
            </div>
          </div>

          <div v-if="relatorio.warnings.length" class="mt-3">
            <p class="text-xs font-semibold text-amber-600">⚠️ Avisos ({{ relatorio.warnings.length }})</p>
            <ul class="mt-1 text-xs text-amber-600 space-y-1 max-h-24 overflow-y-auto">
              <li v-for="w in relatorio.warnings" :key="w">{{ w }}</li>
            </ul>
          </div>
        </div>

        <div class="flex gap-2 pt-2">
          <NuxtLink
            v-if="relatorio.projetoId"
            :to="linkProjeto(relatorio.projetoId)"
            class="botao-primario text-sm flex-1 text-center"
            @click="fecharRelatorio"
          >
            Ir para o projeto
          </NuxtLink>
          <button class="botao-secundario text-sm flex-1" @click="fecharRelatorio">
            Fechar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'
import type { RelatorioImportacao } from '~/composables/useImportProjeto'

export default defineComponent({
  name: 'PaginaProjetos',

  setup() {
    const { exportando, exportarProjeto } = useExportProjeto()
    const { importando, importarProjeto, lerArquivoJson } = useImportProjeto()
    const permissoes = usePermissoesProjeto()
    return { exportando, exportarProjeto, importando, importarProjeto, lerArquivoJson, permissoes }
  },

  data() {
    return {
      loja: useLojaProjetos(),
      abrindo: false,
      projetoEditando: null as any,
      relatorio: null as RelatorioImportacao | null,
      mostrarPromptIA: false,
      confirmandoExclusao: null as string | null,
      excluindo: false,
      filtroStatus: 'ativo' as string,
      abas: [
        { valor: 'ativo',    label: 'Ativos'     },
        { valor: 'pausado',  label: 'Pausados'   },
        { valor: 'concluido',label: 'Concluídos' },
        { valor: 'arquivado',label: 'Arquivados' },
      ],
    }
  },

  computed: {
    projetosFiltrados(): any[] {
      return this.loja.projetos.filter((p: any) => p.status === this.filtroStatus)
    },
  },

  mounted() {
    this.carregarProjetos()
  },

  methods: {
    carregarProjetos() {
      this.loja.carregar()
    },

    abrirModal() {
      this.projetoEditando = null
      this.abrindo = true
    },

    abrirEdicao(projeto: any) {
      this.projetoEditando = projeto
      this.abrindo = true
    },

    fecharModal() {
      this.abrindo = false
      this.projetoEditando = null
    },

    projetoCriado() {
      this.fecharModal()
      this.carregarProjetos()
    },

    fecharRelatorio() {
      this.relatorio = null
    },

    async confirmarExclusao(id: string) {
      this.excluindo = true
      try {
        await this.loja.excluir(id)
        this.confirmandoExclusao = null
      } catch (err: any) {
        alert(`Erro ao excluir: ${err.message}`)
      } finally {
        this.excluindo = false
      }
    },

    async handleImportar() {
      try {
        const json = await this.lerArquivoJson()
        const rel  = await this.importarProjeto(json)
        this.relatorio = rel
        if (!rel.erros.length) this.carregarProjetos()
      } catch (err: any) {
        // Usuário cancelou o file picker — ignorar silenciosamente
      }
    },

    contarStatus(status: string): number {
      return this.loja.projetos.filter((p: any) => p.status === status).length
    },

    labelStatus(status: string): string {
      return this.abas.find(a => a.valor === status)?.label.toLowerCase() ?? status
    },

    linkProjeto(id: string) { return `/dashboardProjeto?id=${id}` },
    linkKanban(id: string)  { return `/kanban?projeto=${id}` },
    linkSprint(id: string)  { return `/sprints?projeto=${id}` },
  },
})
</script>
