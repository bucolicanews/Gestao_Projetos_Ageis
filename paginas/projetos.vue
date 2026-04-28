<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-bold">
        📁 Projetos
      </h1>

      <button class="botao-primario" @click="abrirModal">
        + Novo projeto
      </button>
    </div>

    <div v-if="loja.carregando">
      Carregando...
    </div>

    <div v-else class="grid gap-4 md:grid-cols-3">
      <NuxtLink v-for="p in loja.projetos" :key="p.id" :to="linkProjeto(p.id)"
        class="cartao hover:shadow-md transition">
        <div class="flex justify-between items-start">
          <h3 class="font-semibold text-lg">
            {{ p.nome }}
          </h3>

          <span class="text-xs px-2 py-1 rounded bg-slate-100">
            {{ p.status }}
          </span>
        </div>

        <p class="text-sm text-slate-500 mt-2 line-clamp-3">
          {{ p.descricao || 'Sem descrição.' }}
        </p>

        <div class="mt-3 flex gap-3 text-xs text-slate-500">
          <NuxtLink :to="linkProjeto(p.id)" @click.stop class="hover:text-primaria">
            📊 Dashboard
          </NuxtLink>

          <NuxtLink :to="linkKanban(p.id)" @click.stop class="hover:text-primaria">
            Kanban
          </NuxtLink>

          <NuxtLink :to="linkSprint(p.id)" @click.stop class="hover:text-primaria">
            Sprints
          </NuxtLink>
        </div>
      </NuxtLink>

      <div v-if="!loja.projetos.length" class="text-slate-500">
        Nenhum projeto ainda.
      </div>
    </div>

    <ModalProjeto v-if="abrindo" @fechar="fecharModal" @criado="projetoCriado" />
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'PaginaProjetos',

  data() {
    return {
      loja: useLojaProjetos(),
      abrindo: false
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
      this.abrindo = true
    },

    fecharModal() {
      this.abrindo = false
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