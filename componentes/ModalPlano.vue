<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
      <div class="flex items-center justify-between p-6 border-b border-slate-100">
        <h2 class="text-lg font-bold">{{ plano ? 'Editar Plano' : 'Novo Plano' }}</h2>
        <button @click="$emit('fechar')" class="text-slate-400 hover:text-slate-600 text-xl leading-none">&times;</button>
      </div>

      <form @submit.prevent="salvar" class="p-6 flex flex-col gap-4">
        <!-- Título -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Título *</label>
          <input
            v-model="form.titulo"
            required
            placeholder="Ex: Pro"
            class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria"
          />
        </div>

        <!-- Descrição -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Descrição</label>
          <textarea
            v-model="form.descricao"
            rows="2"
            placeholder="Para times em crescimento..."
            class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria resize-none"
          />
        </div>

        <!-- Preço -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Preço (R$) *</label>
          <input
            v-model.number="form.preco"
            type="number"
            min="0"
            step="0.01"
            required
            placeholder="99.90"
            class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria"
          />
        </div>

        <!-- Imagem URL -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">URL da Imagem</label>
          <input
            v-model="form.imagem_url"
            type="url"
            placeholder="https://..."
            class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria"
          />
          <img
            v-if="form.imagem_url"
            :src="form.imagem_url"
            class="mt-2 h-20 w-full object-cover rounded-lg border border-slate-200"
            @error="form.imagem_url = ''"
          />
        </div>

        <!-- Recursos -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Recursos incluídos</label>
          <div v-for="(_, idx) in form.recursos" :key="idx" class="flex gap-2 mb-2">
            <input
              v-model="form.recursos[idx]"
              placeholder="Ex: Projetos ilimitados"
              class="flex-1 border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria"
            />
            <button
              type="button"
              @click="removerRecurso(idx)"
              class="text-perigo hover:opacity-70 px-2 text-lg leading-none"
            >&times;</button>
          </div>
          <button
            type="button"
            @click="adicionarRecurso"
            class="text-sm text-primaria hover:underline mt-1"
          >+ Adicionar recurso</button>
        </div>

        <!-- Ativo -->
        <div class="flex items-center gap-3">
          <input
            id="ativo"
            v-model="form.ativo"
            type="checkbox"
            class="w-4 h-4 accent-primaria"
          />
          <label for="ativo" class="text-sm font-medium text-slate-700">Plano ativo (visível para usuários)</label>
        </div>

        <!-- Erro -->
        <p v-if="erro" class="text-sm text-perigo">{{ erro }}</p>

        <!-- Ações -->
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" @click="$emit('fechar')" class="botao-secundario">Cancelar</button>
          <button type="submit" :disabled="salvando" class="botao-primario">
            {{ salvando ? 'Salvando...' : (plano ? 'Salvar alterações' : 'Criar plano') }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Plano, PlanoInput } from '~/servicos/servicoPlanos'

const props = defineProps<{
  plano?: Plano | null
}>()

const emit = defineEmits<{
  fechar: []
  salvo: [plano: Plano]
}>()

const loja = useLojaPlanos()
const salvando = ref(false)
const erro = ref('')

const form = reactive<PlanoInput>({
  titulo: props.plano?.titulo ?? '',
  descricao: props.plano?.descricao ?? '',
  imagem_url: props.plano?.imagem_url ?? '',
  preco: props.plano?.preco ?? 0,
  recursos: props.plano?.recursos ? [...props.plano.recursos] : [],
  ativo: props.plano?.ativo ?? true,
})

function adicionarRecurso() {
  form.recursos.push('')
}

function removerRecurso(idx: number) {
  form.recursos.splice(idx, 1)
}

async function salvar() {
  erro.value = ''
  salvando.value = true
  try {
    const payload: PlanoInput = {
      ...form,
      recursos: form.recursos.filter(r => r.trim() !== ''),
      imagem_url: form.imagem_url || null,
      descricao: form.descricao || null,
    }

    let resultado: Plano
    if (props.plano) {
      resultado = await loja.atualizar(props.plano.id, payload)
    } else {
      resultado = await loja.criar(payload)
    }
    emit('salvo', resultado)
    emit('fechar')
  } catch (e: any) {
    erro.value = e.message ?? 'Erro ao salvar plano.'
  } finally {
    salvando.value = false
  }
}
</script>
