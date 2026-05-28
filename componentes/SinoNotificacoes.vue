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

  <!-- Modal — painel direito -->
  <Teleport to="body">
    <div
      v-if="modalAberto"
      class="fixed inset-0 z-[100] flex"
      @click.self="fecharModal"
    >
      <!-- Backdrop -->
      <div class="flex-1 bg-black/40" @click="fecharModal" />

      <!-- Painel -->
      <div class="w-full max-w-sm bg-white flex flex-col shadow-2xl">

        <!-- Cabeçalho -->
        <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
          <div class="flex items-center gap-2">
            <span class="text-lg">🔔</span>
            <h2 class="font-bold text-slate-800">Notificações</h2>
            <span v-if="naoLidas > 0"
              class="text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-red-100 text-red-600">
              {{ naoLidas }} nova{{ naoLidas !== 1 ? 's' : '' }}
            </span>
          </div>
          <div class="flex items-center gap-2">
            <button
              v-if="naoLidas > 0"
              class="text-xs text-indigo-600 hover:text-indigo-800 font-medium"
              @click="lerTodas"
            >
              Ler todas
            </button>
            <button
              class="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-400 text-lg leading-none"
              @click="fecharModal"
            >
              ✕
            </button>
          </div>
        </div>

        <!-- Lista -->
        <div class="flex-1 overflow-y-auto">
          <div v-if="carregando" class="py-12 text-center text-slate-400 text-sm">
            Carregando...
          </div>

          <div v-else-if="lista.length === 0" class="py-16 text-center">
            <div class="text-4xl mb-3">🔔</div>
            <p class="text-slate-400 text-sm">Nenhuma notificação ainda.</p>
          </div>

          <div
            v-for="n in lista"
            :key="n.id"
            :class="[
              'flex gap-3 px-5 py-4 border-b border-slate-50 transition-colors cursor-pointer',
              n.lida ? 'hover:bg-slate-50' : 'bg-indigo-50 hover:bg-indigo-100'
            ]"
            @click="marcarLida(n)"
          >
            <span class="text-xl shrink-0 mt-0.5">{{ icone(n.tipo) }}</span>
            <div class="flex-1 min-w-0">
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
            <span v-if="!n.lida" class="w-2 h-2 bg-indigo-500 rounded-full shrink-0 mt-2" />
          </div>
        </div>

        <!-- Rodapé -->
        <div class="px-5 py-3 border-t border-slate-100 text-center">
          <p class="text-xs text-slate-400">{{ lista.length }} notificaç{{ lista.length !== 1 ? 'ões' : 'ão' }} no total</p>
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

const modalAberto = ref(false)
const carregando  = ref(false)
const lista       = ref<any[]>([])

const naoLidas = computed(() => lista.value.filter(n => !n.lida).length)

function icone(tipo: string) {
  const mapa: Record<string, string> = {
    tarefa_atribuida: '📋',
    comentario:       '💬',
    prazo:            '⏰',
    subtarefa:        '🔗',
    convite:          '✉️',
    geral:            '📢',
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
    lista.value = await svc.listar()
  } finally {
    carregando.value = false
  }
}

async function abrirModal() {
  modalAberto.value = true
  await carregar()
}

function fecharModal() {
  modalAberto.value = false
}

async function marcarLida(n: any) {
  if (!n.lida) {
    n.lida = true
    await svc.marcarLida(n.id)
  }
}

async function lerTodas() {
  lista.value.forEach(n => (n.lida = true))
  await svc.marcarTodasLidas()
}

// Fecha com Esc
function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') fecharModal()
}

let canal: any = null

onMounted(async () => {
  await carregar()
  document.addEventListener('keydown', onKeydown)

  if (user.value) {
    // Nome único por mount (userId + timestamp) → nunca reutiliza canal já subscribed
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
          lista.value.unshift(payload.new)
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
