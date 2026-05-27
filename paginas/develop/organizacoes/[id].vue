<template>
  <div>
    <div v-if="verificando" class="flex items-center justify-center h-40 text-slate-400">Verificando...</div>

    <template v-else-if="isDevelopAdmin">
      <!-- Header -->
      <div class="flex items-center gap-3 mb-6">
        <NuxtLink to="/develop/organizacoes" class="text-slate-400 hover:text-primaria text-lg">←</NuxtLink>
        <div class="flex-1">
          <h1 class="text-2xl font-bold">{{ org?.nome ?? 'Carregando...' }}</h1>
          <p class="text-sm text-slate-500 mt-0.5">Detalhe da organização</p>
        </div>
        <div v-if="org" class="flex gap-2">
          <button class="botao-secundario text-sm" @click="abrirEdicao">✏️ Editar</button>
          <button
            class="text-sm px-4 py-2 rounded-lg font-medium transition"
            :class="org.status === 'bloqueado' ? 'bg-green-100 text-green-700 hover:bg-green-200' : 'bg-amber-100 text-amber-700 hover:bg-amber-200'"
            @click="abrirBloqueio"
          >
            {{ org.status === 'bloqueado' ? '🔓 Desbloquear' : '🔒 Bloquear' }}
          </button>
          <button class="botao-primario text-sm" @click="abrirMensagem">💬 Mensagem</button>
        </div>
      </div>

      <div v-if="carregando" class="text-slate-400 text-sm">Carregando...</div>

      <template v-else-if="org">
        <div class="grid md:grid-cols-3 gap-6">

          <!-- Coluna esquerda: info -->
          <div class="md:col-span-2 flex flex-col gap-5">

            <!-- Dados principais -->
            <div class="cartao">
              <h3 class="font-semibold text-sm mb-4 text-slate-700">Informações Gerais</h3>
              <div class="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p class="text-xs text-slate-400 mb-0.5">Status</p>
                  <span class="text-xs px-2 py-0.5 rounded-full font-semibold" :class="corStatus(org.status)">
                    {{ org.status }}
                  </span>
                </div>
                <div>
                  <p class="text-xs text-slate-400 mb-0.5">Plano</p>
                  <p class="font-medium">{{ org.planos?.titulo ?? org.plano ?? '—' }}</p>
                  <p v-if="org.planos" class="text-xs text-slate-400">R$ {{ Number(org.planos.preco).toFixed(2) }}/mês</p>
                </div>
                <div>
                  <p class="text-xs text-slate-400 mb-0.5">Vencimento</p>
                  <p class="font-medium" :class="vencimentoProximo(org.vencimento) ? 'text-amber-600' : ''">
                    {{ org.vencimento ? new Date(org.vencimento).toLocaleDateString('pt-BR') : '—' }}
                    <span v-if="vencimentoProximo(org.vencimento)" class="text-xs ml-1">⚠ Próximo</span>
                  </p>
                </div>
                <div>
                  <p class="text-xs text-slate-400 mb-0.5">Criada em</p>
                  <p class="font-medium">{{ new Date(org.criado_em).toLocaleDateString('pt-BR') }}</p>
                </div>
                <div>
                  <p class="text-xs text-slate-400 mb-0.5">Telefone (WhatsApp)</p>
                  <p class="font-medium">{{ org.telefone || '—' }}</p>
                </div>
                <div>
                  <p class="text-xs text-slate-400 mb-0.5">Email contato</p>
                  <p class="font-medium">{{ org.email_contato || org.dono?.email || '—' }}</p>
                </div>
              </div>

              <div v-if="org.status === 'bloqueado'" class="mt-4 p-3 bg-red-50 rounded-lg border border-red-100">
                <p class="text-xs font-semibold text-red-700 mb-1">Bloqueada em {{ new Date(org.bloqueado_em!).toLocaleDateString('pt-BR') }}</p>
                <p class="text-xs text-red-600">{{ org.bloqueado_motivo || 'Sem motivo informado.' }}</p>
              </div>
            </div>

            <!-- Usuários da org -->
            <div class="cartao">
              <h3 class="font-semibold text-sm mb-4 text-slate-700">Usuários ({{ usuarios.length }})</h3>
              <div class="flex flex-col gap-2">
                <div
                  v-for="u in usuarios" :key="u.id"
                  class="flex items-center justify-between py-2 border-b border-slate-50 last:border-0"
                >
                  <div>
                    <p class="text-sm font-medium">{{ u.nome }}</p>
                    <p class="text-xs text-slate-400">{{ u.email }}</p>
                  </div>
                  <span class="text-xs px-2 py-0.5 rounded-full bg-slate-100 text-slate-600">{{ u.perfil }}</span>
                </div>
                <p v-if="!usuarios.length" class="text-sm text-slate-400 py-4 text-center">Nenhum usuário.</p>
              </div>
            </div>
          </div>

          <!-- Coluna direita: histórico de mensagens -->
          <div class="cartao flex flex-col">
            <div class="flex justify-between items-center mb-4">
              <h3 class="font-semibold text-sm text-slate-700">Histórico de Mensagens</h3>
              <button class="text-xs text-primaria hover:underline" @click="abrirMensagem">+ Enviar</button>
            </div>
            <div class="flex flex-col gap-3 flex-1">
              <div
                v-for="msg in mensagens" :key="msg.id"
                class="p-3 rounded-lg border border-slate-100 text-xs"
              >
                <div class="flex justify-between items-start mb-1">
                  <span class="font-semibold text-slate-600">{{ msg.tipo }}</span>
                  <span
                    class="px-1.5 py-0.5 rounded text-[10px] font-medium"
                    :class="msg.status === 'enviado' ? 'bg-green-100 text-green-700' : msg.status === 'falhou' ? 'bg-red-100 text-red-700' : 'bg-blue-100 text-blue-700'"
                  >{{ msg.status }}</span>
                </div>
                <p class="text-slate-600 line-clamp-2">{{ msg.mensagem }}</p>
                <p class="text-slate-400 mt-1">{{ new Date(msg.enviado_em).toLocaleString('pt-BR') }}</p>
              </div>
              <p v-if="!mensagens.length" class="text-sm text-slate-400 py-6 text-center">Nenhuma mensagem enviada.</p>
            </div>
          </div>

        </div>
      </template>

      <!-- Modais -->
      <ModalOrganizacao
        v-if="modalEdicao && org"
        :org="org"
        :planos="planos"
        @fechar="modalEdicao = false"
        @salvo="onSalvo"
      />
      <ModalBloquearOrg
        v-if="modalBloqueio && org"
        :org="org"
        @fechar="modalBloqueio = false"
        @atualizado="recarregar"
      />
      <ModalMensagemOrg
        v-if="modalMensagem && org"
        :org="org"
        @fechar="modalMensagem = false"
        @enviado="carregarMensagens"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import type { OrgAdmin } from '~/servicos/servicoOrganizacoesAdmin'

