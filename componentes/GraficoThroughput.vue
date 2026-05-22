<template>
  <div class="cartao">
    <div class="flex justify-between items-center mb-3">
      <h3 class="font-semibold">
        ⚡ Throughput diário
      </h3>

      <span class="text-xs text-slate-500">
        {{ total }} tarefas em {{ chaves.length }} dias · média {{ media }}/dia
      </span>
    </div>

    <svg v-if="chaves.length" :viewBox="`0 0 ${largura} ${altura}`" class="w-full h-40">
      <g v-for="(data, indice) in chaves" :key="data">
        <rect :x="indice * stepX + 1" :y="altura - 16 - barAltura(dados[data])" :width="stepX - 2"
          :height="barAltura(dados[data])" fill="hsl(217 91% 60%)" rx="2" />

        <text v-if="dados[data] > 0" :x="indice * stepX + stepX / 2" :y="altura - 18 - barAltura(dados[data])"
          text-anchor="middle" class="text-[8px] fill-slate-600 font-semibold">
          {{ dados[data] }}
        </text>
      </g>

      <text v-for="(item, indice) in marcosX" :key="indice + '-lbl'" :x="posicaoMarco(indice)" :y="altura - 4"
        class="text-[8px] fill-slate-500" :text-anchor="alinhamentoMarco(indice)">
        {{ item }}
      </text>
    </svg>

    <div v-else class="text-sm text-slate-400 py-6 text-center">
      Sem entregas no período.
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'GraficoThroughput',

  props: {
    dados: {
      type: Object,
      default: () => ({})
    },

    total: {
      type: Number,
      default: 0
    },

    media: {
      type: Number,
      default: 0
    }
  },

  data() {
    return {
      largura: 600,
      altura: 160
    }
  },

  computed: {
    chaves(): string[] {
      return Object.keys(this.dados || {})
    },

    max(): number {
      return Math.max(
        1,
        ...Object.values(this.dados || {})
      )
    },

    stepX(): number {
      return (
        this.largura /
        Math.max(1, this.chaves.length)
      )
    },

    marcosX(): string[] {
      if (!this.chaves.length) {
        return []
      }

      const indices = [
        0,
        Math.floor(this.chaves.length / 2),
        this.chaves.length - 1
      ]

      return indices.map((indice) =>
        (this.chaves[indice] || '').slice(5)
      )
    }
  },

  methods: {
    barAltura(valor: number): number {
      return (
        (valor / this.max) *
        (this.altura - 30)
      )
    },

    posicaoMarco(indice: number): number {
      return (
        indice *
        (this.largura /
          Math.max(1, this.marcosX.length - 1))
      )
    },

    alinhamentoMarco(indice: number): string {
      if (indice === 0) {
        return 'start'
      }

      if (indice === this.marcosX.length - 1) {
        return 'end'
      }

      return 'middle'
    }
  }
})
</script>