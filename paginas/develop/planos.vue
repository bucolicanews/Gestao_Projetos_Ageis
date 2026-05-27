<template>
  <div>
    <!-- Guard: enquanto verifica role -->
    <div v-if="verificando" class="flex items-center justify-center h-40 text-slate-400">
      Verificando permissões...
    </div>

    <template v-else-if="isDevelopAdmin">
      <!-- Header -->
      <div class="flex justify-between items-center mb-6">
        <div>
          <h1 class="text-2xl font-bold">📦 Planos</h1>
          <p class="text-sm text-slate-500 mt-0.5">Gerencie os planos disponíveis para organizações</p>
        </div>
        <button class="botao-primario" @click="abrirNovo">+ Novo plano</button>
      </div>

      <!-- Carregando -->
      <div v-if="loja.carregando" class="text-slate-400 text-sm">Carregando planos...</div>

      <!-- Erro -->
      <div v-else-if="loja.erro" class="text-perigo text-sm">{{ loja.erro }}</div>

      <!-- Lista -->
      <div v-else class="grid gap-4 md:grid-cols-3">
        <div
          v-for="plano in loja.planos"
          :key="plano.id"
          class="cartao flex flex-col gap-3"
          :class="{ 'opacity-50': !plano.ativo }"
        >
          <!-- Imagem -->
          <img
            v-if="plano.imagem_url"
            :src="plano.imagem_url"
            class="w-full h-28 object-cover rounded-lg border border-slate-100"
          />
          <div v-else class="w-full h-28 bg-slate-100 rounded-lg flex items-center justify-center text-4xl">
            📦
          </div>

          <!-- Info -->
          <div class="flex justify-between items-start">
            <div>
              <h3 class="font-bold text-base">{{ plano.titulo }}</h3>
              <p v-if="plano.descricao" class="text-xs text-slate-500 mt-0.5">{{ plano.descricao }}</p>
            </div>
            <span
              class="text-xs px-2 py-0.5 rounded-full font-semibold"
              :class="plano.ativo ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-500'"
            >
              {{ plano.ativo ? 'Ativo' : 'Inativo' }}
            </span>
          </div>

          <!-- Preço -->
          <div class="text-2xl font-bold text-primaria">
            R$ {{ Number(plano.preco).toFixed(2).replace('.', ',') }}
            <span class="text-sm font-normal text-slate-400">/mês</span>
          </div>

          <!-- Recursos -->
          <ul v-if="plano.recursos?.length" class="flex flex-col gap-1">
            <li
              v-for="(r, i) in plano.recursos"
              :key="i"
              class="text-xs text-slate-600 flex items-center gap-1.5"
            >
              <span class="text-green-500">✓</span> {{ r }}
            </li>
          </ul>

          <!-- Ações -->
          <div class="flex gap-2 mt-auto pt-2 border-t border-slate-100">
            <button
              class="botao-secundario text-xs py-1 px-3 flex-1"
              @click="abrirEdicao(plano)"
            >
              ✏️ Editar
            </button>
            <button
              class="text-xs py-1 px-3 rounded-lg font-medium transition"
              :class="plano.ativo ? 'bg-amber-50 text-amber-700 hover:bg-amber-100' : 'bg-green-50 text-green-700 hover:bg-green-100'"
              @click="alternarAtivo(plano.id)"
            >
              {{ plano.ativo ? '⏸ Desativar' : '▶ Ativar' }}
            </button>
            <button
              class="botao-perigo text-xs py-1 px-3"
              @click="confirmarExclusao(plano)"
            >
              🗑
            </button>
          </div>
        </div>

        <div v-if="!loja.planos.length" class="col-span-3 text-slate-400 text-sm py-10 text-center">
          Nenhum plano cadastrado ainda. Crie o primeiro!
        </div>
      </div>

      <!-- Confirmação de exclusão -->
      <div v-if="planoParaExcluir" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-2xl shadow-xl p-6 w-full max-w-sm">
          <h3 class="font-bold text-base mb-2">Excluir plano</h3>
          <p class="text-sm text-slate-600 mb-4">
            Excluir <strong>{{ planoParaExcluir.titulo }}</strong>? Organizações ativas neste plano não serão afetadas.
          </p>
          <div class="flex gap-3 justify-end">
            <button class="botao-secundario" @click="planoParaExcluir = null">Cancelar</button>
            <button class="botao-perigo" :disabled="excluindo" @click="excluir">
              {{ excluindo ? 'Excluindo...' : 'Excluir' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Modal criar/editar -->
      <ModalPlano
        v-if="modalAberto"
        :plano="planoEditando"
        @fechar="fecharModal"
        @salvo="fecharModal"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import type { Plano } from '~/servicos/servicoPlanos'

definePageMeta({ layout: 'default' })

const { isDevelopAdmin, verificando } = useDevelopAdmin()
const loja = useLojaPlanos()

const modalAberto = ref(false)
const planoEditando = ref<Plano | null>(null)
const planoParaExcluir = ref<Plano | null>(null)
const excluindo = ref(false)

onMounted(() => loja.carregar())

function abrirNovo() {
  planoEditando.value = null
  modalAberto.value = true
}

function abrirEdicao(plano: Plano) {
  planoEditando.value = plano
  modalAberto.value = true
}

function fecharModal() {
  modalAberto.value = false
  planoEditando.value = null
}

function confirmarExclusao(plano: Plano) {
  planoParaExcluir.value = plano
}

async function excluir() {
  if (!planoParaExcluir.value) return
  excluindo.value = true
  try {
    await loja.excluir(planoParaExcluir.value.id)
    planoParaExcluir.value = null
  } finally {
    excluindo.value = false
  }
}

async function alternarAtivo(id: string) {
  await loja.alternarAtivo(id)
}
</script>
