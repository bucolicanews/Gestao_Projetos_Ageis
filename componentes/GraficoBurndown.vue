<template>
  <div class="cartao">
    <div class="flex justify-between items-center mb-3">
      <h3 class="font-semibold">
        📉 Burndown
      </h3>

      <button class="text-xs text-primaria" @click="emitirAtualizacao">
        Registrar snapshot de hoje
      </button>
    </div>

    <div v-if="!pontos.length" class="text-sm text-slate-500 py-8 text-center">
      Sem dados ainda. Clique em "Registrar snapshot de hoje"
      para começar.
    </div>

    <svg v-else viewBox="0 0 600 260" class="w-full h-64">
      <line x1="40" y1="220" x2="580" y2="220" stroke="#cbd5e1" />

      <line x1="40" y1="20" x2="40" y2="220" stroke="#cbd5e1" />

      <g v-for="i in 4" :key="i">
        <line :x1="40" :y1="20 + i * 40" :x2="580" :y2="20 + i * 40" stroke="#f1f5f9" />
      </g>

      <line :x1="px(0)" :y1="py(maxTotal)" :x2="px(pontos.length - 1)" :y2="py(0)" stroke="#94a3b8"
        stroke-dasharray="4 4" />

      <polyline :points="linhaReal" fill="none" stroke="hsl(238 84% 60%)" stroke-width="2.5" />

      <g v-for="(p, i) in pontos" :key="p.data">
        <circle :cx="px(i)" :cy="py(p.restantes)" r="3.5" fill="hsl(238 84% 60%)" />

        <text :x="px(i)" y="240" font-size="9" text-anchor="middle" fill="#64748b">
          {{ formatar(p.data) }}
        </text>
      </g>

      <text x="50" y="15" font-size="10" fill="#64748b">
        Tarefas restantes
      </text>
    </svg>

    <div class="flex gap-4 text-xs text-slate-500 mt-2">
      <span>━━ Real</span>
      <span>┄┄ Ideal</span>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'GraficoBurndown',

  props: {
    snapshots: {
      type: Array,
      default: () => []
    }
  },

  emits: ['atualizar'],

  computed: {
    pontos(): any[] {
      return this.snapshots || []
    },

    maxTotal(): number {
      return Math.max(
        1,
        ...this.pontos.map(
          (item: any) => item.total_tarefas
        )
      )
    },

    linhaReal(): string {
      return this.pontos
        .map((p: any, i: number) => {
          return `${this.px(i)},${this.py(p.restantes)}`
        })
        .join(' ')
    }
  },

  methods: {
    emitirAtualizacao() {
      this.$emit('atualizar')
    },

    px(indice: number): number {
      if (this.pontos.length <= 1) {
        return 40
      }

      return (
        40 +
        indice *
        (540 / (this.pontos.length - 1))
      )
    },

    py(valor: number): number {
      return (
        220 -
        (valor / this.maxTotal) * 200
      )
    },

    formatar(data: string): string {
      const [, mes, dia] = data.split('-')
      return `${dia}/${mes}`
    }
  }
})
</script>