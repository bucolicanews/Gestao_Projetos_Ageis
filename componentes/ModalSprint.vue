<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div class="cartao w-full max-w-md">
      <h2 class="text-xl font-bold mb-4">
        {{ editando ? 'Editar sprint' : 'Nova sprint' }}
      </h2>

      <form class="space-y-3" @submit.prevent="salvar">
        <input v-model="form.nome" placeholder="Nome (ex: Sprint 1)" required
          class="w-full px-3 py-2 border rounded-lg" />

        <textarea v-model="form.objetivo" placeholder="Objetivo da sprint" rows="3"
          class="w-full px-3 py-2 border rounded-lg" />

        <div class="grid grid-cols-2 gap-2">
          <div>
            <label class="text-xs text-slate-500">Início</label>
            <input v-model="form.data_inicio" type="date" required class="w-full px-3 py-2 border rounded-lg" />
          </div>
          <div>
            <label class="text-xs text-slate-500">Fim</label>
            <input v-model="form.data_fim" type="date" required class="w-full px-3 py-2 border rounded-lg" />
          </div>
        </div>

        <select v-model="form.status" class="w-full px-3 py-2 border rounded-lg">
          <option value="planejada">Planejada</option>
          <option value="ativa">Ativa</option>
          <option value="concluida">Concluída</option>
        </select>

        <p v-if="erro" class="text-perigo text-sm">{{ erro }}</p>

        <div class="flex gap-2 justify-end">
          <button type="button" class="botao-secundario" @click="fechar">Cancelar</button>
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
  name: 'ModalSprint',

  props: {
    sprint: {
      type: Object,
      default: null
    }
  },

  emits: ['fechar', 'criada', 'atualizada'],

  data() {
    return {
      loja: useLojaSprints(),

      form: {
        nome: this.sprint?.nome || '',
        objetivo: this.sprint?.objetivo || '',
        data_inicio: this.sprint?.data_inicio || '',
        data_fim: this.sprint?.data_fim || '',
        status: this.sprint?.status || 'planejada'
      },

      erro: '',
      salvando: false
    }
  },

  computed: {
    editando() {
      return !!this.sprint?.id
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
          await this.loja.atualizar(this.sprint.id, this.form)
          this.$emit('atualizada')
        } else {
          await this.loja.criar({ ...this.form })
          this.$emit('criada')
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
