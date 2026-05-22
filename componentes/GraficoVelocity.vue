<template>
  <div class="cartao">
    <div class="flex justify-between items-center mb-4">
      <h3 class="font-semibold">🚀 Velocity por Sprint</h3>
      <div class="flex gap-4 text-xs text-slate-500">
        <span class="flex items-center gap-1">
          <span class="inline-block w-3 h-3 rounded bg-primaria opacity-80" /> Concluídos
        </span>
        <span class="flex items-center gap-1">
          <span class="inline-block w-3 h-3 rounded bg-slate-300" /> Planejados
        </span>
        <span class="flex items-center gap-1">
          <span class="inline-block w-4 border-t-2 border-dashed border-perigo" /> Média
        </span>
      </div>
    </div>

    <div v-if="!historico.length" class="text-sm text-slate-400 py-10 text-center">
      Sem sprints concluídas ainda.<br>
      <span class="text-xs">Conclua uma sprint para ver o velocity.</span>
    </div>

    <template v-else>
      <svg :viewBox="`0 0 ${W} ${H}`" class="w-full" :style="{ height: `${H}px` }">
        <!-- Grades horizontais -->
        <g v-for="i in 4" :key="`g${i}`">
          <line
            :x1="PAD_L" :y1="py(maxVal * i / 4)"
            :x2="W - PAD_R" :y2="py(maxVal * i / 4)"
            stroke="#f1f5f9" stroke-width="1"
          />
          <text :x="PAD_L - 4" :y="py(maxVal * i / 4) + 3" font-size="9" text-anchor="end" fill="#94a3b8">
            {{ Math.round(maxVal * i / 4) }}
          </text>
        </g>

        <!-- Eixo X -->
        <line :x1="PAD_L" :y1="H - PAD_B" :x2="W - PAD_R" :y2="H - PAD_B" stroke="#e2e8f0" />

        <!-- Barras planejados (fundo, mais clara) -->
        <rect
          v-for="(item, i) in historico"
          :key="`p${i}`"
          :x="barX(i) - barW / 2"
          :y="py(item.sp_planejados)"
          :width="barW"
          :height="H - PAD_B - py(item.sp_planejados)"
          fill="#e2e8f0"
          rx="3"
        />

        <!-- Barras concluídos (frente) -->
        <rect
          v-for="(item, i) in historico"
          :key="`c${i}`"
          :x="barX(i) - barW / 2 + 4"
          :y="py(item.sp_concluidos)"
          :width="barW - 8"
          :height="H - PAD_B - py(item.sp_concluidos)"
          fill="hsl(221 83% 53%)"
          rx="3"
          opacity="0.85"
        />

        <!-- Valores concluídos acima das barras -->
        <text
          v-for="(item, i) in historico"
          :key="`v${i}`"
          :x="barX(i)"
          :y="py(item.sp_concluidos) - 4"
          font-size="10"
          text-anchor="middle"
          font-weight="600"
          fill="hsl(221 83% 40%)"
        >
          {{ item.sp_concluidos }}
        </text>

        <!-- Labels sprint no eixo X -->
        <text
          v-for="(item, i) in historico"
          :key="`l${i}`"
          :x="barX(i)"
          :y="H - PAD_B + 12"
          font-size="9"
          text-anchor="middle"
          fill="#64748b"
        >
          {{ nomeAbreviado(item.sprint?.nome || `S${i + 1}`) }}
        </text>

        <!-- Linha velocity média -->
        <line
          v-if="media > 0"
          :x1="PAD_L"
          :y1="py(media)"
          :x2="W - PAD_R"
          :y2="py(media)"
          stroke="hsl(0 84% 60%)"
          stroke-width="1.5"
          stroke-dasharray="5 3"
        />
        <text
          v-if="media > 0"
          :x="W - PAD_R + 4"
          :y="py(media) + 3"
          font-size="9"
          fill="hsl(0 84% 60%)"
        >
          {{ media }}
        </text>
      </svg>

      <!-- KPI row abaixo -->
      <div class="grid grid-cols-3 gap-3 mt-4 pt-4 border-t border-slate-100">
        <div class="text-center">
          <div class="text-xl font-bold text-primaria">{{ media }}</div>
          <div class="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Velocity média</div>
        </div>
        <div class="text-center">
          <div class="text-xl font-bold text-sucesso">{{ maxConcluidos }}</div>
          <div class="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Melhor sprint</div>
        </div>
        <div class="text-center">
          <div class="text-xl font-bold" :class="taxaMedia >= 80 ? 'text-sucesso' : taxaMedia >= 60 ? 'text-alerta' : 'text-perigo'">
            {{ taxaMedia }}%
          </div>
          <div class="text-[10px] text-slate-400 uppercase font-semibold tracking-wider">Taxa conclusão</div>
        </div>
      </div>
    </template>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'GraficoVelocity',

  props: {
    historico: { type: Array as () => any[], default: () => [] },
    media:     { type: Number, default: 0 },
  },

  data() {
    return {
      W: 600,
      H: 200,
      PAD_L: 36,
      PAD_R: 36,
      PAD_T: 20,
      PAD_B: 24,
    }
  },

  computed: {
    maxVal(): number {
      return Math.max(
        1,
        ...this.historico.map((h: any) => Math.max(h.sp_planejados || 0, h.sp_concluidos || 0))
      )
    },

    barW(): number {
      const n = Math.max(1, this.historico.length)
      return Math.min(60, (this.W - this.PAD_L - this.PAD_R) / n * 0.65)
    },

    maxConcluidos(): number {
      return Math.max(0, ...this.historico.map((h: any) => h.sp_concluidos || 0))
    },

    taxaMedia(): number {
      if (!this.historico.length) return 0
      const spPlan = this.historico.reduce((acc: number, h: any) => acc + (h.sp_planejados || 0), 0)
      const spConc = this.historico.reduce((acc: number, h: any) => acc + (h.sp_concluidos || 0), 0)
      return spPlan ? Math.round((spConc / spPlan) * 100) : 0
    },
  },

  methods: {
    py(valor: number): number {
      return this.PAD_T + (1 - valor / this.maxVal) * (this.H - this.PAD_T - this.PAD_B)
    },

    barX(i: number): number {
      const n = this.historico.length
      if (n === 1) return (this.W - this.PAD_L - this.PAD_R) / 2 + this.PAD_L
      return this.PAD_L + i * (this.W - this.PAD_L - this.PAD_R) / (n - 1)
    },

    nomeAbreviado(nome: string): string {
      return nome.length > 8 ? nome.slice(0, 7) + '…' : nome
    },
  },
})
</script>
