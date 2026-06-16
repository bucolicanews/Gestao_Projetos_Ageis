<template>
  <div class="p-6 space-y-5">

    <!-- sem título ainda -->
    <div v-if="!titulo.trim()" class="text-center py-10 text-slate-400 text-sm">
      Preencha o título da tarefa para gerar o guia Git.
    </div>

    <template v-else>

      <!-- Branch -->
      <div>
        <p class="rotulo">🌿 Nome da branch</p>
        <div class="flex items-center gap-2 mt-1">
          <code class="flex-1 bg-slate-900 text-green-400 text-sm px-4 py-3 rounded-lg font-mono break-all">{{ branch }}</code>
          <button class="btn-copiar" @click="copiar(branch, 'branch')">{{ copiado === 'branch' ? '✅' : '📋' }}</button>
        </div>
      </div>

      <!-- Comandos Git -->
      <div>
        <p class="rotulo">⚡ Comandos para criar a branch</p>
        <div class="relative mt-1">
          <pre class="bg-slate-900 text-green-400 text-sm px-4 py-3 rounded-lg font-mono leading-relaxed whitespace-pre-wrap">{{ comandos }}</pre>
          <button class="btn-copiar absolute top-2 right-2" @click="copiar(comandos, 'cmds')">{{ copiado === 'cmds' ? '✅' : '📋' }}</button>
        </div>
      </div>

      <!-- Commit sugerido -->
      <div>
        <p class="rotulo">💬 Commit inicial sugerido</p>
        <div class="flex items-center gap-2 mt-1">
          <code class="flex-1 bg-slate-100 text-slate-800 text-sm px-4 py-3 rounded-lg font-mono">{{ commit }}</code>
          <button class="btn-copiar" @click="copiar(commit, 'commit')">{{ copiado === 'commit' ? '✅' : '📋' }}</button>
        </div>
        <p class="text-xs text-slate-400 mt-1">Faça commits pequenos e frequentes — não um único "projeto pronto".</p>
      </div>

      <!-- Push -->
      <div>
        <p class="rotulo">🚀 Após desenvolver — enviar ao servidor</p>
        <div class="flex items-center gap-2 mt-1">
          <code class="flex-1 bg-slate-100 text-slate-700 text-sm px-4 py-3 rounded-lg font-mono">{{ push }}</code>
          <button class="btn-copiar" @click="copiar(push, 'push')">{{ copiado === 'push' ? '✅' : '📋' }}</button>
        </div>
      </div>

      <!-- Fluxo visual -->
      <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
        <p class="text-xs font-bold text-blue-700 uppercase tracking-wide mb-3">Fluxo obrigatório</p>
        <div class="flex flex-wrap items-center gap-1.5 text-xs font-mono">
          <span class="bg-blue-100 text-blue-800 px-2 py-0.5 rounded">develop</span>
          <span class="text-slate-400">→</span>
          <span class="bg-green-100 text-green-800 px-2 py-0.5 rounded">{{ branch }}</span>
          <span class="text-slate-400">→</span>
          <span class="bg-yellow-100 text-yellow-800 px-2 py-0.5 rounded">commits</span>
          <span class="text-slate-400">→</span>
          <span class="bg-orange-100 text-orange-800 px-2 py-0.5 rounded">push</span>
          <span class="text-slate-400">→</span>
          <span class="bg-purple-100 text-purple-800 px-2 py-0.5 rounded">PR → develop</span>
          <span class="text-slate-400">→</span>
          <span class="bg-red-100 text-red-800 px-2 py-0.5 rounded">CI ✅ + Review ✅</span>
          <span class="text-slate-400">→</span>
          <span class="bg-slate-800 text-white px-2 py-0.5 rounded">merge</span>
        </div>
      </div>

      <!-- Regras -->
      <div class="border-l-4 border-amber-400 bg-amber-50 px-4 py-3 rounded-r-lg space-y-0.5">
        <p class="text-xs font-bold text-amber-800">⚠️ Regras de ouro</p>
        <p class="text-xs text-amber-700">• Nunca commite direto em <code class="bg-amber-100 px-1 rounded">main</code> ou <code class="bg-amber-100 px-1 rounded">develop</code></p>
        <p class="text-xs text-amber-700">• Sempre crie a branch a partir de <code class="bg-amber-100 px-1 rounded">develop</code>, nunca de <code class="bg-amber-100 px-1 rounded">main</code></p>
        <p class="text-xs text-amber-700">• PR sempre aponta para <code class="bg-amber-100 px-1 rounded">develop</code> — nunca direto para <code class="bg-amber-100 px-1 rounded">main</code></p>
      </div>

    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'

const props = defineProps<{
  tipo: string
  titulo: string
}>()

const { gerarBranch, gerarCommit, gerarComandos, gerarPush } = useBranchGenerator()

const branch   = computed(() => gerarBranch(props.tipo, props.titulo))
const commit   = computed(() => gerarCommit(props.tipo, props.titulo))
const comandos = computed(() => gerarComandos(branch.value))
const push     = computed(() => gerarPush(branch.value))

const copiado = ref('')

async function copiar(texto: string, chave: string) {
  await navigator.clipboard.writeText(texto)
  copiado.value = chave
  setTimeout(() => { copiado.value = '' }, 2000)
}
</script>

<style scoped>
.rotulo {
  display: block;
  font-size: 11px;
  font-weight: 700;
  color: hsl(215 16% 47%);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.btn-copiar {
  flex-shrink: 0;
  padding: 6px 10px;
  border-radius: 8px;
  border: 1.5px solid hsl(214 32% 91%);
  background: white;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.15s;
}

.btn-copiar:hover {
  border-color: hsl(221 83% 53%);
}
</style>
