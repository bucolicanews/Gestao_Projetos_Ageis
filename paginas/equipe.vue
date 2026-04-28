<template>
  <div class="p-6 max-w-5xl mx-auto">
    <header class="mb-8">
      <div class="flex justify-between items-end">
        <div>
          <h1 class="text-2xl font-bold text-slate-800">
            Gerenciamento de Equipe
          </h1>

          <p class="text-slate-500">
            Visualize quem tem acesso aos projetos e envie novos convites.
          </p>
        </div>

        <button v-if="projetoAtivo" @click="selecionarOutroProjeto"
          class="text-sm text-blue-600 hover:text-blue-800 font-semibold bg-blue-50 px-3 py-1 rounded-full transition-colors">
          Escolher outro projeto
        </button>
      </div>
    </header>

    <div v-if="projetoAtivo" class="space-y-6">
      <GerenciarEquipe :membros="membros" :todos-usuarios="listaGlobalUsuarios" :sou-admin="souControleGeral"
        :projeto-id="projetoAtivo.id" :dono-id="projetoAtivo.proprietario_id" @atualizar="carregarMembros" />
    </div>

    <div v-else-if="carregando" class="animate-pulse space-y-4">
      <div class="h-40 bg-slate-100 rounded-xl"></div>
    </div>

    <div v-else>
      <h2 class="text-sm font-bold text-slate-400 uppercase tracking-wider mb-4">
        Selecione um projeto para continuar:
      </h2>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div v-for="p in lojaProjetos.projetos" :key="p.id" @click="selecionarProjeto(p)"
          class="p-5 border-2 border-transparent bg-white rounded-xl shadow-sm hover:border-blue-500 hover:shadow-md cursor-pointer transition-all group">
          <h3 class="font-bold text-slate-700 group-hover:text-blue-600">
            {{ p.nome }}
          </h3>

          <p class="text-xs text-slate-400 mt-1 line-clamp-2">
            {{ p.descricao || 'Sem descrição cadastrada.' }}
          </p>
        </div>
      </div>

      <div v-if="lojaProjetos.projetos.length === 0"
        class="text-center py-12 bg-slate-50 rounded-xl border-2 border-dashed">
        <p class="text-slate-500">
          Você ainda não tem projetos criados.
        </p>
      </div>
    </div>
  </div>
  
</template>

<script lang="ts">
import { defineComponent } from 'vue'


const EMAIL_DEV_MASTER = 'jmokatavares@gmail.com'

export default defineComponent({
  name: 'PaginaGerenciamentoEquipe',

  data() {
    return {
      listarMembros: servicoEquipe(),
      lojaProjetos: useLojaProjetos(),
      membros: [],
      listaGlobalUsuarios: [],
      carregando: false,
      user: useSupabaseUser(),
      cliente: useSupabaseClient(),
      perfilUsuarioLogado: null as number | null
    }
  },

  computed: {
    projetoAtivo() {
      return this.lojaProjetos.projetoSelecionado
    },

    souControleGeral() {
      return (
        this.perfilUsuarioLogado === 1 ||
        this.user?.email === EMAIL_DEV_MASTER
      )
    }
  },

  watch: {
    projetoAtivo: {
      immediate: true,
      handler() {
        this.carregarMembros()
      }
    }
  },

  async mounted() {
    await this.inicializarPagina()
  },

  methods: {
    async inicializarPagina() {
      if (this.lojaProjetos.projetos.length === 0) {
        await this.lojaProjetos.carregar()
      }

      await this.buscarPerfilUsuario()
      await this.carregarUsuariosGlobais()
    },

    async buscarPerfilUsuario() {
      if (!this.user) return

      const { data } = await this.cliente
        .from('usuarios')
        .select('perfil')
        .eq('id', this.user.id)
        .single()

      if (data) {
        this.perfilUsuarioLogado = data.perfil
      }
    },

    async carregarUsuariosGlobais() {
      if (!this.souControleGeral) return

      const { data } = await this.cliente
        .from('usuarios')
        .select('id, nome, email, avatar_url, perfil')
        .order('nome')

      if (data) {
        this.listaGlobalUsuarios = data
      }
    },

    async carregarMembros() {
      if (!this.projetoAtivo) return

      this.carregando = true

      const { data, error } = await this.cliente
        .from('membros_projeto')
        .select(`
          id,
          usuario_id,
          papel,
          usuarios (
            id,
            nome,
            email,
            avatar_url,
            perfil
          )
        `)
        .eq('projeto_id', this.projetoAtivo.id)

      if (!error) {
        this.membros = data
      }

      this.carregando = false
    },

    selecionarProjeto(projeto: any) {
      this.lojaProjetos.projetoSelecionado = projeto
    },

    selecionarOutroProjeto() {
      this.lojaProjetos.projetoSelecionado = null
    }
  }
})
</script>