<template>
  <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
    <div class="bg-white rounded-xl shadow-xl w-full max-w-2xl p-6">
      <h3 class="text-lg font-bold mb-5">
        Gerenciar Usuários Globais
      </h3>

      <div class="mb-6 border-b pb-4">
        <h4 class="font-semibold mb-3">
          Criar Novo Usuário
        </h4>

        <form @submit.prevent="criarUsuario" class="space-y-4">
          <div>
            <label class="block text-xs font-bold mb-1">
              Nome
            </label>

            <input v-model="novoUsuario.nome" type="text" required class="w-full border rounded-lg px-3 py-2"
              placeholder="Nome Completo" />
          </div>

          <div>
            <label class="block text-xs font-bold mb-1">
              E-mail
            </label>

            <input v-model="novoUsuario.email" type="email" required class="w-full border rounded-lg px-3 py-2"
              placeholder="email@empresa.com" />
          </div>

          <div>
            <label class="block text-xs font-bold mb-1">
              Senha
            </label>

            <input v-model="novoUsuario.senha" type="password" required class="w-full border rounded-lg px-3 py-2"
              placeholder="********" />
          </div>

          <div>
            <label class="block text-xs font-bold mb-1">
              Papel Global
            </label>

            <select v-model="novoUsuario.papel" class="w-full border rounded-lg px-3 py-2">
              <option value="">
                Selecione um papel
              </option>

              <option v-for="role in rolesData" :key="role.codigo" :value="role.codigo">
                {{ role.nome }}
              </option>
            </select>
          </div>

          <button type="submit" :disabled="carregandoCriacao"
            class="bg-green-600 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-green-700 transition disabled:opacity-50">
            {{ carregandoCriacao ? 'Criando...' : 'Criar Usuário' }}
          </button>
        </form>

        <p v-if="erroCriacao" class="text-red-500 text-sm mt-2">
          {{ erroCriacao }}
        </p>
      </div>

      <div class="mb-6">
        <h4 class="font-semibold mb-3">
          Editar Papel de Usuários Existentes
        </h4>

        <ul class="divide-y divide-slate-200 max-h-60 overflow-y-auto border rounded-lg">
          <li v-for="user in usuariosGlobais" :key="user.id"
            class="p-3 flex items-center justify-between hover:bg-slate-50">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-xs font-bold">
                {{ inicialUsuario(user.nome) }}
              </div>

              <div>
                <p class="text-sm font-semibold">
                  {{ user.nome }}
                </p>

                <p class="text-xs text-slate-500">
                  {{ user.email }}
                </p>
              </div>
            </div>

            <div class="flex items-center gap-2">
              <select v-model="user.perfil" @change="atualizarPapelGlobal(user)"
                class="border rounded-lg px-2 py-1 text-sm">
                <option v-for="role in rolesData" :key="role.codigo" :value="role.codigo">
                  {{ role.nome }}
                </option>
              </select>

              <button @click="editarUsuario(user)" title="Editar"
                class="text-blue-600 hover:text-blue-800 p-1">
                ✏️
              </button>

              <button @click="adicionarAoProjeto(user)" title="Adicionar ao Projeto"
                class="text-green-600 hover:text-green-800 p-1">
                ➕
              </button>

              <button @click="confirmarExclusao(user)" title="Excluir"
                class="text-red-600 hover:text-red-800 p-1">
                🗑️
              </button>

              <span v-if="carregandoEdicao[user.id]" class="text-xs text-slate-500">
                Salvando...
              </span>
            </div>
          </li>

          <li v-if="!usuariosGlobais.length" class="p-3 text-sm text-slate-500 text-center">
            Nenhum usuário global encontrado.
          </li>
        </ul>

        <p v-if="erroEdicao" class="text-red-500 text-sm mt-2">
          {{ erroEdicao }}
        </p>
      </div>

      <div class="mt-6 flex justify-end gap-3">
        <button @click="fecharModal" class="text-slate-600">
          Fechar
        </button>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'GerenciarUsuariosGlobaisModal',

  props: {
    usuariosGlobais: {
      type: Array,
      default: () => []
    },

    rolesData: {
      type: Array,
      default: () => []
    }
  },

  emits: ['fechar', 'atualizar'],

  data() {
    return {
      cliente: useSupabaseClient(),

      novoUsuario: {
        nome: '',
        email: '',
        senha: '',
        papel: ''
      },

      carregandoCriacao: false,
      erroCriacao: '',

      carregandoEdicao: {} as Record<string, boolean>,
      erroEdicao: ''
    }
  },

  methods: {
    fecharModal() {
      this.$emit('fechar')
    },

    async criarUsuario() {
      this.carregandoCriacao = true
      this.erroCriacao = ''

      try {
        const { data, error: authError } =
          await this.cliente.auth.admin.createUser({
            email: this.novoUsuario.email,
            password: this.novoUsuario.senha,
            email_confirm: true,
            user_metadata: {
              nome: this.novoUsuario.nome,
              perfil: this.novoUsuario.papel
            }
          })

        if (authError) {
          throw authError
        }

        const { error: profileError } =
          await this.cliente
            .from('usuarios')
            .insert({
              id: data.user?.id,
              nome: this.novoUsuario.nome,
              email: this.novoUsuario.email,
              perfil: this.novoUsuario.papel
            })

        if (profileError) {
          throw profileError
        }

        alert('Usuário criado com sucesso!')

        this.limparFormulario()

        this.$emit('atualizar')
      } catch (error: any) {
        this.erroCriacao = error.message
      } finally {
        this.carregandoCriacao = false
      }
    },

    async atualizarPapelGlobal(user: any) {
      this.carregandoEdicao = {
        ...this.carregandoEdicao,
        [user.id]: true
      }

      this.erroEdicao = ''

      try {
        const { error } = await this.cliente
          .from('usuarios')
          .update({
            perfil: user.perfil
          })
          .eq('id', user.id)

        if (error) {
          throw error
        }

        alert(
          `Papel de ${user.nome} atualizado para ${this.formatarPapel(user.perfil)}.`
        )

        this.$emit('atualizar')
      } catch (error: any) {
        this.erroEdicao = error.message
      } finally {
        this.carregandoEdicao = {
          ...this.carregandoEdicao,
          [user.id]: false
        }
      }
    },

    limparFormulario() {
      this.novoUsuario = {
        nome: '',
        email: '',
        senha: '',
        papel: ''
      }
    },

    formatarPapel(codigo: string) {
      const role = this.rolesData.find(
        (item: any) => item.codigo === codigo
      )

      return role ? role.nome : 'Sem Perfil'
    },

    editarUsuario(user: any) {
      const novoNome = prompt('Editar nome:', user.nome)
      if (novoNome && novoNome !== user.nome) {
        this.salvarEdicao(user.id, { nome: novoNome })
      }
    },

    async salvarEdicao(userId: string, dados: any) {
      try {
        const { error } = await this.cliente
          .from('usuarios')
          .update(dados)
          .eq('id', userId)

        if (error) throw error

        alert('Usuário atualizado!')
        this.$emit('atualizar')
      } catch (error: any) {
        alert('Erro: ' + error.message)
      }
    },

    adicionarAoProjeto(user: any) {
      const projetoId = prompt('Digite o ID do projeto para adicionar este usuário:')
      if (projetoId) {
        this.salvarMembroProjeto(user.id, projetoId)
      }
    },

    async salvarMembroProjeto(usuarioId: string, projetoId: string) {
      try {
        const { error } = await this.cliente
          .from('membros_projeto')
          .insert({
            projeto_id: projetoId,
            usuario_id: usuarioId,
            papel: 'desenvolvedor'
          })

        if (error) throw error

        alert('Usuário adicionado ao projeto!')
        this.$emit('atualizar')
      } catch (error: any) {
        alert('Erro: ' + error.message)
      }
    },

    confirmarExclusao(user: any) {
      if (confirm(`Tem certeza que deseja excluir o usuário "${user.nome}"?`)) {
        this.excluirUsuario(user)
      }
    },

    async excluirUsuario(user: any) {
      try {
        const { error } = await this.cliente
          .from('usuarios')
          .delete()
          .eq('id', user.id)

        if (error) throw error

        alert('Usuário excluído!')
        this.$emit('atualizar')
      } catch (error: any) {
        alert('Erro: ' + error.message)
      }
    },

    inicialUsuario(nome: string) {
      return (nome || '?')
        .charAt(0)
        .toUpperCase()
    }
  }
})
</script>