<template>
  <div class="cartao bg-slate-50 min-h-[400px] flex flex-col w-full min-w-[260px] flex-shrink-0 md:min-w-0 md:flex-1">
    <div class="flex justify-between items-start mb-3">
      <div>
        <h3 class="font-semibold">
          {{ titulo }}
          <span class="text-slate-400 text-sm">({{ tarefas.length }})</span>
        </h3>
        <p v-if="etapa" class="text-[10px] text-slate-400 mt-0.5">{{ etapa }}</p>
      </div>

      <button v-if="podeCriar" class="text-xs text-primaria mt-0.5" @click="abrirFormulario">
        + adicionar
      </button>
    </div>

    <draggable :list="lista" group="kanban" item-key="id" class="flex-1 space-y-2" @change="aoAlterar">
      <template #item="{ element }">
        <CartaoTarefa :tarefa="element" @clicar="$emit('clicar-tarefa', $event)" />
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
import { defineComponent, ref } from 'vue'
import draggable from 'vuedraggable'

export default defineComponent({
  name: 'ColunaKanban',

  components: {
    draggable
  },

  props: {
    titulo: { type: String, required: true },
    coluna: { type: String, required: true },
    tarefas: { type: Array, required: true },
    podeCriar: { type: Boolean, default: false },
    etapa: { type: String, default: '' }
  },

  emits: ['mover', 'nova', 'clicar-tarefa'],

  setup(props, { emit }) {
    const abrindo = ref(false)
    const novoTitulo = ref('')

    const abrirFormulario = () => {
      abrindo.value = true
    }

    const fecharFormulario = () => {
      abrindo.value = false
      novoTitulo.value = ''
    }

    const aoAlterar = (evento: any) => {
      const adicionado = evento.added
      const movido = evento.moved

      if (adicionado) {
        emit('mover', {
          tarefa_id: adicionado.element.id,
          coluna: props.coluna,
          posicao: adicionado.newIndex
        })
      }

      if (movido) {
        emit('mover', {
          tarefa_id: movido.element.id,
          coluna: props.coluna,
          posicao: movido.newIndex
        })
      }
    }

    const criar = () => {
      const titulo = novoTitulo.value.trim()
      if (!titulo) return
      emit('nova', { titulo, coluna: props.coluna })
      novoTitulo.value = ''
      abrindo.value = false
    }

    return {
      abrindo,
      novoTitulo,
      abrirFormulario,
      fecharFormulario,
      aoAlterar,
      criar
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
  }
})
</script>