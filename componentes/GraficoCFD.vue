<template>
  <div class="cartao">
    <h3 class="font-semibold mb-2">
      📈 Cumulative Flow Diagram
    </h3>

    <p class="text-xs text-slate-500 mb-3">
      Distribuição de tarefas por coluna ao longo do tempo
      (últimos {{ dados.length }} dias).
    </p>

    <svg v-if="dados.length" :viewBox="`0 0 ${largura} ${altura}`" class="w-full h-64">
      <g v-for="(serie, indice) in series" :key="serie.coluna">
        <polygon :points="serie.pontos" :fill="cores[indice]" fill-opacity="0.85" stroke="white" stroke-width="0.5" />
      </g>

      <g :transform="`translate(0, ${altura - 14})`">
        <text v-for="(item, indice) in marcosX" :key="indice" :x="posicaoMarco(indice)" y="10"
          class="text-[8px] fill-slate-500" :text-anchor="alinhamentoMarco(indice)">
          {{ item }}
        </text>
      </g>
    </svg>

    <div v-else class="text-sm text-slate-400 py-6 text-center">
      Sem dados ainda — crie tarefas para popular o gráfico.
    </div>

    <div class="flex flex-wrap gap-3 mt-3 text-xs">
      <div v-for="(coluna, indice) in COLUNAS" :key="coluna" class="flex items-center gap-1">
        <span class="w-3 h-3 rounded" :style="{ background: cores[indice] }"></span>

        <span class="capitalize">
          {{ coluna.replace('_', ' ') }}
        </span>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'GraficoCFD',

  props: {
    dados: {
      type: Array,
      default: () => []
    }
  },

  data() {
    return {
      COLUNAS: [
        'backlog',
        'a_fazer',
        'em_progresso',
        'em_revisao',
        'concluido'
      ],

      cores: [
        '#94a3b8',
        '#60a5fa',
        '#fbbf24',
        '#a78bfa',
        '#34d399'
      ],

      largura: 600,
      altura: 220,
      padBottom: 20
    }
  },

  computed: {
    series(): any[] {
      if (!this.dados.length) {
        return []
      }

      const totalPontos = this.dados.length

      const maximo = Math.max(
        1,
        ...this.dados.map((item: any) =>
          this.COLUNAS.reduce(
            (soma: number, coluna: string) =>
              soma + (item[coluna] ?? 0),
            0
          )
        )
      )

      const stepX =
        this.largura /
        Math.max(1, totalPontos - 1)

      const acumulado = this.dados.map(
        (item: any) => {
          const atual: Record<string, number> = {}
          let soma = 0

          for (const coluna of this.COLUNAS) {
            soma += item[coluna] ?? 0
            atual[coluna] = soma
          }

          return atual
        }
      )

      return this.COLUNAS.map(
        (coluna: string, indice: number) => {
          const topo = acumulado.map(
            (acc, posicao) => {
              const x = posicao * stepX

              const y =
                this.altura -
                this.padBottom -
                (acc[coluna] / maximo) *
                (this.altura - this.padBottom)

              return `${x},${y}`
            }
          )

          let base: string[] = []

          if (indice === 0) {
            base = [
              `${this.largura},${this.altura - this.padBottom}`,
              `0,${this.altura - this.padBottom}`
            ]
          } else {
            const colunaAnterior =
              this.COLUNAS[indice - 1]

            base = acumulado
              .map((acc, posicao) => {
                const x =
                  (this.dados.length - 1 - posicao) *
                  stepX

                const y =
                  this.altura -
                  this.padBottom -
                  (acc[colunaAnterior] / maximo) *
                  (this.altura - this.padBottom)

                return `${x},${y}`
              })
              .reverse()
          }

          return {
            coluna,
            pontos: [...topo, ...base].join(' ')
          }
        }
      )
    },

    marcosX(): string[] {
      if (!this.dados.length) {
        return []
      }

      const indices = [
        0,
        Math.floor(this.dados.length / 2),
        this.dados.length - 1
      ]

      return indices.map((indice) => {
        const data =
          (this.dados[indice] as any)?.data ?? ''

        return data.slice(5)
      })
    }
  },

  methods: {
    posicaoMarco(indice: number): number {
      if (this.marcosX.length <= 1) {
        return 0
      }

      return (
        indice *
        (this.largura /
          (this.marcosX.length - 1))
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