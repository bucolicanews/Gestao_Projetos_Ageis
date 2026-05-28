<template>
  <div>
    <div class="flex flex-wrap justify-between items-center mb-6 gap-3">
      <h1 class="text-2xl sm:text-3xl font-bold">
        📁 Projetos
      </h1>

      <button class="botao-primario text-sm" @click="abrirModal">
        + Novo projeto
      </button>
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

    <ModalProjeto
      v-if="abrindo"
      :projeto="projetoEditando"
      @fechar="fecharModal"
      @criado="projetoCriado"
      @atualizado="fecharModal"
    />
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'PaginaProjetos',

  data() {
    return {
      loja: useLojaProjetos(),
      abrindo: false,
      projetoEditando: null as any
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

    linkProjeto(id: string) {
      return `/dashboardProjeto?id=${id}`
    },

    linkKanban(id: string) {
      return `/kanban?projeto=${id}`
    },

    linkSprint(id: string) {
      return `/sprints?projeto=${id}`
    }
  }
})
</script>