definePageMeta({ layout: 'default' })

const { isDevelopAdmin, verificando } = useDevelopAdmin()
const route = useRoute()
const svc = servicoOrganizacoesAdmin()

const org = ref<OrgAdmin | null>(null)
const usuarios = ref<any[]>([])
const mensagens = ref<any[]>([])
const planos = ref<{ id: string; titulo: string; preco: number }[]>([])
const carregando = ref(false)

const modalEdicao = ref(false)
const modalBloqueio = ref(false)
const modalMensagem = ref(false)

async function recarregar() {
  carregando.value = true
  try {
    const [orgData, usuariosData, planosData] = await Promise.all([
      svc.obter(route.params.id as string),
      svc.listarUsuarios(route.params.id as string),
      useSupabaseClient().from('planos').select('id, titulo, preco').eq('ativo', true),
    ])
    org.value = orgData
    usuarios.value = usuariosData
    planos.value = (planosData.data ?? []) as any
    await carregarMensagens()
  } finally {
    carregando.value = false
  }
}

async function carregarMensagens() {
  mensagens.value = await svc.listarMensagens(route.params.id as string)
}

onMounted(() => recarregar())

function corStatus(status: string) {
  const map: Record<string, string> = {
    ativo: 'bg-green-100 text-green-700',
    trial: 'bg-blue-100 text-blue-700',
    bloqueado: 'bg-red-100 text-red-700',
    vencido: 'bg-amber-100 text-amber-700',
    cancelado: 'bg-slate-100 text-slate-500',
  }
  return map[status] ?? 'bg-slate-100 text-slate-500'
}

function vencimentoProximo(vencimento: string | null): boolean {
  if (!vencimento) return false
  const dias = Math.ceil((new Date(vencimento).getTime() - Date.now()) / 86_400_000)
  return dias <= 7 && dias >= 0
}

function abrirEdicao() { modalEdicao.value = true }
function abrirBloqueio() { modalBloqueio.value = true }
function abrirMensagem() { modalMensagem.value = true }

function onSalvo(atualizado: OrgAdmin) {
  org.value = atualizado
  modalEdicao.value = false
}
</script>
