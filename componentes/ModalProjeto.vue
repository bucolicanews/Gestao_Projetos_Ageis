<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4" @click.self="fechar">
    <div class="cartao w-full max-w-md">
      <h2 class="text-xl font-bold mb-4">
        Novo projeto
      </h2>

      <form class="space-y-3" @submit.prevent="salvar">
        <input v-model="nome" placeholder="Nome do projeto" required class="w-full px-3 py-2 border rounded-lg" />

        <textarea v-model="descricao" placeholder="Descrição" rows="3" class="w-full px-3 py-2 border rounded-lg" />

        <p v-if="erro" class="text-perigo text-sm">
          {{ erro }}
        </p>

        <div class="flex gap-2 justify-end">
          <button type="button" class="botao-secundario" @click="fechar">
            Cancelar
          </button>

          <button class="botao-primario" :disabled="salvando">
            {{ salvando ? 'Salvando...' : 'Criar' }}
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

  emits: ['fechar', 'criado'],

  data() {
    return {
      loja: useLojaProjetos(),

      nome: '',
      descricao: '',
      erro: '',
      salvando: false
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
        await this.loja.criar({
          nome: this.nome,
          descricao: this.descricao
        })

        this.$emit('criado')
        this.$emit('fechar')
      } catch (error: any) {
        this.erro =
          error?.message || 'Erro'
      } finally {
        this.salvando = false
      }
    }
  }
})
</script>