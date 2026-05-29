<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div class="cartao w-full max-w-md">
      <h2 class="text-xl font-bold mb-4">
        {{ editando ? 'Editar projeto' : 'Novo projeto' }}
      </h2>

      <form class="space-y-3" @submit.prevent="salvar">
        <input v-model="nome" placeholder="Nome do projeto" required class="w-full px-3 py-2 border rounded-lg" />

        <textarea v-model="descricao" placeholder="Descrição" rows="3" class="w-full px-3 py-2 border rounded-lg" />

        <div v-if="editando" class="w-full">
          <label class="block text-sm text-slate-500 mb-1">Status</label>
          <select v-model="status" class="w-full px-3 py-2 border rounded-lg">
            <option value="ativo">Ativo</option>
            <option value="pausado">Pausado</option>
            <option value="concluido">Concluído</option>
            <option value="arquivado">Arquivado</option>
          </select>
        </div>

        <p v-if="erro" class="text-perigo text-sm">
          {{ erro }}
        </p>

        <div class="flex gap-2 justify-end">
          <button type="button" class="botao-secundario" @click="fechar">
            Cancelar
          </button>

          <button class="botao-primario" :disabled="salvando">
            {{ salvando ? 'Salvando...' : (editando ? 'Salvar' : 'Criar') }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'ModalProjeto',

  props: {
    projeto: {
      type: Object,
      default: null
    }
  },

  emits: ['fechar', 'criado', 'atualizado'],

  data() {
    return {
      loja: useLojaProjetos(),

      nome: this.projeto?.nome || '',
      descricao: this.projeto?.descricao || '',
      status: this.projeto?.status || 'ativo',
      erro: '',
      salvando: false
    }
  },

  computed: {
    editando() {
      return !!this.projeto?.id
    }
  },

  methods: {
    fechar() {
      this.$emit('fechar')
    },

    async salvar() {
      this.salvando = true
      this.erro = ''

      try {
        if (this.editando) {
          await this.loja.atualizar({
            id: this.projeto.id,
            nome: this.nome,
            descricao: this.descricao,
            status: this.status
          })
          this.$emit('atualizado')
        } else {
          await this.loja.criar({
            nome: this.nome,
            descricao: this.descricao
          })
          this.$emit('criado')
        }

        this.$emit('fechar')
      } catch (error: any) {
        this.erro = error?.message || 'Erro'
      } finally {
        this.salvando = false
      }
    }
  }
})
</script>
