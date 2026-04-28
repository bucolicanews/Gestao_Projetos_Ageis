<template>
  <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
    <div class="p-6 border-b bg-slate-50/50 flex justify-between items-center">
      <div>
        <h2 class="text-lg font-bold text-slate-800 flex items-center gap-2">
          👥 Equipe do Projeto
        </h2>

        <p class="text-xs text-slate-500">
          Membros ativos com acesso ao quadro Kanban
        </p>
      </div>

      <button v-if="podeConvidar" @click="abrirModal"
        class="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-blue-700 transition">
        + Convidar
      </button>
    </div>

    <h1>Lista de membros</h1>

    <ListaUsuarios :membros="membros" :sou-admin="souAdmin" :projeto-id="projetoId" :dono-id="donoId"
      @atualizar="carregarMembros" @remover="removerMembro" />

    <div v-if="souAdmin" class="mt-8 border-t">
      <div class="p-6 bg-slate-900 text-white">
        <div class="flex justify-between items-center">
          <div>
            <h3 class="font-bold">
              🌐 Diretório Global
            </h3>

            <p class="text-xs text-slate-400">
              Todos os usuários cadastrados no sistema
            </p>
          </div>

          <button @click="abrirModalGerenciarUsuariosGlobais"
            class="bg-blue-500 text-white px-3 py-1 rounded-lg text-sm font-semibold hover:bg-blue-600 transition">
            + Gerenciar Usuários
          </button>
        </div>
      </div>

      <div v-if="todosUsuarios.length" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-px bg-slate-200">
        <div v-for="user in todosUsuarios" :key="user.id" class="bg-white p-4 flex items-center gap-3">
          <div class="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-xs font-bold">
            {{ inicialUsuario(user.nome) }}
          </div>

          <div class="flex-1 overflow-hidden">
            <div class="flex justify-between gap-2">
              <p class="text-xs font-bold truncate">
                {{ user.nome }}
              </p>

              <span :class="[
                'text-[10px] px-2 py-1 rounded border uppercase font-bold',
                obterEstiloPerfil(user.perfil)
              ]">
                {{ formatarPerfilGlobal(user.perfil) }}
              </span>
            </div>

            <p class="text-[11px] text-slate-500 truncate">
              {{ user.email }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <Teleport to="body">
      <div v-if="exibirModal" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
        <div class="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
          <h3 class="text-lg font-bold mb-5">
            Convidar Colaborador
          </h3>

          <div class="space-y-4">
            <div>
              <label class="text-xs font-bold block mb-1">
                E-mail
              </label>

              <input v-model="novoEmail" type="email" class="w-full border rounded-lg px-3 py-2"
                placeholder="email@empresa.com" />
            </div>

            <div>
              <label class="text-xs font-bold block mb-1">
                Papel no Projeto
              </label>

              <select v-model="novoPapel" class="w-full border rounded-lg px-3 py-2">
                <option value="">
                  Selecione um papel
                </option>

                <option v-for="role in ROLES_DATA" :key="role.codigo" :value="role.codigo">
                  {{ role.nome }}
                </option>
              </select>
            </div>

            <div v-if="linkGerado" class="p-3 bg-green-50 border rounded-lg">
              <p class="text-xs font-bold mb-2">
                Link gerado:
              </p>

              <div class="flex gap-2">
                <input :value="linkGerado" readonly class="flex-1 border rounded px-2 py-1 text-xs" />

                <button @click="copiarLink" class="bg-green-600 text-white px-3 rounded">
                  Copiar
                </button>
              </div>
            </div>
          </div>

          <div class="mt-6 flex justify-end gap-3">
            <button @click="fecharModal" class="text-slate-600">
              Fechar
            </button>

            <button @click="gerarConvite" :disabled="!novoEmail || carregando"
              class="bg-blue-600 text-white px-4 py-2 rounded-lg disabled:opacity-50">
              {{ carregando ? 'Gerando...' : 'Gerar Convite' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <Teleport to="body">
      <GerenciarUsuariosGlobaisModal v-if="exibirModalGerenciarUsuariosGlobais" :usuarios-globais="todosUsuarios"
        :roles-data="ROLES_DATA" @fechar="fecharModalGerenciarUsuariosGlobais" @atualizar="emitirAtualizacao" />
    </Teleport>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'
import ListaUsuarios from './ListaUsuarios.vue'

const ROLES_DATA = [
  { id: 1, codigo: 'desenvolvedor', nome: 'Desenvolvedor Master' },
  { id: 2, codigo: 'admin', nome: 'Administrador' },
  { id: 3, codigo: 'engenheiro_software', nome: 'Engenheiro de Software' },
  { id: 4, codigo: 'gerente_projeto', nome: 'Gerente de Projeto' },
  { id: 5, codigo: 'lider_equipe', nome: 'Líder de Equipe' },
  { id: 6, codigo: 'analista_qualidade', nome: 'Qualidade / QA' },
  { id: 7, codigo: 'designer', nome: 'Designer UX/UI' },
  
]

export default defineComponent({
  name: 'GerenciarEquipe',

  components: {
    ListaUsuarios
  },

  props: {
    membros: {
      type: Array,
      default: () => []
    },
    todosUsuarios: {
      type: Array,
      default: () => []
    },
    souAdmin: {
      type: Boolean,
      default: false
    },
    projetoId: {
      type: String,
      default: ''
    },
    donoId: {
      type: String,
      default: ''
    }
  },

  emits: ['atualizar'],

  data() {
    return {
      cliente: useSupabaseClient(),
      usuario: useSupabaseUser(),
      ROLES_DATA,

      exibirModal: false,
      exibirModalGerenciarUsuariosGlobais: false,

      novoEmail: '',
      novoPapel: '',
      linkGerado: '',
      carregando: false
    }
  },

  computed: {
    podeConvidar(): boolean {
      if (this.souAdmin) {
        return true
      }

      const eu = this.membros.find(
        (m: any) => m.usuario_id === this.usuario?.id
      )

      return ['ADMIN', 'ENGN', 'DESENVOLVEDOR'].includes(
        eu?.papel
      )
    }
  },

  methods: {
    abrirModal() {
      this.exibirModal = true
    },

    fecharModal() {
      this.exibirModal = false
      this.linkGerado = ''
      this.novoEmail = ''
      this.novoPapel = ''
    },

    abrirModalGerenciarUsuariosGlobais() {
      this.exibirModalGerenciarUsuariosGlobais = true
    },

    fecharModalGerenciarUsuariosGlobais() {
      this.exibirModalGerenciarUsuariosGlobais = false
    },

    emitirAtualizacao() {
      this.$emit('atualizar')
    },

    carregarMembros() {
      this.$emit('atualizar')
    },

    async gerarConvite() {
      this.carregando = true

      const { data, error } = await this.cliente
        .from('convites_projeto')
        .insert({
          projeto_id: this.projetoId,
          email: this.novoEmail,
          papel: this.novoPapel
        })
        .select()
        .single()

      this.carregando = false

      if (error) {
        alert(error.message)
        return
      }

      const base = window.location.origin

      this.linkGerado =
        `${base}/cadastro?invite=${data.token}&email=${this.novoEmail}`

      this.$emit('atualizar')
    },

    copiarLink() {
      navigator.clipboard.writeText(this.linkGerado)
    },

    removerMembro(id: string) {
      console.log('Remover:', id)
    },

    formatarPerfilGlobal(perfilId: number | string) {
      const role = this.ROLES_DATA.find(
        item => item.id === Number(perfilId)
      )

      return role ? role.nome : 'Usuário'
    },

    obterEstiloPerfil(perfilId: number | string) {
      if (Number(perfilId) === 1) {
        return 'bg-purple-50 text-purple-700 border-purple-100'
      }

      if (Number(perfilId) === 2) {
        return 'bg-blue-50 text-blue-700 border-blue-100'
      }

      return 'bg-slate-50 text-slate-600 border-slate-200'
    },

    inicialUsuario(nome: string) {
      return (nome || '?')
        .charAt(0)
        .toUpperCase()
    }
  }
})
</script>