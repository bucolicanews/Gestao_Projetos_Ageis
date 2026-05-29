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

    <div v-if="loja.carregando">
      Carregando...
    </div>

    <div v-else class="grid gap-4 md:grid-cols-3">
      <div v-for="p in loja.projetos" :key="p.id" class="cartao hover:shadow-md transition">
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

      <div v-if="!loja.projetos.length" class="text-slate-500">
        Nenhum projeto ainda.
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
    return { exportando, exportarProjeto, importando, importarProjeto, lerArquivoJson }
  },

  data() {
    return {
      loja: useLojaProjetos(),
      abrindo: false,
      projetoEditando: null as any,
      relatorio: null as RelatorioImportacao | null,
      mostrarPromptIA: false,
    }
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

    linkProjeto(id: string) { return `/dashboardProjeto?id=${id}` },
    linkKanban(id: string)  { return `/kanban?projeto=${id}` },
    linkSprint(id: string)  { return `/sprints?projeto=${id}` },
  },
})
</script>
