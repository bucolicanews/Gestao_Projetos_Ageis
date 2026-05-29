<template>
  <div
    class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
    @click.self="$emit('fechar')"
  >
    <div class="bg-white rounded-xl shadow-xl w-full max-w-lg flex flex-col max-h-[90vh]">

      <!-- Cabeçalho -->
      <div class="flex justify-between items-center p-5 border-b">
        <h2 class="text-lg font-bold">↑ Importar projeto</h2>
        <button class="text-slate-400 hover:text-slate-700 text-xl leading-none" @click="$emit('fechar')">✕</button>
      </div>

      <!-- Abas -->
      <div class="flex border-b">
        <button
          class="flex-1 py-2.5 text-sm font-medium transition-colors"
          :class="aba === 'colar'
            ? 'border-b-2 border-primaria text-primaria -mb-px'
            : 'text-slate-500 hover:text-slate-700'"
          @click="aba = 'colar'"
        >
          📋 Colar JSON
        </button>
        <button
          class="flex-1 py-2.5 text-sm font-medium transition-colors"
          :class="aba === 'arquivo'
            ? 'border-b-2 border-primaria text-primaria -mb-px'
            : 'text-slate-500 hover:text-slate-700'"
          @click="aba = 'arquivo'"
        >
          📁 Importar arquivo
        </button>
      </div>

      <!-- Corpo -->
      <div class="p-5 flex-1 overflow-y-auto space-y-4">

        <!-- Aba: Colar JSON -->
        <template v-if="aba === 'colar'">
          <p class="text-sm text-slate-500">
            Cole o JSON gerado pela IA ou exportado de outro projeto.
          </p>
          <textarea
            v-model="jsonColado"
            rows="12"
            placeholder='{ "_meta": { "versao": "1.0", ... } }'
            class="w-full text-xs font-mono border rounded-lg p-3 resize-none focus:outline-none focus:ring-2 focus:ring-primaria placeholder:text-slate-300"
            :class="erroValidacao ? 'border-red-400' : ''"
            @input="erroValidacao = ''"
          />
          <p v-if="erroValidacao" class="text-xs text-red-500">{{ erroValidacao }}</p>
        </template>

        <!-- Aba: Arquivo -->
        <template v-else>
          <p class="text-sm text-slate-500">
            Selecione um arquivo <code class="bg-slate-100 px-1 rounded">.json</code> exportado pelo sistema.
          </p>

          <div
            class="border-2 border-dashed rounded-xl p-8 text-center cursor-pointer hover:border-primaria hover:bg-slate-50 transition-colors"
            :class="arquivoSelecionado ? 'border-primaria bg-primaria/5' : 'border-slate-200'"
            @click="selecionarArquivo"
          >
            <div v-if="arquivoSelecionado" class="space-y-1">
              <p class="text-2xl">✅</p>
              <p class="text-sm font-medium text-slate-700">{{ arquivoSelecionado.name }}</p>
              <p class="text-xs text-slate-400">{{ formatarTamanho(arquivoSelecionado.size) }}</p>
            </div>
            <div v-else class="space-y-2">
              <p class="text-3xl text-slate-300">📁</p>
              <p class="text-sm text-slate-500">Clique para selecionar o arquivo JSON</p>
            </div>
          </div>

          <input ref="inputArquivo" type="file" accept=".json" class="hidden" @change="onArquivoSelecionado" />
        </template>

      </div>

      <!-- Rodapé -->
      <div class="p-4 border-t flex justify-end gap-2">
        <button class="botao-secundario text-sm" @click="$emit('fechar')">Cancelar</button>
        <button
          class="botao-primario text-sm min-w-[100px]"
          :disabled="!podеImportar || importando"
          @click="importar"
        >
          {{ importando ? 'Importando...' : '↑ Importar' }}
        </button>
      </div>

    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed } from 'vue'

export default defineComponent({
  name: 'ModalImportarProjeto',

  emits: ['fechar', 'importado'],

  setup(_, { emit }) {
    const { importando, importarProjeto } = useImportProjeto()

    const aba              = ref<'colar' | 'arquivo'>('colar')
    const jsonColado       = ref('')
    const arquivoSelecionado = ref<File | null>(null)
    const jsonDoArquivo    = ref('')
    const erroValidacao    = ref('')
    const inputArquivo     = ref<HTMLInputElement | null>(null)

    const podеImportar = computed(() => {
      if (aba.value === 'colar')   return jsonColado.value.trim().length > 0
      if (aba.value === 'arquivo') return !!arquivoSelecionado.value
      return false
    })

    function selecionarArquivo() {
      inputArquivo.value?.click()
    }

    function onArquivoSelecionado(e: Event) {
      const file = (e.target as HTMLInputElement).files?.[0]
      if (!file) return
      arquivoSelecionado.value = file
      const reader = new FileReader()
      reader.onload = (ev) => { jsonDoArquivo.value = ev.target?.result as string }
      reader.readAsText(file)
    }

    async function importar() {
      erroValidacao.value = ''
      const json = aba.value === 'colar' ? jsonColado.value.trim() : jsonDoArquivo.value

      // Validação rápida de JSON antes de enviar
      try { JSON.parse(json) }
      catch { erroValidacao.value = 'JSON inválido — verifique a formatação.'; return }

      const relatorio = await importarProjeto(json)
      emit('importado', relatorio)
    }

    function formatarTamanho(bytes: number): string {
      if (bytes < 1024) return `${bytes} B`
      if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
      return `${(bytes / 1024 / 1024).toFixed(1)} MB`
    }

    return {
      aba, jsonColado, arquivoSelecionado, erroValidacao,
      inputArquivo, podеImportar, importando,
      selecionarArquivo, onArquivoSelecionado, importar, formatarTamanho,
    }
  },
})
</script>
