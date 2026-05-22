<template>
  <div>
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-3xl font-bold">🎭 Papéis</h1>
        <p class="text-sm text-slate-500 mt-1">Cargos e funções disponíveis para membros de projetos</p>
      </div>
      <button class="botao-primario" @click="abrirNovo">+ Novo papel</button>
    </div>

    <!-- Formulário criar/editar -->
    <div v-if="formulario" class="cartao mb-6">
      <h3 class="font-semibold mb-4">{{ editando ? 'Editar papel' : 'Novo papel' }}</h3>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div class="sm:col-span-1">
          <label class="text-xs text-slate-500 block mb-1">Nome *</label>
          <input
            v-model="form.nome"
            type="text"
            placeholder="Ex: Dev Frontend"
            class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:border-primaria"
          />
        </div>
        <div class="sm:col-span-1">
          <label class="text-xs text-slate-500 block mb-1">Descrição</label>
          <input
            v-model="form.descricao"
            type="text"
            placeholder="Breve descrição"
            class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:border-primaria"
          />
        </div>
        <div>
          <label class="text-xs text-slate-500 block mb-1">Cor</label>
          <div class="flex items-center gap-2">
            <input
              v-model="form.cor"
              type="color"
              class="w-10 h-9 border rounded cursor-pointer p-0.5"
            />
            <span class="text-xs text-slate-500 font-mono">{{ form.cor }}</span>
          </div>
        </div>
      </div>

      <p v-if="erro" class="text-xs text-perigo mt-2">{{ erro }}</p>

      <div class="flex gap-2 mt-4">
        <button
          class="botao-primario text-sm px-4 py-2"
          :disabled="!form.nome.trim() || salvando"
          @click="salvar"
        >
          {{ salvando ? 'Salvando...' : (editando ? 'Salvar' : 'Criar') }}
        </button>
        <button class="botao-secundario text-sm px-4 py-2" @click="cancelar">Cancelar</button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="carregando" class="text-slate-400 text-center py-12">Carregando...</div>

    <!-- Lista -->
    <div v-else class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
      <div
        v-for="p in papeis"
        :key="p.id"
        class="cartao flex items-start gap-3 group"
      >
        <!-- Indicador de cor -->
        <div
          class="w-3 h-3 rounded-full mt-1 shrink-0"
          :style="{ background: p.cor }"
        />

        <div class="flex-1 min-w-0">
          <div class="font-semibold text-slate-800">{{ p.nome }}</div>
          <div v-if="p.descricao" class="text-xs text-slate-400 mt-0.5">{{ p.descricao }}</div>
        </div>

        <div class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
          <button
            class="text-xs text-slate-400 hover:text-primaria px-2 py-1 rounded hover:bg-slate-50"
            @click="abrirEdicao(p)"
          >
            ✏️
          </button>
          <button
            class="text-xs text-slate-400 hover:text-perigo px-2 py-1 rounded hover:bg-red-50"
            @click="excluir(p)"
          >
            🗑
          </button>
        </div>
      </div>

      <div v-if="!papeis.length" class="col-span-full text-center text-slate-400 py-12">
        Nenhum papel cadastrado.
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'PaginaPapeis',

  data() {
    return {
      papeis: [] as any[],
      carregando: false,
      formulario: false,
      editando: null as any,
      salvando: false,
      erro: '',
      form: {
        nome: '',
        descricao: '',
        cor: '#6366f1'
      }
    }
  },

  async mounted() {
    await this.carregar()
  },

  methods: {
    async carregar() {
      this.carregando = true
      try {
        this.papeis = await servicoPapeis().listar()
      } finally {
        this.carregando = false
      }
    },

    abrirNovo() {
      this.editando = null
      this.form = { nome: '', descricao: '', cor: '#6366f1' }
      this.erro = ''
      this.formulario = true
    },

    abrirEdicao(p: any) {
      this.editando = p
      this.form = { nome: p.nome, descricao: p.descricao || '', cor: p.cor || '#6366f1' }
      this.erro = ''
      this.formulario = true
    },

    cancelar() {
      this.formulario = false
      this.editando = null
    },

    async salvar() {
      if (!this.form.nome.trim()) return
      this.salvando = true
      this.erro = ''
      try {
        const svc = servicoPapeis()
        if (this.editando) {
          const atualizado = await svc.atualizar(this.editando.id, this.form)
          const idx = this.papeis.findIndex(p => p.id === this.editando.id)
          if (idx !== -1) this.papeis[idx] = atualizado
        } else {
          const novo = await svc.criar(this.form)
          this.papeis.push(novo)
          this.papeis.sort((a, b) => a.nome.localeCompare(b.nome))
        }
        this.cancelar()
      } catch (e: any) {
        this.erro = e?.message || String(e) || 'Erro desconhecido'
      } finally {
        this.salvando = false
      }
    },

    async excluir(p: any) {
      if (!confirm(`Excluir papel "${p.nome}"?`)) return
      await servicoPapeis().excluir(p.id)
      this.papeis = this.papeis.filter(x => x.id !== p.id)
    }
  }
})
</script>
