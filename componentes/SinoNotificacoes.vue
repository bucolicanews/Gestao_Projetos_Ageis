<template>
  <!-- Botão sino -->
  <button
    class="relative w-10 h-10 flex items-center justify-center rounded-lg hover:bg-slate-100 transition-colors"
    @click="abrirModal"
  >
    <span class="text-xl">🔔</span>
    <span
      v-if="naoLidas > 0"
      class="absolute top-1 right-1 min-w-[16px] h-[16px] bg-red-500 text-white text-[9px] font-bold rounded-full flex items-center justify-center px-1 leading-none"
    >
      {{ naoLidas > 99 ? '99+' : naoLidas }}
    </span>
  </button>

  <!-- Painel lateral direito -->
  <Teleport to="body">
    <div
      v-if="modalAberto"
      class="fixed inset-0 z-[100] flex"
      @click.self="fecharModal"
    >
      <div class="flex-1 bg-black/40" @click="fecharModal" />

      <div class="w-full max-w-sm bg-white flex flex-col shadow-2xl">

        <!-- Cabeçalho -->
        <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100 shrink-0">
          <div class="flex items-center gap-2">
            <span class="text-lg">🔔</span>
            <h2 class="font-bold text-slate-800">Notificações</h2>
            <span
              v-if="naoLidas > 0 && aba === 'atuais'"
              class="text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-red-100 text-red-600"
            >
              {{ naoLidas }} nova{{ naoLidas !== 1 ? 's' : '' }}
            </span>
          </div>
          <div class="flex items-center gap-0.5">
            <!-- Marcar todas como lidas -->
            <button
              v-if="aba === 'atuais' && naoLidas > 0"
              class="w-8 h-8 flex items-center justify-center rounded-lg text-indigo-500 hover:text-indigo-700 hover:bg-indigo-50 transition text-sm"
              title="Marcar todas como lidas"
              @click="lerTodas"
            >
              ✓✓
            </button>
            <!-- Arquivar lidas -->
            <button
              v-if="aba === 'atuais' && listaAtual.some(n => n.lida)"
              class="w-8 h-8 flex items-center justify-center rounded-lg text-slate-400 hover:text-amber-500 hover:bg-amber-50 transition text-sm"
              title="Arquivar todas as lidas"
              @click="arquivarLidas"
            >
              📦
            </button>
            <!-- Fechar -->
            <button
              class="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-400 hover:text-slate-600 transition text-base leading-none"
              title="Fechar"
              @click="fecharModal"
            >
              ✕
            </button>
          </div>
        </div>

        <!-- Tabs -->
        <div class="flex border-b border-slate-100 shrink-0">
          <button
            v-for="t in tabs"
            :key="t.id"
            :class="[
              'flex-1 py-2.5 text-xs font-semibold transition border-b-2 -mb-px',
              aba === t.id
                ? 'border-indigo-500 text-indigo-600'
                : 'border-transparent text-slate-400 hover:text-slate-600'
            ]"
            @click="trocarAba(t.id)"
          >
            {{ t.label }}
            <span v-if="t.id === 'atuais' && listaAtual.length" class="ml-1 text-[10px] bg-slate-100 text-slate-500 px-1.5 py-0.5 rounded-full">
              {{ listaAtual.length }}
            </span>
            <span v-if="t.id === 'arquivadas' && listaArquivada.length" class="ml-1 text-[10px] bg-slate-100 text-slate-500 px-1.5 py-0.5 rounded-full">
              {{ listaArquivada.length }}
            </span>
          </button>
        </div>

        <!-- Lista -->
        <div class="flex-1 overflow-y-auto">
          <div v-if="carregando" class="py-12 text-center text-slate-400 text-sm">
            Carregando...
          </div>

          <div v-else-if="listaVisivel.length === 0" class="py-16 text-center">
            <div class="text-4xl mb-3">{{ aba === 'arquivadas' ? '📦' : '🔔' }}</div>
            <p class="text-slate-400 text-sm">
              {{ aba === 'arquivadas' ? 'Nenhuma notificação arquivada.' : 'Nenhuma notificação.' }}
            </p>
          </div>

          <div
            v-for="n in listaVisivel"
            :key="n.id"
            class="group relative flex gap-3 px-5 py-4 border-b border-slate-50 transition-colors"
            :class="n.lida ? 'hover:bg-slate-50' : 'bg-indigo-50 hover:bg-indigo-100'"
            @click="marcarLida(n)"
          >
            <span class="text-xl shrink-0 mt-0.5">{{ icone(n.tipo) }}</span>

            <div class="flex-1 min-w-0 pr-14">
              <p :class="['text-sm leading-snug', n.lida ? 'text-slate-600' : 'text-slate-800 font-semibold']">
                {{ n.titulo }}
              </p>
              <p v-if="n.mensagem" class="text-xs text-slate-500 mt-0.5 line-clamp-2">
                {{ n.mensagem }}
              </p>
              <p class="text-[10px] text-slate-400 mt-1.5">
                {{ formatarTempo(n.criado_em) }}
              </p>
            </div>

            <!-- Dot não lida -->
            <span v-if="!n.lida && aba === 'atuais'" class="w-2 h-2 bg-indigo-500 rounded-full shrink-0 mt-2" />

            <!-- Ações (aparecem no hover) -->
            <div
              class="absolute right-3 top-1/2 -translate-y-1/2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity"
              @click.stop
            >
              <button
                v-if="aba === 'atuais'"
                class="w-7 h-7 flex items-center justify-center rounded-lg bg-white border border-slate-200 text-slate-400 hover:text-amber-500 hover:border-amber-200 transition text-xs"
                title="Arquivar"
                @click="arquivarItem(n)"
              >
                📦
              </button>
              <button
                class="w-7 h-7 flex items-center justify-center rounded-lg bg-white border border-slate-200 text-slate-400 hover:text-red-500 hover:border-red-200 transition text-xs"
                title="Excluir"
                @click="excluirItem(n)"
              >
                🗑
              </button>
            </div>
          </div>
        </div>

        <!-- Rodapé -->
        <div class="px-5 py-3 border-t border-slate-100 text-center shrink-0">
          <p class="text-xs text-slate-400">
            {{ listaVisivel.length }} notificaç{{ listaVisivel.length !== 1 ? 'ões' : 'ão' }}
            {{ aba === 'arquivadas' ? 'arquivadas' : '' }}
          </p>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'

