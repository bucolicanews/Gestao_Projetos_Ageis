<template>
  <div class="space-y-3">
    <p class="rotulo">📝 Template do Pull Request</p>
    <p class="text-xs text-slate-400">Copie e cole na descrição do PR no GitHub.</p>

    <div class="relative">
      <pre class="bg-slate-900 text-slate-100 text-xs px-4 py-4 rounded-lg font-mono leading-relaxed whitespace-pre-wrap overflow-auto max-h-72">{{ template }}</pre>
      <button class="btn-copiar absolute top-2 right-2 text-xs" @click="copiar">
        {{ copiado ? '✅ Copiado' : '📋 Copiar' }}
      </button>
    </div>

    <div class="bg-green-50 border border-green-200 rounded-xl p-3 space-y-1">
      <p class="text-xs font-bold text-green-700">✅ Checklist antes de abrir o PR</p>
      <label v-for="item in checklist" :key="item.id" class="flex items-center gap-2 text-xs text-green-800 cursor-pointer">
        <input v-model="item.ok" type="checkbox" class="rounded" />
        <span :class="item.ok ? 'line-through opacity-50' : ''">{{ item.texto }}</span>
      </label>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, reactive } from 'vue'

const props = defineProps<{
  titulo: string
  descricao?: string
  criterio_aceite?: string
  tipo: string
  pontos?: number | null
}>()

const checklist = reactive([
  { id: 1, ok: false, texto: 'Branch criada a partir de develop' },
  { id: 2, ok: false, texto: 'Commits seguem Conventional Commits' },
  { id: 3, ok: false, texto: 'Build local passando sem erros' },
  { id: 4, ok: false, texto: 'Testes rodando e passando' },
  { id: 5, ok: false, texto: 'push feito para o servidor remoto' },
  { id: 6, ok: false, texto: 'PR aponta para develop (não main)' },
])

const template = computed(() => {
  const linhas: string[] = []

  linhas.push(`## O que foi feito`)
  linhas.push(props.descricao?.trim() || `Implementa: ${props.titulo}`)
  linhas.push('')

  if (props.criterio_aceite?.trim()) {
    linhas.push(`## Critérios de aceite`)
    linhas.push(props.criterio_aceite.trim())
    linhas.push('')
  }

  linhas.push(`## Checklist`)
  linhas.push(`- [ ] Testes passando`)
  linhas.push(`- [ ] Build sem erros`)
  linhas.push(`- [ ] Review solicitado (mín. 1 aprovação)`)
  linhas.push(`- [ ] Testado em ambiente local`)
  if (props.pontos) {
    linhas.push('')
    linhas.push(`**Story Points:** ${props.pontos}`)
  }

  return linhas.join('\n')
})

const copiado = ref(false)

async function copiar() {
  await navigator.clipboard.writeText(template.value)
  copiado.value = true
  setTimeout(() => { copiado.value = false }, 2000)
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
  padding: 4px 8px;
  border-radius: 6px;
  border: 1.5px solid hsl(214 32% 91%);
  background: hsl(222 47% 11%);
  color: #9ca3af;
  cursor: pointer;
  font-size: 11px;
  transition: all 0.15s;
  white-space: nowrap;
}

.btn-copiar:hover {
  color: #e2e8f0;
}
</style>
