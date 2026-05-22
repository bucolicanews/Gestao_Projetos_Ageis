<template>
  <div class="relative" ref="containerRef">
    <!-- Botão sino -->
    <button
      class="relative p-2 rounded-lg hover:bg-slate-100 transition-colors"
      @click="alternarDropdown"
    >
      <span class="text-xl">🔔</span>
      <span
        v-if="naoLidas > 0"
        class="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center px-1"
      >
        {{ naoLidas > 99 ? '99+' : naoLidas }}
      </span>
    </button>

    <!-- Dropdown -->
    <div
      v-if="aberto"
      class="absolute right-0 top-full mt-2 w-80 bg-white rounded-xl shadow-xl border border-slate-200 z-50 overflow-hidden"
    >
      <!-- Cabeçalho -->
      <div class="flex justify-between items-center px-4 py-3 border-b border-slate-100">
        <h3 class="font-semibold text-slate-800 text-sm">Notificações</h3>
        <button
          v-if="naoLidas > 0"
          class="text-xs text-indigo-600 hover:text-indigo-800 font-medium"
          @click="lerTodas"
        >
          Marcar todas como lidas
        </button>
      </div>

      <!-- Lista -->
      <div class="max-h-[400px] overflow-y-auto">
        <div v-if="carregando" class="py-8 text-center text-slate-400 text-sm">
          Carregando...
        </div>

        <div v-else-if="lista.length === 0" class="py-8 text-center text-slate-400 text-sm">
          Nenhuma notificação
        </div>

        <div
          v-for="n in lista"
          :key="n.id"
          :class="[
            'flex gap-3 px-4 py-3 border-b border-slate-50 cursor-pointer transition-colors',
            n.lida ? 'hover:bg-slate-50' : 'bg-indigo-50 hover:bg-indigo-100'
          ]"
          @click="abrirNotificacao(n)"
        >
          <span class="text-lg shrink-0 mt-0.5">{{ icone(n.tipo) }}</span>
          <div class="flex-1 min-w-0">
            <p :class="['text-sm leading-tight', n.lida ? 'text-slate-600' : 'text-slate-800 font-medium']">
              {{ n.titulo }}
            </p>
            <p v-if="n.mensagem" class="text-xs text-slate-400 mt-0.5 truncate">
              {{ n.mensagem }}
            </p>
            <p class="text-[10px] text-slate-400 mt-1">
              {{ formatarTempo(n.criado_em) }}
            </p>
          </div>
          <span v-if="!n.lida" class="w-2 h-2 bg-indigo-500 rounded-full shrink-0 mt-2" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'

const svc = servicoNotificacoes()
const cliente = useSupabaseClient()
const user = useSupabaseUser()

const aberto = ref(false)
const carregando = ref(false)
const lista = ref<any[]>([])
const containerRef = ref<HTMLElement | null>(null)

const naoLidas = computed(() => lista.value.filter(n => !n.lida).length)

function icone(tipo: string) {
  const mapa: Record<string, string> = {
    tarefa_atribuida: '📋',
    comentario: '💬',
    prazo: '⏰',
    subtarefa: '🔗',
    convite: '✉️',
    geral: '📢',
  }
  return mapa[tipo] || '🔔'
}

function formatarTempo(iso: string) {
  const diff = Date.now() - new Date(iso).getTime()
  const min = Math.floor(diff / 60000)
  if (min < 1) return 'agora'
  if (min < 60) return `${min}min atrás`
  const h = Math.floor(min / 60)
  if (h < 24) return `${h}h atrás`
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

async function alternarDropdown() {
  aberto.value = !aberto.value
  if (aberto.value) await carregar()
}

async function abrirNotificacao(n: any) {
  if (!n.lida) {
    n.lida = true
    await svc.marcarLida(n.id)
  }
}

async function lerTodas() {
  lista.value.forEach(n => (n.lida = true))
  await svc.marcarTodasLidas()
}

function fecharSeClicarFora(e: MouseEvent) {
  if (containerRef.value && !containerRef.value.contains(e.target as Node)) {
    aberto.value = false
  }
}

let canal: any = null

onMounted(async () => {
  await carregar()
  document.addEventListener('click', fecharSeClicarFora)

  if (user.value) {
    canal = cliente
      .channel('notificacoes-usuario')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notificacoes',
          filter: `usuario_id=eq.${user.value.id}`,
        },
        (payload) => {
          lista.value.unshift(payload.new)
        }
      )
      .subscribe()
  }
})

onUnmounted(() => {
  document.removeEventListener('click', fecharSeClicarFora)
  if (canal) cliente.removeChannel(canal)
})
</script>
