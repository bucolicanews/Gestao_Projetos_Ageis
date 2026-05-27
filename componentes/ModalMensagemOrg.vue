<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg flex flex-col max-h-[90vh]">

      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100 shrink-0">
        <div class="flex items-center gap-3">
          <span class="text-2xl">💬</span>
          <div>
            <h2 class="font-bold text-slate-800">Enviar Mensagem</h2>
            <p class="text-xs text-slate-400">{{ org.nome }}</p>
          </div>
        </div>
        <button
          type="button"
          @click="$emit('fechar')"
          class="w-8 h-8 rounded-full flex items-center justify-center text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition text-lg font-bold"
        >×</button>
      </div>

      <!-- Body -->
      <form @submit.prevent="enviar" class="flex flex-col gap-4 p-6 overflow-y-auto">

        <!-- Destino (compacto) -->
        <div class="flex gap-4 text-sm">
          <div class="flex-1 rounded-xl border px-3 py-2.5"
            :class="org.telefone ? 'border-green-200 bg-green-50' : 'border-amber-200 bg-amber-50'">
            <p class="text-[10px] font-semibold uppercase tracking-wide mb-0.5"
              :class="org.telefone ? 'text-green-600' : 'text-amber-600'">
              📱 WhatsApp
            </p>
            <p class="font-medium text-slate-700 text-xs">{{ org.telefone || 'Não cadastrado' }}</p>
          </div>
          <div class="flex-1 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5">
            <p class="text-[10px] font-semibold uppercase tracking-wide text-slate-400 mb-0.5">✉ Email</p>
            <p class="font-medium text-slate-700 text-xs truncate">{{ org.email_contato || org.dono?.email || '—' }}</p>
          </div>
        </div>

        <!-- Aviso sem telefone -->
        <div v-if="!org.telefone"
          class="flex items-start gap-2 p-3 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-700">
          <span class="mt-0.5 shrink-0">⚠️</span>
          <span>Telefone não cadastrado. Edite a organização para adicionar antes de enviar via WhatsApp.</span>
        </div>

        <!-- Templates rápidos -->
        <div>
          <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Templates rápidos</p>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="t in templates"
              :key="t.label"
              type="button"
              class="text-xs px-3 py-1.5 rounded-full border transition"
              :class="form.mensagem === t.texto
                ? 'bg-primaria text-white border-primaria'
                : 'bg-white text-slate-600 border-slate-200 hover:border-primaria hover:text-primaria'"
              @click="form.mensagem = t.texto"
            >{{ t.label }}</button>
          </div>
        </div>

        <!-- Textarea -->
        <div>
          <label class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2 block">
            Mensagem *
          </label>
          <textarea
            v-model="form.mensagem"
            required
            rows="4"
            placeholder="Digite ou selecione um template acima..."
            class="w-full border border-slate-200 rounded-xl px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primaria resize-none transition"
          />
          <p class="text-[11px] text-slate-400 mt-1.5">
            Variáveis:
            <code class="bg-slate-100 rounded px-1">{nome}</code>
            <code class="bg-slate-100 rounded px-1 ml-1">{plano}</code>
            <code class="bg-slate-100 rounded px-1 ml-1">{vencimento}</code>
          </p>
        </div>

        <!-- Preview interpolado -->
        <div v-if="form.mensagem" class="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3">
          <p class="text-[10px] font-semibold uppercase tracking-wide text-slate-400 mb-1.5">Preview</p>
          <p class="text-sm text-slate-700 whitespace-pre-wrap">{{ mensagemInterpolada }}</p>
        </div>

        <!-- Feedback -->
        <div v-if="n8n.erro.value" class="p-3 bg-red-50 border border-red-100 rounded-xl text-sm text-red-600">
          {{ n8n.erro.value }}
        </div>
        <div v-if="sucesso" class="p-3 bg-green-50 border border-green-100 rounded-xl text-sm text-green-700 flex items-center gap-2">
          <span>✓</span> Mensagem enviada com sucesso!
        </div>

      </form>

      <!-- Footer fixo -->
      <div class="flex justify-end gap-3 px-6 py-4 border-t border-slate-100 shrink-0">
        <button type="button" @click="$emit('fechar')" class="botao-secundario">Fechar</button>
        <button
          type="button"
          :disabled="n8n.enviando.value || sucesso || !form.mensagem"
          class="botao-primario"
          @click="enviar"
        >
          <span v-if="n8n.enviando.value">Enviando...</span>
          <span v-else>📤 Enviar via n8n</span>
        </button>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import type { OrgAdmin } from '~/servicos/servicoOrganizacoesAdmin'

const props = defineProps<{ org: OrgAdmin }>()
const emit = defineEmits<{ fechar: []; enviado: [] }>()

const n8n = useN8n()
const sucesso = ref(false)
const form = reactive({ mensagem: '' })

const templatesFallback = [
  { label: '⏰ Vencimento próximo', texto: `Olá {nome}! Seu plano {plano} está próximo do vencimento ({vencimento}). Renove agora para manter o acesso.` },
  { label: '❌ Plano vencido',      texto: `Olá {nome}! Seu plano {plano} venceu. Entre em contato para reativar.` },
  { label: '👋 Boas-vindas',        texto: `Olá {nome}! Seja bem-vindo ao sistema. Seu plano {plano} está ativo.` },
  { label: '🔒 Conta bloqueada',    texto: `Olá {nome}! Sua conta foi temporariamente bloqueada. Entre em contato conosco.` },
]
const templates = ref<{ label: string; texto: string }[]>(templatesFallback)

onMounted(async () => {
  const cfg = useConfiguracoesSistema()
  const dados = await cfg.carregar()
  const chaves: Array<{ chave: string; label: string }> = [
    { chave: 'msg_cadastro',            label: '👋 Boas-vindas' },
    { chave: 'msg_bloqueio',            label: '🔒 Bloqueio' },
    { chave: 'msg_mensagem_manual',     label: '💬 Manual' },
    { chave: 'msg_vencimento_iminente', label: '⚠️ Vencimento iminente' },
    { chave: 'msg_dia_vencimento',      label: '📅 Dia do vencimento' },
    { chave: 'msg_apos_vencimento',     label: '🔴 Após vencimento' },
  ]
  const doDb = chaves
    .filter(c => dados[c.chave])
    .map(c => ({ label: c.label, texto: dados[c.chave] }))
  if (doDb.length) templates.value = doDb
})

const mensagemInterpolada = computed(() =>
  form.mensagem
    .replace(/{nome}/g, props.org.nome)
    .replace(/{plano}/g, props.org.planos?.titulo ?? props.org.plano ?? '')
    .replace(/{vencimento}/g, props.org.vencimento
      ? new Date(props.org.vencimento).toLocaleDateString('pt-BR')
      : 'não definido'
    )
)

async function enviar() {
  const ok = await n8n.enviarMensagem({
    org_id: props.org.id,
    org_nome: props.org.nome,
    telefone: props.org.telefone ?? '',
    email: props.org.email_contato ?? props.org.dono?.email ?? '',
    mensagem: mensagemInterpolada.value,
    tipo: 'mensagem_manual',
    plano: props.org.planos?.titulo ?? props.org.plano ?? '',
    vencimento: props.org.vencimento,
  })
  if (ok) {
    sucesso.value = true
    emit('enviado')
    setTimeout(() => emit('fechar'), 1500)
  }
}
</script>