const svc    = servicoNotificacoes()
const cliente = useSupabaseClient()
const user   = useSupabaseUser()

const modalAberto    = ref(false)
const carregando     = ref(false)
const listaAtual     = ref<any[]>([])
const listaArquivada = ref<any[]>([])
const aba            = ref<'atuais' | 'arquivadas'>('atuais')

const tabs = [
  { id: 'atuais',     label: 'Atuais' },
  { id: 'arquivadas', label: 'Arquivadas' },
]

const listaVisivel = computed(() =>
  aba.value === 'arquivadas' ? listaArquivada.value : listaAtual.value
)

const naoLidas = computed(() => listaAtual.value.filter(n => !n.lida).length)

function icone(tipo: string) {
  const mapa: Record<string, string> = {
    tarefa_atribuida: '📋',
    comentario:       '💬',
    prazo:            '⏰',
    subtarefa:        '🔗',
    convite:          '✉️',
    geral:            '📢',
    cobranca:         '💳',
  }
  return mapa[tipo] || '🔔'
}

function formatarTempo(iso: string) {
  const diff = Date.now() - new Date(iso).getTime()
  const min  = Math.floor(diff / 60000)
  if (min < 1)  return 'agora'
  if (min < 60) return `${min}min atrás`
  const h = Math.floor(min / 60)
  if (h < 24)   return `${h}h atrás`
  return new Date(iso).toLocaleDateString('pt-BR')
}

async function carregar() {
  carregando.value = true
  try {
    const [atuais, arquivadas] = await Promise.all([
      svc.listar(),
      svc.listarArquivadas(),
    ])
    listaAtual.value     = atuais
    listaArquivada.value = arquivadas
  } finally {
    carregando.value = false
  }
}

async function trocarAba(id: 'atuais' | 'arquivadas') {
  aba.value = id
}

async function abrirModal() {
  modalAberto.value = true
  await carregar()
}

function fecharModal() {
  modalAberto.value = false
  aba.value = 'atuais'
}

async function marcarLida(n: any) {
  if (!n.lida && aba.value === 'atuais') {
    n.lida = true
    await svc.marcarLida(n.id)
  }
}

async function lerTodas() {
  listaAtual.value.forEach(n => (n.lida = true))
  await svc.marcarTodasLidas()
}

async function arquivarLidas() {
  const ids = listaAtual.value.filter(n => n.lida).map(n => n.id)
  listaAtual.value = listaAtual.value.filter(n => !n.lida)
  await svc.arquivarTodasLidas()
  // Recarrega arquivadas para refletir
  listaArquivada.value = await svc.listarArquivadas()
}

async function arquivarItem(n: any) {
  listaAtual.value = listaAtual.value.filter(x => x.id !== n.id)
  await svc.arquivar(n.id)
  listaArquivada.value.unshift({ ...n, arquivada: true, lida: true })
}

async function excluirItem(n: any) {
  if (aba.value === 'atuais') {
    listaAtual.value = listaAtual.value.filter(x => x.id !== n.id)
  } else {
    listaArquivada.value = listaArquivada.value.filter(x => x.id !== n.id)
  }
  await svc.excluir(n.id)
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') fecharModal()
}

let canal: any = null

onMounted(async () => {
  await carregar()
  document.addEventListener('keydown', onKeydown)

  if (user.value) {
    canal = cliente
      .channel(`notif-${user.value.id}-${Date.now()}`)
      .on(
        'postgres_changes',
        {
          event:  'INSERT',
          schema: 'public',
          table:  'notificacoes',
          filter: `usuario_id=eq.${user.value.id}`,
        },
        (payload: any) => {
          listaAtual.value.unshift(payload.new)
        }
      )
      .subscribe()
  }
})

onUnmounted(() => {
  document.removeEventListener('keydown', onKeydown)
  if (canal) cliente.removeChannel(canal)
})
</script>
