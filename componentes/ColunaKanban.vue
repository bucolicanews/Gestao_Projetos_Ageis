<template>
  <div class="cartao bg-slate-50 min-h-[400px] flex flex-col">
    <div class="flex justify-between items-center mb-3">
      <h3 class="font-semibold">
        {{ titulo }}

        <span class="text-slate-400 text-sm">
          ({{ tarefas.length }})
        </span>
      </h3>

      <button v-if="podeCriar" class="text-xs text-primaria" @click="abrirFormulario">
        + adicionar
      </button>
    </div>

    <draggable :list="lista" group="kanban" item-key="id" class="flex-1 space-y-2" @change="aoAlterar">
      <template #item="{ element }">
        <CartaoTarefa :tarefa="element" />
      </template>
    </draggable>

    <div v-if="abrindo" class="mt-3">
      <input v-model="novoTitulo" placeholder="Título da tarefa..." class="w-full px-2 py-1 border rounded text-sm" />

      <div class="flex gap-2 mt-2">
        <button class="botao-primario text-xs px-3 py-1" @click="criar">
          Criar
        </button>

        <button class="botao-secundario text-xs px-3 py-1" @click="fecharFormulario">
          Cancelar
        </button>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'
import draggable from 'vuedraggable'
import { servicoTarefas } from '~/servicos/servicoTarefas'
const servico = servicoTarefas()

export default defineComponent({
  name: 'ColunaKanban',

  components: {
    draggable
  },

  props: {
    titulo: {
      type: String,
      required: true
    },

    coluna: {
      type: String,
      required: true
    },

    tarefas: {
      type: Array,
      required: true
    },

    podeCriar: {
      type: Boolean,
      default: false
    }
  },

  emits: ['mover', 'nova'],

  data() {
    return {
      abrindo: false,
      novoTitulo: '',
      servico: servicoTarefas(), 
    }
  },

  computed: {
    lista: {
      get(): any[] {
        return this.tarefas
      },

      set(novaLista: any[]) {
        return novaLista
      }
    }
  },

  methods: {

    
    abrirFormulario() {
      this.abrindo = true
    },

    fecharFormulario() {
      this.abrindo = false
      this.novoTitulo = ''
    },

    aoAlterar(evento: any) {
      const adicionado = evento.added

      if (adicionado) {
        this.$emit('mover', {
          tarefa_id: adicionado.element.id,
          coluna: this.coluna,
          posicao: adicionado.newIndex
        })
      }

      const movido = evento.moved

      if (movido) {
        this.$emit('mover', {
          tarefa_id: movido.element.id,
          coluna: this.coluna,
          posicao: movido.newIndex
        })
      }
    },

    async criar() {
      const titulo = this.novoTitulo.trim()

      if (!titulo) return

      try {
        const tarefa = await this.servico.criarTarefa({
          titulo,
          coluna: this.coluna
        })

        this.$emit('nova', tarefa)

      } catch (erro) {
        console.error(erro)
      }

      this.novoTitulo = ''
      this.abrindo = false
    }
  }
})
</script>